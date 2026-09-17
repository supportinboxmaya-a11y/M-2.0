// Maya 2.0 - Multi-Modal View
export class MultiModalView {
    constructor(app) {
        this.app = app;
        this.container = null;
        this.currentTab = 'image';
    }

    show() {
        if (!this.container) {
            this.container = document.createElement('div');
            this.container.className = 'view multimodal-view';
        }
        this.container.innerHTML = this.render();
        this.app.viewContainer.appendChild(this.container);
        this.bindEvents();
        this.loadStatus();
    }

    hide() {
        if (this.container?.parentNode) this.container.parentNode.removeChild(this.container);
    }

    render() {
        return `
            <div class="view-header">
                <h2><span class="icon">🎨</span> Multi-Modal Processing</h2>
                <div class="view-actions">
                    <span class="badge" id="mmStatus">Checking...</span>
                </div>
            </div>

            <div class="mm-tabs">
                <button class="tab-btn active" data-tab="image">🖼️ Image</button>
                <button class="tab-btn" data-tab="audio">🎵 Audio</button>
                <button class="tab-btn" data-tab="document">📄 Document</button>
            </div>

            <div class="tab-panels">
                <!-- Image Tab -->
                <div class="tab-panel active" id="imagePanel">
                    <div class="mm-upload">
                        <div class="upload-zone" id="imageDropZone">
                            <div class="upload-icon">🖼️</div>
                            <p>Drag & drop image or click to browse</p>
                            <input type="file" id="imageInput" accept="image/*" style="display: none;" />
                        </div>
                        <img id="imagePreview" class="preview-image" style="display: none;" />
                    </div>

                    <div class="mm-tasks">
                        <h4>Processing Tasks</h4>
                        <div class="task-checkboxes">
                            <label><input type="checkbox" name="imgTask" value="embed" checked> Generate Embedding</label>
                            <label><input type="checkbox" name="imgTask" value="classify"> Zero-shot Classify</label>
                        </div>
                        <div class="classify-labels" id="classifyLabels" style="display: none;">
                            <label>Labels (comma-separated):</label>
                            <input type="text" id="classifyInput" placeholder="cat, dog, car, person" />
                        </div>
                    </div>

                    <button class="btn btn-primary btn-lg" id="processImageBtn" disabled>
                        <span>🔄</span> Process Image
                    </button>

                    <div class="mm-results" id="imageResults" style="display: none;">
                        <h4>Results</h4>
                        <pre id="imageOutput"></pre>
                    </div>
                </div>

                <!-- Audio Tab -->
                <div class="tab-panel" id="audioPanel">
                    <div class="mm-upload">
                        <div class="upload-zone" id="audioDropZone">
                            <div class="upload-icon">🎵</div>
                            <p>Drag & drop audio or click to browse</p>
                            <input type="file" id="audioInput" accept="audio/*" style="display: none;" />
                        </div>
                        <audio id="audioPreview" controls style="display: none; width: 100%;"></audio>
                    </div>

                    <div class="mm-tasks">
                        <h4>Processing Options</h4>
                        <div class="task-checkboxes">
                            <label><input type="checkbox" name="audTask" value="transcribe" checked> Transcribe</label>
                            <label><input type="checkbox" name="audTask" value="translate"> Translate to English</label>
                            <label><input type="checkbox" name="audTask" value="diarize" checked> Speaker Diarization</label>
                        </div>
                    </div>

                    <button class="btn btn-primary btn-lg" id="processAudioBtn" disabled>
                        <span>🔄</span> Process Audio
                    </button>

                    <div class="mm-results" id="audioResults" style="display: none;">
                        <h4>Transcription</h4>
                        <div id="audioTranscript"></div>
                        <h4>Segments</h4>
                        <div id="audioSegments" class="segments-list"></div>
                    </div>
                </div>

                <!-- Document Tab -->
                <div class="tab-panel" id="documentPanel">
                    <div class="mm-upload">
                        <div class="upload-zone" id="docDropZone">
                            <div class="upload-icon">📄</div>
                            <p>Drag & drop PDF/image or click to browse</p>
                            <input type="file" id="docInput" accept=".pdf,image/*" style="display: none;" />
                        </div>
                        <div id="docPreview" class="preview-image" style="display: none;"></div>
                    </div>

                    <div class="mm-tasks">
                        <h4>Processing Options</h4>
                        <div class="task-checkboxes">
                            <label><input type="checkbox" name="docTask" value="layout" checked> Layout Analysis</label>
                            <label><input type="checkbox" name="docTask" value="tables" checked> Extract Tables</label>
                            <label><input type="checkbox" name="docTask" value="figures" checked> Extract Figures</label>
                        </div>
                        <div class="form-group">
                            <label>Question (optional)</label>
                            <input type="text" id="docQuestion" placeholder="Ask a question about the document..." />
                        </div>
                    </div>

                    <button class="btn btn-primary btn-lg" id="processDocBtn" disabled>
                        <span>🔄</span> Process Document
                    </button>

                    <div class="mm-results" id="docResults" style="display: none;">
                        <h4>Extracted Text</h4>
                        <pre id="docText" class="output-content"></pre>
                        <h4>Tables</h4>
                        <div id="docTables"></div>
                        <h4>Figures</h4>
                        <div id="docFigures"></div>
                        <div id="docQA" style="display: none;">
                            <h4>Answer</h4>
                            <pre id="docAnswer"></pre>
                        </div>
                    </div>
                </div>
            </div>
        `;
    }

