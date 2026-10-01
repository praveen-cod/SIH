import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/doctor_dashboard_models.dart';
import '../../../shared/widgets/glass_card.dart';

/// Doctor Clinical Performance Card
class DoctorPerformanceCard extends StatelessWidget {
 final DoctorPerformance performance;

 const DoctorPerformanceCard({super.key, required this.performance});

 @override
 Widget build(BuildContext context) {
  return GlassCard(
   padding: const EdgeInsets.all(18),
   borderColor: AppColors.borderLight,
   child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
     Row(
      children: [
       Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
         color: AppColors.doctorPrimary.withValues(alpha: 0.15),
         borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
         Icons.trending_up_rounded,
         color: AppColors.doctorPrimary,
         size: 20,
        ),
       ),
       const SizedBox(width: 12),
       Expanded(
        child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
          Text('Your Performance', style: AppTextStyles.headingSmall),
          Text(
           'Clinical practice milestones & patient feedback',
           style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
           maxLines: 1,
           overflow: TextOverflow.ellipsis,
          ),
         ],
        ),
       ),
      ],
     ),
     const SizedBox(height: 16),
      LayoutBuilder(
       builder: (context, constraints) {
        return Column(
         children: [
          Row(
           children: [
            Expanded(
             child: _PerfMetric(
              label: 'Consultations',
              value: '${performance.totalConsultations}',
              icon: Icons.video_camera_front_outlined,
              color: AppColors.primary,
             ),
            ),
            const SizedBox(width: 10),
            Expanded(
             child: _PerfMetric(
              label: 'Completion Rate',
              value: '${performance.completionRate}%',
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.success,
             ),
            ),
           ],
          ),
          const SizedBox(height: 10),
          Row(
           children: [
            Expanded(
             child: _PerfMetric(
              label: 'Avg. Consultation',
              value: '${performance.avgConsultationMinutes} min',
              icon: Icons.timelapse_rounded,
              color: AppColors.warning,
             ),
            ),
            const SizedBox(width: 10),
            Expanded(
             child: _PerfMetric(
              label: 'Patient Rating',
              value: '${performance.patientRating} / 5',
              icon: Icons.star_rate_rounded,
              color: const Color(0xFFFBBF24),
             ),
            ),
           ],
          ),
         ],
        );
       },
      ),
    ],
   ),
  );
 }
}

class _PerfMetric extends StatelessWidget {
 final String label;
 final String value;
 final IconData icon;
 final Color color;

 const _PerfMetric({
  required this.label,
  required this.value,
  required this.icon,
  required this.color,
 });

 @override
 Widget build(BuildContext context) {
  return Container(
   padding: const EdgeInsets.all(8),
   decoration: BoxDecoration(
    color: color.withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: color.withValues(alpha: 0.2), width: 0.8),
   ),
   child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
     Icon(icon, size: 18, color: color),
     const SizedBox(height: 6),
     FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
       value,
       style: AppTextStyles.statSmall.copyWith(
        fontSize: 14,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
       ),
       maxLines: 1,
      ),
     ),
     const SizedBox(height: 4),
     FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
       label,
       style: AppTextStyles.caption.copyWith(
        color: AppColors.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w500,
       ),
       maxLines: 1,
      ),
     ),
    ],
   ),
  );
 }
}
