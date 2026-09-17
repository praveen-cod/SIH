import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/admin_dashboard_models.dart';
import '../../../shared/widgets/glass_card.dart';

/// Live Activity Stream for Admin Operations Center
class AdminActivityFeed extends StatelessWidget {
  final List<ActivityItem> activities;

  const AdminActivityFeed({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderColor: AppColors.borderLight,
      child: Column(
        children: activities.map((item) {
          final isEmergency = item.isEmergency;

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isEmergency
                  ? AppColors.error.withValues(alpha: 0.1)
                  : AppColors.surface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isEmergency
                    ? AppColors.error.withValues(alpha: 0.4)
                    : AppColors.border.withValues(alpha: 0.5),
                width: isEmergency ? 1.0 : 0.6,
              ),
            ),
            child: Row(
              children: [
                // Status dot or warning icon
                if (isEmergency)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.error,
                      size: 16,
                    ),
                  )
                else
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _colorForType(item.type).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _iconForType(item.type),
                      color: _colorForType(item.type),
                      size: 15,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isEmergency
                          ? AppColors.errorLight
                          : AppColors.textPrimary,
                      fontWeight: isEmergency ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item.timeAgo,
                  style: AppTextStyles.caption.copyWith(
                    color: isEmergency ? AppColors.errorLight : AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'patient':
        return AppColors.primary;
      case 'appointment':
        return AppColors.secondary;
      case 'doctor':
        return AppColors.doctorPrimary;
      case 'ai':
        return AppColors.accent;
      default:
        return AppColors.info;
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'patient':
        return Icons.person_outline_rounded;
      case 'appointment':
        return Icons.calendar_today_outlined;
      case 'doctor':
        return Icons.medical_services_outlined;
      case 'ai':
        return Icons.smart_toy_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }
}
