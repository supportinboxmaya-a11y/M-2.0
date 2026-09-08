"""
Maya 2.0 — Multi-Modal Perception (Phase 4)
============================================
Vision encoder (CLIP/SigLIP), Audio processor (Whisper + diarization),
Document understanding (LayoutLM/Donut). Optimized for Oracle ARM64.
"""

import asyncio
import base64
import io
import os
import tempfile
import time
import uuid
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple, Union

import numpy as np
from PIL import Image

from config.settings import STORAGE_DIR, WORKSPACE_DIR


MULTIMODAL_DIR = STORAGE_DIR / "multimodal"
MULTIMODAL_DIR.mkdir(parents=True, exist_ok=True)
MODEL_CACHE_DIR = MULTIMODAL_DIR / "models"
MODEL_CACHE_DIR.mkdir(parents=True, exist_ok=True)


@dataclass
class VisionEmbedding:
    """Vision embedding result."""
    embedding: np.ndarray
    model: str
    dimensions: int
    processing_time_ms: float


@dataclass
class AudioTranscript:
    """Audio transcription result."""
    text: str
    segments: List[Dict]  # {start, end, text, speaker}
    language: str
    duration: float
    processing_time_ms: float


@dataclass
class DocumentElement:
    """Document layout element."""
    type: str  # text, table, figure, title, header, footer
    bbox: List[float]  # [x1, y1, x2, y2] normalized 0-1
    content: str
    confidence: float
    metadata: Dict = field(default_factory=dict)


@dataclass
class ParsedDocument:
    """Parsed document result."""
    elements: List[DocumentElement]
    full_text: str
    tables: List[Dict]
    images: List[Dict]
    metadata: Dict
    processing_time_ms: float


