import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/reusable_dashboard_components.dart';

/// Doctor Availability and Today's Schedule Card
class DoctorAvailabilityCard extends StatelessWidget {
  final bool isAvailable;
  final VoidCallback onManage;

  const DoctorAvailabilityCard({
    super.key,
    required this.isAvailable,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderColor: isAvailable
          ? AppColors.success.withValues(alpha: 0.25)
          : AppColors.border,
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
                      color: (isAvailable ? AppColors.success : AppColors.textMuted)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.schedule_rounded,
                      color: isAvailable ? AppColors.success : AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Your Availability', style: AppTextStyles.headingSmall),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isAvailable ? AppColors.success : AppColors.textMuted)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (isAvailable ? AppColors.success : AppColors.textMuted)
                        .withValues(alpha: 0.35),
                    width: 0.6,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PulseDot(
                      color: isAvailable ? AppColors.success : AppColors.textMuted,
                      size: 6,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isAvailable ? 'Available' : 'Unavailable',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isAvailable ? AppColors.success : AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Today's Schedule",
            style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ScheduleSlot(
                  time: '09:00 AM — 01:00 PM',
                  label: 'Morning Clinic',
                  isActive: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ScheduleSlot(
                  time: '02:00 PM — 05:00 PM',
                  label: 'Afternoon Clinic',
                  isActive: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onManage,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  width: 1,
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Manage Availability',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleSlot extends StatelessWidget {
  final String time;
  final String label;
  final bool isActive;

  const _ScheduleSlot({
    required this.time,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: isActive ? AppColors.primaryLight : AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
