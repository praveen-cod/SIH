import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/services/vision_ai_service.dart';
import '../controllers/visual_assessment_controller.dart';

class LiveCameraView extends ConsumerWidget {
 const LiveCameraView({super.key});

 @override
 Widget build(BuildContext context, WidgetRef ref) {
  final state = ref.watch(visualAssessmentControllerProvider);
  final service = ref.watch(visionAiServiceProvider);

  if (state.isInitializing) {
   return Center(
    child: Column(
     mainAxisAlignment: MainAxisAlignment.center,
     children: [
      const CircularProgressIndicator(),
      const SizedBox(height: 16),
      Text('Initializing Camera & AI...', style: AppTextStyles.bodyMedium),
     ],
    ),
   );
  }

  if (state.error != null || !state.hasPermission) {
   return Center(
    child: Column(
     mainAxisAlignment: MainAxisAlignment.center,
     children: [
      Icon(Icons.videocam_off, size: 48, color: AppColors.error),
      const SizedBox(height: 16),
      Text(
       state.error ?? 'Camera Permission Denied',
       style: AppTextStyles.bodyLarge.copyWith(color: AppColors.error),
       textAlign: TextAlign.center,
      ),
     ],
    ),
   );
  }

  if (service.textureId == null) {
   return const SizedBox.shrink();
  }

  return Stack(
   fit: StackFit.expand,
   children: [
    // Camera Preview
    NativeDeviceOrientationReader(
     builder: (context) {
      final orientation = NativeDeviceOrientationReader.orientation(context);
      int quarterTurns = 0;
      
      switch (orientation) {
       case NativeDeviceOrientation.landscapeLeft:
        quarterTurns = 3; // Swapped from 1
        break;
       case NativeDeviceOrientation.landscapeRight:
        quarterTurns = 1; // Swapped from 3
        break;
       case NativeDeviceOrientation.portraitDown:
        quarterTurns = 2;
        break;
       case NativeDeviceOrientation.portraitUp:
       case NativeDeviceOrientation.unknown:
        quarterTurns = 0;
        break;
      }

      return ClipRRect(
       borderRadius: BorderRadius.circular(16),
       child: SizedBox.expand(
        child: FittedBox(
         fit: BoxFit.cover,
         child: RotatedBox(
          quarterTurns: quarterTurns,
          child: SizedBox(
           width: 720, // Assumed native portrait texture resolution
           height: 1280,
           child: Texture(textureId: service.textureId!),
          ),
         ),
        ),
       ),
      );
     },
    ),
    
    // Face Detection Overlay
    if (state.faceDetected)
     Positioned.fill(
      child: Container(
       margin: const EdgeInsets.all(40),
       decoration: BoxDecoration(
        border: Border.all(color: Colors.greenAccent, width: 3),
        borderRadius: BorderRadius.circular(16),
       ),
       child: Stack(
        children: [
         Positioned(
          top: 8,
          right: 8,
          child: Container(
           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
           decoration: BoxDecoration(
            color: Colors.greenAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
           ),
           child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
             const Icon(Icons.face, size: 14, color: Colors.greenAccent),
             const SizedBox(width: 4),
             Text(
              'Face Detected',
              style: AppTextStyles.labelSmall.copyWith(color: Colors.greenAccent),
             ),
            ],
           ),
          ),
         ),
        ],
       ),
      ),
     ),
   ],
  );
 }
}