class VisionEncoder:
    """
    Vision encoder using CLIP/SigLIP for image/video embeddings.
    Supports: image similarity, zero-shot classification, visual search.
    """
    
    def __init__(
        self,
        model_name: str = "ViT-B-32",
        pretrained: str = "openai",
        device: str = "cpu",
        cache_dir: str = None,
    ):
        self.model_name = model_name
        self.pretrained = pretrained
        self.device = device
        self.cache_dir = cache_dir or str(MODEL_CACHE_DIR)
        self._model = None
        self._preprocess = None
        self._tokenizer = None
        self._dimension = 512
    
    async def initialize(self) -> None:
        """Initialize the vision model."""
        try:
            import open_clip
            import torch
        except ImportError:
            raise RuntimeError("open_clip_torch not installed. Run: pip install open_clip_torch")
        
        self._model, _, self._preprocess = open_clip.create_model_and_transforms(
            self.model_name,
            pretrained=self.pretrained,
            device=self.device,
            cache_dir=self.cache_dir,
        )
        self._tokenizer = open_clip.get_tokenizer(self.model_name)
        self._model.eval()
        
        # Get embedding dimension
        with torch.no_grad():
            dummy = torch.randn(1, 3, 224, 224).to(self.device)
            dummy_emb = self._model.encode_image(dummy)
            self._dimension = dummy_emb.shape[-1]
        
        print(f"✅ Vision encoder initialized: {self.model_name} ({self._dimension}D)")
    
    async def embed_image(
        self, 
        image: Union[str, Path, Image.Image, bytes],
    ) -> VisionEmbedding:
        """Generate embedding for an image."""
        import torch
        
        start_time = time.time()
        
        # Load image
        if isinstance(image, (str, Path)):
            pil_image = Image.open(image).convert("RGB")
        elif isinstance(image, bytes):
            pil_image = Image.open(io.BytesIO(image)).convert("RGB")
        elif isinstance(image, Image.Image):
            pil_image = image.convert("RGB")
        else:
            raise ValueError(f"Unsupported image type: {type(image)}")
        
        # Preprocess
        image_tensor = self._preprocess(pil_image).unsqueeze(0).to(self.device)
        
        # Embed
        with torch.no_grad():
            embedding = self._model.encode_image(image_tensor)
            embedding = embedding / embedding.norm(dim=-1, keepdim=True)
            embedding = embedding.cpu().numpy().astype(np.float32).flatten()
        
        return VisionEmbedding(
            embedding=embedding,
            model=self.model_name,
            dimensions=self._dimension,
            processing_time_ms=(time.time() - start_time) * 1000,
        )
    
    async def embed_images_batch(self, images: List[Union[str, Path, Image.Image, bytes]]) -> List[VisionEmbedding]:
        """Embed multiple images efficiently."""
        import torch
        
        start_time = time.time()
        tensors = []
        valid_indices = []
        
        for i, image in enumerate(images):
            try:
                if isinstance(image, (str, Path)):
                    pil_image = Image.open(image).convert("RGB")
                elif isinstance(image, bytes):
                    pil_image = Image.open(io.BytesIO(image)).convert("RGB")
                elif isinstance(image, Image.Image):
                    pil_image = image.convert("RGB")
                else:
                    continue
                
                tensors.append(self._preprocess(pil_image))
                valid_indices.append(i)
            except Exception:
                pass
        
        if not tensors:
            return []
        
        batch = torch.stack(tensors).to(self.device)
        
        with torch.no_grad():
            embeddings = self._model.encode_image(batch)
            embeddings = embeddings / embeddings.norm(dim=-1, keepdim=True)
            embeddings = embeddings.cpu().numpy().astype(np.float32)
        
        results = [None] * len(images)
        for idx, emb in zip(valid_indices, embeddings):
            results[idx] = VisionEmbedding(
                embedding=emb.flatten(),
                model=self.model_name,
                dimensions=self._dimension,
                processing_time_ms=(time.time() - start_time) * 1000,
            )
        
        return results
    
    async def embed_text(self, texts: List[str]) -> np.ndarray:
        """Embed text using CLIP text encoder."""
        import torch
        
        tokens = self._tokenizer(texts).to(self.device)
        
        with torch.no_grad():
            text_features = self._model.encode_text(tokens)
            text_features = text_features / text_features.norm(dim=-1, keepdim=True)
            return text_features.cpu().numpy().astype(np.float32)
    
    async def similarity(self, image_emb: np.ndarray, text_emb: np.ndarray) -> float:
        """Compute cosine similarity between image and text embeddings."""
        return float(np.dot(image_emb, text_emb) / (np.linalg.norm(image_emb) * np.linalg.norm(text_emb)))
    
    async def zero_shot_classify(
        self, 
        image: Union[str, Path, Image.Image, bytes],
        labels: List[str],
        templates: List[str] = None,
    ) -> Dict[str, float]:
        """Zero-shot image classification."""
        templates = templates or ["a photo of a {}", "an image of a {}", "a picture of a {}"]
        
        image_emb = await self.embed_image(image)
        
        # Create text prompts
        prompts = []
        for label in labels:
            for template in templates:
                prompts.append(template.format(label))
        
        text_embs = await self.embed_text(prompts)
        
        # Average over templates per label
        similarities = {}
        for i, label in enumerate(labels):
            template_embs = text_embs[i*len(templates):(i+1)*len(templates)]
            avg_emb = template_embs.mean(axis=0)
            sim = await self.similarity(image_emb.embedding, avg_emb)
            similarities[label] = sim
        
        return similarities
    
    @property
    def dimension(self) -> int:
        return self._dimension


