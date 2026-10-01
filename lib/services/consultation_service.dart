import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/consultation_model.dart';
import '../core/config/env_config.dart';

/// Service for communicating with the FastAPI Consultation Backend
class ConsultationService {
 /// Publicly hosted backend URL accessible from any mobile device, cellular network, or Wi-Fi
 static const String lanBaseUrl = 'http://10.209.83.140:8000/api/consultations';
 static const String publicBaseUrl = 'https://witch-exists-headers-assistance.trycloudflare.com/api/consultations';
 static const String localBaseUrl = 'http://127.0.0.1:8000/api/consultations';

 /// Currently active base URL. Defaults to EnvConfig.consultationsUrl (derived from .env)
 static String? _customActiveBaseUrl;
 static String get activeBaseUrl => _customActiveBaseUrl ?? EnvConfig.consultationsUrl;
 static set activeBaseUrl(String url) => _customActiveBaseUrl = url;

 static String get baseUrl => activeBaseUrl;

 static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'bypass-tunnel-reminder': 'true',
   };

 final http.Client _client;

 ConsultationService({http.Client? client})
   : _client = client ?? http.Client();

 /// Starts a new consultation session (logged-in or guest)
 Future<Map<String, dynamic>> startSession({
  String? patientId,
  String? authToken,
  String? language,
 }) async {
  final url = Uri.parse(baseUrl);
  final langCode = language ?? 'en';
  try {
   final response = await _client
     .post(
      url,
      headers: defaultHeaders,
      body: jsonEncode({
       'patient_id': patientId,
       'auth_token': authToken,
       'language': langCode,
      }),
     )
     .timeout(const Duration(seconds: 8));

   if (response.statusCode == 200) {
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
   }
  } catch (e) {
   debugPrint('Backend connection error ($e). Using local fallback session.');
  }

  // Graceful offline fallback if backend is not started yet
  final isGuest = patientId == null;
  final initialGreeting = _getLocalizedInitialGreeting(langCode, isGuest: isGuest);

  return {
   'session_id': 'local_${DateTime.now().millisecondsSinceEpoch}',
   'is_guest': isGuest,
   'language': langCode,
   'initial_message': initialGreeting,
   'status': 'active',
   'intake_data': {
    if (!isGuest) ...{
     'name': 'Praveen Kumar',
     'age': 22,
     'gender': 'Male',
     'phone': '+91 9876543210',
     'email': 'praveen@healthcall.ai',
    }
   },
  };
 }

 static String _getLocalizedInitialGreeting(String langCode, {required bool isGuest}) {
  final clean = langCode.toLowerCase().trim().split('_').first.split('-').first;
  switch (clean) {
   case 'ta':
    return isGuest
      ? "வணக்கம்! நான் உங்கள் HealthCall AI மருத்துவ உதவியாளர்.\nஆரம்பிக்க உங்கள் பெயரைத் தெரிவிக்க முடியுமா?"
      : "வணக்கம் Praveen நான் உங்கள் HealthCall AI மருத்துவ உதவியாளர்.\nஉங்களுக்கு இன்று என்ன உடல்நல பிரச்சனை அல்லது அறிகுறிகள் உள்ளன?";
   case 'hi':
    return isGuest
      ? "नमस्ते! मैं आपका HealthCall AI सहायक हूँ।\nशुरू करने से पहले क्या मैं आपका नाम जान सकता हूँ?"
      : "नमस्ते Praveen मैं आपका HealthCall AI सहायक हूँ।\nआज आपको क्या स्वास्थ्य समस्या या लक्षण महसूस हो रहे हैं?";
   case 'kn':
    return isGuest
      ? "ನಮಸ್ಕಾರ! ನಾನು ನಿಮ್ಮ HealthCall AI ಸಹಾಯಕ.\nಪ್ರಾರಂಭಿಸುವ ಮೊದಲು ನಿಮ್ಮ ಹೆಸರನ್ನು ತಿಳಿಸಬಹುದೇ?"
      : "ನಮಸ್ಕಾರ Praveen ನಾನು ನಿಮ್ಮ HealthCall AI ಸಹಾಯಕ.\nಇಂದು ನಿಮಗೆ ಯಾವ ಆರೋಗ್ಯ ಸಮಸ್ಯೆ ಅಥವಾ ಲಕ್ಷಣಗಳು ಕಾಣಿಸಿಕೊಂಡಿವೆ?";
   case 'te':
    return isGuest
      ? "నమస్కారం! నేను మీ HealthCall AI అసిస్టెంట్.\nమొదలుపెట్టే ముందు మీ పేరు తెలుసుకోవచ్చా?"
      : "నమస్కారం Praveen నేను మీ HealthCall AI అసిస్టెంట్.\nఈరోజు మీకు ఎలాంటి ఆరోగ్య సమస్య లేదా లక్షణాలు ఉన్నాయి?";
   case 'ml':
    return isGuest
      ? "നമസ്കാരം! ഞാൻ നിങ്ങളുടെ HealthCall AI അസിസ്റ്റന്റ്.\nതുടങ്ങുന്നതിന് മുമ്പ് നിങ്ങളുടെ പേര് അറിയാമോ?"
      : "നമസ്കാരം Praveen ഞാൻ നിങ്ങളുടെ HealthCall AI അസിസ്റ്റന്റ്.\nഇന്ന് നിങ്ങൾക്ക് എന്തെങ്കിലും ആരോഗ്യ പ്രശ്നങ്ങളോ ലക്ഷണങ്ങളോ ഉണ്ടോ?";
   case 'bn':
    return isGuest
      ? "নমস্কার! আমি আপনার HealthCall AI সহকারী।\nশুরু করার আগে আপনার নাম জানতে পারি?"
      : "নমস্কার Praveen আমি আপনার HealthCall AI সহকারী।\nআজ আপনার কি স্বাস্থ্য সমস্যা দেখা দিচ্ছে?";
   case 'mr':
    return isGuest
      ? "नमस्कार! मी तुमचा HealthCall AI सहाय्यक आहे.\nसुरुवात करण्यापूर्वी आपले नाव जाणून घेऊ शकतो का?"
      : "नमस्कार Praveen मी तुमचा HealthCall AI सहाय्यक आहे.\nआज तुम्हाला काय आरोग्याच्या तक्रары जाणवत आहेत?";
   case 'en':
   default:
    return isGuest
      ? "Hello! I am your HealthCall AI Assistant.\nBefore we begin your health consultation, may I know your name?"
      : "Hi Praveen I'm your HealthCall AI assistant.\nWhat health problem or symptoms are you experiencing today?";
  }
 }

 /// Sends a patient message and receives structured AI response
 Future<Map<String, dynamic>> sendMessage({
  required String sessionId,
  required String message,
  String? language,
 }) async {
  final url = Uri.parse('$baseUrl/$sessionId/messages');
  try {
   final response = await _client
     .post(
      url,
      headers: defaultHeaders,
      body: jsonEncode({
       'message': message,
       'language': ?language,
      }),
     )
     .timeout(const Duration(seconds: 15));

   if (response.statusCode == 200) {
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
   }
  } catch (e) {
   debugPrint('Backend sendMessage error ($e). Using local fallback.');
  }

  // Local fallback logic
  return _localTurnFallback(message);
 }

 /// Fetches final structured consultation summary
 Future<ConsultationSummaryModel?> getSummary(String sessionId) async {
  final url = Uri.parse('$baseUrl/$sessionId/summary');
  try {
   final response = await _client
     .get(url, headers: defaultHeaders)
     .timeout(const Duration(seconds: 8));

   if (response.statusCode == 200) {
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    return ConsultationSummaryModel.fromJson(data);
   }
  } catch (e) {
   debugPrint('Backend getSummary error ($e). Using local summary fallback.');
  }

  return ConsultationSummaryModel(
   sessionId: sessionId,
   patientName: 'Praveen Kumar',
   age: 22,
   gender: 'Male',
   chiefComplaint: 'Fever and Headache',
   symptoms: const ['Fever', 'Headache', 'Mild weakness'],
   duration: '2 days',
   severity: 'Moderate',
   language: 'en',
   isEmergency: false,
   completedAt: DateTime.now(),
  );
 }

 /// Updates consultation summary in backend with patient edits
 Future<String?> uploadDocument({
  required String sessionId,
  required String fileBase64,
  required String mimeType,
  String? language,
 }) async {
  final url = Uri.parse('$baseUrl/$sessionId/documents');
  try {
   final response = await _client
     .post(
    url,
    headers: defaultHeaders,
    body: jsonEncode({
     'file_base64': fileBase64,
     'mime_type': mimeType,
     'language': language ?? 'en',
    }),
   )
     .timeout(const Duration(seconds: 25));

   if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['analysis'];
   } else {
    debugPrint('Upload failed: ${response.statusCode}');
    return null;
   }
  } catch (e) {
   debugPrint('Upload error: $e');
   return null;
  }
 }

 Future<ConsultationSummaryModel?> updateSummary(
  String sessionId,
  ConsultationSummaryModel summary,
 ) async {
  final url = Uri.parse('$baseUrl/$sessionId/summary');
  try {
   final response = await _client
     .put(
      url,
      headers: defaultHeaders,
      body: jsonEncode({
       'chief_complaint': summary.chiefComplaint,
       'symptoms': summary.symptoms,
       'duration': summary.duration,
       'severity': summary.severity,
       if (summary.clinicalSummary != null)
        'clinical_summary': summary.clinicalSummary,
       if (summary.recommendedSpecialist != null)
        'recommended_specialist': summary.recommendedSpecialist,
      }),
     )
     .timeout(const Duration(seconds: 8));

   if (response.statusCode == 200) {
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    return ConsultationSummaryModel.fromJson(data);
   }
  } catch (e) {
   debugPrint('Backend updateSummary error ($e). Returning locally updated summary.');
  }
  return summary;
 }

 Future<void> uploadEmergencyImage(String sessionId, String imageBase64) async {
  final url = Uri.parse('$baseUrl/emergencies/$sessionId/image');
  try {
   final res = await _client.post(
    url,
    headers: defaultHeaders,
    body: jsonEncode({'image_base64': imageBase64}),
   );
   if (res.statusCode != 200) {
    debugPrint('Failed to upload emergency image: ${res.body}');
   }
  } catch (e) {
   debugPrint('Error uploading emergency image: $e');
  }
 }

 /// Updates the patient's location during an emergency
 Future<void> updateLocation(
  String sessionId,
  String latitude,
  String longitude,
 ) async {
  final url = Uri.parse('$baseUrl/$sessionId/location');
  try {
   await _client
     .post(
      url,
      headers: defaultHeaders,
      body: jsonEncode({
       'latitude': latitude,
       'longitude': longitude,
      }),
     )
     .timeout(const Duration(seconds: 8));
  } catch (e) {
   debugPrint('Backend updateLocation error ($e).');
  }
 }

 /// Simple local simulation for when backend server is starting up or in standalone mode
 Map<String, dynamic> _localTurnFallback(String message) {
  final lower = message.toLowerCase();
  final isEmergency = lower.contains('chest pain') ||
    lower.contains('breathe') ||
    lower.contains('bleeding') ||
    lower.contains('stroke');

  if (isEmergency) {
   return {
    'response_text':
      ' Your symptoms may require immediate medical attention. Please contact your local emergency service or seek immediate emergency care.',
    'language': 'en',
    'extracted_data': {
     'chief_complaint': message,
     'symptoms': [message],
     'should_flag_emergency': true,
    },
    'missing_fields': <String>[],
    'should_flag_emergency': true,
    'intake_complete': false,
   };
  }

  return {
   'response_text':
     "Thank you for sharing that. How long have you had these symptoms, and how severe would you rate them?",
   'language': 'en',
   'extracted_data': {
    'chief_complaint': message,
    'symptoms': [message],
    'should_flag_emergency': false,
   },
   'missing_fields': ['duration', 'severity'],
   'should_flag_emergency': false,
   'intake_complete': false,
  };
 }
}

