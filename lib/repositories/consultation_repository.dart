import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/consultation_model.dart';
import '../services/consultation_service.dart';
import '../services/tts_service.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import '../features/ai_visual_assessment/presentation/pages/ai_visual_assessment_page.dart';

/// Provider for ConsultationService
final consultationServiceProvider = Provider<ConsultationService>((ref) {
 return ConsultationService();
});

/// Provider for TextToSpeechService
final ttsServiceProvider = Provider<TextToSpeechService>((ref) {
 final service = TextToSpeechService();
 ref.onDispose(() {
  service.dispose();
 });
 return service;
});

/// State held by the ConsultationNotifier
class ConsultationState {
 final String? sessionId;
 final bool isGuest;
 final List<ConsultationMessage> messages;
 final ExtractedIntake intake;
 final ConsultationUIState uiState;
 final ConsultationSummaryModel? summary;
 final String? errorMessage;
 final String currentLanguage;

 const ConsultationState({
  this.sessionId,
  this.isGuest = true,
  this.messages = const [],
  this.intake = const ExtractedIntake(),
  this.uiState = ConsultationUIState.idle,
  this.summary,
  this.errorMessage,
  this.currentLanguage = 'en',
 });

 ConsultationState copyWith({
  String? sessionId,
  bool? isGuest,
  List<ConsultationMessage>? messages,
  ExtractedIntake? intake,
  ConsultationUIState? uiState,
  ConsultationSummaryModel? summary,
  String? errorMessage,
  String? currentLanguage,
  bool clearError = false,
 }) {
  return ConsultationState(
   sessionId: sessionId ?? this.sessionId,
   isGuest: isGuest ?? this.isGuest,
   messages: messages ?? this.messages,
   intake: intake ?? this.intake,
   uiState: uiState ?? this.uiState,
   summary: summary ?? this.summary,
   errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
   currentLanguage: currentLanguage ?? this.currentLanguage,
  );
 }
}

/// State notifier managing consultation session lifecycle and messages
class ConsultationNotifier extends StateNotifier<ConsultationState> {
 final ConsultationService _service;
 final TextToSpeechService _tts;

 ConsultationNotifier(this._service, this._tts) : super(const ConsultationState());

 TextToSpeechService get tts => _tts;

 /// Resets the consultation state completely (e.g. on logout)
 void reset() {
  state = const ConsultationState();
 }

 /// Initializes or resets the consultation
 Future<void> initSession({String? patientId, bool isGuest = true, String? language}) async {
  final langCode = language ?? state.currentLanguage;

  // Prevent resetting session if it's already active (e.g., on device rotation)
  if (state.sessionId != null && state.uiState != ConsultationUIState.idle) {
   if (state.isGuest == isGuest && state.currentLanguage == langCode) {
    return; // Keep existing session
   }
  }

  _locationFetched = false;

  state = state.copyWith(
   uiState: ConsultationUIState.processing,
   isGuest: isGuest,
   messages: [],
   intake: const ExtractedIntake(),
   currentLanguage: langCode,
   clearError: true,
  );

  try {
   final sessionData = await _service.startSession(
    patientId: patientId,
    language: langCode,
   );
   final sessionId = sessionData['session_id'] as String;
   final initialMsg = sessionData['initial_message'] as String;
   final intakeMap = sessionData['intake_data'] as Map<String, dynamic>?;
   final serverLang = sessionData['language'] as String? ?? langCode;

   final initialMessageObj = ConsultationMessage(
    id: 'msg_0',
    role: ChatRole.ai,
    content: initialMsg,
    timestamp: DateTime.now(),
    language: serverLang,
   );

   state = state.copyWith(
    sessionId: sessionId,
    isGuest: sessionData['is_guest'] ?? isGuest,
    messages: [initialMessageObj],
    currentLanguage: serverLang,
    intake: intakeMap != null
      ? ExtractedIntake.fromJson(intakeMap)
      : const ExtractedIntake(),
    uiState: ConsultationUIState.idle,
   );

   // Speak opening message in user's preferred language if auto-speak is enabled
   if (_tts.autoSpeakEnabled) {
    _tts.speak(initialMsg, languageCode: serverLang);
   }
  } catch (e) {
   state = state.copyWith(
    uiState: ConsultationUIState.error,
    errorMessage: 'Failed to start consultation session.',
   );
  }
 }