class AudioProcessor:
    """
    Audio processor using Whisper for transcription + speaker diarization.
    Supports: transcription, translation, speaker identification, VAD.
    """
    
    def __init__(
        self,
        model_size: str = "base",  # tiny, base, small, medium, large
        device: str = "cpu",
        compute_type: str = "int8",
        cache_dir: str = None,
    ):
        self.model_size = model_size
        self.device = device
        self.compute_type = compute_type
        self.cache_dir = cache_dir or str(MODEL_CACHE_DIR)
        self._model = None
        self._diarization_pipeline = None
    
    async def initialize(self) -> None:
        """Initialize Whisper and diarization."""
        try:
            from faster_whisper import WhisperModel
        except ImportError:
            raise RuntimeError("faster-whisper not installed. Run: pip install faster-whisper")
        
        self._model = WhisperModel(
            self.model_size,
            device=self.device,
            compute_type=self.compute_type,
            download_root=self.cache_dir,
        )
        
        # Try to load diarization (requires pyannote.audio)
        try:
            from pyannote.audio import Pipeline
            self._diarization_pipeline = Pipeline.from_pretrained(
                "pyannote/speaker-diarization-3.1",
                use_auth_token=os.getenv("HUGGINGFACE_TOKEN"),
            )
        except Exception:
            print("⚠️  Speaker diarization not available (requires pyannote.audio + HF token)")
        
        print(f"✅ Audio processor initialized: Whisper {self.model_size}")
    
    async def transcribe(
        self,
        audio: Union[str, Path, bytes, io.BytesIO],
        language: str = None,
        task: str = "transcribe",  # transcribe or translate
        vad_filter: bool = True,
        word_timestamps: bool = True,
    ) -> AudioTranscript:
        """Transcribe audio file."""
        start_time = time.time()
        
        # Save bytes to temp file if needed
        if isinstance(audio, bytes):
            with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
                f.write(audio)
                audio_path = f.name
        elif isinstance(audio, io.BytesIO):
            with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
                f.write(audio.getvalue())
                audio_path = f.name
        else:
            audio_path = str(audio)
        
        try:
            segments, info = self._model.transcribe(
                audio_path,
                language=language,
                task=task,
                vad_filter=vad_filter,
                word_timestamps=word_timestamps,
            )
            
            segment_list = []
            full_text = []
            
            for segment in segments:
                seg_dict = {
                    "start": segment.start,
                    "end": segment.end,
                    "text": segment.text.strip(),
                    "speaker": "unknown",
                }
                if word_timestamps and segment.words:
                    seg_dict["words"] = [
                        {"word": w.word, "start": w.start, "end": w.end, "probability": w.probability}
                        for w in segment.words
                    ]
                segment_list.append(seg_dict)
                full_text.append(segment.text.strip())
            
            # Run diarization if available
            if self._diarization_pipeline:
                segment_list = await self._diarize(audio_path, segment_list)
            
            return AudioTranscript(
                text=" ".join(full_text),
                segments=segment_list,
                language=info.language,
                duration=info.duration,
                processing_time_ms=(time.time() - start_time) * 1000,
            )
        finally:
            # Cleanup temp file
            if isinstance(audio, (bytes, io.BytesIO)) and os.path.exists(audio_path):
                os.unlink(audio_path)
    
    async def _diarize(self, audio_path: str, segments: List[Dict]) -> List[Dict]:
        """Run speaker diarization and assign speakers to segments."""
        try:
            diarization = self._diarization_pipeline(audio_path)
            
            # Build speaker timeline
            speaker_timeline = []
            for turn, _, speaker in diarization.itertracks(yield_label=True):
                speaker_timeline.append({
                    "start": turn.start,
                    "end": turn.end,
                    "speaker": speaker,
                })
            
            # Assign speakers to segments
            for segment in segments:
                seg_mid = (segment["start"] + segment["end"]) / 2
                for turn in speaker_timeline:
                    if turn["start"] <= seg_mid <= turn["end"]:
                        segment["speaker"] = turn["speaker"]
                        break
            
            return segments
        except Exception as e:
            print(f"Diarization failed: {e}")
            return segments
    
    async def transcribe_streaming(
        self,
        audio_chunks: AsyncGenerator[bytes, None],
        chunk_duration: float = 5.0,
    ) -> AsyncGenerator[AudioTranscript, None]:
        """Streaming transcription for real-time audio."""
        # This would use a streaming Whisper implementation
        # For now, accumulate chunks and transcribe periodically
        buffer = bytearray()
        last_transcribe = time.time()
        
        async for chunk in audio_chunks:
            buffer.extend(chunk)
            
            if time.time() - last_transcribe >= chunk_duration:
                if len(buffer) > 1000:  # Minimum audio size
                    transcript = await self.transcribe(bytes(buffer))
                    yield transcript
                    buffer.clear()
                    last_transcribe = time.time()


