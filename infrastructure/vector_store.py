"""
Maya 2.0 — Vector Store Adapters (Phase 1-2)
============================================
Persistent vector storage with ChromaDB and Qdrant backends.
Hybrid retrieval combining BM25 + dense embeddings.
Optimized for Oracle ARM64 VPS.
"""

import asyncio
import json
import os
import time
import uuid
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple, Literal

from config.settings import STORAGE_DIR


VECTOR_STORE_DIR = STORAGE_DIR / "vector_store"
VECTOR_STORE_DIR.mkdir(parents=True, exist_ok=True)


@dataclass
class VectorDocument:
    """A document in the vector store."""
    id: str
    content: str
    metadata: Dict = field(default_factory=dict)
    embedding: List[float] = field(default_factory=list)
    created_at: float = field(default_factory=time.time)


@dataclass
class SearchResult:
    """Search result with score."""
    document: VectorDocument
    score: float
    distance: float


class VectorStore(ABC):
    """Abstract base class for vector stores."""
    
    @abstractmethod
    async def initialize(self) -> None:
        """Initialize the vector store."""
        pass
    
    @abstractmethod
    async def add_documents(self, documents: List[VectorDocument]) -> List[str]:
        """Add documents to the store."""
        pass
    
    @abstractmethod
    async def search(
        self, query: str, limit: int = 10, 
        filter_metadata: Dict = None,
        hybrid: bool = True,
    ) -> List[SearchResult]:
        """Search for similar documents."""
        pass
    
    @abstractmethod
    async def search_by_vector(
        self, vector: List[float], limit: int = 10,
        filter_metadata: Dict = None,
    ) -> List[SearchResult]:
        """Search by vector directly."""
        pass
    
    @abstractmethod
    async def delete(self, ids: List[str]) -> int:
        """Delete documents by IDs."""
        pass
    
    @abstractmethod
    async def get(self, ids: List[str]) -> List[VectorDocument]:
        """Get documents by IDs."""
        pass
    
    @abstractmethod
    async def count(self) -> int:
        """Get total document count."""
        pass
    
    @abstractmethod
    async def clear(self) -> None:
        """Clear all documents."""
        pass
    
    @abstractmethod
    async def get_stats(self) -> Dict:
        """Get store statistics."""
        pass


class EmbeddingProvider:
    """Embedding provider with multiple backends."""
    
    def __init__(
        self,
        provider: Literal["sentence_transformers", "openai", "cohere", "huggingface"] = "sentence_transformers",
        model: str = "all-MiniLM-L6-v2",
        api_key: str = None,
        device: str = "cpu",
    ):
        self.provider = provider
        self.model_name = model
        self.api_key = api_key
        self.device = device
        self._model = None
        self._dimension = None
    
    async def initialize(self) -> None:
        """Initialize the embedding model."""
        if self.provider == "sentence_transformers":
            try:
                from sentence_transformers import SentenceTransformer
                self._model = SentenceTransformer(self.model_name, device=self.device)
                self._dimension = self._model.get_sentence_embedding_dimension()
            except ImportError:
                raise RuntimeError("sentence-transformers not installed. Run: pip install sentence-transformers")
        elif self.provider == "openai":
            try:
                import openai
                self._client = openai.AsyncOpenAI(api_key=self.api_key)
                self._dimension = 1536  # text-embedding-3-small
            except ImportError:
                raise RuntimeError("openai not installed. Run: pip install openai")
        elif self.provider == "cohere":
            try:
                import cohere
                self._client = cohere.AsyncClient(api_key=self.api_key)
                self._dimension = 1024  # embed-english-v3.0
            except ImportError:
                raise RuntimeError("cohere not installed. Run: pip install cohere")
        else:
            raise ValueError(f"Unknown provider: {self.provider}")
    
    async def embed(self, texts: List[str]) -> List[List[float]]:
        """Generate embeddings for texts."""
        if self.provider == "sentence_transformers":
            if self._model is None:
                await self.initialize()
            embeddings = self._model.encode(texts, convert_to_tensor=False)
            return embeddings.tolist()
        elif self.provider == "openai":
            response = await self._client.embeddings.create(
                input=texts,
                model="text-embedding-3-small",
            )
            return [d.embedding for d in response.data]
        elif self.provider == "cohere":
            response = await self._client.embed(
                texts=texts,
                model="embed-english-v3.0",
                input_type="search_document",
            )
            return response.embeddings
        raise ValueError(f"Unknown provider: {self.provider}")
    
    async def embed_query(self, query: str) -> List[float]:
        """Generate embedding for a query."""
        if self.provider == "sentence_transformers":
            if self._model is None:
                await self.initialize()
            embedding = self._model.encode([query], convert_to_tensor=False)
            return embedding[0].tolist()
        elif self.provider == "openai":
            response = await self._client.embeddings.create(
                input=[query],
                model="text-embedding-3-small",
            )
            return response.data[0].embedding
        elif self.provider == "cohere":
            response = await self._client.embed(
                texts=[query],
                model="embed-english-v3.0",
                input_type="search_query",
            )
            return response.embeddings[0]
        raise ValueError(f"Unknown provider: {self.provider}")
    
    @property
    def dimension(self) -> int:
        return self._dimension


