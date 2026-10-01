import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:clay_containers/clay_containers.dart';
import 'package:screenshot/screenshot.dart';
import '../../../consultation/presentation/consultation_screen.dart';
import '../widgets/live_camera_view.dart';
import '../widgets/emotion_panel.dart';
import '../widgets/assessment_summary.dart';
import '../../../../core/theme/app_colors.dart';

final ScreenshotController emergencyScreenshotController = ScreenshotController();

class AIVisualAssessmentPage extends ConsumerStatefulWidget {
 final bool isGuest;
 const AIVisualAssessmentPage({super.key, this.isGuest = false});

 @override
 ConsumerState<AIVisualAssessmentPage> createState() => _AIVisualAssessmentPageState();
}

class _AIVisualAssessmentPageState extends ConsumerState<AIVisualAssessmentPage> {
 bool _showSummary = false;

 @override
 void dispose() {
  super.dispose();
 }

 void _onEndAssessment() {
  setState(() {
   _showSummary = true;
  });
 }

 @override
 Widget build(BuildContext context) {
  if (_showSummary) {
   return Scaffold(
    backgroundColor: AppColors.background,
    body: AssessmentSummary(
     onDone: () {
      context.pop();
     },
    ),
   );
  }

  final cameraSection = Screenshot(
   controller: emergencyScreenshotController,
   child: Stack(
    fit: StackFit.expand,
   children: [
    const LiveCameraView(),
    const Positioned(
     top: 16,
     right: 16,
     child: EmotionPanel(),
    ),
    Positioned(
     top: 16,
     left: 16,
     child: Container(
      decoration: const BoxDecoration(
       color: Colors.black45,
       shape: BoxShape.circle,
      ),
      child: IconButton(
       icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
       onPressed: _onEndAssessment,
      ),
     ),
    ),
   ],
  ),
 );

   return Scaffold(
   backgroundColor: Colors.black, // Behind camera
   body: LayoutBuilder(
    builder: (context, constraints) {
     return Stack(
      fit: StackFit.expand,
      children: [
       // Full screen camera
       Positioned.fill(child: cameraSection),
       // Floating Draggable Chat
       FloatingDraggableChat(
        screenWidth: constraints.maxWidth,
        screenHeight: constraints.maxHeight,
        child: ConsultationScreen(isGuest: widget.isGuest),
       ),
      ],
     );
    },
   ),
  );
 }
}

class FloatingDraggableChat extends StatefulWidget {
 final Widget child;
 final double screenWidth;
 final double screenHeight;
 const FloatingDraggableChat({
  super.key,
  required this.child,
  required this.screenWidth,
  required this.screenHeight,
 });
 @override
 State<FloatingDraggableChat> createState() => _FloatingDraggableChatState();
}

class _FloatingDraggableChatState extends State<FloatingDraggableChat> {
 double _x = -1;
 double _y = -1;
 double _w = -1;
 double _h = -1;
 bool _wasLandscape = false;

 void _initIfNeeded() {
  final sw = widget.screenWidth;
  final sh = widget.screenHeight;
  final isLandscape = sw > sh;
  
  if (_x < 0 || _wasLandscape != isLandscape) {
   if (isLandscape) {
    _w = sw * 0.4;
    _h = sh - 48;
    _x = sw - _w - 16;
    _y = 24;
   } else {
    _w = sw - 48;
    _h = sh * 0.45;
    _x = 24;
    _y = sh - _h - 24;
   }
   _wasLandscape = isLandscape;
  }
  // Clamp to new screen bounds on rotation
  _w = _w.clamp(200.0, sw);
  _h = _h.clamp(180.0, sh);
  _x = _x.clamp(0.0, sw - _w);
  _y = _y.clamp(0.0, sh - _h);
 }

 @override
 Widget build(BuildContext context) {
  _initIfNeeded();

  return Positioned(
   left: _x,
   top: _y,
   width: _w,
   height: _h,
   child: ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: ClayContainer(
     depth: 20,
     spread: 4,
     borderRadius: 24,
     color: AppColors.background.withValues(alpha: 0.92),
     child: Column(
      children: [
      // ── Drag Handle ──────────────────────────────────────────
      GestureDetector(
       behavior: HitTestBehavior.opaque,
       onPanUpdate: (d) {
        setState(() {
         _x = (_x + d.delta.dx).clamp(0.0, widget.screenWidth - _w);
         _y = (_y + d.delta.dy).clamp(0.0, widget.screenHeight - _h);
        });
       },
       child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
         color: Colors.transparent,
         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Container(
         width: 40,
         height: 4,
         decoration: BoxDecoration(
          color: AppColors.textMuted,
          borderRadius: BorderRadius.circular(2),
         ),
        ),
       ),
      ),
      // ── Chat Content ─────────────────────────────────────────
      Expanded(
       child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        child: widget.child,
       ),
      ),
      // ── Resize Handle ────────────────────────────────────────
      GestureDetector(
       behavior: HitTestBehavior.opaque,
       onPanUpdate: (d) {
        setState(() {
         _w = (_w + d.delta.dx).clamp(200.0, widget.screenWidth - _x);
         _h = (_h + d.delta.dy).clamp(180.0, widget.screenHeight - _y);
        });
       },
       child: Container(
        height: 24,
        width: double.infinity,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 12),
        decoration: const BoxDecoration(
         color: Colors.transparent,
         borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        child: const Icon(Icons.drag_indicator, size: 20, color: AppColors.textMuted),
       ),
      ),
      ],
     ),
    ),
   ),
  );
 }
}

