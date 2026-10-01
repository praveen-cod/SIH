import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clay_containers/clay_containers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../controllers/visual_assessment_controller.dart';
import '../../../../repositories/consultation_repository.dart';
import '../../../../shared/widgets/app_buttons.dart';

class AssessmentSummary extends ConsumerWidget {
 final VoidCallback onDone;

 const AssessmentSummary({super.key, required this.onDone});

 @override
 Widget build(BuildContext context, WidgetRef ref) {
  final controller = ref.read(visualAssessmentControllerProvider.notifier);
  final dist = controller.getExpressionDistribution();
  final dominant = controller.getDominantExpression();
  
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final baseColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

  return Center(
   child: Padding(
    padding: const EdgeInsets.all(24.0),
    child: ClayContainer(
     color: baseColor,
     borderRadius: 16,
     depth: 20,
     spread: 2,
     child: Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
       child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
         Text(
          'AI Visual Observation Summary',
          style: AppTextStyles.headingSmall,
          textAlign: TextAlign.center,
         ),
         const SizedBox(height: 16),
         Text('• Face detected consistently.', style: AppTextStyles.bodySmall),
         const SizedBox(height: 4),
         Text('• Dominant expression: $dominant.', style: AppTextStyles.bodySmall),
         const SizedBox(height: 12),
         Text('Distribution:', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
         const SizedBox(height: 4),
         ...dist.entries.map((e) {
          return Padding(
           padding: const EdgeInsets.only(bottom: 2.0),
           child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
             Text(e.key.toUpperCase(), style: AppTextStyles.caption),
             Text('${(e.value * 100).toStringAsFixed(0)}%', style: AppTextStyles.caption),
            ],
           ),
          );
         }),
         const SizedBox(height: 16),
         Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
           color: AppColors.error.withValues(alpha: 0.1),
           borderRadius: BorderRadius.circular(8),
           border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
          ),
          child: Text(
           'Disclaimer: Not a medical diagnosis. Clinician interpretation required.',
           style: AppTextStyles.caption.copyWith(color: AppColors.error, fontSize: 10),
          ),
         ),
         const SizedBox(height: 16),
         GradientButton(
          label: 'Done',
          onPressed: () async {
           final consultationNotifier = ref.read(consultationProvider.notifier);
           var summary = ref.read(consultationProvider).summary;
           summary ??= await consultationNotifier.endConsultation();
           
           if (summary != null) {
            final assessmentState = ref.read(visualAssessmentControllerProvider);
            final durationSecs = assessmentState.sessionStartTime != null 
              ? DateTime.now().difference(assessmentState.sessionStartTime!).inSeconds
              : 0;
              
            final updatedSummary = summary.copyWith(
             visualDominantEmotion: dominant,
             visualEmotionDistribution: dist,
             visualAssessmentDurationSeconds: durationSecs,
            );
            
            await consultationNotifier.updateSummary(updatedSummary);
           }
           onDone();
          },
         ),
        ],
       ),
      ),
     ),
    ),
   ),
  );
 }
}