class ChromaVectorStore(VectorStore):
    """ChromaDB vector store implementation."""
    
    def __init__(
        self,
        collection_name: str = "maya",
        persist_directory: str = None,
        embedding_provider: EmbeddingProvider = None,
        distance_metric: Literal["cosine", "l2", "ip"] = "cosine",
    ):
        self.collection_name = collection_name
        self.persist_directory = persist_directory or str(VECTOR_STORE_DIR / "chroma")
        self.embedding_provider = embedding_provider or EmbeddingProvider()
        self.distance_metric = distance_metric
        self._client = None
        self._collection = None
    
    async def initialize(self) -> None:
        """Initialize ChromaDB."""
        try:
            import chromadb
            from chromadb.config import Settings
        except ImportError:
            raise RuntimeError("chromadb not installed. Run: pip install chromadb")
        
        await self.embedding_provider.initialize()
        
        self._client = chromadb.PersistentClient(
            path=self.persist_directory,
            settings=Settings(
                anonymized_telemetry=False,
                allow_reset=True,
            ),
        )
        
        self._collection = self._client.get_or_create_collection(
            name=self.collection_name,
            metadata={"hnsw:space": self.distance_metric},
        )
        
        print(f"✅ ChromaDB initialized: {self.collection_name} at {self.persist_directory}")
    
    async def add_documents(self, documents: List[VectorDocument]) -> List[str]:
        if not documents:
            return []
        
        # Generate embeddings if not provided
        texts = [d.content for d in documents]
        ids = [d.id for d in documents]
        metadatas = [d.metadata for d in documents]
        
        embeddings = []
        for doc in documents:
            if doc.embedding:
                embeddings.append(doc.embedding)
            else:
                emb = await self.embedding_provider.embed([doc.content])
                embeddings.append(emb[0])
        
        self._collection.add(
            ids=ids,
            embeddings=embeddings,
            documents=texts,
            metadatas=metadatas,
        )
        
        return ids
    
    async def search(
        self, query: str, limit: int = 10,
        filter_metadata: Dict = None,
        hybrid: bool = True,
    ) -> List[SearchResult]:
        query_embedding = await self.embedding_provider.embed_query(query)
        
        where = filter_metadata or {}
        
        results = self._collection.query(
            query_embeddings=[query_embedding],
            n_results=limit,
            where=where if where else None,
            include=["documents", "metadatas", "distances", "embeddings"],
        )
        
        search_results = []
        if results["ids"] and results["ids"][0]:
            for i, doc_id in enumerate(results["ids"][0]):
                doc = VectorDocument(
                    id=doc_id,
                    content=results["documents"][0][i],
                    metadata=results["metadatas"][0][i] or {},
                    embedding=results["embeddings"][0][i] if results["embeddings"] else [],
                )
                distance = results["distances"][0][i]
                # Convert distance to similarity score
                if self.distance_metric == "cosine":
                    score = 1.0 - distance
                elif self.distance_metric == "l2":
                    score = 1.0 / (1.0 + distance)
                else:
                    score = distance
                
                search_results.append(SearchResult(
                    document=doc,
                    score=score,
                    distance=distance,
                ))
        
        return search_results
    
    async def search_by_vector(
        self, vector: List[float], limit: int = 10,
        filter_metadata: Dict = None,
    ) -> List[SearchResult]:
        where = filter_metadata or {}
        
        results = self._collection.query(
            query_embeddings=[vector],
            n_results=limit,
            where=where if where else None,
            include=["documents", "metadatas", "distances", "embeddings"],
        )
        
        search_results = []
        if results["ids"] and results["ids"][0]:
            for i, doc_id in enumerate(results["ids"][0]):
                doc = VectorDocument(
                    id=doc_id,
                    content=results["documents"][0][i],
                    metadata=results["metadatas"][0][i] or {},
                    embedding=results["embeddings"][0][i] if results["embeddings"] else [],
                )
                distance = results["distances"][0][i]
                score = 1.0 - distance if self.distance_metric == "cosine" else 1.0 / (1.0 + distance)
                
                search_results.append(SearchResult(document=doc, score=score, distance=distance))
        
        return search_results
    
    async def delete(self, ids: List[str]) -> int:
        self._collection.delete(ids=ids)
        return len(ids)
    
    async def get(self, ids: List[str]) -> List[VectorDocument]:
        results = self._collection.get(ids=ids, include=["documents", "metadatas", "embeddings"])
        
        documents = []
        if results["ids"]:
            for i, doc_id in enumerate(results["ids"]):
                documents.append(VectorDocument(
                    id=doc_id,
                    content=results["documents"][i],
                    metadata=results["metadatas"][i] or {},
                    embedding=results["embeddings"][i] if results["embeddings"] else [],
                ))
        return documents
    
    async def count(self) -> int:
        return self._collection.count()
    
    async def clear(self) -> None:
        self._client.delete_collection(self.collection_name)
        self._collection = self._client.create_collection(
            name=self.collection_name,
            metadata={"hnsw:space": self.distance_metric},
        )
    
    async def get_stats(self) -> Dict:
        return {
            "backend": "chromadb",
            "collection": self.collection_name,
            "count": await self.count(),
            "persist_directory": self.persist_directory,
            "embedding_model": self.embedding_provider.model_name,
            "embedding_dimension": self.embedding_provider.dimension,
            "distance_metric": self.distance_metric,
        }


