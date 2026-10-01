import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clay_containers/clay_containers.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/language_selector_sheet.dart';

/// Prominent AI assistant card for patient dashboard
class AIAssistantCard extends ConsumerStatefulWidget {
 final VoidCallback onStartConsultation;

 const AIAssistantCard({super.key, required this.onStartConsultation});

 @override
 ConsumerState<AIAssistantCard> createState() => _AIAssistantCardState();
}

class _AIAssistantCardState extends ConsumerState<AIAssistantCard>
  with SingleTickerProviderStateMixin {
 late AnimationController _pulseController;
 late Animation<double> _pulseAnim;

 @override
 void initState() {
  super.initState();
  _pulseController = AnimationController(
   vsync: this,
   duration: const Duration(milliseconds: 2000),
  )..repeat(reverse: true);
  _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
   CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
  );
 }

 @override
 void dispose() {
  _pulseController.dispose();
  super.dispose();
 }

 @override
 Widget build(BuildContext context) {
  final currentLang = ref.watch(languageProvider).currentLanguage;

  return AnimatedBuilder(
   animation: _pulseAnim,
   builder: (context, child) {
    return ClayContainer(
     depth: 20,
     spread: 4,
     borderRadius: 20,
     color: AppColors.background,
     child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
       children: [
        // Background grid pattern
        Positioned.fill(
         child: CustomPaint(painter: _GridPainter()),
        ),
        Padding(
         padding: const EdgeInsets.all(20),
         child: Row(
          children: [
           // AI Avatar
           Stack(
            alignment: Alignment.center,
            children: [
             Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
               color: AppColors.primary.withValues(alpha: 0.1 * _pulseAnim.value),
               shape: BoxShape.circle,
              ),
             ),
             Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
               gradient: LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
               ),
               shape: BoxShape.circle,
              ),
              child: const Icon(
               Icons.smart_toy_rounded,
               color: Colors.white,
               size: 28,
              ),
             ),
            ],
           ),
           const SizedBox(width: 16),
           // Text content
           Expanded(
            child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
              Row(
               children: [
                Text(
                 'AI Health Assistant',
                 style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.textPrimary,
                 ),
                ),
                const SizedBox(width: 8),
                Container(
                 padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2,
                 ),
                 decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                   color: AppColors.success.withValues(alpha: 0.4),
                   width: 0.5,
                  ),
                 ),
                 child: Text(
                  'LIVE',
                  style: AppTextStyles.overline.copyWith(
                   color: AppColors.success,
                   fontSize: 8,
                  ),
                 ),
                ),
               ],
              ),
              const SizedBox(height: 4),
              Text(
               '"Speaks in ${currentLang.name} (${currentLang.englishName})"',
               style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
                fontSize: 11.5,
               ),
              ),
              const SizedBox(height: 12),
              Wrap(
               spacing: 8,
               runSpacing: 8,
               crossAxisAlignment: WrapCrossAlignment.center,
               children: [
                GestureDetector(
                 onTap: widget.onStartConsultation,
                 child: Container(
                  padding: const EdgeInsets.symmetric(
                   horizontal: 14,
                   vertical: 9,
                  ),
                  decoration: BoxDecoration(
                   gradient: const LinearGradient(
                    colors: AppColors.primaryGradient,
                   ),
                   borderRadius: BorderRadius.circular(10),
                   boxShadow: [
                    BoxShadow(
                     color: AppColors.primary.withValues(alpha: 0.4 * _pulseAnim.value),
                     blurRadius: 12,
                     offset: const Offset(0, 4),
                    ),
                   ],
                  ),
                  child: Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                    const Icon(
                     Icons.auto_awesome,
                     color: Colors.white,
                     size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                     'Start Consultation',
                     style: AppTextStyles.buttonMedium.copyWith(
                      color: Colors.white,
                      fontSize: 12,
                     ),
                    ),
                   ],
                  ),
                 ),
                ),
                GestureDetector(
                 onTap: () => LanguageSelectorSheet.show(context),
                 child: Container(
                  padding: const EdgeInsets.symmetric(
                   horizontal: 10,
                   vertical: 8,
                  ),
                  decoration: BoxDecoration(
                   color: Colors.grey.withValues(alpha: 0.1),
                   borderRadius: BorderRadius.circular(10),
                   border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.2),
                    width: 0.8,
                   ),
                  ),
                  child: Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                    const Icon(
                     Icons.translate_rounded,
                     color: AppColors.primary,
                     size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                     currentLang.name,
                     style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                     ),
                    ),
                   ],
                  ),
                 ),
                ),
               ],
              ),
             ],
            ),
           ),
          ],
         ),
        ),
       ],
      ),
     ),
    );
   },
  );
 }
}

class _GridPainter extends CustomPainter {
 @override
 void paint(Canvas canvas, Size size) {
  final paint = Paint()
   ..color = const Color(0xFF2D8EFF).withValues(alpha: 0.04)
   ..strokeWidth = 0.5;

  const step = 28.0;
  for (double x = 0; x < size.width; x += step) {
   canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
  }
  for (double y = 0; y < size.height; y += step) {
   canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }
 }

 @override
 bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
