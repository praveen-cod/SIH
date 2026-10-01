import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/glass_card.dart';

/// Doctor Availability / Manage Schedule Screen
class DoctorAvailabilityScreen extends ConsumerStatefulWidget {
  const DoctorAvailabilityScreen({super.key});

  @override
  ConsumerState<DoctorAvailabilityScreen> createState() =>
      _DoctorAvailabilityScreenState();
}

class _DoctorAvailabilityScreenState
    extends ConsumerState<DoctorAvailabilityScreen> {
  bool _isSaving = false;
  bool _isLoading = true;

  // Availability model: day -> list of time slots (start, end, enabled)
  final Map<String, List<_TimeSlot>> _schedule = {
    'Monday': [],
    'Tuesday': [],
    'Wednesday': [],
    'Thursday': [],
    'Friday': [],
    'Saturday': [],
    'Sunday': [],
  };

  final List<String> _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('/api/doctor/availability', requireAuth: true);
      
      final Map<String, dynamic> data = response as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          for (final day in _days) {
            if (data.containsKey(day)) {
              _schedule[day] = (data[day] as List).map((e) => 
                _TimeSlot(e['start'], e['end'], e['enabled'] == true)).toList();
            } else {
              _schedule[day] = [];
            }
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSchedule() async {
    setState(() => _isSaving = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      
      final payload = {
        'schedule': _schedule.map((key, value) => MapEntry(key, value.map((e) => {
          'start': e.start,
          'end': e.end,
          'enabled': e.enabled,
        }).toList()))
      };
      
      await apiClient.post('/api/doctor/availability', body: payload, requireAuth: true);
    } catch (_) {}
    
    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Schedule saved successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _addSlot(String day) async {
    TimeOfDay? start = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Select start time',
    );
    if (start == null || !mounted) return;

    TimeOfDay? end = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: start.hour + 1, minute: start.minute),
      helpText: 'Select end time',
    );
    if (end == null) return;

    final startStr = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final endStr = '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';

    setState(() {
      _schedule[day]!.add(_TimeSlot(startStr, endStr, true));
    });
  }

  void _removeSlot(String day, int index) {
    setState(() {
      _schedule[day]!.removeAt(index);
    });
  }

  void _toggleSlot(String day, int index, bool val) {
    setState(() {
      _schedule[day]![index] = _schedule[day]![index].copyWith(enabled: val);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSecondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/doctor-dashboard');
            }
          },
        ),
        title: const Text(
          'Manage Schedule',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: _isSaving ? null : _saveSchedule,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.doctorPrimary))
                  : const Icon(Icons.save_outlined, size: 18, color: AppColors.doctorPrimary),
              label: Text(
                'Save',
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.doctorPrimary),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
        children: [
          // Summary banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: AppColors.doctorPrimary.withValues(alpha: 0.08),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.doctorPrimary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Set your available hours for each day. Patients can only book during enabled slots.',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.doctorPrimary),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _days.length,
              separatorBuilder: (context, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final day = _days[index];
                final slots = _schedule[day] ?? [];
                final hasSlots = slots.isNotEmpty;
                final isWeekend = day == 'Saturday' || day == 'Sunday';

                return GlassCard(
                  padding: const EdgeInsets.all(16),
                  borderColor: hasSlots
                      ? AppColors.doctorPrimary.withValues(alpha: 0.25)
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
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: hasSlots
                                      ? AppColors.doctorPrimary
                                          .withValues(alpha: 0.15)
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    day.substring(0, 3).toUpperCase(),
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: hasSlots
                                          ? AppColors.doctorPrimary
                                          : AppColors.textMuted,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(day, style: AppTextStyles.labelLarge),
                                  Text(
                                    hasSlots
                                        ? '${slots.where((s) => s.enabled).length} active slot${slots.where((s) => s.enabled).length != 1 ? 's' : ''}'
                                        : 'No availability',
                                    style: AppTextStyles.caption.copyWith(
                                      color: hasSlots
                                          ? AppColors.success
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => _addSlot(day),
                            icon: const Icon(Icons.add_circle_outline,
                                color: AppColors.doctorPrimary, size: 22),
                            tooltip: 'Add slot',
                          ),
                        ],
                      ),
                      if (slots.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Divider(color: AppColors.border, height: 1),
                        const SizedBox(height: 8),
                        ...slots.asMap().entries.map((entry) {
                          final i = entry.key;
                          final slot = entry.value;
                          return _SlotRow(
                            slot: slot,
                            onToggle: (val) => _toggleSlot(day, i, val),
                            onDelete: () => _removeSlot(day, i),
                          );
                        }),
                      ] else
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            isWeekend ? 'Weekend — tap + to add availability' : 'Tap + to add time slots',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textMuted),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  final _TimeSlot slot;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const _SlotRow({
    required this.slot,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Switch(
            value: slot.enabled,
            onChanged: onToggle,
            activeTrackColor: AppColors.doctorPrimary.withValues(alpha: 0.5),
            activeThumbColor: AppColors.doctorPrimary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: slot.enabled
                  ? AppColors.doctorPrimary.withValues(alpha: 0.1)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: slot.enabled
                    ? AppColors.doctorPrimary.withValues(alpha: 0.3)
                    : AppColors.border,
              ),
            ),
            child: Text(
              '${slot.start} – ${slot.end}',
              style: AppTextStyles.labelMedium.copyWith(
                color:
                    slot.enabled ? AppColors.doctorPrimary : AppColors.textMuted,
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppColors.error, size: 18),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

class _TimeSlot {
  final String start;
  final String end;
  final bool enabled;

  const _TimeSlot(this.start, this.end, this.enabled);

  _TimeSlot copyWith({bool? enabled}) =>
      _TimeSlot(start, end, enabled ?? this.enabled);
}
