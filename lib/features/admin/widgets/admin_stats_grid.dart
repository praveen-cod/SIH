import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/admin_dashboard_models.dart';
import '../../../shared/widgets/glass_card.dart';

/// Admin 6-Card Overview Statistics Grid
class AdminStatsGrid extends StatelessWidget {
 final AdminDashboardStats stats;

 const AdminStatsGrid({super.key, required this.stats});

 @override
 Widget build(BuildContext context) {
  return Column(
   children: [
    Row(
     children: [
      Expanded(
       child: StatCard(
        label: 'Total Patients',
        value: _format(stats.totalPatients),
        icon: Icons.people_alt_rounded,
        accentColor: AppColors.primary,
        change: stats.patientGrowth,
        isPositive: true,
        subtitle: 'vs last week',
       ),
      ),
      const SizedBox(width: 12),
      Expanded(
       child: StatCard(
        label: 'Total Doctors',
        value: '${stats.totalDoctors}',
        icon: Icons.medical_services_rounded,
        accentColor: AppColors.doctorPrimary,
        change: stats.doctorGrowth,
        isPositive: true,
       ),
      ),
     ],
    ),
    const SizedBox(height: 12),
    Row(
     children: [
      Expanded(
       child: StatCard(
        label: "Today's Appointments",
        value: '${stats.todayAppointments}',
        icon: Icons.calendar_month_rounded,
        accentColor: AppColors.secondary,
        change: stats.appointmentGrowth,
        isPositive: true,
       ),
      ),
      const SizedBox(width: 12),
      Expanded(
       child: StatCard(
        label: 'Active Consultations',
        value: '${stats.activeConsultations}',
        icon: Icons.videocam_rounded,
        accentColor: AppColors.accent,
        statusBadge: '● Live',
        statusBadgeColor: AppColors.accent,
        showLivePulse: true,
       ),
      ),
     ],
    ),
    const SizedBox(height: 12),
    Row(
     children: [
      Expanded(
       child: StatCard(
        label: 'Completed Today',
        value: '${stats.completedConsultations}',
        icon: Icons.check_circle_rounded,
        accentColor: AppColors.success,
        change: stats.completedGrowth,
        isPositive: true,
       ),
      ),
      const SizedBox(width: 12),
      Expanded(
       child: StatCard(
        label: 'Emergency Alerts',
        value: '${stats.emergencyAlerts}',
        icon: Icons.warning_amber_rounded,
        accentColor: AppColors.error,
        statusBadge: 'Requires Attention',
        statusBadgeColor: AppColors.error,
       ),
      ),
     ],
    ),
   ],
  );
 }

 String _format(int num) {
  if (num >= 1000) {
   final val = (num / 1000).toStringAsFixed(1);
   return val.endsWith('.0') ? '${num ~/ 1000},000' : '$val k';
  }
  return '$num';
 }
}
