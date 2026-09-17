import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_dashboard_models.dart';

/// Abstract Admin Repository (designed for easy FastAPI backend binding)
abstract class AdminRepository {
  Future<AdminDashboardStats> getDashboardStats({String dateFilter = 'Today'});
  Future<List<PipelineStage>> getAppointmentPipeline();
  Future<AIPerformance> getAIPerformance();
  Future<List<ConsultationReason>> getTopConsultationReasons();
  Future<List<EmergencyAlert>> getEmergencyAlerts();
  Future<List<ActivityItem>> getLiveActivity();
  Future<List<PlatformOverviewPoint>> getPlatformOverview({String timeframe = 'Weekly'});
}

/// Mock Admin Repository for UI prototype and development
class MockAdminRepository implements AdminRepository {
  @override
  Future<AdminDashboardStats> getDashboardStats({String dateFilter = 'Today'}) async {
    // Simulate brief API latency
    await Future.delayed(const Duration(milliseconds: 200));

    int multiplier = 1;
    if (dateFilter == 'Yesterday') multiplier = 1;
    if (dateFilter == 'Last 7 Days') multiplier = 7;
    if (dateFilter == 'Last 30 Days') multiplier = 30;

    return AdminDashboardStats(
      totalPatients: 1284 * (multiplier > 1 ? 1 : 1),
      patientGrowth: '↑ 8.4%',
      totalDoctors: 86,
      doctorGrowth: '↑ 4.2%',
      todayAppointments: 342 * (multiplier > 1 ? 3 : 1),
      appointmentGrowth: '↑ 12.6%',
      activeConsultations: 34,
      completedConsultations: 308 * (multiplier > 1 ? 3 : 1),
      completedGrowth: '↑ 15.2%',
      emergencyAlerts: 3,
      systemStatus: 'Online',
    );
  }

