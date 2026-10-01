import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../models/appointment_model.dart';
import '../models/consultation_model.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final appointmentServiceProvider = Provider<AppointmentService>((ref) {
 return AppointmentService(apiClient: ref.read(apiClientProvider));
});

class AppointmentService {
 final ApiClient _apiClient;

 AppointmentService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

 /// Fetches recommended doctors based on an AI consultation's symptoms
 Future<List<RecommendedDoctorModel>> getRecommendedDoctors({
  String? consultationId,
  String? chiefComplaint,
  String? specialization,
 }) async {
  final queryParams = <String, String>{};
  if (consultationId != null && consultationId.isNotEmpty) {
   queryParams['consultation_id'] = consultationId;
  }
  if (chiefComplaint != null && chiefComplaint.isNotEmpty) {
   queryParams['chief_complaint'] = chiefComplaint;
  }
  if (specialization != null && specialization.isNotEmpty) {
   queryParams['specialization'] = specialization;
  }

  final data = await _apiClient.get(
   '/api/appointments/recommended-doctors',
   queryParams: queryParams.isNotEmpty ? queryParams : null,
  );

  if (data is List) {
   return data.map((json) => RecommendedDoctorModel.fromJson(json as Map<String, dynamic>)).toList();
  }
  return [];
 }

 /// Fetches real-time available slots for a doctor
 Future<List<DoctorSlotModel>> getDoctorAvailability(String doctorId) async {
  final data = await _apiClient.get('/api/doctors/$doctorId/availability');
  if (data is List) {
   return data.map((json) => DoctorSlotModel.fromJson(json as Map<String, dynamic>)).toList();
  }
  return [];
 }

 /// Submits an appointment request (Status: REQUESTED)
 Future<ClinicalAppointmentModel> requestAppointment({
  required String doctorId,
  String? consultationId,
  int? availabilityId,
  required String appointmentDate,
  required String startTime,
  String? endTime,
  String consultationType = 'Video',
  required String reason,
  String? patientNotes,
 }) async {
  final body = <String, dynamic>{
   'doctor_id': doctorId,
   'appointment_date': appointmentDate,
   'start_time': startTime,
   'consultation_type': consultationType,
   'reason': reason,
  };
  if (consultationId != null) body['consultation_id'] = consultationId;
  if (availabilityId != null) body['availability_id'] = availabilityId;
  if (endTime != null) body['end_time'] = endTime;
  if (patientNotes != null) body['patient_notes'] = patientNotes;

  final data = await _apiClient.post(
   '/api/appointments/request',
   body: body,
   requireAuth: true,
  );

  return ClinicalAppointmentModel.fromJson(data as Map<String, dynamic>);
 }

 /// Fetches patient's appointments
 Future<List<ClinicalAppointmentModel>> getPatientAppointments({String? status}) async {
  final queryParams = <String, String>{};
  if (status != null && status.isNotEmpty) {
   queryParams['status'] = status;
  }

  final data = await _apiClient.get(
   '/api/patient/appointments',
   queryParams: queryParams.isNotEmpty ? queryParams : null,
   requireAuth: true,
  );

  if (data is List) {
   return data.map((json) => ClinicalAppointmentModel.fromJson(json as Map<String, dynamic>)).toList();
  }
  return [];
 }

 /// Doctor fetches pending appointment requests (REQUESTED)
 Future<List<ClinicalAppointmentModel>> getDoctorPendingRequests() async {
  final data = await _apiClient.get(
   '/api/doctor/appointments/requests',
   requireAuth: true,
  );

  if (data is List) {
   return data.map((json) => ClinicalAppointmentModel.fromJson(json as Map<String, dynamic>)).toList();
  }
  return [];
 }

 /// Doctor fetches all appointments (e.g. APPROVED, REQUESTED, etc.)
 Future<List<ClinicalAppointmentModel>> getDoctorAppointments({String? status}) async {
  final queryParams = <String, String>{};
  if (status != null && status.isNotEmpty) {
   queryParams['status'] = status;
  }

  final data = await _apiClient.get(
   '/api/doctor/appointments',
   queryParams: queryParams.isNotEmpty ? queryParams : null,
   requireAuth: true,
  );

  if (data is List) {
   return data.map((json) => ClinicalAppointmentModel.fromJson(json as Map<String, dynamic>)).toList();
  }
  return [];
 }

 /// Doctor views AI consultation summary for an appointment request
 Future<ConsultationSummaryModel?> getAppointmentConsultationSummary(String appointmentId) async {
  try {
   final data = await _apiClient.get(
    '/api/doctor/appointments/$appointmentId/consultation-summary',
    requireAuth: true,
   );
   if (data is Map<String, dynamic>) {
    return ConsultationSummaryModel(
     sessionId: data['session_id']?.toString() ?? '',
     patientName: data['patient_name']?.toString() ?? 'Patient',
     age: data['age'] as int?,
     gender: data['gender']?.toString(),
     chiefComplaint: data['chief_complaint']?.toString() ?? 'Not specified',
     symptoms: (data['symptoms'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
     duration: data['duration']?.toString() ?? 'Unknown',
     severity: data['severity']?.toString() ?? 'Normal',
     language: data['preferred_language']?.toString() ?? 'en',
     isEmergency: data['emergency_flag'] as bool? ?? false,
     completedAt: DateTime.tryParse(data['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
   }
  } catch (_) {
   return null;
  }
  return null;
 }

 /// Doctor approves appointment (Transaction-safe status transition)
 Future<ClinicalAppointmentModel> approveAppointment(
  String appointmentId, {
  String? doctorNotes,
 }) async {
  final body = <String, dynamic>{};
  if (doctorNotes != null) body['doctor_notes'] = doctorNotes;

  final data = await _apiClient.post(
   '/api/doctor/appointments/$appointmentId/approve',
   body: body,
   requireAuth: true,
  );
  return ClinicalAppointmentModel.fromJson(data as Map<String, dynamic>);
 }

 /// Doctor rejects appointment with clinical reason
 Future<ClinicalAppointmentModel> rejectAppointment(
  String appointmentId, {
  String? rejectionReason,
 }) async {
  final data = await _apiClient.post(
   '/api/doctor/appointments/$appointmentId/reject',
   body: {
    'rejection_reason': rejectionReason ?? 'Doctor unavailable due to urgent clinical duty.',
   },
   requireAuth: true,
  );
  return ClinicalAppointmentModel.fromJson(data as Map<String, dynamic>);
 }
}