    bindEvents() {
        // Tab switching
        this.container.querySelectorAll('.tab-btn').forEach(btn => {
            btn.addEventListener('click', () => this.switchTab(btn.dataset.tab));
        });

        // Image
        this.setupFileUpload('imageDropZone', 'imageInput', 'imagePreview', 'processImageBtn', (file) => file.type.startsWith('image/'));
        this.container.querySelectorAll('input[name="imgTask"]').forEach(cb => {
            cb.addEventListener('change', () => this.updateImageTasks());
        });
        this.container.querySelector('#processImageBtn').addEventListener('click', () => this.processImage());

        // Audio
        this.setupFileUpload('audioDropZone', 'audioInput', 'audioPreview', 'processAudioBtn', (file) => file.type.startsWith('audio/'));
        this.container.querySelector('#processAudioBtn').addEventListener('click', () => this.processAudio());

        // Document
        this.setupFileUpload('docDropZone', 'docInput', 'docPreview', 'processDocBtn', (file) => file.type === 'application/pdf' || file.type.startsWith('image/'));
        this.container.querySelector('#processDocBtn').addEventListener('click', () => this.processDocument());
    }

    setupFileUpload(dropZoneId, inputId, previewId, processBtnId, validateFn) {
        const dropZone = this.container.querySelector(`#${dropZoneId}`);
        const input = this.container.querySelector(`#${inputId}`);
        const preview = this.container.querySelector(`#${previewId}`);
        const processBtn = this.container.querySelector(`#${processBtnId}`);

        dropZone.addEventListener('click', () => input.click());
        dropZone.addEventListener('dragover', (e) => { e.preventDefault(); dropZone.classList.add('dragover'); });
        dropZone.addEventListener('dragleave', () => dropZone.classList.remove('dragover'));
        dropZone.addEventListener('drop', (e) => {
            e.preventDefault();
            dropZone.classList.remove('dragover');
            const file = e.dataTransfer.files[0];
            if (file && validateFn(file)) this.handleFile(file, input, preview, processBtn);
        });

        input.addEventListener('change', () => {
            if (input.files[0] && validateFn(input.files[0])) this.handleFile(input.files[0], input, preview, processBtn);
        });

        this.currentFiles = this.currentFiles || {};
        this.currentFiles[dropZoneId] = { input, preview, processBtn, validateFn };
    }

    handleFile(file, input, preview, processBtn) {
        this.currentFile = file;
        processBtn.disabled = false;
        
        if (file.type.startsWith('image/')) {
            const url = URL.createObjectURL(file);
            preview.src = url;
            preview.style.display = 'block';
            preview.onload = () => URL.revokeObjectURL(url);
        } else if (file.type.startsWith('audio/')) {
            preview.src = URL.createObjectURL(file);
            preview.style.display = 'block';
        } else if (file.type === 'application/pdf') {
            preview.style.display = 'none';
            preview.alt = file.name;
            preview.title = file.name;
        }
    }

    updateImageTasks() {
        const classify = this.container.querySelector('input[name="imgTask"][value="classify"]').checked;
        this.container.querySelector('#classifyLabels').style.display = classify ? 'block' : 'none';
    }

    switchTab(tab) {
        this.currentTab = tab;
        this.container.querySelectorAll('.tab-btn').forEach(btn => {
            btn.classList.toggle('active', btn.dataset.tab === tab);
        });
        this.container.querySelectorAll('.tab-panel').forEach(panel => {
            panel.classList.toggle('active', panel.id === tab + 'Panel');
        });
    }

    async loadStatus() {
        try {
            // Could check multi-modal status
            this.container.querySelector('#mmStatus').textContent = 'Ready';
            this.container.querySelector('#mmStatus').className = 'badge success';
        } catch (e) {
            this.container.querySelector('#mmStatus').textContent = 'Unavailable';
            this.container.querySelector('#mmStatus').className = 'badge danger';
        }
    }

    async processImage() {
        if (!this.currentFile) return;
        
        const btn = this.container.querySelector('#processImageBtn');
        btn.disabled = true;
        btn.innerHTML = '<span class="spinner"></span> Processing...';

        const tasks = Array.from(this.container.querySelectorAll('input[name="imgTask"]:checked')).map(cb => cb.value);
        const labels = this.container.querySelector('#classifyInput').value.split(',').map(s => s.trim()).filter(Boolean);

        try {
            // Convert to base64
            const base64 = await this.fileToBase64(this.currentFile);
            
            const result = await this.app.api.post('/api/v1/multimodal/image', {
                image: base64,
                tasks,
                labels
            });

            this.showImageResults(result);
            this.app.showToast('Image processed', 'success');
        } catch (e) {
            this.app.showToast('Processing failed: ' + e.message, 'error');
        } finally {
            btn.disabled = false;
            btn.innerHTML = '<span>🔄</span> Process Image';
        }
    }

