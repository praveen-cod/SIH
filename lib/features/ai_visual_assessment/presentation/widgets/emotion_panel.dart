import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clay_containers/clay_containers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../controllers/visual_assessment_controller.dart';

class EmotionPanel extends ConsumerWidget {
 const EmotionPanel({super.key});

 @override
 Widget build(BuildContext context, WidgetRef ref) {
  final state = ref.watch(visualAssessmentControllerProvider);
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final baseColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

  return ClayContainer(
   color: baseColor,
   borderRadius: 20,
   depth: 20,
   spread: 1,
   child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    child: Row(
     mainAxisSize: MainAxisSize.min,
     children: [
      Icon(Icons.face_retouching_natural_rounded, color: AppColors.primary, size: 20),
      const SizedBox(width: 8),
      Text(
       state.currentEmotion != null 
        ? '${state.currentEmotion!.toUpperCase()} (${(state.currentConfidence * 100).toStringAsFixed(0)}%)'
        : 'ANALYZING...',
       style: AppTextStyles.labelSmall.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
       ),
      ),
     ],
    ),
   ),
  );
 }
}
