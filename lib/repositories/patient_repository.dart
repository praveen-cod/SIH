import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/appointment_model.dart';

/// Mock patient data repository
class MockPatientRepository {
  List<AppointmentModel> getUpcomingAppointments() {
    return [
      AppointmentModel(
        id: 'APT-001',
        patientId: 'PAT-001',
        patientName: 'Alex Johnson',
        doctorId: 'DOC-001',
        doctorName: 'Dr. Sarah Wilson',
        specialty: 'General Physician',
        dateTime: DateTime(2026, 8, 29, 10, 30),
        status: AppointmentStatus.confirmed,
        notes: 'Annual wellness check-up',
      ),
      AppointmentModel(
        id: 'APT-002',
        patientId: 'PAT-001',
        patientName: 'Alex Johnson',
        doctorId: 'DOC-002',
        doctorName: 'Dr. Michael Chen',
        specialty: 'Cardiologist',
        dateTime: DateTime(2026, 9, 5, 14, 0),
        status: AppointmentStatus.pending,
      ),
    ];
  }

  List<Map<String, dynamic>> getRecentActivity() {
    return [
      {
        'title': 'AI Consultation',
        'subtitle': 'Symptom assessment completed',
        'time': '2 hours ago',
        'icon': '🤖',
      },
      {
        'title': 'Prescription',
        'subtitle': 'New prescription from Dr. Wilson',
        'time': 'Yesterday',
        'icon': '💊',
      },
      {
        'title': 'Lab Results',
        'subtitle': 'Blood test results are ready',
        'time': '3 days ago',
        'icon': '🧪',
      },
    ];
  }

  Map<String, dynamic> getHealthSummary() {
    return {
      'bloodPressure': '120/80',
      'heartRate': '72 bpm',
      'bloodSugar': '98 mg/dL',
      'weight': '70 kg',
      'lastUpdated': '2 days ago',
    };
  }
}

final patientRepositoryProvider = Provider<MockPatientRepository>((ref) {
  return MockPatientRepository();
});