    async processAudio() {
        if (!this.currentFiles?.audioDropZone?.input?.files[0]) return;
        
        const btn = this.container.querySelector('#processAudioBtn');
        btn.disabled = true;
        btn.innerHTML = '<span class="spinner"></span> Processing...';

        const tasks = Array.from(this.container.querySelectorAll('input[name="audTask"]:checked')).map(cb => cb.value);

        try {
            const file = this.currentFiles.audioDropZone.input.files[0];
            const base64 = await this.fileToBase64(file);
            
            const result = await this.app.api.post('/api/v1/multimodal/audio', {
                audio: base64,
                transcribe: tasks.includes('transcribe'),
                translate: tasks.includes('translate'),
                diarize: tasks.includes('diarize')
            });

            this.showAudioResults(result);
            this.app.showToast('Audio processed', 'success');
        } catch (e) {
            this.app.showToast('Processing failed: ' + e.message, 'error');
        } finally {
            btn.disabled = false;
            btn.innerHTML = '<span>🔄</span> Process Audio';
        }
    }

    async processDocument() {
        if (!this.currentFiles?.docDropZone?.input?.files[0]) return;
        
        const btn = this.container.querySelector('#processDocBtn');
        btn.disabled = true;
        btn.innerHTML = '<span class="spinner"></span> Processing...';

        const tasks = Array.from(this.container.querySelectorAll('input[name="docTask"]:checked')).map(cb => cb.value);
        const question = this.container.querySelector('#docQuestion').value.trim() || null;

        try {
            const file = this.currentFiles.docDropZone.input.files[0];
            const base64 = await this.fileToBase64(file);
            
            const result = await this.app.api.post('/api/v1/multimodal/document', {
                document: base64,
                extract_tables: tasks.includes('tables'),
                extract_figures: tasks.includes('figures'),
                question
            });

            this.showDocResults(result);
            this.app.showToast('Document processed', 'success');
        } catch (e) {
            this.app.showToast('Processing failed: ' + e.message, 'error');
        } finally {
            btn.disabled = false;
            btn.innerHTML = '<span>🔄</span> Process Document';
        }
    }

    fileToBase64(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => resolve(reader.result);
            reader.onerror = reject;
            reader.readAsDataURL(file);
        });
    }

    showImageResults(result) {
        const output = this.container.querySelector('#imageOutput');
        const resultsEl = this.container.querySelector('#imageResults');
        
        let html = '';
        if (result.embedding) {
            html += `<h5>Embedding</h5><pre>Vector: ${result.embedding.length} dimensions\nFirst 5: [${result.embedding.slice(0,5).join(', ')}...]</pre>`;
        }
        if (result.classification) {
            html += `<h5>Classification</h5><pre>${JSON.stringify(result.classification, null, 2)}</pre>`;
        }
        
        output.innerHTML = html || '<pre>No results</pre>';
        resultsEl.style.display = 'block';
    }

    showAudioResults(result) {
        const transcript = this.container.querySelector('#audioTranscript');
        const segments = this.container.querySelector('#audioSegments');
        const resultsEl = this.container.querySelector('#audioResults');

        transcript.innerHTML = `<p>${this.app.escapeHtml(result.text)}</p>`;
        
        if (result.segments && result.segments.length) {
            segments.innerHTML = result.segments.map(s => `
                <div class="segment">
                    <span class="segment-time">[${s.start.toFixed(1)}s - ${s.end.toFixed(1)}s]</span>
                    <span class="segment-speaker">${s.speaker || 'Unknown'}</span>
                    <span class="segment-text">${this.app.escapeHtml(s.text)}</span>
                </div>
            `).join('');
        }

        resultsEl.style.display = 'block';
    }

    showDocResults(result) {
        const resultsEl = this.container.querySelector('#docResults');
        
        this.container.querySelector('#docText').textContent = result.full_text || '(no text extracted)';
        
        const tables = this.container.querySelector('#docTables');
        if (result.tables && result.tables.length) {
            tables.innerHTML = result.tables.map((t, i) => `
                <div class="table-preview">
                    <h5>Table ${i + 1}</h5>
                    <pre>${JSON.stringify(t, null, 2)}</pre>
                </div>
            `).join('');
        } else {
            tables.innerHTML = '<p>No tables found</p>';
        }

        const figures = this.container.querySelector('#docFigures');
        if (result.figures && result.figures.length) {
            figures.innerHTML = result.figures.map((f, i) => `
                <div class="figure-preview">
                    <h5>Figure ${i + 1}</h5>
                    ${f.path ? `<img src="/api/v1/workspace/files/${f.path.split('/').pop()}" style="max-width: 100%;" />` : ''}
                    <pre>${JSON.stringify(f, null, 2)}</pre>
                </div>
            `).join('');
        } else {
            figures.innerHTML = '<p>No figures found</p>';
        }

        if (result.qa) {
            this.container.querySelector('#docQA').style.display = 'block';
            this.container.querySelector('#docAnswer').textContent = result.qa.answer || 'No answer';
        }

        resultsEl.style.display = 'block';
    }
}