class DocumentUnderstanding:
    """
    Document understanding using LayoutLM/Donut for layout analysis,
    table extraction, and form understanding.
    """
    
    def __init__(
        self,
        layout_model: str = "microsoft/layoutlmv3-base",
        detection_model: str = "facebook/detr-resnet-50",
        device: str = "cpu",
        cache_dir: str = None,
    ):
        self.layout_model_name = layout_model
        self.detection_model_name = detection_model
        self.device = device
        self.cache_dir = cache_dir or str(MODEL_CACHE_DIR)
        self._layout_processor = None
        self._layout_model = None
        self._detection_model = None
        self._donut_processor = None
        self._donut_model = None
    
    async def initialize(self) -> None:
        """Initialize document understanding models."""
        try:
            from transformers import (
                LayoutLMv3Processor, LayoutLMv3ForTokenClassification,
                DetrImageProcessor, DetrForObjectDetection,
                DonutProcessor, VisionEncoderDecoderModel,
            )
            import torch
        except ImportError:
            raise RuntimeError("transformers not installed. Run: pip install transformers torch")
        
        # LayoutLM for token classification (NER on documents)
        self._layout_processor = LayoutLMv3Processor.from_pretrained(
            self.layout_model_name,
            cache_dir=self.cache_dir,
        )
        self._layout_model = LayoutLMv3ForTokenClassification.from_pretrained(
            self.layout_model_name,
            cache_dir=self.cache_dir,
        ).to(self.device)
        
        # DETR for layout detection (tables, figures, etc.)
        self._detection_processor = DetrImageProcessor.from_pretrained(
            self.detection_model_name,
            cache_dir=self.cache_dir,
        )
        self._detection_model = DetrForObjectDetection.from_pretrained(
            self.detection_model_name,
            cache_dir=self.cache_dir,
        ).to(self.device)
        
        # Donut for document parsing (optional)
        try:
            self._donut_processor = DonutProcessor.from_pretrained(
                "naver-clova-ix/donut-base-finetuned-docvqa",
                cache_dir=self.cache_dir,
            )
            self._donut_model = VisionEncoderDecoderModel.from_pretrained(
                "naver-clova-ix/donut-base-finetuned-docvqa",
                cache_dir=self.cache_dir,
            ).to(self.device)
        except Exception:
            print("⚠️  Donut model not loaded (optional)")
        
        print(f"✅ Document understanding initialized: {self.layout_model_name}")
    
    async def parse_document(
        self,
        document: Union[str, Path, Image.Image, bytes],
        extract_tables: bool = True,
        extract_figures: bool = True,
        ocr: bool = True,
    ) -> ParsedDocument:
        """Parse document layout and extract structured content."""
        import torch
        from PIL import Image
        
        start_time = time.time()
        
        # Load image
        if isinstance(document, (str, Path)):
            image = Image.open(document).convert("RGB")
        elif isinstance(document, bytes):
            image = Image.open(io.BytesIO(document)).convert("RGB")
        elif isinstance(document, Image.Image):
            image = document.convert("RGB")
        else:
            raise ValueError(f"Unsupported document type: {type(document)}")
        
        width, height = image.size
        
        # Layout detection with DETR
        detection_inputs = self._detection_processor(images=image, return_tensors="pt").to(self.device)
        with torch.no_grad():
            detection_outputs = self._detection_model(**detection_inputs)
        
        # Process detections
        target_sizes = torch.tensor([image.size[::-1]]).to(self.device)
        results = self._detection_processor.post_process_object_detection(
            detection_outputs, target_sizes=target_sizes, threshold=0.5
        )[0]
        
        # LayoutLM token classification
        layout_inputs = self._layout_processor(
            image, return_tensors="pt", truncation=True, max_length=512
        ).to(self.device)
        
        with torch.no_grad():
            layout_outputs = self._layout_model(**layout_inputs)
        
        # Extract elements
        elements = await self._extract_elements(
            image, layout_inputs, layout_outputs, results, width, height
        )
        
        # Extract tables
        tables = []
        if extract_tables:
            tables = await self._extract_tables(image, results, width, height)
        
        # Extract figures
        images_list = []
        if extract_figures:
            images_list = await self._extract_figures(image, results, width, height)
        
        # Full text
        full_text = " ".join([e.content for e in elements if e.type == "text"])
        
        return ParsedDocument(
            elements=elements,
            full_text=full_text,
            tables=tables,
            images=images_list,
            metadata={
                "page_size": [width, height],
                "element_count": len(elements),
                "table_count": len(tables),
                "figure_count": len(images_list),
            },
            processing_time_ms=(time.time() - start_time) * 1000,
        )
    
    async def _extract_elements(
        self, image: Image.Image, layout_inputs, layout_outputs, detection_results, width: int, height: int
    ) -> List[DocumentElement]:
        """Extract document elements from model outputs."""
        import torch
        
        elements = []
        
        # Get layout detection boxes
        boxes = detection_results["boxes"].cpu().numpy()
        labels = detection_results["labels"].cpu().numpy()
        scores = detection_results["scores"].cpu().numpy()
        
        label_map = self._detection_model.config.id2label
        
        for box, label_id, score in zip(boxes, labels, scores):
            x1, y1, x2, y2 = box
            label = label_map.get(label_id, "unknown")
            
            # Normalize bbox
            norm_box = [x1/width, y1/height, x2/width, y2/height]
            
            # Crop and OCR the region (simplified)
            content = ""
            if label in ["text", "title", "header", "footer"]:
                crop = image.crop((int(x1), int(y1), int(x2), int(y2)))
                # Would run OCR here - placeholder
                content = f"[{label} content]"
            
            elements.append(DocumentElement(
                type=label,
                bbox=norm_box,
                content=content,
                confidence=float(score),
                metadata={"label_id": int(label_id)},
            ))
        
        return elements
    
    async def _extract_tables(
        self, image: Image.Image, detection_results, width: int, height: int
    ) -> List[Dict]:
        """Extract table structures."""
        import torch
        
        tables = []
        boxes = detection_results["boxes"].cpu().numpy()
        labels = detection_results["labels"].cpu().numpy()
        
        label_map = self._detection_model.config.id2label
        
        for box, label_id in zip(boxes, labels):
            label = label_map.get(label_id, "")
            if "table" in label.lower():
                x1, y1, x2, y2 = box
                crop = image.crop((int(x1), int(y1), int(x2), int(y2)))
                
                # Would use table structure recognition (TableTransformer, etc.)
                # Placeholder for now
                tables.append({
                    "bbox": [x1/width, y1/height, x2/width, y2/height],
                    "rows": 0,
                    "cols": 0,
                    "data": [],
                })
        
        return tables
    
    async def _extract_figures(
        self, image: Image.Image, detection_results, width: int, height: int
    ) -> List[Dict]:
        """Extract figures/images."""
        import torch
        
        figures = []
        boxes = detection_results["boxes"].cpu().numpy()
        labels = detection_results["labels"].cpu().numpy()
        
        label_map = self._detection_model.config.id2label
        
        for box, label_id in zip(boxes, labels):
            label = label_map.get(label_id, "")
            if label.lower() in ["figure", "picture", "image", "chart"]:
                x1, y1, x2, y2 = box
                crop = image.crop((int(x1), int(y1), int(x2), int(y2)))
                
                # Save figure
                fig_path = WORKSPACE_DIR / f"figure_{uuid.uuid4().hex[:8]}.png"
                crop.save(fig_path)
                
                figures.append({
                    "bbox": [x1/width, y1/height, x2/width, y2/height],
                    "path": str(fig_path),
                    "size": crop.size,
                })
        
        return figures
    
    async def answer_question(
        self,
        document: Union[str, Path, Image.Image, bytes],
        question: str,
    ) -> Dict:
        """Visual Question Answering on document using Donut."""
        if not self._donut_model:
            return {"answer": "Donut model not available", "confidence": 0.0}
        
        import torch
        from PIL import Image
        
        if isinstance(document, (str, Path)):
            image = Image.open(document).convert("RGB")
        elif isinstance(document, bytes):
            image = Image.open(io.BytesIO(document)).convert("RGB")
        elif isinstance(document, Image.Image):
            image = document.convert("RGB")
        else:
            raise ValueError(f"Unsupported document type: {type(document)}")
        
        # Prepare Donut input
        task_prompt = f"<s_docvqa><s_question>{question}</s_question><s_answer>"
        decoder_input_ids = self._donut_processor.tokenizer(
            task_prompt, add_special_tokens=False, return_tensors="pt"
        ).input_ids
        
        pixel_values = self._donut_processor(image, return_tensors="pt").pixel_values
        
        with torch.no_grad():
            outputs = self._donut_model.generate(
                pixel_values.to(self.device),
                decoder_input_ids=decoder_input_ids.to(self.device),
                max_length=512,
                pad_token_id=self._donut_processor.tokenizer.pad_token_id,
                eos_token_id=self._donut_processor.tokenizer.eos_token_id,
                use_cache=True,
                bad_words_ids=[[self._donut_processor.tokenizer.unk_token_id]],
                return_dict_in_generate=True,
            )
        
        sequence = self._donut_processor.batch_decode(outputs.sequences)[0]
        sequence = sequence.replace(self._donut_processor.tokenizer.eos_token, "").replace(self._donut_processor.tokenizer.pad_token, "")
        answer = sequence.split("<s_answer>")[-1].strip()
        
        return {"answer": answer, "confidence": 0.8}


