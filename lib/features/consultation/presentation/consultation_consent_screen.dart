import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:clay_containers/clay_containers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/app_buttons.dart';

class ConsultationConsentScreen extends ConsumerStatefulWidget {
 final bool isGuest;
 const ConsultationConsentScreen({super.key, this.isGuest = false});

 @override
 ConsumerState<ConsultationConsentScreen> createState() => _ConsultationConsentScreenState();
}

class _ConsultationConsentScreenState extends ConsumerState<ConsultationConsentScreen> {
 bool _isAccepted = false;

 void _onAccept() {
  setState(() {
   _isAccepted = true;
  });
 }

 void _onSelectMode(bool videoEnabled) {
  if (videoEnabled) {
   context.push('${AppRoutes.visualAssessment}?guest=${widget.isGuest}');
  } else {
   context.push('${AppRoutes.consultation}?guest=${widget.isGuest}');
  }
 }

 @override
 Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final baseColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

  return Scaffold(
   backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
   appBar: AppBar(
    title: const Text('AI Assessment Consent'),
    backgroundColor: Colors.transparent,
    elevation: 0,
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
   ),
   body: SafeArea(
    child: Padding(
     padding: const EdgeInsets.all(24.0),
     child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
       Expanded(
        child: SingleChildScrollView(
         child: ClayContainer(
          color: baseColor,
          borderRadius: 16,
          depth: 20,
          spread: 2,
          child: Padding(
           padding: const EdgeInsets.all(24.0),
           child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             Row(
              children: [
               Icon(Icons.info_outline, color: AppColors.primary, size: 28),
               const SizedBox(width: 12),
               Expanded(
                child: Text(
                 'AI Clinical Observation',
                 style: AppTextStyles.headingSmall,
                ),
               ),
              ],
             ),
             const SizedBox(height: 20),
             Text(
              'Please read carefully before proceeding:\n\n'
              '1. This system uses Artificial Intelligence to observe and analyze verbal and (if enabled) non-verbal signals.\n\n'
              '2. The observations made by the AI are NOT a medical diagnosis. They are meant to assist the clinician in understanding your current state.\n\n'
              '3. Your camera feed is processed securely on your device. We do not store or transmit raw video frames. Only summary analytics are kept securely in your health record.\n\n'
              '4. If you are experiencing a life-threatening emergency, please call emergency services immediately.\n\n'
              '5. EMERGENCY NOTICE: In the event that our AI detects a potential medical emergency during your consultation, your current location and a camera image may be captured to assist emergency responders.',
              style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
             ),
            ],
           ),
          ),
         ),
        ),
       ),
       const SizedBox(height: 24),
       if (!_isAccepted)
        GradientButton(
         label: 'I Accept & Understand',
         onPressed: _onAccept,
        )
       else ...[
        Text(
         'Select Consultation Mode',
         style: AppTextStyles.headingSmall,
         textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Row(
         children: [
          Expanded(
           child: OutlinedAppButton(
            label: 'Voice Only',
            icon: Icons.mic_rounded,
            onPressed: () => _onSelectMode(false),
           ),
          ),
          const SizedBox(width: 16),
          Expanded(
           child: GradientButton(
            label: 'Video + Voice',
            icon: Icons.videocam_rounded,
            onPressed: () => _onSelectMode(true),
           ),
          ),
         ],
        ),
       ],
      ],
     ),
    ),
   ),
  );
 }
}
