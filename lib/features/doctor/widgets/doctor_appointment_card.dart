import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/doctor_dashboard_models.dart';
import '../../../shared/widgets/glass_card.dart';

/// Doctor Appointment Card
class DoctorAppointmentCard extends StatelessWidget {
 final DoctorAppointment appointment;
 final VoidCallback onView;

 const DoctorAppointmentCard({
  super.key,
  required this.appointment,
  required this.onView,
 });

 @override
 Widget build(BuildContext context) {
  final status = appointment.status;

  return GlassCard(
   margin: const EdgeInsets.only(bottom: 10),
   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
   borderColor: status.color.withValues(alpha: 0.2),
   child: Row(
    children: [
     // Time badge
     Container(
      width: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
       color: status.color.withValues(alpha: 0.12),
       borderRadius: BorderRadius.circular(10),
       border: Border.all(
        color: status.color.withValues(alpha: 0.3),
        width: 0.8,
       ),
      ),
      child: Column(
       mainAxisAlignment: MainAxisAlignment.center,
       children: [
        Text(
         appointment.timeFormatted.split(' ')[0],
         style: AppTextStyles.labelLarge.copyWith(
          color: status.color,
          fontWeight: FontWeight.w700,
          fontSize: 13,
         ),
        ),
        Text(
         appointment.timeFormatted.split(' ')[1],
         style: AppTextStyles.overline.copyWith(
          color: status.color,
          fontSize: 9,
         ),
        ),
       ],
      ),
     ),
     const SizedBox(width: 14),
     // Patient info
     Expanded(
      child: Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
        Row(
         children: [
          Flexible(
           child: Text(
            appointment.patientName,
            style: AppTextStyles.bodyMedium.copyWith(
             color: AppColors.textPrimary,
             fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
           ),
          ),
          const SizedBox(width: 6),
          Flexible(
           child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
             color: AppColors.surfaceLight,
             borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
             appointment.patientId,
             style: AppTextStyles.caption.copyWith(
              fontSize: 9,
              color: AppColors.textMuted,
             ),
             maxLines: 1,
             overflow: TextOverflow.ellipsis,
            ),
           ),
          ),
         ],
        ),
        const SizedBox(height: 3),
        Text(
         appointment.consultationType,
         style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
          fontSize: 12,
         ),
         maxLines: 1,
         overflow: TextOverflow.ellipsis,
        ),
       ],
      ),
     ),
     const SizedBox(width: 8),
     // Status Badge + View Action
     Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
       _AppointmentStatusBadge(status: status),
       const SizedBox(height: 6),
       GestureDetector(
        onTap: onView,
        child: Container(
         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
         decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
           color: AppColors.primary.withValues(alpha: 0.3),
           width: 0.5,
          ),
         ),
         child: Text(
          'View',
          style: AppTextStyles.caption.copyWith(
           color: AppColors.primaryLight,
           fontWeight: FontWeight.w600,
           fontSize: 11,
          ),
         ),
        ),
       ),
      ],
     ),
    ],
   ),
  );
 }
}

class _AppointmentStatusBadge extends StatelessWidget {
 final DoctorAppointmentStatus status;

 const _AppointmentStatusBadge({required this.status});

 @override
 Widget build(BuildContext context) {
  String prefix = '● ';
  if (status == DoctorAppointmentStatus.completed) prefix = '✓ ';
  if (status == DoctorAppointmentStatus.cancelled) prefix = '× ';

  return Container(
   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
   decoration: BoxDecoration(
    color: status.color.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
     color: status.color.withValues(alpha: 0.3),
     width: 0.5,
    ),
   ),
   child: Text(
    '$prefix${status.label}',
    style: AppTextStyles.labelSmall.copyWith(
     color: status.color,
     fontSize: 10,
     fontWeight: FontWeight.w600,
    ),
   ),
  );
 }
}
