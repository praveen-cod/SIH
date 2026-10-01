import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/doctor_dashboard_models.dart';
import '../../../shared/widgets/reusable_dashboard_components.dart';

/// Prominent Active Consultation Card with ticking stopwatch timer
class ActiveConsultationCard extends StatefulWidget {
 final ActiveConsultation consultation;
 final VoidCallback onContinue;
 final bool enableLiveTimer;

 const ActiveConsultationCard({
  super.key,
  required this.consultation,
  required this.onContinue,
  this.enableLiveTimer = true,
 });

 @override
 State<ActiveConsultationCard> createState() => _ActiveConsultationCardState();
}

class _ActiveConsultationCardState extends State<ActiveConsultationCard> {
 late int _seconds;
 Timer? _timer;

 @override
 void initState() {
  super.initState();
  _seconds = widget.consultation.initialDurationSeconds;
  if (widget.enableLiveTimer) {
   _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
    if (mounted) {
     setState(() => _seconds++);
    }
   });
  }
 }

 @override
 void dispose() {
  _timer?.cancel();
  super.dispose();
 }

 String get _formattedDuration {
  final m = (_seconds ~/ 60).toString().padLeft(2, '0');
  final s = (_seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
 }

 @override
 Widget build(BuildContext context) {
  return Container(
   decoration: BoxDecoration(
    gradient: const LinearGradient(
     colors: [Color(0xFF162544), Color(0xFF101B33)],
     begin: Alignment.topLeft,
     end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
     color: AppColors.accent.withValues(alpha: 0.4),
     width: 1.2,
    ),
    boxShadow: [
     BoxShadow(
      color: AppColors.accent.withValues(alpha: 0.12),
      blurRadius: 20,
      offset: const Offset(0, 6),
     ),
     BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 10,
      offset: const Offset(0, 4),
     ),
    ],
   ),
   child: Padding(
    padding: const EdgeInsets.all(18),
    child: Column(
     crossAxisAlignment: CrossAxisAlignment.start,
     children: [
      Row(
       children: [
        Container(
         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
         decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
           color: AppColors.accent.withValues(alpha: 0.35),
           width: 0.8,
          ),
         ),
         child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
           const PulseDot(color: AppColors.accent, size: 6),
           const SizedBox(width: 6),
           Text(
            'In Consultation',
            style: AppTextStyles.labelSmall.copyWith(
             color: AppColors.accent,
             fontWeight: FontWeight.w600,
            ),
           ),
          ],
         ),
        ),
        const Spacer(),
        Container(
         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
         decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
         ),
         child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
           const Icon(Icons.timer_outlined, size: 14, color: AppColors.accent),
           const SizedBox(width: 5),
           Text(
            _formattedDuration,
            style: const TextStyle(
             fontFamily: 'Inter',
             fontSize: 14,
             fontWeight: FontWeight.w700,
             color: Colors.white,
             letterSpacing: 0.5,
            ),
           ),
          ],
         ),
        ),
       ],
      ),
      const SizedBox(height: 16),
      Row(
       children: [
        Container(
         width: 44,
         height: 44,
         decoration: BoxDecoration(
          gradient: const LinearGradient(
           colors: [Color(0xFF2D8EFF), Color(0xFF00D4FF)],
          ),
          shape: BoxShape.circle,
         ),
         child: Center(
          child: Text(
           widget.consultation.patientId.substring(widget.consultation.patientId.length - 2),
           style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
          ),
         ),
        ),
        const SizedBox(width: 14),
        Expanded(
         child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           Row(
            children: [
             Text('Patient ID: ', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
             Text(
              widget.consultation.patientId,
              style: AppTextStyles.labelMedium.copyWith(
               color: AppColors.textPrimary,
               fontWeight: FontWeight.w700,
              ),
             ),
            ],
           ),
           const SizedBox(height: 3),
           Text(
            widget.consultation.reason,
            style: AppTextStyles.bodyMedium.copyWith(
             color: AppColors.primaryLight,
             fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
           ),
          ],
         ),
        ),
       ],
      ),
      const SizedBox(height: 16),
      SizedBox(
       width: double.infinity,
       child: ElevatedButton.icon(
        onPressed: widget.onContinue,
        style: ElevatedButton.styleFrom(
         backgroundColor: AppColors.primary,
         foregroundColor: Colors.white,
         padding: const EdgeInsets.symmetric(vertical: 12),
         shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
         ),
         elevation: 0,
        ),
        icon: const Icon(Icons.videocam_rounded, size: 18),
        label: const Text(
         'Continue Consultation',
         style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
       ),
      ),
     ],
    ),
   ),
  );
 }
}
