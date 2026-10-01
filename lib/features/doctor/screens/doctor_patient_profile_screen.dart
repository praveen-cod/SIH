import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/glass_card.dart';

/// Doctor view of a specific patient's full profile
class DoctorPatientProfileScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String? patientName;

  const DoctorPatientProfileScreen({
    super.key,
    required this.patientId,
    this.patientName,
  });

  @override
  ConsumerState<DoctorPatientProfileScreen> createState() =>
      _DoctorPatientProfileScreenState();
}

class _DoctorPatientProfileScreenState
    extends ConsumerState<DoctorPatientProfileScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get(
        '/api/doctor/patients/${widget.patientId}/profile',
        requireAuth: true,
      );
      setState(() {
        _profile = response as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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
        title: Text(
          widget.patientName != null
              ? 'Patient: ${widget.patientName}'
              : 'Patient Profile',
          style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 48),
                      const SizedBox(height: 12),
                      Text('Failed to load profile',
                          style: AppTextStyles.headingSmall),
                      const SizedBox(height: 8),
                      Text(_error!,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textMuted),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _loadProfile,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.doctorPrimary),
                      ),
                    ],
                  ),
                )
              : _profile == null
                  ? const Center(child: Text('No profile data found.'))
                  : _buildProfileContent(_profile!),
    );
  }

  Widget _buildProfileContent(Map<String, dynamic> p) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header card
        GlassCard(
          padding: const EdgeInsets.all(20),
          borderColor: AppColors.doctorPrimary.withValues(alpha: 0.3),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.doctorPrimary.withValues(alpha: 0.15),
                child: Text(
                  (p['name'] as String? ?? 'P').substring(0, 1).toUpperCase(),
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.doctorPrimary),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['name'] ?? 'Unknown',
                        style: AppTextStyles.headingMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${p['age'] ?? '--'} yrs • ${p['gender'] ?? '--'}',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textMuted),
                    ),
                    if (p['blood_group'] != null)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '🩸 ${p['blood_group']}',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.errorLight),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Contact info
        _section('Contact Information', [
          _row('Phone', p['phone']),
          _row('Email', p['email']),
          _row('City / Country', '${p['city'] ?? '--'} / ${p['country'] ?? '--'}'),
          _row('Emergency Contact', p['emergency_contact']),
        ]),

        // Medical History
        if ((p['medical_history'] as List?)?.isNotEmpty == true) ...[
          const SizedBox(height: 16),
          _section(
            'Medical History',
            (p['medical_history'] as List).map((h) {
              return _row(
                h['condition'] ?? 'Unknown',
                h['status'] ?? 'Active',
              );
            }).toList(),
          ),
        ],

        // Allergies
        if ((p['allergies'] as List?)?.isNotEmpty == true) ...[
          const SizedBox(height: 16),
          _section(
            'Allergies',
            (p['allergies'] as List).map((a) {
              return _row(a['allergen'] ?? '--', a['severity'] ?? '');
            }).toList(),
          ),
        ],

        // Lab Results
        if ((p['lab_results'] as List?)?.isNotEmpty == true) ...[
          const SizedBox(height: 16),
          _section(
            'Lab Results',
            (p['lab_results'] as List).map((l) {
              return _row(
                l['test_name'] ?? '--',
                '${l['result_value'] ?? '--'} ${l['unit'] ?? ''}',
              );
            }).toList(),
          ),
        ],

        // Medications
        if ((p['medications'] as List?)?.isNotEmpty == true) ...[
          const SizedBox(height: 16),
          _section(
            'Current Medications',
            (p['medications'] as List).map((m) {
              return _row(
                m['name'] ?? '--',
                '${m['dosage'] ?? ''} ${m['frequency'] ?? ''}',
              );
            }).toList(),
          ),
        ],

        // Vital Signs
        if ((p['vital_signs'] as List?)?.isNotEmpty == true) ...[
          const SizedBox(height: 16),
          _section(
            'Latest Vital Signs',
            [
              _row('Heart Rate', '${(p['vital_signs'] as List).last['heart_rate'] ?? '--'} bpm'),
              _row('Blood Pressure',
                  '${(p['vital_signs'] as List).last['systolic_bp'] ?? '--'}/${(p['vital_signs'] as List).last['diastolic_bp'] ?? '--'} mmHg'),
              _row('Temperature',
                  '${(p['vital_signs'] as List).last['temperature'] ?? '--'} °C'),
              _row('O2 Saturation',
                  '${(p['vital_signs'] as List).last['oxygen_saturation'] ?? '--'}%'),
            ],
          ),
        ],

        // Uploaded Documents
        if ((p['documents'] as List?)?.isNotEmpty == true) ...[
          const SizedBox(height: 16),
          _section(
            'Uploaded Documents',
            (p['documents'] as List).map((d) {
              return _row(
                d['file_name'] ?? '--',
                d['processing_status'] ?? '',
              );
            }).toList(),
          ),
        ],

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _section(String title, List<Widget> rows) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTextStyles.headingSmall
                  .copyWith(color: AppColors.doctorPrimary)),
          const SizedBox(height: 4),
          const Divider(color: AppColors.border),
          ...rows,
        ],
      ),
    );
  }

  Widget _row(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
