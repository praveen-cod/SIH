import 'package:flutter/material.dart';

/// Admin Dashboard Statistics Model
class AdminDashboardStats {
 final int totalPatients;
 final String patientGrowth;
 final int totalDoctors;
 final String doctorGrowth;
 final int todayAppointments;
 final String appointmentGrowth;
 final int activeConsultations;
 final int completedConsultations;
 final String completedGrowth;
 final int emergencyAlerts;
 final String systemStatus;

 const AdminDashboardStats({
  required this.totalPatients,
  required this.patientGrowth,
  required this.totalDoctors,
  required this.doctorGrowth,
  required this.todayAppointments,
  required this.appointmentGrowth,
  required this.activeConsultations,
  required this.completedConsultations,
  required this.completedGrowth,
  required this.emergencyAlerts,
  required this.systemStatus,
 });
}

/// Pipeline Funnel Stage Model
class PipelineStage {
 final String title;
 final int count;
 final double? conversionRate; // Conversion from previous stage

 const PipelineStage({
  required this.title,
  required this.count,
  this.conversionRate,
 });
}

/// AI Performance Metrics Model
class AIPerformance {
 final String responseTime;
 final String responseTimeTrend;
 final double speechAccuracy;
 final String speechAccuracyTrend;
 final double intakeAccuracy;
 final String intakeAccuracyTrend;
 final double availability;
 final String availabilityTrend;
 final int totalConsultations;

 const AIPerformance({
  required this.responseTime,
  required this.responseTimeTrend,
  required this.speechAccuracy,
  required this.speechAccuracyTrend,
  required this.intakeAccuracy,
  required this.intakeAccuracyTrend,
  required this.availability,
  required this.availabilityTrend,
  required this.totalConsultations,
 });
}

/// Consultation Reason Breakdown
class ConsultationReason {
 final String category;
 final int percentage;
 final int count;
 final List<Color> gradientColors;

 const ConsultationReason({
  required this.category,
  required this.percentage,
  required this.count,
  required this.gradientColors,
 });
}

/// Emergency Alert Item Model
class EmergencyAlert {
 final String id;
 final String patientId;
 final String? patientName;
 final String symptomSummary;
 final String requestedTimeAgo;
 final String severityLevel; // critical, high, moderate
 final DateTime timestamp;
 final String? latitude;
 final String? longitude;
 final String? emergencyImageUrl;

 const EmergencyAlert({
  required this.id,
  required this.patientId,
  this.patientName,
  required this.symptomSummary,
  required this.requestedTimeAgo,
  required this.severityLevel,
  required this.timestamp,
  this.latitude,
  this.longitude,
  this.emergencyImageUrl,
 });
}

/// Live Activity Stream Item
class ActivityItem {
 final String id;
 final String title;
 final String timeAgo;
 final String type; // patient, appointment, doctor, emergency, ai
 final bool isEmergency;

 const ActivityItem({
  required this.id,
  required this.title,
  required this.timeAgo,
  required this.type,
  this.isEmergency = false,
 });
}

/// Platform Overview Chart Data Point
class PlatformOverviewPoint {
 final String label; // Mon, Tue or Week 1, etc.
 final int patients;
 final int doctors;
 final int appointments;
 final int consultations;

 const PlatformOverviewPoint({
  required this.label,
  required this.patients,
  required this.doctors,
  required this.appointments,
  required this.consultations,
 });
}
