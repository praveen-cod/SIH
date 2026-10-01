import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Coming Soon placeholder screen
class ComingSoonScreen extends StatelessWidget {
 final String featureTitle;

 const ComingSoonScreen({super.key, required this.featureTitle});

 @override
 Widget build(BuildContext context) {
  return Scaffold(
   backgroundColor: AppColors.background,
   appBar: AppBar(
    backgroundColor: AppColors.background,
    leading: IconButton(
     icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
     onPressed: () {
      if (Navigator.of(context).canPop()) {
       Navigator.of(context).pop();
      } else {
       Navigator.of(context).maybePop();
      }
     },
    ),
    title: Text(featureTitle, style: AppTextStyles.headingSmall),
    iconTheme: const IconThemeData(color: AppColors.textPrimary),
   ),
   body: Center(
    child: Padding(
     padding: const EdgeInsets.all(40),
     child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
       Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
         color: AppColors.primary.withValues(alpha: 0.1),
         shape: BoxShape.circle,
         border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
         ),
        ),
        child: const Icon(
         Icons.rocket_launch_rounded,
         color: AppColors.primary,
         size: 48,
        ),
       )
         .animate()
         .fadeIn(duration: 600.ms)
         .scale(begin: const Offset(0.8, 0.8)),
       const SizedBox(height: 32),
       Text(
        'Coming Soon',
        style: AppTextStyles.displaySmall,
       ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
       const SizedBox(height: 12),
       Text(
        '$featureTitle is being built and will be available in the next update.',
        style: AppTextStyles.bodyMedium,
        textAlign: TextAlign.center,
       ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
       const SizedBox(height: 32),
       Container(
        padding: const EdgeInsets.symmetric(
         horizontal: 20,
         vertical: 10,
        ),
        decoration: BoxDecoration(
         gradient: const LinearGradient(
          colors: AppColors.primaryGradient,
         ),
         borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
         'Phase 2 Feature',
         style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
         ),
        ),
       ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
      ],
     ),
    ),
   ),
  );
 }
}
