import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// HealthCall AI logo widget
class AppLogo extends StatelessWidget {
 final double size;
 final bool showTagline;
 final bool compact;

 const AppLogo({
  super.key,
  this.size = 56,
  this.showTagline = true,
  this.compact = false,
 });

 @override
 Widget build(BuildContext context) {
  if (compact) {
   return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
     _buildLogoIcon(32),
     const SizedBox(width: 10),
     Text(
      'HealthCall AI',
      style: AppTextStyles.headingMedium.copyWith(
       foreground: Paint()
        ..shader = const LinearGradient(
         colors: AppColors.primaryGradient,
        ).createShader(
         const Rect.fromLTWH(0, 0, 200, 40),
        ),
      ),
     ),
    ],
   );
  }

  return Column(
   mainAxisSize: MainAxisSize.min,
   children: [
    _buildLogoIcon(size),
    const SizedBox(height: 16),
    ShaderMask(
     shaderCallback: (bounds) => const LinearGradient(
      colors: AppColors.primaryGradient,
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
     ).createShader(bounds),
     child: Text(
      'HealthCall AI',
      style: AppTextStyles.displaySmall.copyWith(
       color: Colors.white,
       letterSpacing: -0.5,
      ),
     ),
    ),
    if (showTagline) ...[
     const SizedBox(height: 6),
     Text(
      'AI-Powered Healthcare Assistant',
      style: AppTextStyles.bodySmall.copyWith(
       color: AppColors.textMuted,
       letterSpacing: 0.3,
      ),
     ),
    ],
   ],
  );
 }

 Widget _buildLogoIcon(double iconSize) {
  return Container(
   width: iconSize,
   height: iconSize,
   decoration: BoxDecoration(
    gradient: const LinearGradient(
     colors: AppColors.primaryGradient,
     begin: Alignment.topLeft,
     end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(iconSize * 0.28),
    boxShadow: [
     BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.4),
      blurRadius: 20,
      spreadRadius: 0,
      offset: const Offset(0, 8),
     ),
    ],
   ),
   child: Center(
    child: Icon(
     Icons.health_and_safety_rounded,
     color: Colors.white,
     size: iconSize * 0.55,
    ),
   ),
  );
 }
}
