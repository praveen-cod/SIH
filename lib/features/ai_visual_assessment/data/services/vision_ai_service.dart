import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vision_ai/vision_ai.dart';
import 'package:vision_ai_models/vision_ai_models.dart';

final visionAiServiceProvider = Provider.autoDispose<VisionAiService>((ref) {
 final service = VisionAiService();
 ref.onDispose(() => service.stop());
 return service;
});

class VisionAiService {
 VisionAi? _vision;
 int? _textureId;
 StreamSubscription<VisionResult>? _subscription;

 bool _isInitialized = false;
 bool get isInitialized => _isInitialized;
 
 int? get textureId => _textureId;

 Future<bool> requestCameraPermission() async {
  final status = await Permission.camera.request();
  return status.isGranted;
 }

 Future<void> initialize() async {
  if (_isInitialized) return;

  final hasPermission = await requestCameraPermission();
  if (!hasPermission) {
   throw Exception('Camera permission denied.');
  }

  final models = await VisionAiModels.ensureLoaded();

  _vision = VisionAi(
   face: const FaceConfig(detectEmotion: true, accurateMode: true),
   models: models,
  );

  _textureId = await _vision!.start();
  _isInitialized = true;
 }

 Stream<VisionResult> get resultsStream {
  if (_vision == null) {
   return const Stream.empty();
  }
  return _vision!.results;
 }

 Future<void> stop() async {
  await _subscription?.cancel();
  if (_vision != null) {
   await _vision!.stop();
   await _vision!.dispose();
   _vision = null;
   _textureId = null;
   _isInitialized = false;
  }
 }
}
