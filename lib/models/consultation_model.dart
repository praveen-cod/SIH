import 'package:equatable/equatable.dart';

/// Visual and operational states of the AI Consultation screen
enum ConsultationUIState {
 idle,
 listening,
 processing,
 responding,
 error,
 emergency,
 completed;

 String get label {
  switch (this) {
   case ConsultationUIState.idle:
    return 'Online';
   case ConsultationUIState.listening:
    return 'Listening...';
   case ConsultationUIState.processing:
    return 'Understanding...';
   case ConsultationUIState.responding:
    return 'AI is responding...';
   case ConsultationUIState.error:
    return 'Connection error';
   case ConsultationUIState.emergency:
    return 'Emergency alert';
   case ConsultationUIState.completed:
    return 'Intake completed';
  }
 }
}

/// Message role inside the chat
enum ChatRole {
 ai,
 patient,
 system;

 bool get isPatient => this == ChatRole.patient;
 bool get isAI => this == ChatRole.ai;
 bool get isSystem => this == ChatRole.system;
}

/// Single conversational chat message
class ConsultationMessage extends Equatable {
 final String id;
 final ChatRole role;
 final String content;
 final DateTime timestamp;
 final String? language;
 final bool isEmergencyWarning;

 const ConsultationMessage({
  required this.id,
  required this.role,
  required this.content,
  required this.timestamp,
  this.language,
  this.isEmergencyWarning = false,
 });

 @override
 List<Object?> get props => [id, role, content, timestamp, isEmergencyWarning];

 factory ConsultationMessage.fromJson(Map<String, dynamic> json) {
  return ConsultationMessage(
   id: json['id'] ?? '',
   role: json['role'] == 'patient' ? ChatRole.patient : ChatRole.ai,
   content: json['content'] ?? '',
   timestamp: json['timestamp'] != null
     ? DateTime.parse(json['timestamp'])
     : DateTime.now(),
   language: json['language'],
  );
 }
}

/// Structured medical data extracted so far
class ExtractedIntake extends Equatable {
 final String? name;
 final int? age;
 final String? gender;
 final String? phone;
 final String? email;
 final String? chiefComplaint;
 final List<String> symptoms;
 final String? duration;
 final String? severity;
 final String preferredLanguage;
 final bool shouldFlagEmergency;
 final bool intakeComplete;

 const ExtractedIntake({
  this.name,
  this.age,
  this.gender,
  this.phone,
  this.email,
  this.chiefComplaint,
  this.symptoms = const [],
  this.duration,
  this.severity,
  this.preferredLanguage = 'en',
  this.shouldFlagEmergency = false,
  this.intakeComplete = false,
 });

 @override
 List<Object?> get props => [
    name,
    age,
    gender,
    phone,
    email,
    chiefComplaint,
    symptoms,
    duration,
    severity,
    preferredLanguage,
    shouldFlagEmergency,
    intakeComplete,
   ];

 factory ExtractedIntake.fromJson(Map<String, dynamic> json) {
  return ExtractedIntake(
   name: json['name'],
   age: json['age'],
   gender: json['gender'],
   phone: json['phone'],
   email: json['email'],
   chiefComplaint: json['chief_complaint'],
   symptoms: (json['symptoms'] as List<dynamic>?)
       ?.map((e) => e.toString())
       .toList() ??
     [],
   duration: json['duration'],
   severity: json['severity'],
   preferredLanguage: json['preferred_language'] ?? 'en',
   shouldFlagEmergency: json['should_flag_emergency'] ?? false,
   intakeComplete: json['intake_complete'] ?? false,
  );
 }

 ExtractedIntake copyWith({
  String? name,
  int? age,
  String? gender,
  String? phone,
  String? email,
  String? chiefComplaint,
  List<String>? symptoms,
  String? duration,
  String? severity,
  String? preferredLanguage,
  bool? shouldFlagEmergency,
  bool? intakeComplete,
 }) {
  return ExtractedIntake(
   name: name ?? this.name,
   age: age ?? this.age,
   gender: gender ?? this.gender,
   phone: phone ?? this.phone,
   email: email ?? this.email,
   chiefComplaint: chiefComplaint ?? this.chiefComplaint,
   symptoms: symptoms ?? this.symptoms,
   duration: duration ?? this.duration,
   severity: severity ?? this.severity,
   preferredLanguage: preferredLanguage ?? this.preferredLanguage,
   shouldFlagEmergency: shouldFlagEmergency ?? this.shouldFlagEmergency,
   intakeComplete: intakeComplete ?? this.intakeComplete,
  );
 }
}

/// Final consultation summary presented to user
class ConsultationSummaryModel extends Equatable {
 final String sessionId;
 final String patientName;
 final int? age;
 final String? gender;
 final String chiefComplaint;
 final List<String> symptoms;
 final String? duration;
 final String? severity;
 final String language;
 final bool isEmergency;
 final DateTime completedAt;
 final String? clinicalSummary;
 final String? recommendedSpecialist;
 final List<String> keyObservations;
 final String? preliminaryGuidance;
 final String? triageLevel;
 final String? visualDominantEmotion;
 final Map<String, dynamic>? visualEmotionDistribution;
 final int? visualAssessmentDurationSeconds;
 final String? latitude;
 final String? longitude;

