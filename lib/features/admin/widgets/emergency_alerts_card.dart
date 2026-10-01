import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/admin_dashboard_models.dart';
import '../../../shared/widgets/glass_card.dart';

/// Dedicated Emergency Alerts Section Card for Admin Dashboard
class EmergencyAlertsCard extends StatelessWidget {
 final List<EmergencyAlert> alerts;
 final Function(EmergencyAlert) onViewAlert;

 const EmergencyAlertsCard({
  super.key,
  required this.alerts,
  required this.onViewAlert,
 });

 @override
 Widget build(BuildContext context) {
  return GlassCard(
   borderColor: AppColors.error.withValues(alpha: 0.35),
   boxShadow: [
    BoxShadow(
     color: AppColors.error.withValues(alpha: 0.08),
     blurRadius: 20,
     offset: const Offset(0, 6),
    ),
    BoxShadow(
     color: Colors.black.withValues(alpha: 0.3),
     blurRadius: 10,
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
         color: AppColors.error.withValues(alpha: 0.15),
         borderRadius: BorderRadius.circular(10),
         border: Border.all(
          color: AppColors.error.withValues(alpha: 0.35),
          width: 0.8,
         ),
        ),
        child: const Icon(
         Icons.warning_amber_rounded,
         color: AppColors.error,
         size: 20,
        ),
       ),
       const SizedBox(width: 12),
       Expanded(
        child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
          Row(
           children: [
            Text('Emergency Alerts', style: AppTextStyles.headingSmall),
            const SizedBox(width: 8),
            Container(
             padding: const EdgeInsets.symmetric(
              horizontal: 7,
              vertical: 2,
             ),
             decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(10),
             ),
             child: Text(
              '${alerts.length}',
              style: AppTextStyles.labelSmall.copyWith(
               color: Colors.white,
               fontWeight: FontWeight.w700,
               fontSize: 10,
              ),
             ),
            ),
           ],
          ),
          Text(
           '${alerts.length} active triage alerts requiring physician review',
           style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
         ],
        ),
       ),
      ],
     ),
     const SizedBox(height: 16),
     ...alerts.map((alert) {
      return Container(
       margin: const EdgeInsets.only(bottom: 10),
       padding: const EdgeInsets.all(12),
       decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
         color: AppColors.error.withValues(alpha: 0.25),
         width: 0.8,
        ),
       ),
       child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         // Severity dot
         Container(
          margin: const EdgeInsets.only(top: 2),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
           shape: BoxShape.circle,
           color: alert.severityLevel == 'critical'
               ? AppColors.error
               : AppColors.error.withValues(alpha: 0.6),
          ),
         ),
         const SizedBox(width: 10),
         Expanded(
          child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
            // Patient name
            Text(
             alert.patientName ?? alert.patientId,
             style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
             ),
            ),
            const SizedBox(height: 2),
            // Symptom summary
            Text(
             alert.symptomSummary,
             style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.3,
             ),
             maxLines: 2,
             overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Time + location badge
            Row(
             children: [
              Icon(Icons.access_time_rounded, size: 11, color: AppColors.textMuted),
              const SizedBox(width: 3),
              Text(
               alert.requestedTimeAgo,
               style: AppTextStyles.caption.copyWith(
                color: AppColors.textMuted,
                fontSize: 10,
               ),
              ),
              if (alert.latitude != null) ...[ 
               const SizedBox(width: 8),
               Icon(Icons.location_on_outlined, size: 11, color: AppColors.primary),
               const SizedBox(width: 2),
               Flexible(
                child: Text(
                 'Location available',
                 style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontSize: 10,
                 ),
                 overflow: TextOverflow.ellipsis,
                ),
               ),
              ],
             ],
            ),
           ],
          ),
         ),
         const SizedBox(width: 10),
         // Expand button
         InkWell(
          onTap: () => onViewAlert(alert),
          borderRadius: BorderRadius.circular(8),
          child: Container(
           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
           decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
           ),
           child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
             const Icon(Icons.open_in_full_rounded, size: 13, color: AppColors.error),
             const SizedBox(width: 4),
             Text(
              'Expand',
              style: AppTextStyles.labelSmall.copyWith(
               color: AppColors.error,
               fontWeight: FontWeight.w600,
               fontSize: 11,
              ),
             ),
            ],
           ),
          ),
         ),
        ],
       ),
      );
     }),
    ],
   ),
  );
 }
}