 Future<void> uploadDocument(String base64Content, String mimeType, {String? language}) async {
  if (state.sessionId == null) return;
  final sid = state.sessionId!;
  
  state = state.copyWith(uiState: ConsultationUIState.processing);
  
  try {
   final analysis = await _service.uploadDocument(
    sessionId: sid,
    fileBase64: base64Content,
    mimeType: mimeType,
    language: language ?? state.currentLanguage,
   );
   
   if (analysis != null) {
    // Add system message with result
    final sysMsg = ConsultationMessage(
     id: DateTime.now().millisecondsSinceEpoch.toString(),
     role: ChatRole.system,
     content: analysis,
     timestamp: DateTime.now(),
    );
    state = state.copyWith(
     messages: [...state.messages, sysMsg],
     uiState: ConsultationUIState.idle,
    );
   } else {
    state = state.copyWith(
     errorMessage: 'Failed to analyze document',
     uiState: ConsultationUIState.idle,
    );
   }
  } catch (e) {
   state = state.copyWith(
    errorMessage: 'Upload failed: $e',
    uiState: ConsultationUIState.idle,
   );
  }
 }

 /// Sends a patient message, transitions UI to processing, and receives AI reply
 Future<void> sendPatientMessage(String text, {String? language}) async {
  final cleanText = text.trim();
  if (cleanText.isEmpty || state.sessionId == null) return;
  final effectiveLang = language ?? state.currentLanguage;

  // 1. Append patient message immediately
  final patientMsg = ConsultationMessage(
   id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
   role: ChatRole.patient,
   content: cleanText,
   timestamp: DateTime.now(),
   language: effectiveLang,
  );

  state = state.copyWith(
   messages: [...state.messages, patientMsg],
   uiState: ConsultationUIState.processing,
   clearError: true,
  );

  try {
   // 2. Call backend
   final res = await _service.sendMessage(
    sessionId: state.sessionId!,
    message: cleanText,
    language: language,
   );

   final responseText = res['response_text'] as String;
   final lang = res['language'] as String? ?? 'en';
   final isEmergency = res['should_flag_emergency'] as bool? ?? false;
   final isComplete = res['intake_complete'] as bool? ?? false;
   final extData = res['extracted_data'] as Map<String, dynamic>?;

   // 3. Append AI reply
   final aiMsg = ConsultationMessage(
    id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
    role: ChatRole.ai,
    content: responseText,
    timestamp: DateTime.now(),
    language: lang,
    isEmergencyWarning: isEmergency,
   );

   ConsultationUIState nextState = ConsultationUIState.idle;
   if (isEmergency) {
    nextState = ConsultationUIState.emergency;
    
    // Attempt to get location and update if not already done for this session
    _fetchAndUpdateLocation();
    _uploadEmergencyImage();
   } else if (isComplete) {
    nextState = ConsultationUIState.completed;
   }

   state = state.copyWith(
    messages: [...state.messages, aiMsg],
    uiState: nextState,
    currentLanguage: lang,
    intake: extData != null ? ExtractedIntake.fromJson(extData) : state.intake,
   );

   // Auto-speak AI response in the detected/responded language (ta, hi, te, en)
   if (_tts.autoSpeakEnabled) {
    _tts.speak(responseText, languageCode: lang);
   }

   // If intake completed, auto-fetch summary
   if (isComplete) {
    await loadSummary();
   }
  } catch (e) {
   state = state.copyWith(
    uiState: ConsultationUIState.error,
    errorMessage: 'Unable to process message. Please retry.',
   );
  }
 }

 bool _locationFetched = false;
 bool _emergencyImageUploaded = false;

 Future<void> _uploadEmergencyImage() async {
  if (_emergencyImageUploaded || state.sessionId == null) return;
  _emergencyImageUploaded = true;

  try {
   final imageBytes = await emergencyScreenshotController.capture(
       delay: const Duration(milliseconds: 500),
   );
   
   if (imageBytes != null) {
       final base64Image = base64Encode(imageBytes);
       await _service.uploadEmergencyImage(
        state.sessionId!,
        base64Image,
       );
   }
  } catch (e) {
   // Silently fail if image cannot be uploaded
  }
 }

 Future<void> _fetchAndUpdateLocation() async {
  if (_locationFetched || state.sessionId == null) return;
  _locationFetched = true;

  try {
   LocationPermission permission = await Geolocator.checkPermission();
   if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
     return;
    }
   }

