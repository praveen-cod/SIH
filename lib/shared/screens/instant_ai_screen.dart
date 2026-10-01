import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/language_provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../widgets/app_buttons.dart';
import '../widgets/language_selector_sheet.dart';

/// Instant AI Consultation placeholder screen
class InstantAIScreen extends ConsumerWidget {
 const InstantAIScreen({super.key});

 @override
 Widget build(BuildContext context, WidgetRef ref) {
  final languageState = ref.watch(languageProvider);
  final activeLanguage = languageState.currentLanguage;

  return Scaffold(
   backgroundColor: AppColors.background,
   appBar: AppBar(
    backgroundColor: AppColors.background,
    title: const Text('AI Consultation'),
    iconTheme: const IconThemeData(color: AppColors.textPrimary),
    leading: IconButton(
     icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
     onPressed: () {
      if (context.canPop()) {
       context.pop();
      } else {
       context.go('/patient-dashboard');
      }
     },
    ),
    actions: [
     IconButton(
      tooltip: 'Choose Language',
      icon: const Icon(Icons.translate_rounded, color: AppColors.primary),
      onPressed: () => LanguageSelectorSheet.show(context),
     ),
    ],
   ),
   body: SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
     children: [
      const SizedBox(height: 30),
      // AI avatar glow animation
      _AIAvatarWidget()
        .animate()
        .fadeIn(duration: 800.ms)
        .scale(begin: const Offset(0.7, 0.7)),
      const SizedBox(height: 32),
      Text(
       'AI Health Assistant',
       style: AppTextStyles.displaySmall,
       textAlign: TextAlign.center,
      ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
      const SizedBox(height: 12),
      Text(
       'Your intelligent health companion, available 24/7. Describe your symptoms and get instant AI-powered health guidance.',
       style: AppTextStyles.bodyMedium,
       textAlign: TextAlign.center,
      ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
      const SizedBox(height: 28),
      Container(
       padding: const EdgeInsets.all(20),
       decoration: BoxDecoration(
        gradient: LinearGradient(
         colors: [
          AppColors.primary.withValues(alpha: 0.1),
          AppColors.secondary.withValues(alpha: 0.1),
         ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
         color: AppColors.primary.withValues(alpha: 0.2),
        ),
       ),
       child: Column(
        children: [
         const Icon(
          Icons.auto_awesome,
          color: AppColors.primary,
          size: 36,
         ),
         const SizedBox(height: 12),
         Text(
          'Instant Medical Intake',
          style: AppTextStyles.headingSmall,
          textAlign: TextAlign.center,
         ),
         const SizedBox(height: 8),
         Text(
          'Speak or text with HealthCall AI in your language (English, தமிழ், हिन्दी, ಕನ್ನಡ, తెలుగు, etc.). Structured symptom intake and immediate emergency triage.',
          style: AppTextStyles.bodySmall,
          textAlign: TextAlign.center,
         ),
        ],
       ),
      ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
      const SizedBox(height: 24),
      
      // Language Selection Card
      InkWell(
       onTap: () => LanguageSelectorSheet.show(context),
       borderRadius: BorderRadius.circular(12),
       child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
         color: AppColors.surface,
         borderRadius: BorderRadius.circular(12),
         border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
         ),
        ),
        child: Row(
         children: [
          const Icon(
           Icons.translate_rounded,
           color: AppColors.primary,
           size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
           child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             Text(
              'Conversation Language',
              style: AppTextStyles.caption.copyWith(
               color: AppColors.textSecondary,
              ),
             ),
             Text(
              '${activeLanguage.name} (${activeLanguage.englishName})',
              style: AppTextStyles.bodyMedium.copyWith(
               fontWeight: FontWeight.w600,
               color: AppColors.textPrimary,
              ),
             ),
            ],
           ),
          ),
          Text(
           'Change',
           style: AppTextStyles.caption.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
           ),
          ),
          const Icon(
           Icons.chevron_right_rounded,
           color: AppColors.primary,
           size: 18,
          ),
         ],
        ),
       ),
      ).animate().fadeIn(delay: 550.ms, duration: 500.ms),
      const SizedBox(height: 24),

      AIActionButton(
       label: 'Start Instant Consultation',
       onPressed: () async {
        if (!ref.read(languageProvider).hasChosenPreference) {
         await LanguageSelectorSheet.show(context, isMandatory: true);
        }
        if (context.mounted) {
         context.push('${AppRoutes.consultationConsent}?guest=true');
        }
       },
      ).animate().fadeIn(delay: 600.ms, duration: 500.ms),
     ],
    ),
   ),
  );
 }
}

class _AIAvatarWidget extends StatefulWidget {
 @override
 State<_AIAvatarWidget> createState() => _AIAvatarWidgetState();
}

class _AIAvatarWidgetState extends State<_AIAvatarWidget>
  with SingleTickerProviderStateMixin {
 late AnimationController _controller;
 late Animation<double> _pulseAnim;

 @override
 void initState() {
  super.initState();
  _controller = AnimationController(
   vsync: this,
   duration: const Duration(milliseconds: 2000),
  )..repeat(reverse: true);
  _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
   CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
  );
 }

 @override
 void dispose() {
  _controller.dispose();
  super.dispose();
 }

 @override
 Widget build(BuildContext context) {
  return AnimatedBuilder(
   animation: _pulseAnim,
   builder: (context, child) {
    return Stack(
     alignment: Alignment.center,
     children: [
      // Outer glow ring
      Container(
       width: 140,
       height: 140,
       decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
         color: AppColors.primary.withValues(alpha: 0.2 * _pulseAnim.value),
         width: 2,
        ),
        boxShadow: [
         BoxShadow(
          color: AppColors.primary
            .withValues(alpha: 0.15 * _pulseAnim.value),
          blurRadius: 40 * _pulseAnim.value,
          spreadRadius: 10,
         ),
        ],
       ),
      ),
      // Inner glow ring
      Container(
       width: 110,
       height: 110,
       decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
         color: AppColors.secondary.withValues(alpha: 0.3 * _pulseAnim.value),
         width: 1,
        ),
       ),
      ),
      // Core avatar
      Container(
       width: 88,
       height: 88,
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
        size: 44,
       ),
      ),
     ],
    );
   },
  );
 }
}
