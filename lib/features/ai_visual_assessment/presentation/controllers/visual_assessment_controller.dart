import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/vision_ai_service.dart';

class EmotionRecord {
 final DateTime timestamp;
 final String emotion;
 final double confidence;

 EmotionRecord(this.timestamp, this.emotion, this.confidence);
}

class VisualAssessmentState {
 final bool isInitializing;
 final String? error;
 final bool hasPermission;
 final bool faceDetected;
 final bool multipleFaces;
 final String? currentEmotion;
 final double currentConfidence;
 final String guidanceMessage;
 final List<EmotionRecord> history;
 final DateTime? sessionStartTime;

 VisualAssessmentState({
  this.isInitializing = true,
  this.error,
  this.hasPermission = false,
  this.faceDetected = false,
  this.multipleFaces = false,
  this.currentEmotion,
  this.currentConfidence = 0.0,
  this.guidanceMessage = 'Initializing...',
  this.history = const [],
  this.sessionStartTime,
 });

 VisualAssessmentState copyWith({
  bool? isInitializing,
  String? error,
  bool? hasPermission,
  bool? faceDetected,
  bool? multipleFaces,
  String? currentEmotion,
  double? currentConfidence,
  String? guidanceMessage,
  List<EmotionRecord>? history,
  DateTime? sessionStartTime,
 }) {
  return VisualAssessmentState(
   isInitializing: isInitializing ?? this.isInitializing,
   error: error, // explicitly allow nulling out error
   hasPermission: hasPermission ?? this.hasPermission,
   faceDetected: faceDetected ?? this.faceDetected,
   multipleFaces: multipleFaces ?? this.multipleFaces,
   currentEmotion: currentEmotion ?? this.currentEmotion,
   currentConfidence: currentConfidence ?? this.currentConfidence,
   guidanceMessage: guidanceMessage ?? this.guidanceMessage,
   history: history ?? this.history,
   sessionStartTime: sessionStartTime ?? this.sessionStartTime,
  );
 }
}

final visualAssessmentControllerProvider =
  StateNotifierProvider.autoDispose<VisualAssessmentController, VisualAssessmentState>((ref) {
 final service = ref.watch(visionAiServiceProvider);
 return VisualAssessmentController(service);
});

class VisualAssessmentController extends StateNotifier<VisualAssessmentState> {
 final VisionAiService _service;
 StreamSubscription? _subscription;
 DateTime? _lastInferenceTime;
 // Throttle inference updates to 2 Hz for UI smoothness
 static const int _throttleMs = 500;

 VisualAssessmentController(this._service) : super(VisualAssessmentState()) {
  _init();
 }

 Future<void> _init() async {
  try {
   await _service.initialize();
   state = state.copyWith(
    isInitializing: false,
    hasPermission: true,
    sessionStartTime: DateTime.now(),
    guidanceMessage: 'Position your face inside the frame',
   );
   _listenToResults();
  } catch (e) {
   state = state.copyWith(
    isInitializing: false,
    hasPermission: false,
    error: e.toString(),
    guidanceMessage: 'Camera access required.',
   );
  }
 }

 void _listenToResults() {
  _subscription = _service.resultsStream.listen((result) {
   final now = DateTime.now();
   if (_lastInferenceTime != null &&
     now.difference(_lastInferenceTime!).inMilliseconds < _throttleMs) {
    return; // throttle
   }
   _lastInferenceTime = now;

   final faces = result.faces;
   if (faces.isEmpty) {
    state = state.copyWith(
     faceDetected: false,
     multipleFaces: false,
     guidanceMessage: 'No face detected',
     currentEmotion: null,
     currentConfidence: 0.0,
    );
    return;
   }

   if (faces.length > 1) {
    state = state.copyWith(
     faceDetected: true,
     multipleFaces: true,
     guidanceMessage: 'Please ensure only one patient is visible',
     currentEmotion: null,
     currentConfidence: 0.0,
    );
    return;
   }

   final face = faces.first;
   final emotion = face.emotion; // e.g. FaceEmotion.happy
   final confidence = face.emotionConfidence; // e.g. 0.92
   
   String guidance = 'Face detected';
   // Simple logic based on bounding box or distance if available
   // The API may provide face distance, but we keep it simple here.
   
   final newRecord = EmotionRecord(now, emotion.name, confidence);
   final newHistory = List<EmotionRecord>.from(state.history)..add(newRecord);

   // keep rolling history of last 5 minutes (or 600 records at 2Hz max)
   if (newHistory.length > 600) {
    newHistory.removeAt(0);
   }

   state = state.copyWith(
    faceDetected: true,
    multipleFaces: false,
    guidanceMessage: guidance,
    currentEmotion: emotion.name,
    currentConfidence: confidence,
    history: newHistory,
   );
  });
 }

 Map<String, double> getExpressionDistribution() {
  if (state.history.isEmpty) return {};
  final counts = <String, int>{};
  for (final rec in state.history) {
   counts[rec.emotion] = (counts[rec.emotion] ?? 0) + 1;
  }
  final total = state.history.length;
  final dist = <String, double>{};
  counts.forEach((key, val) {
   dist[key] = val / total;
  });
  return dist;
 }

 String getDominantExpression() {
  final dist = getExpressionDistribution();
  if (dist.isEmpty) return 'Unknown';
  return dist.entries.reduce((a, b) => a.value > b.value ? a : b).key;
 }

 @override
 void dispose() {
  _subscription?.cancel();
  _service.stop();
  super.dispose();
 }
}
