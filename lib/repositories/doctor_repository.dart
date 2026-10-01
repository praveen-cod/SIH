import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/doctor_dashboard_models.dart';

/// Abstract Doctor Repository (ready for FastAPI endpoints)
abstract class DoctorRepository {
 Future<DoctorDashboardStats> getDashboardStats();
 Future<List<DoctorAppointment>> getTodayAppointments();
 Future<List<PatientRequest>> getPendingRequests();
 Future<ActiveConsultation?> getActiveConsultation();
 Future<List<RecentPatientSummary>> getRecentPatients();
 Future<DoctorPerformance> getDoctorPerformance();
 Future<bool> updateAvailability(bool isAvailable);
 Future<bool> acceptRequest(String requestId);
 Future<bool> declineRequest(String requestId);
}

/// Mock Doctor Repository with realistic clinical state
class MockDoctorRepository implements DoctorRepository {
 bool _isAvailable = true;

 final List<PatientRequest> _requests = [
  const PatientRequest(
   id: 'REQ-1024',
   patientId: 'P1024',
   reason: 'Fever and severe persistent headache for 2 days',
   requestedAgo: '5 min ago',
   urgency: 'urgent',
  ),
  const PatientRequest(
   id: 'REQ-1048',
   patientId: 'P1048',
   reason: 'Rash on left forearm with mild itching',
   requestedAgo: '18 min ago',
   urgency: 'normal',
  ),
  const PatientRequest(
   id: 'REQ-1062',
   patientId: 'P1062',
   reason: 'Stomach pain after meals & nausea',
   requestedAgo: '32 min ago',
   urgency: 'normal',
  ),
  const PatientRequest(
   id: 'REQ-1090',
   patientId: 'P1090',
   reason: 'Medication refill consultation for Hypertension',
   requestedAgo: '45 min ago',
   urgency: 'normal',
  ),
 ];

 final List<DoctorAppointment> _appointments = [
  DoctorAppointment(
   id: 'APT-101',
   patientId: 'P1024',
   patientName: 'John Doe',
   consultationType: 'General Consultation',
   timeFormatted: '10:30 AM',
   dateTime: DateTime(2026, 8, 30, 10, 30),
   status: DoctorAppointmentStatus.upcoming,
  ),
  DoctorAppointment(
   id: 'APT-102',
   patientId: 'P1028',
   patientName: 'Priya Kumar',
   consultationType: 'Follow-up Consultation',
   timeFormatted: '11:15 AM',
   dateTime: DateTime(2026, 8, 30, 11, 15),
   status: DoctorAppointmentStatus.upcoming,
  ),
  DoctorAppointment(
   id: 'APT-103',
   patientId: 'P1032',
   patientName: 'Rahul Sharma',
   consultationType: 'Diabetic Assessment',
   timeFormatted: '02:00 PM',
   dateTime: DateTime(2026, 8, 30, 14, 0),
   status: DoctorAppointmentStatus.inProgress,
  ),
  DoctorAppointment(
   id: 'APT-104',
   patientId: 'P1055',
   patientName: 'Sarah Jenkins',
   consultationType: 'Routine Blood Pressure Check',
   timeFormatted: '03:30 PM',
   dateTime: DateTime(2026, 8, 30, 15, 30),
   status: DoctorAppointmentStatus.completed,
  ),
  DoctorAppointment(
   id: 'APT-105',
   patientId: 'P1067',
   patientName: 'David Chen',
   consultationType: 'Allergy Reaction Follow-up',
   timeFormatted: '04:15 PM',
   dateTime: DateTime(2026, 8, 30, 16, 15),
   status: DoctorAppointmentStatus.cancelled,
  ),
 ];

 @override
 Future<DoctorDashboardStats> getDashboardStats() async {
  await Future.delayed(const Duration(milliseconds: 200));
  return DoctorDashboardStats(
   todayAppointments: _appointments.length + 7, // 12 total
   appointmentTrend: '+2 today',
   pendingRequests: _requests.length,
   completedToday: 8,
   totalPatients: 248,
   patientTrend: '+12 this month',
  );
 }

 @override
 Future<List<DoctorAppointment>> getTodayAppointments() async {
  await Future.delayed(const Duration(milliseconds: 150));
  return List.unmodifiable(_appointments);
 }

 @override
 Future<List<PatientRequest>> getPendingRequests() async {
  await Future.delayed(const Duration(milliseconds: 150));
  return List.unmodifiable(_requests);
 }

 @override
 Future<ActiveConsultation?> getActiveConsultation() async {
  await Future.delayed(const Duration(milliseconds: 150));
  return const ActiveConsultation(
   id: 'CNS-9821',
   patientId: 'P1024',
   reason: 'Fever / Severe Headache',
   initialDurationSeconds: 272, // 04:32
   status: 'In Consultation',
  );
 }

 @override
 Future<List<RecentPatientSummary>> getRecentPatients() async {
  await Future.delayed(const Duration(milliseconds: 150));
  return const [
   RecentPatientSummary(
    patientId: 'P1024',
    name: 'John Doe',
    age: 38,
    condition: 'Acute Viral Fever',
    lastConsultation: 'Today',
    clinicalStatus: 'Improving',
   ),
   RecentPatientSummary(
    patientId: 'P1028',
    name: 'Priya Kumar',
    age: 45,
    condition: 'Hypertension Stage 1',
    lastConsultation: 'Yesterday',
    clinicalStatus: 'Stable',
   ),
   RecentPatientSummary(
    patientId: 'P1032',
    name: 'Rahul Sharma',
    age: 52,
    condition: 'Type 2 Diabetes',
    lastConsultation: '2 days ago',
    clinicalStatus: 'Follow-up Needed',
   ),
   RecentPatientSummary(
    patientId: 'P1044',
    name: 'Elena Rostova',
    age: 29,
    condition: 'Migraine with Aura',
    lastConsultation: '3 days ago',
    clinicalStatus: 'Stable',
   ),
  ];
 }

 @override
 Future<DoctorPerformance> getDoctorPerformance() async {
  await Future.delayed(const Duration(milliseconds: 150));
  return const DoctorPerformance(
   totalConsultations: 124,
   completionRate: 96.4,
   avgConsultationMinutes: 12,
   patientRating: 4.8,
  );
 }

 @override
 Future<bool> updateAvailability(bool isAvailable) async {
  await Future.delayed(const Duration(milliseconds: 100));
  _isAvailable = isAvailable;
  return _isAvailable;
 }

 @override
 Future<bool> acceptRequest(String requestId) async {
  await Future.delayed(const Duration(milliseconds: 150));
  _requests.removeWhere((r) => r.id == requestId);
  return true;
 }

 @override
 Future<bool> declineRequest(String requestId) async {
  await Future.delayed(const Duration(milliseconds: 150));
  _requests.removeWhere((r) => r.id == requestId);
  return true;
 }
}

final doctorRepositoryProvider = Provider<DoctorRepository>((ref) {
 return MockDoctorRepository();
});