class QdrantVectorStore(VectorStore):
    """Qdrant vector store implementation."""
    
    def __init__(
        self,
        collection_name: str = "maya",
        host: str = "localhost",
        port: int = 6333,
        grpc_port: int = 6334,
        embedding_provider: EmbeddingProvider = None,
        distance_metric: Literal["Cosine", "Euclid", "Dot"] = "Cosine",
        prefer_grpc: bool = False,
    ):
        self.collection_name = collection_name
        self.host = host
        self.port = port
        self.grpc_port = grpc_port
        self.embedding_provider = embedding_provider or EmbeddingProvider()
        self.distance_metric = distance_metric
        self.prefer_grpc = prefer_grpc
        self._client = None
    
    async def initialize(self) -> None:
        """Initialize Qdrant client."""
        try:
            from qdrant_client import QdrantClient
            from qdrant_client.http import models
        except ImportError:
            raise RuntimeError("qdrant-client not installed. Run: pip install qdrant-client")
        
        await self.embedding_provider.initialize()
        
        if self.prefer_grpc:
            self._client = QdrantClient(
                host=self.host,
                grpc_port=self.grpc_port,
                prefer_grpc=True,
            )
        else:
            self._client = QdrantClient(
                host=self.host,
                port=self.port,
            )
        
        # Create collection if not exists
        collections = self._client.get_collections().collections
        collection_names = [c.name for c in collections]
        
        if self.collection_name not in collection_names:
            self._client.create_collection(
                collection_name=self.collection_name,
                vectors_config=models.VectorParams(
                    size=self.embedding_provider.dimension,
                    distance=models.Distance[self.distance_metric.upper()],
                ),
            )
            # Create payload index for common metadata fields
            self._client.create_payload_index(
                collection_name=self.collection_name,
                field_name="type",
                field_schema=models.PayloadSchemaType.KEYWORD,
            )
        
        print(f"✅ Qdrant initialized: {self.collection_name} at {self.host}:{self.port}")
    
    async def add_documents(self, documents: List[VectorDocument]) -> List[str]:
        if not documents:
            return []
        
        from qdrant_client.http import models
        
        texts = [d.content for d in documents]
        ids = [d.id for d in documents]
        
        # Generate embeddings
        embeddings = []
        for doc in documents:
            if doc.embedding:
                embeddings.append(doc.embedding)
            else:
                emb = await self.embedding_provider.embed([doc.content])
                embeddings.append(emb[0])
        
        points = [
            models.PointStruct(
                id=doc.id,
                vector=emb,
                payload={
                    "content": doc.content,
                    **doc.metadata,
                },
            )
            for doc, emb in zip(documents, embeddings)
        ]
        
        self._client.upsert(
            collection_name=self.collection_name,
            points=points,
        )
        
        return ids
    
    async def search(
        self, query: str, limit: int = 10,
        filter_metadata: Dict = None,
        hybrid: bool = True,
    ) -> List[SearchResult]:
        query_embedding = await self.embedding_provider.embed_query(query)
        return await self.search_by_vector(query_embedding, limit, filter_metadata)
    
    async def search_by_vector(
        self, vector: List[float], limit: int = 10,
        filter_metadata: Dict = None,
    ) -> List[SearchResult]:
        from qdrant_client.http import models
        
        filter_cond = None
        if filter_metadata:
            conditions = []
            for key, value in filter_metadata.items():
                conditions.append(
                    models.FieldCondition(key=key, match=models.MatchValue(value=value))
                )
            filter_cond = models.Filter(must=conditions) if conditions else None
        
        results = self._client.search(
            collection_name=self.collection_name,
            query_vector=vector,
            limit=limit,
            query_filter=filter_cond,
            with_payload=True,
            with_vectors=True,
        )
        
        search_results = []
        for hit in results:
            payload = hit.payload or {}
            content = payload.pop("content", "")
            
            doc = VectorDocument(
                id=str(hit.id),
                content=content,
                metadata=payload,
                vector=hit.vector if hasattr(hit, "vector") else [],
            )
            
            # Qdrant returns similarity score directly
            score = hit.score
            distance = 1.0 - score if self.distance_metric == "Cosine" else score
            
            search_results.append(SearchResult(document=doc, score=score, distance=distance))
        
        return search_results
    
    async def delete(self, ids: List[str]) -> int:
        from qdrant_client.http import models
        
        self._client.delete(
            collection_name=self.collection_name,
            points_selector=models.PointIdsList(points=ids),
        )
        return len(ids)
    
    async def get(self, ids: List[str]) -> List[VectorDocument]:
        from qdrant_client.http import models
        
        results = self._client.retrieve(
            collection_name=self.collection_name,
            ids=ids,
            with_payload=True,
            with_vectors=True,
        )
        
        documents = []
        for hit in results:
            payload = hit.payload or {}
            content = payload.pop("content", "")
            documents.append(VectorDocument(
                id=str(hit.id),
                content=content,
                metadata=payload,
                vector=hit.vector if hit.vector else [],
            ))
        return documents
    
    async def count(self) -> int:
        info = self._client.get_collection(self.collection_name)
        return info.points_count
    
    async def clear(self) -> None:
        from qdrant_client.http import models
        
        self._client.delete_collection(self.collection_name)
        self._client.create_collection(
            collection_name=self.collection_name,
            vectors_config=models.VectorParams(
                size=self.embedding_provider.dimension,
                distance=models.Distance[self.distance_metric.upper()],
            ),
        )
    
    async def get_stats(self) -> Dict:
        info = self._client.get_collection(self.collection_name)
        return {
            "backend": "qdrant",
            "collection": self.collection_name,
            "count": info.points_count,
            "host": self.host,
            "port": self.port,
            "embedding_model": self.embedding_provider.model_name,
            "embedding_dimension": self.embedding_provider.dimension,
            "distance_metric": self.distance_metric,
        }


