import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/appointment_model.dart';
import '../../../shared/widgets/glass_card.dart';

/// Appointment card for patient dashboard
class PatientAppointmentCard extends StatelessWidget {
 final AppointmentModel appointment;

 const PatientAppointmentCard({super.key, required this.appointment});

 @override
 Widget build(BuildContext context) {
  final formattedDate =
    DateFormat('d MMM yyyy').format(appointment.dateTime);
  final formattedTime = DateFormat('h:mm a').format(appointment.dateTime);

  final statusColor = _statusColor(appointment.status);

  return GlassCard(
   margin: const EdgeInsets.only(bottom: 12),
   padding: const EdgeInsets.all(16),
   borderColor: statusColor.withValues(alpha: 0.2),
   boxShadow: [
    BoxShadow(
     color: statusColor.withValues(alpha: 0.06),
     blurRadius: 16,
     offset: const Offset(0, 4),
    ),
    BoxShadow(
     color: Colors.black.withValues(alpha: 0.2),
     blurRadius: 10,
     offset: const Offset(0, 3),
    ),
   ],
   child: Row(
    children: [
     // Date pill
     Container(
      width: 52,
      height: 60,
      decoration: BoxDecoration(
       color: AppColors.primary.withValues(alpha: 0.12),
       borderRadius: BorderRadius.circular(12),
       border: Border.all(
        color: AppColors.primary.withValues(alpha: 0.25),
        width: 0.5,
       ),
      ),
      child: Column(
       mainAxisAlignment: MainAxisAlignment.center,
       children: [
        Text(
         DateFormat('d').format(appointment.dateTime),
         style: AppTextStyles.statSmall.copyWith(
          color: AppColors.primary,
          fontSize: 22,
          fontWeight: FontWeight.w800,
         ),
        ),
        Text(
         DateFormat('MMM').format(appointment.dateTime)
           .toUpperCase(),
         style: AppTextStyles.overline.copyWith(
          color: AppColors.primary,
         ),
        ),
       ],
      ),
     ),
     const SizedBox(width: 14),
     // Info
     Expanded(
      child: Column(
       mainAxisSize: MainAxisSize.min,
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
        Text(
         appointment.doctorName,
         style: AppTextStyles.headingSmall.copyWith(fontSize: 15),
        ),
        const SizedBox(height: 3),
        Text(
         appointment.specialty,
         style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 8),
        Row(
         children: [
          Icon(
           Icons.access_time_rounded,
           size: 13,
           color: AppColors.textMuted,
          ),
          const SizedBox(width: 4),
          Expanded(
           child: Text(
            '$formattedDate · $formattedTime',
            style: AppTextStyles.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
           ),
          ),
         ],
        ),
       ],
      ),
     ),
     const SizedBox(width: 8),
     // Status badge
     Flexible(child: _StatusBadgeWidget(status: appointment.status)),
    ],
   ),
  );
 }

 Color _statusColor(AppointmentStatus status) {
  switch (status) {
   case AppointmentStatus.confirmed:
    return AppColors.success;
   case AppointmentStatus.pending:
    return AppColors.warning;
   case AppointmentStatus.completed:
    return AppColors.primary;
   case AppointmentStatus.cancelled:
    return AppColors.error;
  }
 }
}

class _StatusBadgeWidget extends StatelessWidget {
 final AppointmentStatus status;

 const _StatusBadgeWidget({required this.status});

 @override
 Widget build(BuildContext context) {
  final color = _color;
  return Container(
   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
   decoration: BoxDecoration(
    color: color.withValues(alpha: 0.14),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
   ),
   child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
     Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
     ),
     const SizedBox(width: 4),
     Flexible(
      child: Text(
       status.label,
       style: AppTextStyles.labelSmall.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
        fontSize: 10,
       ),
       overflow: TextOverflow.ellipsis,
       maxLines: 1,
      ),
     ),
    ],
   ),
  );
 }

 Color get _color {
  switch (status) {
   case AppointmentStatus.confirmed:
    return AppColors.success;
   case AppointmentStatus.pending:
    return AppColors.warning;
   case AppointmentStatus.completed:
    return AppColors.primary;
   case AppointmentStatus.cancelled:
    return AppColors.error;
  }
 }
}
