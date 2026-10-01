import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/admin_dashboard_models.dart';
import '../../../shared/widgets/glass_card.dart';

/// AI Performance Metrics Card
class AIPerformanceCard extends StatelessWidget {
 final AIPerformance data;

 const AIPerformanceCard({super.key, required this.data});

 @override
 Widget build(BuildContext context) {
  return GlassCard(
   borderColor: AppColors.primary.withValues(alpha: 0.25),
   boxShadow: [
    BoxShadow(
     color: AppColors.primary.withValues(alpha: 0.08),
     blurRadius: 24,
     offset: const Offset(0, 6),
    ),
    BoxShadow(
     color: Colors.black.withValues(alpha: 0.25),
     blurRadius: 12,
     offset: const Offset(0, 4),
    ),
   ],
   child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
     Row(
      children: [
       Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
         gradient: const LinearGradient(
          colors: [Color(0xFF2D8EFF), Color(0xFF8B5CF6)],
         ),
         borderRadius: BorderRadius.circular(10),
         boxShadow: [
          BoxShadow(
           color: AppColors.primary.withValues(alpha: 0.3),
           blurRadius: 10,
           offset: const Offset(0, 3),
          ),
         ],
        ),
        child: const Icon(
         Icons.psychology_rounded,
         color: Colors.white,
         size: 20,
        ),
       ),
       const SizedBox(width: 12),
       Expanded(
        child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
          Text('AI Performance', style: AppTextStyles.headingSmall),
          Text(
           'Real-time neural intake & clinical benchmark',
           style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
         ],
        ),
       ),
       Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
         color: AppColors.success.withValues(alpha: 0.12),
         borderRadius: BorderRadius.circular(10),
         border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
          width: 0.5,
         ),
        ),
        child: Text(
         'OPTIMAL',
         style: AppTextStyles.overline.copyWith(
          color: AppColors.success,
          fontWeight: FontWeight.w700,
          fontSize: 9,
         ),
        ),
       ),
      ],
     ),
     const SizedBox(height: 20),
     // 4 Metric cards
     LayoutBuilder(
      builder: (context, constraints) {
       final isWide = constraints.maxWidth > 500;
       return GridView.count(
        crossAxisCount: isWide ? 4 : 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: isWide ? 1.4 : 1.25,
        children: [
         _MetricItem(
          label: 'AI Response Time',
          value: data.responseTime,
          trend: data.responseTimeTrend,
          icon: Icons.speed_rounded,
          color: AppColors.primary,
         ),
         _MetricItem(
          label: 'Speech Recognition',
          value: '${data.speechAccuracy}%',
          trend: data.speechAccuracyTrend,
          icon: Icons.mic_none_rounded,
          color: AppColors.accent,
         ),
         _MetricItem(
          label: 'Intake Accuracy',
          value: '${data.intakeAccuracy}%',
          trend: data.intakeAccuracyTrend,
          icon: Icons.fact_check_outlined,
          color: AppColors.secondaryLight,
         ),
         _MetricItem(
          label: 'AI Availability',
          value: '${data.availability}%',
          trend: data.availabilityTrend,
          icon: Icons.cloud_done_rounded,
          color: AppColors.success,
         ),
        ],
       );
      },
     ),
     const SizedBox(height: 16),
     // Accuracy bar indicator
     Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
         Text(
          'Speech-to-Text & Clinical Entity Extraction',
          style: AppTextStyles.caption.copyWith(
           color: AppColors.textSecondary,
          ),
         ),
         Text(
          '${data.speechAccuracy}%',
          style: AppTextStyles.labelSmall.copyWith(
           color: AppColors.success,
           fontWeight: FontWeight.w700,
          ),
         ),
        ],
       ),
       const SizedBox(height: 8),
       Stack(
        children: [
         Container(
          height: 6,
          decoration: BoxDecoration(
           color: AppColors.border,
           borderRadius: BorderRadius.circular(3),
          ),
         ),
         FractionallySizedBox(
          widthFactor: (data.speechAccuracy / 100).clamp(0.1, 1.0),
          child: Container(
           height: 6,
           decoration: BoxDecoration(
            gradient: const LinearGradient(
             colors: [Color(0xFF2D8EFF), Color(0xFF22C55E)],
            ),
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
             BoxShadow(
              color: AppColors.success.withValues(alpha: 0.35),
              blurRadius: 6,
              offset: const Offset(0, 2),
             ),
            ],
           ),
          ),
         ),
        ],
       ),
      ],
     ),
    ],
   ),
  );
 }
}

class _MetricItem extends StatelessWidget {
 final String label;
 final String value;
 final String trend;
 final IconData icon;
 final Color color;

 const _MetricItem({
  required this.label,
  required this.value,
  required this.trend,
  required this.icon,
  required this.color,
 });

 @override
 Widget build(BuildContext context) {
  return Container(
   padding: const EdgeInsets.all(12),
   decoration: BoxDecoration(
    color: color.withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
   ),
   child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
     Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
       Icon(icon, size: 18, color: color),
       Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
       ),
      ],
     ),
     FittedBox(
      alignment: Alignment.centerLeft,
      fit: BoxFit.scaleDown,
      child: Text(
       value,
       style: AppTextStyles.statSmall.copyWith(
        fontSize: 20,
        color: AppColors.textPrimary,
       ),
      ),
     ),
     Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       Text(
        label,
        style: AppTextStyles.caption.copyWith(
         color: AppColors.textMuted,
         fontSize: 10,
         fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
       ),
       Text(
        trend,
        style: AppTextStyles.caption.copyWith(
         color: color,
         fontSize: 9,
         fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
       ),
      ],
     ),
    ],
   ),
  );
 }
}
