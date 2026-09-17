import 'package:flutter/material.dart';

/// Doctor Appointment Status Enum
enum DoctorAppointmentStatus {
  upcoming,
  inProgress,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case DoctorAppointmentStatus.upcoming:
        return 'Upcoming';
      case DoctorAppointmentStatus.inProgress:
        return 'In Progress';
      case DoctorAppointmentStatus.completed:
        return 'Completed';
      case DoctorAppointmentStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case DoctorAppointmentStatus.upcoming:
        return const Color(0xFF2D8EFF);
      case DoctorAppointmentStatus.inProgress:
        return const Color(0xFFF59E0B);
      case DoctorAppointmentStatus.completed:
        return const Color(0xFF22C55E);
      case DoctorAppointmentStatus.cancelled:
        return const Color(0xFFEF4444);
    }
  }
}

/// Doctor Dashboard Overview Stats
class DoctorDashboardStats {
  final int todayAppointments;
  final String appointmentTrend;
  final int pendingRequests;
  final int completedToday;
  final int totalPatients;
  final String patientTrend;

  const DoctorDashboardStats({
    required this.todayAppointments,
    this.appointmentTrend = '+2 today',
    required this.pendingRequests,
    required this.completedToday,
    required this.totalPatients,
    this.patientTrend = '+12 this month',
  });
}

/// Doctor Appointment Item
class DoctorAppointment {
  final String id;
  final String patientId;
  final String patientName;
  final String consultationType;
  final String timeFormatted;
  final DateTime dateTime;
  final DoctorAppointmentStatus status;

  const DoctorAppointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.consultationType,
    required this.timeFormatted,
    required this.dateTime,
    required this.status,
  });

  DoctorAppointment copyWith({
    DoctorAppointmentStatus? status,
  }) {
    return DoctorAppointment(
      id: id,
      patientId: patientId,
      patientName: patientName,
      consultationType: consultationType,
      timeFormatted: timeFormatted,
      dateTime: dateTime,
      status: status ?? this.status,
    );
  }
}

/// Pending Patient Consultation Request
class PatientRequest {
  final String id;
  final String patientId;
  final String reason;
  final String requestedAgo;
  final String urgency; // normal, urgent
  final String? consultationId;
  final String? appointmentDate;
  final String? startTime;

  const PatientRequest({
    required this.id,
    required this.patientId,
    required this.reason,
    required this.requestedAgo,
    this.urgency = 'normal',
    this.consultationId,
    this.appointmentDate,
    this.startTime,
  });
}

/// Current Active Consultation
class ActiveConsultation {
  final String id;
  final String patientId;
  final String reason;
  final int initialDurationSeconds;
  final String status;

  const ActiveConsultation({
    required this.id,
    required this.patientId,
    required this.reason,
    required this.initialDurationSeconds,
    this.status = 'In Consultation',
  });
}

/// Recent Patient Summary
class RecentPatientSummary {
  final String patientId;
  final String name;
  final int age;
  final String condition;
  final String lastConsultation;
  final String clinicalStatus; // Stable, Improving, Follow-up Needed

  const RecentPatientSummary({
    required this.patientId,
    required this.name,
    required this.age,
    required this.condition,
    required this.lastConsultation,
    required this.clinicalStatus,
  });
}

/// Doctor Practice Performance Metrics
class DoctorPerformance {
  final int totalConsultations;
  final double completionRate;
  final int avgConsultationMinutes;
  final double patientRating;

  const DoctorPerformance({
    required this.totalConsultations,
    required this.completionRate,
    required this.avgConsultationMinutes,
    required this.patientRating,
  });
}
