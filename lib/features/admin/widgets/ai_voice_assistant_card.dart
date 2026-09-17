import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/reusable_dashboard_components.dart';

/// AI Voice Assistant Status Card with animated waveform & metrics
class AIVoiceAssistantCard extends StatelessWidget {
  final double uptime;
  final double asrAccuracy;
  final double intakeAccuracy;

  const AIVoiceAssistantCard({
    super.key,
    this.uptime = 99.9,
    this.asrAccuracy = 98.6,
    this.intakeAccuracy = 94.3,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppColors.primary.withValues(alpha: 0.35),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D4FF), Color(0xFF2D8EFF)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.graphic_eq_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Voice Assistant', style: AppTextStyles.headingSmall),
                    Text(
                      'Automated patient intake & clinical dialogue',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.35),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const PulseDot(color: AppColors.success, size: 6),
                    const SizedBox(width: 6),
                    Text(
                      'Active',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Animated Waveform Container
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 0.8,
              ),
            ),
            child: Column(
              children: [
                const AIWaveformVisualizer(
                  height: 56,
                  primaryColor: Color(0xFF00D4FF),
                  secondaryColor: Color(0xFF8B5CF6),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StateChip(label: 'Listening', isActive: true, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Text('•', style: TextStyle(color: AppColors.textMuted)),
                    const SizedBox(width: 8),
                    _StateChip(label: 'Processing', isActive: true, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('•', style: TextStyle(color: AppColors.textMuted)),
                    const SizedBox(width: 8),
                    _StateChip(label: 'Responding', isActive: true, color: AppColors.secondaryLight),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // 3 Metric columns
          Row(
            children: [
              Expanded(
                child: _AssistantMetric(
                  label: 'Uptime',
                  value: '$uptime%',
                  icon: Icons.cloud_done_outlined,
                  color: AppColors.success,
                ),
              ),
              Container(width: 1, height: 36, color: AppColors.border),
              Expanded(
                child: _AssistantMetric(
                  label: 'ASR Accuracy',
                  value: '$asrAccuracy%',
                  icon: Icons.mic_none_outlined,
                  color: AppColors.accent,
                ),
              ),
              Container(width: 1, height: 36, color: AppColors.border),
              Expanded(
                child: _AssistantMetric(
                  label: 'Intake Accuracy',
                  value: '$intakeAccuracy%',
                  icon: Icons.verified_outlined,
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

class _StateChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color color;

  const _StateChip({
    required this.label,
    required this.isActive,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.caption.copyWith(
        color: isActive ? color : AppColors.textMuted,
        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
        fontSize: 11,
      ),
    );
  }
}

class _AssistantMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _AssistantMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.statSmall.copyWith(
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textMuted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
