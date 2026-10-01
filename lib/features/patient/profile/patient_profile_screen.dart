import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../models/patient_profile_model.dart';
import '../../../services/patient_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

import '../../../repositories/auth_repository.dart';

final patientProfileProvider = StateNotifierProvider<PatientProfileNotifier, AsyncValue<PatientProfileModel?>>((ref) {
  // Watch auth state so this provider re-initializes on login/logout
  ref.watch(currentUserProvider);
  return PatientProfileNotifier(ref.watch(patientServiceProvider));
});

class PatientProfileNotifier extends StateNotifier<AsyncValue<PatientProfileModel?>> {
  final PatientService _service;

  PatientProfileNotifier(this._service) : super(const AsyncValue.loading()) {
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final profile = await _service.getPatientProfile();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> uploadDocument(String base64String, String mimeType, String fileName) async {
    state = const AsyncValue.loading();
    try {
      final profile = await _service.uploadPatientDocument(
        base64String: base64String,
        mimeType: mimeType,
        fileName: fileName,
      );
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

class PatientProfileScreen extends ConsumerWidget {
  final bool showOnlyDocuments;
  const PatientProfileScreen({super.key, this.showOnlyDocuments = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(patientProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(showOnlyDocuments ? 'Prescriptions & Docs' : 'My Medical Profile', style: AppTextStyles.headingSmall),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          if (!showOnlyDocuments)
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.primary),
              onPressed: () => context.push('/settings'),
            ),
        ],
      ),
      body: profileState.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not found'));
          }
          return _buildProfileContent(context, ref, profile);
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _uploadDocument(context, ref),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload Document'),
      ),
    );
  }

  Future<void> _uploadDocument(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
        final file = File(result.files.first.path!);
        final bytes = await file.readAsBytes();
        final base64String = base64Encode(bytes);
        
        final extension = result.files.first.extension?.toLowerCase() ?? '';
        String mimeType = 'application/octet-stream';
        if (['jpg', 'jpeg'].contains(extension)) {
          mimeType = 'image/jpeg';
        } else if (extension == 'png') {
          mimeType = 'image/png';
        } else if (extension == 'pdf') {
          mimeType = 'application/pdf';
        }
        
        final fileName = result.files.first.name;

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uploading and analyzing document...'),
            backgroundColor: AppColors.primary,
          ),
        );

        await ref.read(patientProfileProvider.notifier).uploadDocument(base64String, mimeType, fileName);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading document: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildProfileContent(BuildContext context, WidgetRef ref, PatientProfileModel profile) {
    if (showOnlyDocuments) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDocuments(profile),
            const SizedBox(height: 80),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBasicDetails(profile),
          const SizedBox(height: 16),
          _buildDemographics(profile),
          const SizedBox(height: 16),
          _buildMedicalHistory(profile),
          const SizedBox(height: 16),
          _buildMedications(profile),
          const SizedBox(height: 16),
          _buildLabResults(profile),
          const SizedBox(height: 16),
          _buildVitalSigns(profile),
          const SizedBox(height: 16),
          _buildDiagnoses(profile),
          const SizedBox(height: 16),
          _buildAllergies(profile),
          const SizedBox(height: 16),
          _buildProcedures(profile),
          const SizedBox(height: 16),
          _buildDocuments(profile),
          const SizedBox(height: 80), // Padding for FAB
        ],
      ),
    );
  }

  Widget _buildCard(String title, Widget child) {
    return Card(
      color: AppColors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.headingSmall.copyWith(color: AppColors.primary)),
            const Divider(),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildBasicDetails(PatientProfileModel profile) {
    return _buildCard('Basic Details', Column(
      children: [
        _buildRow('Name', profile.name),
        _buildRow('Age / Gender', '${profile.age} / ${profile.gender}'),
        _buildRow('Blood Group', profile.bloodGroup ?? 'N/A'),
        _buildRow('Phone', profile.phone),
        _buildRow('Email', profile.email),
        _buildRow('City / Country', '${profile.city ?? 'N/A'} / ${profile.country ?? 'N/A'}'),
        _buildRow('Emergency Contact', profile.emergencyContact ?? 'Not provided'),
      ],
    ));
  }

  Widget _buildDemographics(PatientProfileModel profile) {
    final d = profile.demographics;
    if (d == null) return const SizedBox.shrink();
    return _buildCard('Demographics', Column(
      children: [
        _buildRow('Height (cm)', d['height_cm']?.toString() ?? 'N/A'),
        _buildRow('Weight (kg)', d['weight_kg']?.toString() ?? 'N/A'),
        _buildRow('BMI', d['bmi']?.toString() ?? 'N/A'),
        _buildRow('Smoking Status', d['smoking_status'] ?? 'N/A'),
        _buildRow('Alcohol Use', d['alcohol_use'] ?? 'N/A'),
      ],
    ));
  }

  Widget _buildMedicalHistory(PatientProfileModel profile) {
    final mh = profile.medicalHistory;
    if (mh == null || mh.isEmpty) return const SizedBox.shrink();
    return _buildCard('Medical History', Column(
      children: mh.map((item) => _buildItemRow(item['condition'], item['status'] ?? 'Active')).toList(),
    ));
  }

  Widget _buildMedications(PatientProfileModel profile) {
    final meds = profile.medications;
    if (meds == null || meds.isEmpty) return const SizedBox.shrink();
    return _buildCard('Medications', Column(
      children: meds.map((item) => _buildItemRow(item['drug_name'], '${item['dosage'] ?? ''} - ${item['frequency'] ?? ''}')).toList(),
    ));
  }

  Widget _buildLabResults(PatientProfileModel profile) {
    final labs = profile.labResults;
    if (labs == null || labs.isEmpty) return const SizedBox.shrink();
    return _buildCard('Laboratory Reports', Column(
      children: labs.map((item) => _buildItemRow(item['test_name'], '${item['value']} ${item['unit']}')).toList(),
    ));
  }

  Widget _buildVitalSigns(PatientProfileModel profile) {
    final vitals = profile.vitalSigns;
    if (vitals == null || vitals.isEmpty) return const SizedBox.shrink();
    final latest = vitals.last;
    return _buildCard('Latest Vital Signs', Column(
      children: [
        _buildRow('BP', '${latest['systolic_bp']}/${latest['diastolic_bp']}'),
        _buildRow('Heart Rate', latest['heart_rate']?.toString() ?? 'N/A'),
        _buildRow('Temp', latest['temperature']?.toString() ?? 'N/A'),
        _buildRow('SpO2', latest['oxygen_saturation']?.toString() ?? 'N/A'),
      ],
    ));
  }

  Widget _buildDiagnoses(PatientProfileModel profile) {
    final diag = profile.diagnoses;
    if (diag == null || diag.isEmpty) return const SizedBox.shrink();
    return _buildCard('Diagnoses', Column(
      children: diag.map((item) => _buildItemRow(item['diagnosis_name'], item['status'] ?? 'Active')).toList(),
    ));
  }

  Widget _buildAllergies(PatientProfileModel profile) {
    final allergies = profile.allergies;
    if (allergies == null || allergies.isEmpty) return const SizedBox.shrink();
    return _buildCard('Allergies', Column(
      children: allergies.map((item) => _buildItemRow(item['allergen'], item['reaction'] ?? '')).toList(),
    ));
  }

  Widget _buildProcedures(PatientProfileModel profile) {
    final procedures = profile.procedures;
    if (procedures == null || procedures.isEmpty) return const SizedBox.shrink();
    return _buildCard('Procedures', Column(
      children: procedures.map((item) => _buildItemRow(item['procedure_name'], item['procedure_date'] ?? '')).toList(),
    ));
  }

  Widget _buildDocuments(PatientProfileModel profile) {
    final docs = profile.documents;
    if (docs == null || docs.isEmpty) return const SizedBox.shrink();
    return _buildCard('Uploaded Documents', Column(
      children: docs.map((item) => _buildItemRow(item['file_name'], item['processing_status'] ?? '')).toList(),
    ));
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
          Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildItemRow(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600))),
          Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