  @override
  Future<List<PipelineStage>> getAppointmentPipeline() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return const [
      PipelineStage(
        title: 'Consultation Requests',
        count: 842,
      ),
      PipelineStage(
        title: 'Valid Intakes',
        count: 650,
        conversionRate: 77.2,
      ),
      PipelineStage(
        title: 'Appointment Requests',
        count: 530,
        conversionRate: 81.5,
      ),
      PipelineStage(
        title: 'Appointments Booked',
        count: 483,
        conversionRate: 91.1,
      ),
    ];
  }

  @override
  Future<AIPerformance> getAIPerformance() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return const AIPerformance(
      responseTime: '1.2s',
      responseTimeTrend: '↓ 0.2s faster',
      speechAccuracy: 98.6,
      speechAccuracyTrend: '↑ 0.4% this week',
      intakeAccuracy: 94.3,
      intakeAccuracyTrend: '↑ 1.1% this week',
      availability: 99.9,
      availabilityTrend: 'Zero downtime',
      totalConsultations: 12480,
    );
  }

  @override
  Future<List<ConsultationReason>> getTopConsultationReasons() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return const [
      ConsultationReason(
        category: 'Fever / Cold / Cough',
        percentage: 28,
        count: 360,
        gradientColors: [Color(0xFF2D8EFF), Color(0xFF00D4FF)],
      ),
      ConsultationReason(
        category: 'Appointment Booking',
        percentage: 21,
        count: 270,
        gradientColors: [Color(0xFF8B5CF6), Color(0xFF7B5EA7)],
      ),
      ConsultationReason(
        category: 'Stomach / Digestive',
        percentage: 16,
        count: 205,
        gradientColors: [Color(0xFF10B981), Color(0xFF059669)],
      ),
      ConsultationReason(
        category: 'BP / Diabetes Checkup',
        percentage: 12,
        count: 154,
        gradientColors: [Color(0xFFF59E0B), Color(0xFFD97706)],
      ),
      ConsultationReason(
        category: 'Child Health',
        percentage: 8,
        count: 102,
        gradientColors: [Color(0xFFEC4899), Color(0xFFBE185D)],
      ),
      ConsultationReason(
        category: 'Others & General Advice',
        percentage: 15,
        count: 193,
        gradientColors: [Color(0xFF64748B), Color(0xFF475569)],
      ),
    ];
  }

  @override
  Future<List<EmergencyAlert>> getEmergencyAlerts() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return [
      EmergencyAlert(
        id: 'EMG-1024',
        patientId: 'P1024',
        symptomSummary: 'Possible emergency symptoms detected: Severe acute chest tightness & shortness of breath',
        requestedTimeAgo: '5 min ago',
        severityLevel: 'critical',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      EmergencyAlert(
        id: 'EMG-1087',
        patientId: 'P1087',
        symptomSummary: 'Urgent consultation requested: High fever (103.5°F) with sudden confusion in elderly patient',
        requestedTimeAgo: '12 min ago',
        severityLevel: 'high',
        timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
      ),
      EmergencyAlert(
        id: 'EMG-1105',
        patientId: 'P1105',
        symptomSummary: 'Abnormal heart rate reported during voice intake: Tachycardia > 135 bpm at rest',
        requestedTimeAgo: '18 min ago',
        severityLevel: 'moderate',
        timestamp: DateTime.now().subtract(const Duration(minutes: 18)),
      ),
    ];
  }

  @override
  Future<List<ActivityItem>> getLiveActivity() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return const [
      ActivityItem(
        id: 'ACT-01',
        title: 'New patient registered',
        timeAgo: '2 min ago',
        type: 'patient',
      ),
      ActivityItem(
        id: 'ACT-02',
        title: 'Appointment booked with Cardiology',
        timeAgo: '5 min ago',
        type: 'appointment',
      ),
      ActivityItem(
        id: 'ACT-03',
        title: 'Dr. Sarah Wilson started consultation',
        timeAgo: '8 min ago',
        type: 'doctor',
      ),
      ActivityItem(
        id: 'ACT-04',
        title: 'Emergency alert detected for Patient P1024',
        timeAgo: '10 min ago',
        type: 'emergency',
        isEmergency: true,
      ),
      ActivityItem(
        id: 'ACT-05',
        title: 'AI Intake completed in 1.1s for Patient P1140',
        timeAgo: '14 min ago',
        type: 'ai',
      ),
      ActivityItem(
        id: 'ACT-06',
        title: 'Doctor availability updated by Dr. Priya Sharma',
        timeAgo: '25 min ago',
        type: 'doctor',
      ),
    ];
  }

  @override
  Future<List<PlatformOverviewPoint>> getPlatformOverview({String timeframe = 'Weekly'}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (timeframe == 'Daily') {
      return const [
        PlatformOverviewPoint(label: '8 AM', patients: 120, doctors: 45, appointments: 35, consultations: 28),
        PlatformOverviewPoint(label: '10 AM', patients: 280, doctors: 68, appointments: 85, consultations: 72),
        PlatformOverviewPoint(label: '12 PM', patients: 450, doctors: 82, appointments: 140, consultations: 124),
        PlatformOverviewPoint(label: '2 PM', patients: 620, doctors: 86, appointments: 210, consultations: 185),
        PlatformOverviewPoint(label: '4 PM', patients: 890, doctors: 80, appointments: 290, consultations: 260),
        PlatformOverviewPoint(label: '6 PM', patients: 1284, doctors: 86, appointments: 342, consultations: 308),
      ];
    } else if (timeframe == 'Monthly') {
      return const [
        PlatformOverviewPoint(label: 'Mar', patients: 980, doctors: 72, appointments: 1820, consultations: 1640),
        PlatformOverviewPoint(label: 'Apr', patients: 1040, doctors: 75, appointments: 2100, consultations: 1910),
        PlatformOverviewPoint(label: 'May', patients: 1100, doctors: 78, appointments: 2350, consultations: 2140),
        PlatformOverviewPoint(label: 'Jun', patients: 1150, doctors: 80, appointments: 2600, consultations: 2410),
        PlatformOverviewPoint(label: 'Jul', patients: 1210, doctors: 83, appointments: 2940, consultations: 2750),
        PlatformOverviewPoint(label: 'Aug', patients: 1284, doctors: 86, appointments: 3340, consultations: 3108),
      ];
    } else {
      // Weekly default
      return const [
        PlatformOverviewPoint(label: 'Mon', patients: 1120, doctors: 78, appointments: 290, consultations: 265),
        PlatformOverviewPoint(label: 'Tue', patients: 1150, doctors: 80, appointments: 310, consultations: 280),
        PlatformOverviewPoint(label: 'Wed', patients: 1190, doctors: 82, appointments: 330, consultations: 295),
        PlatformOverviewPoint(label: 'Thu', patients: 1220, doctors: 84, appointments: 325, consultations: 300),
        PlatformOverviewPoint(label: 'Fri', patients: 1250, doctors: 85, appointments: 355, consultations: 320),
        PlatformOverviewPoint(label: 'Sat', patients: 1270, doctors: 75, appointments: 280, consultations: 250),
        PlatformOverviewPoint(label: 'Sun', patients: 1284, doctors: 70, appointments: 210, consultations: 190),
      ];
    }
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return MockAdminRepository();
});
