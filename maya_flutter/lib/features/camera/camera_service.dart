import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'api_service.dart';
import 'app_config.dart';

part 'camera_service.g.dart';

@riverpod
CameraService cameraService(Ref ref) {
  return CameraService(ref.read(apiServiceProvider));
}

class CameraService {
  final ApiService _apiService;
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final ObjectDetector _objectDetector = ObjectDetector(options: ObjectDetectorOptions(mode: DetectionMode.single));

  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isInitialized = false;
  bool _isProcessing = false;

  CameraService(this._apiService);

  CameraController? get controller => _controller;
  List<CameraDescription> get cameras => _cameras;
  int get selectedCameraIndex => _selectedCameraIndex;
  bool get isInitialized => _isInitialized;
  bool get isProcessing => _isProcessing;

  Future<void> initialize() async {
    await _requestPermissions();
    _cameras = await availableCameras();

    if (_cameras.isNotEmpty) {
      _selectedCameraIndex = _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.back);
      if (_selectedCameraIndex == -1) _selectedCameraIndex = 0;
      await _initializeController();
    }
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.microphone.request();
    await Permission.storage.request();
  }

  Future<void> _initializeController() async {
    if (_cameras.isEmpty) return;

    _controller = CameraController(
      _cameras[_selectedCameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _controller!.initialize();
    _isInitialized = true;
  }

  Future<void> switchCamera() async {
    if (_cameras.length < 2) return;

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _controller?.dispose();
    await _initializeController();
  }

  Future<XFile?> takePhoto() async {
    if (!_isInitialized || _controller == null) return null;

    try {
      final photo = await _controller!.takePicture();
      return photo;
    } catch (e) {
      debugPrint('Error taking photo: $e');
      return null;
    }
  }

  Future<VisionAnalysisResult?> analyzePhoto(XFile photo, {String? prompt}) async {
    try {
      return await _apiService.analyzeImage(File(photo.path), prompt: prompt);
    } catch (e) {
      debugPrint('Vision analysis error: $e');
      return null;
    }
  }

  Future<OcrResult?> extractTextFromPhoto(XFile photo) async {
    try {
      final inputImage = InputImage.fromFilePath(photo.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      return OcrResult(
        text: recognizedText.text,
        regions: recognizedText.blocks.map((block) => OcrRegion(
          text: block.text,
          bounds: Rect.fromLTRB(
            block.boundingBox.left.toDouble(),
            block.boundingBox.top.toDouble(),
            block.boundingBox.right.toDouble(),
            block.boundingBox.bottom.toDouble(),
          ),
          confidence: 1.0,
        )).toList(),
      );
    } catch (e) {
      debugPrint('OCR error: $e');
      return null;
    }
  }

  Future<List<DetectedObject>> detectObjects(XFile photo) async {
    try {
      final inputImage = InputImage.fromFilePath(photo.path);
      return await _objectDetector.processImage(inputImage);
    } catch (e) {
      debugPrint('Object detection error: $e');
      return [];
    }
  }

  Future<Uint8List?> getImageBytes(XFile photo) async {
    return await File(photo.path).readAsBytes();
  }

  Stream<CameraImage> get imageStream async* {
    if (_controller == null || !_controller!.value.isInitialized) return;

    await for (final image in _controller!.getImageStream()) {
      yield image;
    }
  }

  void setFlashMode(FlashMode mode) {
    _controller?.setFlashMode(mode);
  }

  void setZoomLevel(double zoom) {
    _controller?.setZoomLevel(zoom.clamp(
      _controller!.value.minAvailableZoom,
      _controller!.value.maxAvailableZoom,
    ));
  }

  double get maxZoomLevel => _controller?.value.maxAvailableZoom ?? 1.0;
  double get minZoomLevel => _controller?.value.minAvailableZoom ?? 1.0;

  void setFocusPoint(Offset point) {
    if (_controller != null && _controller!.value.isInitialized) {
      _controller!.setFocusPoint(point);
      _controller!.setExposurePoint(point);
    }
  }

  void dispose() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }
}