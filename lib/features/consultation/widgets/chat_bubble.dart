import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/consultation_model.dart';
import '../../../repositories/consultation_repository.dart';

/// Individual message bubble in the AI consultation conversation
class ChatBubble extends StatelessWidget {
 final ConsultationMessage message;

 const ChatBubble({super.key, required this.message});

 @override
 Widget build(BuildContext context) {
  if (message.isEmergencyWarning) {
   return _EmergencyBubble(message: message);
  }
  if (message.role.isPatient) {
   return _PatientBubble(message: message);
  }
  return _AIBubble(message: message);
 }
}

class _AIBubble extends ConsumerWidget {
 final ConsultationMessage message;

 const _AIBubble({required this.message});

 @override
 Widget build(BuildContext context, WidgetRef ref) {
  final timeStr = DateFormat('h:mm a').format(message.timestamp);
  final tts = ref.watch(ttsServiceProvider);

  return Padding(
   padding: const EdgeInsets.only(bottom: 16),
   child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
     // AI Avatar
     Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
       gradient: const LinearGradient(
        colors: AppColors.primaryGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
       ),
       borderRadius: BorderRadius.circular(10),
       boxShadow: [
        BoxShadow(
         color: AppColors.primary.withValues(alpha: 0.3),
         blurRadius: 10,
         offset: const Offset(0, 3),
        ),
       ],
      ),
      child: const Icon(
       Icons.smart_toy_rounded,
       color: Colors.white,
       size: 18,
      ),
     ),
     const SizedBox(width: 12),
     // Content bubble
     Flexible(
      child: Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
        Container(
         padding: const EdgeInsets.all(16),
         decoration: BoxDecoration(
          color: AppColors.surfaceLight.withValues(alpha: 0.85),
          borderRadius: const BorderRadius.only(
           topLeft: Radius.circular(4),
           topRight: Radius.circular(18),
           bottomLeft: Radius.circular(18),
           bottomRight: Radius.circular(18),
          ),
          border: Border.all(
           color: AppColors.primary.withValues(alpha: 0.15),
           width: 1,
          ),
          boxShadow: [
           BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
           ),
          ],
         ),
         child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           Text(
            message.content,
            style: AppTextStyles.bodyMedium.copyWith(
             color: AppColors.textPrimary,
             fontSize: 12,
             height: 1.4,
            ),
           ),
           const SizedBox(height: 8),
           Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
             if (message.language != null &&
               message.language != 'en')
              Container(
               padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
               ),
               decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
               ),
               child: Text(
                message.language!.toUpperCase(),
                style: AppTextStyles.overline.copyWith(
                 color: AppColors.primaryLight,
                 fontSize: 9,
                ),
               ),
              )
             else
              const SizedBox(),
             // Speaker button to replay AI voice in this language
             InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
               tts.speak(
                message.content,
                languageCode: message.language ?? 'en',
               );
              },
              child: Padding(
               padding: const EdgeInsets.all(4),
               child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                 Icon(
                  Icons.volume_up_rounded,
                  color: AppColors.primaryLight,
                  size: 16,
                 ),
                 const SizedBox(width: 4),
                 Text(
                  'Listen',
                  style: AppTextStyles.caption.copyWith(
                   color: AppColors.primaryLight,
                   fontSize: 11,
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
        const SizedBox(height: 4),
        Padding(
         padding: const EdgeInsets.only(left: 4),
         child: Text(
          timeStr,
          style: AppTextStyles.caption.copyWith(fontSize: 10),
         ),
        ),
       ],
      ),
     ),
     const SizedBox(width: 40),
    ],
   ),
  );
 }
}

class _PatientBubble extends StatelessWidget {
 final ConsultationMessage message;

 const _PatientBubble({required this.message});

 @override
 Widget build(BuildContext context) {
  final timeStr = DateFormat('h:mm a').format(message.timestamp);

  return Padding(
   padding: const EdgeInsets.only(bottom: 16),
   child: Row(
    mainAxisAlignment: MainAxisAlignment.end,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
     const SizedBox(width: 50),
     Flexible(
      child: Column(
       crossAxisAlignment: CrossAxisAlignment.end,
       children: [
        Container(
         padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
         ),
         decoration: BoxDecoration(
          gradient: const LinearGradient(
           colors: [
            Color(0xFF2D8EFF),
            Color(0xFF1E6FD4),
           ],
           begin: Alignment.topLeft,
           end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
           topLeft: Radius.circular(18),
           topRight: Radius.circular(4),
           bottomLeft: Radius.circular(18),
           bottomRight: Radius.circular(18),
          ),
          boxShadow: [
           BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 4),
           ),
          ],
         ),
         child: Text(
          message.content,
          style: AppTextStyles.bodyMedium.copyWith(
           color: Colors.white,
           fontWeight: FontWeight.w500,
           fontSize: 12,
           height: 1.4,
          ),
         ),
        ),
        const SizedBox(height: 4),
        Padding(
         padding: const EdgeInsets.only(right: 4),
         child: Text(
          timeStr,
          style: AppTextStyles.caption.copyWith(fontSize: 10),
         ),
        ),
       ],
      ),
     ),
     const SizedBox(width: 8),
     Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
       color: AppColors.surfaceLight,
       borderRadius: BorderRadius.circular(8),
       border: Border.all(color: AppColors.border),
      ),
      child: const Icon(
       Icons.person_rounded,
       color: AppColors.textSecondary,
       size: 16,
      ),
     ),
    ],
   ),
  );
 }
}

class _EmergencyBubble extends StatelessWidget {
 final ConsultationMessage message;

 const _EmergencyBubble({required this.message});

 @override
 Widget build(BuildContext context) {
  return Padding(
   padding: const EdgeInsets.symmetric(vertical: 14),
   child: Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
     color: const Color(0xFF330D0D),
     borderRadius: BorderRadius.circular(16),
     border: Border.all(
      color: AppColors.error,
      width: 1.5,
     ),
     boxShadow: [
      BoxShadow(
       color: AppColors.error.withValues(alpha: 0.35),
       blurRadius: 20,
       spreadRadius: 1,
      ),
     ],
    ),
    child: Column(
     crossAxisAlignment: CrossAxisAlignment.start,
     children: [
      Row(
       children: [
        Container(
         padding: const EdgeInsets.all(8),
         decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.25),
          shape: BoxShape.circle,
         ),
         child: const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.error,
          size: 22,
         ),
        ),
        const SizedBox(width: 12),
        Expanded(
         child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           Text(
            'Possible Emergency Detected',
            style: AppTextStyles.headingSmall.copyWith(
             color: AppColors.errorLight,
             fontWeight: FontWeight.w700,
             fontSize: 15,
            ),
           ),
           Text(
            'Immediate medical attention required',
            style: AppTextStyles.caption.copyWith(
             color: Colors.white70,
            ),
           ),
          ],
         ),
        ),
       ],
      ),
      const SizedBox(height: 12),
      Text(
       message.content,
       style: AppTextStyles.bodyMedium.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w500,
        height: 1.45,
       ),
      ),
      const SizedBox(height: 14),
      Container(
       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
       decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
       ),
       child: Row(
        children: [
         const Icon(Icons.phone_in_talk_rounded,
           color: AppColors.errorLight, size: 16),
         const SizedBox(width: 8),
         Expanded(
          child: Text(
           'Call local emergency services (911 / 112 / 108)',
           style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.errorLight,
            fontWeight: FontWeight.w600,
           ),
           maxLines: 2,
           overflow: TextOverflow.ellipsis,
          ),
         ),
        ],
       ),
      ),
     ],
    ),
   ),
  );
 }
}