 const ConsultationSummaryModel({
  required this.sessionId,
  required this.patientName,
  this.age,
  this.gender,
  required this.chiefComplaint,
  required this.symptoms,
  this.duration,
  this.severity,
  required this.language,
  required this.isEmergency,
  required this.completedAt,
  this.clinicalSummary,
  this.recommendedSpecialist,
  this.keyObservations = const [],
  this.preliminaryGuidance,
  this.triageLevel,
  this.visualDominantEmotion,
  this.visualEmotionDistribution,
  this.visualAssessmentDurationSeconds,
  this.latitude,
  this.longitude,
 });

 @override
 List<Object?> get props => [
    sessionId,
    patientName,
    age,
    gender,
    chiefComplaint,
    symptoms,
    duration,
    severity,
    language,
    isEmergency,
    completedAt,
    clinicalSummary,
    recommendedSpecialist,
    keyObservations,
    preliminaryGuidance,
    triageLevel,
    visualDominantEmotion,
    visualEmotionDistribution,
    visualAssessmentDurationSeconds,
    latitude,
    longitude,
   ];

 factory ConsultationSummaryModel.fromJson(Map<String, dynamic> json) {
  return ConsultationSummaryModel(
   sessionId: json['session_id'] ?? '',
   patientName: json['patient_name'] ?? 'Patient',
   age: json['age'],
   gender: json['gender'],
   chiefComplaint: json['chief_complaint'] ?? 'Not specified',
   symptoms: (json['symptoms'] as List<dynamic>?)
       ?.map((e) => e.toString())
       .toList() ??
     [],
   duration: json['duration'],
   severity: json['severity'],
   language: json['language'] ?? 'en',
   isEmergency: json['emergency'] ?? json['emergency_flag'] ?? false,
   clinicalSummary: json['clinical_summary'],
   recommendedSpecialist: json['recommended_specialist'],
   keyObservations: (json['key_observations'] as List<dynamic>?)
       ?.map((e) => e.toString())
       .toList() ??
     const [],
   preliminaryGuidance: json['preliminary_guidance'],
   triageLevel: json['triage_level'] ?? 'Routine',
   visualDominantEmotion: json['visual_dominant_emotion'],
   visualEmotionDistribution: json['visual_emotion_distribution'] != null 
     ? Map<String, dynamic>.from(json['visual_emotion_distribution']) 
     : null,
   visualAssessmentDurationSeconds: json['visual_assessment_duration_seconds'],
   completedAt: json['completed_at'] != null
     ? DateTime.parse(json['completed_at'])
     : (json['created_at'] != null
       ? DateTime.parse(json['created_at'])
       : DateTime.now()),
   latitude: json['latitude'],
   longitude: json['longitude'],
  );
 }

 ConsultationSummaryModel copyWith({
  String? sessionId,
  String? patientName,
  int? age,
  String? gender,
  String? chiefComplaint,
  List<String>? symptoms,
  String? duration,
  String? severity,
  String? language,
  bool? isEmergency,
  DateTime? completedAt,
  String? clinicalSummary,
  String? recommendedSpecialist,
  List<String>? keyObservations,
  String? preliminaryGuidance,
  String? triageLevel,
  String? visualDominantEmotion,
  Map<String, dynamic>? visualEmotionDistribution,
  int? visualAssessmentDurationSeconds,
  String? latitude,
  String? longitude,
 }) {
  return ConsultationSummaryModel(
   sessionId: sessionId ?? this.sessionId,
   patientName: patientName ?? this.patientName,
   age: age ?? this.age,
   gender: gender ?? this.gender,
   chiefComplaint: chiefComplaint ?? this.chiefComplaint,
   symptoms: symptoms ?? this.symptoms,
   duration: duration ?? this.duration,
   severity: severity ?? this.severity,
   language: language ?? this.language,
   isEmergency: isEmergency ?? this.isEmergency,
   completedAt: completedAt ?? this.completedAt,
   clinicalSummary: clinicalSummary ?? this.clinicalSummary,
   recommendedSpecialist:
     recommendedSpecialist ?? this.recommendedSpecialist,
   keyObservations: keyObservations ?? this.keyObservations,
   preliminaryGuidance: preliminaryGuidance ?? this.preliminaryGuidance,
   triageLevel: triageLevel ?? this.triageLevel,
   visualDominantEmotion: visualDominantEmotion ?? this.visualDominantEmotion,
   visualEmotionDistribution: visualEmotionDistribution ?? this.visualEmotionDistribution,
   visualAssessmentDurationSeconds: visualAssessmentDurationSeconds ?? this.visualAssessmentDurationSeconds,
   latitude: latitude ?? this.latitude,
   longitude: longitude ?? this.longitude,
  );
 }
}
