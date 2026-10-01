import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/glass_card.dart';

/// System overview card with specialty breakdown
class SystemOverviewCard extends StatelessWidget {
 final List<Map<String, dynamic>> specialties;

 const SystemOverviewCard({super.key, required this.specialties});

 @override
 Widget build(BuildContext context) {
  return GlassCard(
   child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
     Row(
      children: [
       Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
         color: AppColors.adminPrimary.withValues(alpha: 0.12),
         borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
         Icons.donut_large_rounded,
         color: AppColors.adminPrimary,
         size: 18,
        ),
       ),
       const SizedBox(width: 12),
       Text('Specialty Breakdown', style: AppTextStyles.headingSmall),
      ],
     ),
     const SizedBox(height: 20),
     ...specialties.map((s) {
      final color = _colorForSpecialty(s['name'] as String);
      final percent = s['percent'] as int;
      return _SpecialtyRow(
       name: s['name'] as String,
       count: s['count'] as int,
       percent: percent,
       color: color,
      );
     }),
    ],
   ),
  );
 }

 Color _colorForSpecialty(String name) {
  switch (name) {
   case 'General Medicine':
    return AppColors.primary;
   case 'Cardiology':
    return AppColors.error;
   case 'Neurology':
    return AppColors.secondary;
   case 'Orthopedics':
    return AppColors.warning;
   default:
    return AppColors.textMuted;
  }
 }
}

class _SpecialtyRow extends StatelessWidget {
 final String name;
 final int count;
 final int percent;
 final Color color;

 const _SpecialtyRow({
  required this.name,
  required this.count,
  required this.percent,
  required this.color,
 });

 @override
 Widget build(BuildContext context) {
  return Padding(
   padding: const EdgeInsets.only(bottom: 14),
   child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
     Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
       Row(
        children: [
         Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
           color: color,
           shape: BoxShape.circle,
          ),
         ),
         const SizedBox(width: 8),
         Text(name, style: AppTextStyles.bodySmall.copyWith(fontSize: 13)),
        ],
       ),
       Row(
        children: [
         Text(
          '$count',
          style: AppTextStyles.labelMedium.copyWith(
           color: AppColors.textPrimary,
           fontWeight: FontWeight.w600,
          ),
         ),
         const SizedBox(width: 6),
         Text(
          '$percent%',
          style: AppTextStyles.caption.copyWith(color: color),
         ),
        ],
       ),
      ],
     ),
     const SizedBox(height: 6),
     LayoutBuilder(
      builder: (context, constraints) {
       return Stack(
        children: [
         Container(
          height: 5,
          width: constraints.maxWidth,
          decoration: BoxDecoration(
           color: AppColors.border,
           borderRadius: BorderRadius.circular(3),
          ),
         ),
         Container(
          height: 5,
          width: constraints.maxWidth * (percent / 100),
          decoration: BoxDecoration(
           color: color,
           borderRadius: BorderRadius.circular(3),
          ),
         ),
        ],
       );
      },
     ),
    ],
   ),
  );
 }
}