class MultiModalProcessor:
    """Unified multi-modal processor combining vision, audio, and document understanding."""
    
    def __init__(
        self,
        vision_model: str = "ViT-B-32",
        audio_model: str = "base",
        document_model: str = "microsoft/layoutlmv3-base",
        device: str = "cpu",
    ):
        self.vision = VisionEncoder(model_name=vision_model, device=device)
        self.audio = AudioProcessor(model_size=audio_model, device=device)
        self.document = DocumentUnderstanding(layout_model=document_model, device=device)
        self._initialized = False
    
    async def initialize(self) -> None:
        """Initialize all modalities."""
        await asyncio.gather(
            self.vision.initialize(),
            self.audio.initialize(),
            self.document.initialize(),
        )
        self._initialized = True
        print("✅ Multi-modal processor fully initialized")
    
    async def process_image(
        self, 
        image: Union[str, Path, Image.Image, bytes],
        tasks: List[str] = None,  # embed, classify, caption
        labels: List[str] = None,
    ) -> Dict:
        """Process image with multiple vision tasks."""
        tasks = tasks or ["embed"]
        results = {}
        
        if "embed" in tasks:
            emb = await self.vision.embed_image(image)
            results["embedding"] = emb.embedding.tolist()
            results["embedding_model"] = emb.model
        
        if "classify" in tasks and labels:
            results["classification"] = await self.vision.zero_shot_classify(image, labels)
        
        return results
    
    async def process_audio(
        self,
        audio: Union[str, Path, bytes],
        transcribe: bool = True,
        translate: bool = False,
        diarize: bool = True,
    ) -> Dict:
        """Process audio with transcription and diarization."""
        task = "translate" if translate else "transcribe"
        transcript = await self.audio.transcribe(audio, task=task)
        
        return {
            "text": transcript.text,
            "segments": transcript.segments,
            "language": transcript.language,
            "duration": transcript.duration,
        }
    
    async def process_document(
        self,
        document: Union[str, Path, Image.Image, bytes],
        extract_tables: bool = True,
        extract_figures: bool = True,
        question: str = None,
    ) -> Dict:
        """Process document with layout analysis."""
        parsed = await self.document.parse_document(
            document,
            extract_tables=extract_tables,
            extract_figures=extract_figures,
        )
        
        result = {
            "full_text": parsed.full_text,
            "elements": [
                {
                    "type": e.type,
                    "bbox": e.bbox,
                    "content": e.content,
                    "confidence": e.confidence,
                }
                for e in parsed.elements
            ],
            "tables": parsed.tables,
            "figures": parsed.images,
            "metadata": parsed.metadata,
        }
        
        if question:
            result["qa"] = await self.document.answer_question(document, question)
        
        return result


# Module singletons
_vision_encoder: Optional[VisionEncoder] = None
_audio_processor: Optional[AudioProcessor] = None
_document_understanding: Optional[DocumentUnderstanding] = None
_multimodal_processor: Optional[MultiModalProcessor] = None


async def get_vision_encoder(**kwargs) -> VisionEncoder:
    global _vision_encoder
    if _vision_encoder is None:
        _vision_encoder = VisionEncoder(**kwargs)
        await _vision_encoder.initialize()
    return _vision_encoder


async def get_audio_processor(**kwargs) -> AudioProcessor:
    global _audio_processor
    if _audio_processor is None:
        _audio_processor = AudioProcessor(**kwargs)
        await _audio_processor.initialize()
    return _audio_processor


async def get_document_understanding(**kwargs) -> DocumentUnderstanding:
    global _document_understanding
    if _document_understanding is None:
        _document_understanding = DocumentUnderstanding(**kwargs)
        await _document_understanding.initialize()
    return _document_understanding


async def get_multimodal_processor(**kwargs) -> MultiModalProcessor:
    global _multimodal_processor
    if _multimodal_processor is None:
        _multimodal_processor = MultiModalProcessor(**kwargs)
        await _multimodal_processor.initialize()
    return _multimodal_processor