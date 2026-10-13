import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/maya_api.dart';
import '../../../core/theme/maya_theme.dart';
import '../../../shared/widgets/maya_empty_state.dart';

final visionAnalyzeProvider = FutureProvider.family<Map<String, dynamic>, Map<String, String>>((ref, params) async {
  final api = ref.watch(mayaApiProvider);
  return api.visionAnalyze(image: params['image']!, prompt: params['prompt'] ?? 'Describe this image in detail.');
});

final visionOcrProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, image) async {
  final api = ref.watch(mayaApiProvider);
  return api.visionOcr(image: image);
});

class VisionScreen extends ConsumerStatefulWidget {
  const VisionScreen({super.key});

  @override
  ConsumerState<VisionScreen> createState() => _VisionScreenState();
}

class _VisionScreenState extends ConsumerState<VisionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: MayaTheme.slate900,
        appBar: AppBar(
          title: const Text('Vision AI', style: MayaTheme.headlineSmall),
          backgroundColor: MayaTheme.slate900,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {},
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: MayaTheme.neonCyan,
            labelColor: MayaTheme.neonCyan,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(icon: Icon(Icons.image_rounded), text: 'Analyze'),
              Tab(icon: Icon(Icons.text_fields_rounded), text: 'OCR'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _VisionAnalyzeTab(),
            _VisionOCRTab(),
          ],
        ),
      ),
    );
  }
}

class _VisionAnalyzeTab extends ConsumerStatefulWidget {
  const _VisionAnalyzeTab();

  @override
  ConsumerState<_VisionAnalyzeTab> createState() => _VisionAnalyzeTabState();
}

class _VisionAnalyzeTabState extends ConsumerState<_VisionAnalyzeTab> {
  final _imageController = TextEditingController();
  final _promptController = TextEditingController(text: 'Describe this image in detail.');
  bool _isAnalyzing = false;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _imageController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    if (_imageController.text.trim().isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _result = null;
    });

    try {
      final result = await ref.read(mayaApiProvider).visionAnalyze(
        image: _imageController.text.trim(),
        prompt: _promptController.text.trim(),
      );
      if (mounted) {
        setState(() => _result = result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: MayaTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Analyze Image', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Provide a base64 image, data URL, or workspace path. The AI will analyze it with your prompt.',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _imageController,
            decoration: const InputDecoration(
              labelText: 'Image (base64, data URL, or path)',
              hintText: 'data:image/png;base64,... or /workspace/image.png',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _promptController,
            decoration: const InputDecoration(
              labelText: 'Prompt',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _analyze,
              icon: _isAnalyzing
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: MayaTheme.slate900))
                  : const Icon(Icons.visibility_rounded),
              label: Text(_isAnalyzing ? 'Analyzing...' : 'Analyze Image'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MayaTheme.neonCyan,
                foregroundColor: MayaTheme.slate900,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: MayaTheme.glassCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _result!['success'] == true ? Icons.check_circle_rounded : Icons.error_rounded,
                        color: _result!['success'] == true ? MayaTheme.neonEmerald : MayaTheme.error,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _result!['success'] == true ? 'Analysis Complete' : 'Analysis Failed',
                        style: MayaTheme.titleMedium.copyWith(
                          color: _result!['success'] == true ? MayaTheme.neonEmerald : MayaTheme.error,
                        ),
                      ),
                    ],
                  ),
                  if (_result!['provider'] != null) ...[
                    const SizedBox(height: 8),
                    Text('Provider: ${_result!['provider']}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    _result!['result']?.toString() ?? _result!['error']?.toString() ?? 'No result',
                    style: MayaTheme.bodyMedium.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VisionOCRTab extends ConsumerStatefulWidget {
  const _VisionOCRTab();

  @override
  ConsumerState<_VisionOCRTab> createState() => _VisionOCRTabState();
}

class _VisionOCRTabState extends ConsumerState<_VisionOCRTab> {
  final _imageController = TextEditingController();
  bool _isProcessing = false;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _ocr() async {
    if (_imageController.text.trim().isEmpty) return;

    setState(() {
      _isProcessing = true;
      _result = null;
    });

    try {
      final result = await ref.read(mayaApiProvider).visionOcr(image: _imageController.text.trim());
      if (mounted) {
        setState(() => _result = result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: MayaTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('OCR (Text Extraction)', style: MayaTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Extract text from an image using local Tesseract or vision LLM fallback.',
            style: MayaTheme.bodyMedium.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _imageController,
            decoration: const InputDecoration(
              labelText: 'Image (base64, data URL, or path)',
              hintText: 'data:image/png;base64,... or /workspace/image.png',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _ocr,
              icon: _isProcessing
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: MayaTheme.slate900))
                  : const Icon(Icons.text_fields_rounded),
              label: Text(_isProcessing ? 'Extracting...' : 'Extract Text'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MayaTheme.neonCyan,
                foregroundColor: MayaTheme.slate900,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: MayaTheme.glassCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _result!['success'] == true ? Icons.check_circle_rounded : Icons.error_rounded,
                        color: _result!['success'] == true ? MayaTheme.neonEmerald : MayaTheme.error,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _result!['success'] == true ? 'OCR Complete' : 'OCR Failed',
                        style: MayaTheme.titleMedium.copyWith(
                          color: _result!['success'] == true ? MayaTheme.neonEmerald : MayaTheme.error,
                        ),
                      ),
                    ],
                  ),
                  if (_result!['provider'] != null) ...[
                    const SizedBox(height: 8),
                    Text('Provider: ${_result!['provider']}', style: MayaTheme.bodySmall.copyWith(color: Colors.white54)),
                  ],
                  const SizedBox(height: 12),
                  SelectableText(
                    _result!['result']?.toString() ?? _result!['error']?.toString() ?? 'No text found',
                    style: MayaTheme.bodyMedium.copyWith(fontFamily: 'monospace', color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}