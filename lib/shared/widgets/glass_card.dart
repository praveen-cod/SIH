import 'package:flutter/material.dart';
import 'package:clay_containers/clay_containers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Claymorphism-style card (kept as GlassCard name for backwards compatibility)
class GlassCard extends StatelessWidget {
 final Widget child;
 final EdgeInsetsGeometry? padding;
 final EdgeInsetsGeometry? margin;
 final double borderRadius;
 final Color? borderColor;
 final Gradient? gradient;
 final List<BoxShadow>? boxShadow;
 final VoidCallback? onTap;

 const GlassCard({
  super.key,
  required this.child,
  this.padding,
  this.margin,
  this.borderRadius = 16,
  this.borderColor,
  this.gradient,
  this.boxShadow,
  this.onTap,
 });

 @override
 Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final baseColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

  final card = Container(
   margin: margin,
   child: ClayContainer(
    color: baseColor,
    borderRadius: borderRadius,
    depth: 20,
    spread: 4,
    child: Padding(
     padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
     child: child,
    ),
   ),
  );

  if (onTap != null) {
   return GestureDetector(
    onTap: onTap,
    child: card,
   );
  }
  return card;
 }
}

/// Healthcare Analytics Statistic Card
class StatCard extends StatelessWidget {
 final String label;
 final String value;
 final IconData icon;
 final Color accentColor;
 final String? change;
 final bool isPositive;
 final String? statusBadge;
 final Color? statusBadgeColor;
 final bool showLivePulse;
 final String? subtitle;
 final VoidCallback? onTap;

 const StatCard({
  super.key,
  required this.label,
  required this.value,
  required this.icon,
  required this.accentColor,
  this.change,
  this.isPositive = true,
  this.statusBadge,
  this.statusBadgeColor,
  this.showLivePulse = false,
  this.subtitle,
  this.onTap,
 });

 @override
 Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return GlassCard(
   onTap: onTap,
   padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
   child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
     Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
       ClayContainer(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        height: 36,
        width: 36,
        borderRadius: 10,
        depth: 10,
        child: Center(
         child: Icon(icon, color: accentColor, size: 19),
        ),
       ),
       if (statusBadge != null)
        Flexible(
         child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
           padding: const EdgeInsets.symmetric(
            horizontal: 7,
            vertical: 3,
           ),
           decoration: BoxDecoration(
            color: (statusBadgeColor ?? accentColor).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
           ),
           child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
             if (showLivePulse) ...[
              Container(
               width: 5,
               height: 5,
               decoration: BoxDecoration(
                color: statusBadgeColor ?? accentColor,
                shape: BoxShape.circle,
               ),
              ),
              const SizedBox(width: 4),
             ],
             Text(
              statusBadge!,
              style: AppTextStyles.labelSmall.copyWith(
               color: statusBadgeColor ?? accentColor,
               fontSize: 10,
               fontWeight: FontWeight.w600,
              ),
             ),
            ],
           ),
          ),
         ),
        )
       else if (change != null)
        Flexible(
         child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
           padding: const EdgeInsets.symmetric(
            horizontal: 7,
            vertical: 3,
           ),
           decoration: BoxDecoration(
            color: isPositive
              ? AppColors.success.withValues(alpha: 0.15)
              : AppColors.error.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
           ),
           child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
             Icon(
              isPositive
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
              size: 11,
              color: isPositive ? AppColors.success : AppColors.error,
             ),
             const SizedBox(width: 3),
             Text(
              change!,
              style: AppTextStyles.labelSmall.copyWith(
               color: isPositive
                 ? AppColors.success
                 : AppColors.error,
               fontSize: 10,
               fontWeight: FontWeight.w600,
              ),
             ),
            ],
           ),
          ),
         ),
        ),
      ],
     ),
     const SizedBox(height: 10),
     Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       FittedBox(
        alignment: Alignment.centerLeft,
        fit: BoxFit.scaleDown,
        child: Text(
         value,
         style: AppTextStyles.statMedium.copyWith(
          fontSize: 24,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
         ),
        ),
       ),
       const SizedBox(height: 2),
       Text(
        label.toUpperCase(),
        style: AppTextStyles.overline.copyWith(
         color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
         fontSize: 10,
         fontWeight: FontWeight.w600,
         letterSpacing: 0.6,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
       ),
       if (subtitle != null) ...[
        const SizedBox(height: 2),
        Text(
         subtitle!,
         style: AppTextStyles.caption.copyWith(
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          fontSize: 10,
         ),
         maxLines: 1,
         overflow: TextOverflow.ellipsis,
        ),
       ],
      ],
     ),
    ],
   ),
  );
 }
}

/// Status badge widget
class StatusBadge extends StatelessWidget {
 final String label;
 final Color color;
 final bool showDot;

 const StatusBadge({
  super.key,
  required this.label,
  required this.color,
  this.showDot = true,
 });

 factory StatusBadge.confirmed() => const StatusBadge(
    label: 'Confirmed',
    color: AppColors.success,
   );

 factory StatusBadge.pending() => const StatusBadge(
    label: 'Pending',
    color: AppColors.warning,
   );

 factory StatusBadge.completed() => const StatusBadge(
    label: 'Completed',
    color: AppColors.primary,
   );

 factory StatusBadge.cancelled() => const StatusBadge(
    label: 'Cancelled',
    color: AppColors.error,
   );

 @override
 Widget build(BuildContext context) {
  return Container(
   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
   decoration: BoxDecoration(
    color: color.withValues(alpha: 0.15),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
   ),
   child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
     if (showDot) ...[
      Container(
       width: 5,
       height: 5,
       decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
       ),
      ),
      const SizedBox(width: 5),
     ],
     Text(
      label,
      style: AppTextStyles.labelSmall.copyWith(
       color: color,
       fontWeight: FontWeight.w600,
      ),
     ),
    ],
   ),
  );
 }
}