   if (permission == LocationPermission.deniedForever) {
    return;
   }

   Position position = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
   );

   await _service.updateLocation(
    state.sessionId!,
    position.latitude.toString(),
    position.longitude.toString(),
   );
  } catch (e) {
   // Silently fail if location cannot be fetched
  }
 }

 /// Sets voice listening mode
 void setListening(bool listening) {
  state = state.copyWith(
   uiState: listening ? ConsultationUIState.listening : ConsultationUIState.idle,
  );
 }

 /// Fetches final summary
 Future<void> loadSummary() async {
  if (state.sessionId == null) return;
  try {
   final sum = await _service.getSummary(state.sessionId!);
   if (sum != null) {
    // Blend with collected intake to ensure patient's actual inputs are preserved
    final enriched = sum.copyWith(
     chiefComplaint: (state.intake.chiefComplaint != null &&
         state.intake.chiefComplaint!.isNotEmpty)
       ? state.intake.chiefComplaint
       : sum.chiefComplaint,
     symptoms: state.intake.symptoms.isNotEmpty
       ? state.intake.symptoms
       : sum.symptoms,
     duration: state.intake.duration ?? sum.duration,
     severity: state.intake.severity ?? sum.severity,
    );
    state = state.copyWith(summary: enriched);
   }
  } catch (e) {
   // Ignore background summary load error
  }
 }

 /// Ends the conversation explicitly, marks intake complete, and produces summary
 Future<ConsultationSummaryModel?> endConsultation() async {
  final sId = state.sessionId ?? 'session_${DateTime.now().millisecondsSinceEpoch}';
  final intake = state.intake.copyWith(intakeComplete: true);
  state = state.copyWith(
   uiState: ConsultationUIState.completed,
   intake: intake,
  );

  ConsultationSummaryModel? sum;
  try {
   sum = await _service.getSummary(sId);
  } catch (_) {}

  final effectiveName = intake.name ?? (state.isGuest ? 'Guest Patient' : 'Praveen Kumar');
  final effectiveComplaint = (intake.chiefComplaint != null && intake.chiefComplaint!.isNotEmpty)
    ? intake.chiefComplaint!
    : (sum?.chiefComplaint ?? 'Medical Consultation');
  final effectiveSymptoms = intake.symptoms.isNotEmpty
    ? intake.symptoms
    : (sum != null && sum.symptoms.isNotEmpty ? sum.symptoms : const ['Fever', 'Headache']);

  final resolved = (sum ??
      ConsultationSummaryModel(
       sessionId: sId,
       patientName: effectiveName,
       age: intake.age ?? 22,
       gender: intake.gender ?? 'Male',
       chiefComplaint: effectiveComplaint,
       symptoms: effectiveSymptoms,
       duration: intake.duration ?? '2 days',
       severity: intake.severity ?? 'Moderate',
       language: state.currentLanguage,
       isEmergency: intake.shouldFlagEmergency,
       completedAt: DateTime.now(),
      ))
    .copyWith(
   patientName: effectiveName,
   chiefComplaint: effectiveComplaint,
   symptoms: effectiveSymptoms,
   duration: intake.duration ?? sum?.duration ?? '2 days',
   severity: intake.severity ?? sum?.severity ?? 'Moderate',
   isEmergency: intake.shouldFlagEmergency || (sum?.isEmergency ?? false),
  );

  state = state.copyWith(summary: resolved);
  return resolved;
 }

 /// Saves patient edits to the consultation summary
 Future<void> updateSummary(ConsultationSummaryModel updated) async {
  state = state.copyWith(
   summary: updated,
   intake: state.intake.copyWith(
    chiefComplaint: updated.chiefComplaint,
    symptoms: updated.symptoms,
    duration: updated.duration,
    severity: updated.severity,
   ),
  );

  if (state.sessionId != null) {
   try {
    await _service.updateSummary(state.sessionId!, updated);
   } catch (_) {}
  }
 }
}

/// Riverpod Provider for ConsultationNotifier
final consultationProvider =
  StateNotifierProvider<ConsultationNotifier, ConsultationState>((ref) {
 final service = ref.watch(consultationServiceProvider);
 final tts = ref.watch(ttsServiceProvider);
 return ConsultationNotifier(service, tts);
});