class HybridRetriever:
    """Hybrid retrieval combining BM25 + dense embeddings."""
    
    def __init__(
        self,
        dense_store: VectorStore,
        bm25_weight: float = 0.3,
        dense_weight: float = 0.7,
    ):
        self.dense_store = dense_store
        self.bm25_weight = bm25_weight
        self.dense_weight = dense_weight
        self._bm25_index = None
        self._documents = {}
    
    async def add_documents(self, documents: List[VectorDocument]) -> List[str]:
        """Add documents to both stores."""
        # Add to dense store
        ids = await self.dense_store.add_documents(documents)
        
        # Update BM25 index
        await self._update_bm25(documents)
        
        return ids
    
    async def _update_bm25(self, documents: List[VectorDocument]) -> None:
        """Update BM25 index."""
        try:
            from rank_bm25 import BM25Okapi
        except ImportError:
            print("rank_bm25 not installed, BM25 disabled. Run: pip install rank_bm25")
            return
        
        for doc in documents:
            self._documents[doc.id] = doc
        
        # Rebuild index (simple approach - could be incremental)
        corpus = [doc.content.split() for doc in self._documents.values()]
        if corpus:
            self._bm25_index = BM25Okapi(corpus)
    
    async def search(
        self, query: str, limit: int = 10,
        filter_metadata: Dict = None,
    ) -> List[SearchResult]:
        """Hybrid search combining BM25 + dense."""
        # Dense search
        dense_results = await self.dense_store.search(query, limit=limit*2, filter_metadata=filter_metadata)
        
        if not self._bm25_index:
            return dense_results[:limit]
        
        # BM25 search
        query_tokens = query.split()
        bm25_scores = self._bm25_index.get_scores(query_tokens)
        doc_ids = list(self._documents.keys())
        
        bm25_results = []
        for i, score in enumerate(bm25_scores):
            if score > 0:
                bm25_results.append((doc_ids[i], score))
        
        bm25_results.sort(key=lambda x: x[1], reverse=True)
        bm25_results = bm25_results[:limit*2]
        
        # Combine scores (normalize first)
        dense_dict = {r.document.id: r for r in dense_results}
        bm25_dict = {doc_id: score for doc_id, score in bm25_results}
        
        # Normalize scores
        max_dense = max((r.score for r in dense_results), default=1.0)
        max_bm25 = max(bm25_dict.values(), default=1.0)
        
        combined = {}
        all_ids = set(dense_dict.keys()) | set(bm25_dict.keys())
        
        for doc_id in all_ids:
            dense_score = dense_dict.get(doc_id, SearchResult(None, 0, 0)).score / max_dense if max_dense > 0 else 0
            bm25_score = bm25_dict.get(doc_id, 0) / max_bm25 if max_bm25 > 0 else 0
            
            combined_score = self.dense_weight * dense_score + self.bm25_weight * bm25_score
            combined[doc_id] = combined_score
        
        # Get top results
        top_ids = sorted(combined.keys(), key=lambda x: combined[x], reverse=True)[:limit]
        
        results = []
        for doc_id in top_ids:
            if doc_id in dense_dict:
                results.append(SearchResult(
                    document=dense_dict[doc_id].document,
                    score=combined[doc_id],
                    distance=dense_dict[doc_id].distance,
                ))
            elif doc_id in self._documents:
                # BM25 only result
                results.append(SearchResult(
                    document=self._documents[doc_id],
                    score=combined[doc_id],
                    distance=1.0 - combined[doc_id],
                ))
        
        return results


# Module factory
_vector_store: Optional[VectorStore] = None
_hybrid_retriever: Optional[HybridRetriever] = None


async def get_vector_store(
    backend: Literal["chroma", "qdrant"] = "chroma",
    **kwargs,
) -> VectorStore:
    global _vector_store
    if _vector_store is None:
        if backend == "chroma":
            _vector_store = ChromaVectorStore(**kwargs)
        elif backend == "qdrant":
            _vector_store = QdrantVectorStore(**kwargs)
        else:
            raise ValueError(f"Unknown backend: {backend}")
        await _vector_store.initialize()
    return _vector_store


async def get_hybrid_retriever(
    backend: Literal["chroma", "qdrant"] = "chroma",
    **kwargs,
) -> HybridRetriever:
    global _hybrid_retriever
    if _hybrid_retriever is None:
        store = await get_vector_store(backend, **kwargs)
        _hybrid_retriever = HybridRetriever(store)
    return _hybrid_retriever