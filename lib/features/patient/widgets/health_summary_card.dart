import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/glass_card.dart';

/// Health vitals summary card for patient dashboard
class HealthSummaryCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const HealthSummaryCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppColors.success.withOpacity(0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: AppColors.success,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('Vitals', style: AppTextStyles.headingSmall),
                ],
              ),
              Text(
                'Updated ${data['lastUpdated']}',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _VitalItem(
                  label: 'Blood Pressure',
                  value: data['bloodPressure'] as String,
                  unit: 'mmHg',
                  icon: Icons.water_drop_outlined,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _VitalItem(
                  label: 'Heart Rate',
                  value: '72',
                  unit: 'bpm',
                  icon: Icons.monitor_heart_outlined,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _VitalItem(
                  label: 'Blood Sugar',
                  value: '98',
                  unit: 'mg/dL',
                  icon: Icons.opacity_rounded,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _VitalItem(
                  label: 'Weight',
                  value: '70',
                  unit: 'kg',
                  icon: Icons.fitness_center_outlined,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VitalItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _VitalItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: AppTextStyles.statSmall.copyWith(
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
