import 'package:flutter/material.dart';
import 'package:clay_containers/clay_containers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Gradient primary button
class GradientButton extends StatefulWidget {
 final String label;
 final VoidCallback? onPressed;
 final bool isLoading;
 final IconData? icon;
 final List<Color>? gradientColors;
 final double? width;
 final double height;
 final double borderRadius;

 const GradientButton({
  super.key,
  required this.label,
  this.onPressed,
  this.isLoading = false,
  this.icon,
  this.gradientColors,
  this.width,
  this.height = 54,
  this.borderRadius = 14,
 });

 @override
 State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
  with SingleTickerProviderStateMixin {
 bool _isPressed = false;

 @override
 Widget build(BuildContext context) {
  final isEnabled = widget.onPressed != null && !widget.isLoading;
  final colors = widget.gradientColors ?? [AppColors.primary, AppColors.primary];
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final baseColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

  return GestureDetector(
   onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
   onTapUp: isEnabled
     ? (_) {
       setState(() => _isPressed = false);
       widget.onPressed?.call();
      }
     : null,
   onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
   child: ClayContainer(
    color: baseColor,
    surfaceColor: isEnabled ? colors.first : AppColors.textDisabled,
    borderRadius: widget.borderRadius,
    depth: isEnabled ? 20 : 0,
    spread: 2,
    emboss: _isPressed,
    child: SizedBox(
     width: widget.width,
     height: widget.height,
     child: widget.isLoading
       ? const Center(
         child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
           strokeWidth: 2.5,
           valueColor:
             AlwaysStoppedAnimation<Color>(Colors.white),
          ),
         ),
        )
       : Row(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
          if (widget.icon != null) ...[
           Icon(
            widget.icon,
            color: Colors.white,
            size: 20,
           ),
           const SizedBox(width: 8),
          ],
          Text(
           widget.label,
           style: AppTextStyles.buttonLarge.copyWith(
            color: Colors.white,
           ),
          ),
         ],
        ),
    ),
   ),
  );
 }
}

/// Outlined secondary button
class OutlinedAppButton extends StatelessWidget {
 final String label;
 final VoidCallback? onPressed;
 final IconData? icon;
 final Color? borderColor;

 const OutlinedAppButton({
  super.key,
  required this.label,
  this.onPressed,
  this.icon,
  this.borderColor,
 });

 @override
 Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final baseColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

  return GestureDetector(
   onTap: onPressed,
   child: ClayContainer(
    color: baseColor,
    borderRadius: 14,
    depth: 10,
    spread: 2,
    child: SizedBox(
     height: 54,
     child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
       if (icon != null) ...[
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
       ],
       Text(
        label,
        style: AppTextStyles.buttonLarge.copyWith(
         color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
       ),
      ],
     ),
    ),
   ),
  );
 }
}

/// AI action button with glow effect
class AIActionButton extends StatefulWidget {
 final VoidCallback? onPressed;
 final String label;

 const AIActionButton({
  super.key,
  this.onPressed,
  this.label = 'Start AI Consultation',
 });

 @override
 State<AIActionButton> createState() => _AIActionButtonState();
}

class _AIActionButtonState extends State<AIActionButton>
  with SingleTickerProviderStateMixin {
 late AnimationController _pulseController;
 late Animation<double> _pulseAnim;

 @override
 void initState() {
  super.initState();
  _pulseController = AnimationController(
   vsync: this,
   duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
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
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final baseColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

  return AnimatedBuilder(
   animation: _pulseAnim,
   builder: (context, child) {
    return GestureDetector(
     onTap: widget.onPressed,
     child: ClayContainer(
      color: baseColor,
      surfaceColor: AppColors.primary,
      borderRadius: 16,
      depth: (20 * _pulseAnim.value).toInt(),
      spread: 4 * _pulseAnim.value,
      child: SizedBox(
       height: 58,
       child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
         Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
           color: Colors.white.withValues(alpha: 0.2),
           shape: BoxShape.circle,
          ),
          child: const Icon(
           Icons.auto_awesome,
           color: Colors.white,
           size: 16,
          ),
         ),
         const SizedBox(width: 12),
         Text(
          widget.label,
          style: AppTextStyles.buttonLarge.copyWith(
           color: Colors.white,
          ),
         ),
        ],
       ),
      ),
     ),
    );
   },
  );
 }
}
