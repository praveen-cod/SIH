import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/consultation_model.dart';

/// Animated status pill in the AI Consultation AppBar
class AIStatusIndicator extends StatefulWidget {
 final ConsultationUIState state;
 final bool isCompact;

 const AIStatusIndicator({
  super.key,
  required this.state,
  this.isCompact = false,
 });

 @override
 State<AIStatusIndicator> createState() => _AIStatusIndicatorState();
}

class _AIStatusIndicatorState extends State<AIStatusIndicator>
  with SingleTickerProviderStateMixin {
 late AnimationController _anim;

 @override
 void initState() {
  super.initState();
  _anim = AnimationController(
   vsync: this,
   duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);
 }

 @override
 void dispose() {
  _anim.dispose();
  super.dispose();
 }

 @override
 Widget build(BuildContext context) {
  final (Color color, String label, IconData? icon) = _config(widget.state);
  final isCompact = widget.isCompact;

  return AnimatedContainer(
   duration: const Duration(milliseconds: 250),
   padding: EdgeInsets.symmetric(
    horizontal: isCompact ? 6 : 9,
    vertical: isCompact ? 3.5 : 5,
   ),
   decoration: BoxDecoration(
    color: color.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
     color: color.withValues(alpha: 0.35),
     width: 0.8,
    ),
   ),
   child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
     AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
       if (widget.state == ConsultationUIState.processing) {
        return SizedBox(
         width: isCompact ? 8 : 10,
         height: isCompact ? 8 : 10,
         child: CircularProgressIndicator(
          strokeWidth: 1.5,
          valueColor: AlwaysStoppedAnimation<Color>(color),
         ),
        );
       }

       return Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
         color: color.withValues(alpha: 0.5 + 0.5 * _anim.value),
         shape: BoxShape.circle,
         boxShadow: [
          BoxShadow(
           color: color.withValues(alpha: 0.6 * _anim.value),
           blurRadius: 6,
           spreadRadius: 1,
          ),
         ],
        ),
       );
      },
     ),
     const SizedBox(width: 6),
     Text(
      label,
      style: AppTextStyles.labelSmall.copyWith(
       color: color,
       fontWeight: FontWeight.w600,
       fontSize: 11,
      ),
     ),
    ],
   ),
  );
 }

 (Color, String, IconData?) _config(ConsultationUIState state) {
  switch (state) {
   case ConsultationUIState.idle:
    return (AppColors.success, 'Online', Icons.check_circle_outline);
   case ConsultationUIState.listening:
    return (AppColors.warning, 'Listening...', Icons.mic);
   case ConsultationUIState.processing:
    return (AppColors.primary, 'Processing...', Icons.sync);
   case ConsultationUIState.responding:
    return (AppColors.accentPurple, 'AI Responding...', Icons.smart_toy);
   case ConsultationUIState.emergency:
    return (AppColors.error, 'Emergency Alert', Icons.warning);
   case ConsultationUIState.completed:
    return (AppColors.success, 'Intake Done', Icons.done_all);
   case ConsultationUIState.error:
    return (AppColors.error, 'Offline', Icons.error_outline);
  }
 }
}
