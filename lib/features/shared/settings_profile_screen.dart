import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/utils/app_snackbar.dart';
import '../../repositories/auth_repository.dart';
import '../../services/patient_service.dart';
import '../patient/profile/patient_profile_screen.dart';

class SettingsProfileScreen extends ConsumerStatefulWidget {
 const SettingsProfileScreen({super.key});

 @override
 ConsumerState<SettingsProfileScreen> createState() => _SettingsProfileScreenState();
}

class _SettingsProfileScreenState extends ConsumerState<SettingsProfileScreen> {
 late final TextEditingController _nameCtrl;
 late final TextEditingController _firstNameCtrl;
 late final TextEditingController _lastNameCtrl;
 late final TextEditingController _emailCtrl;
 late final TextEditingController _phoneCtrl;
 late final TextEditingController _dobCtrl;
 late final TextEditingController _ageCtrl;
 late final TextEditingController _genderCtrl;
 late final TextEditingController _bloodGroupCtrl;
 late final TextEditingController _cityCtrl;
 late final TextEditingController _countryCtrl;
 late final TextEditingController _emergencyContactCtrl;
 final _passCtrl = TextEditingController();

 @override
 void initState() {
  super.initState();
  final user = ref.read(currentUserProvider);
  _nameCtrl = TextEditingController(text: user?.name ?? 'Current User');
  _firstNameCtrl = TextEditingController(text: '');
  _lastNameCtrl = TextEditingController(text: '');
  _emailCtrl = TextEditingController(text: user?.email ?? 'user@example.com');
  _phoneCtrl = TextEditingController(text: user?.phone ?? '');
  _dobCtrl = TextEditingController(text: '');
  _ageCtrl = TextEditingController(text: user?.age?.toString() ?? '42');
  _genderCtrl = TextEditingController(text: user?.gender ?? 'Male');
  _bloodGroupCtrl = TextEditingController(text: '');
  _cityCtrl = TextEditingController(text: '');
  _countryCtrl = TextEditingController(text: '');
  _emergencyContactCtrl = TextEditingController(text: user?.emergencyContact ?? '');

  if (user?.role.name == 'patient') {
   _loadPatientData();
  }
 }

  Future<void> _loadPatientData() async {
  try {
   final svc = ref.read(patientServiceProvider);
   final profile = await svc.getPatientProfile();
   if (mounted && profile != null) {
    setState(() {
     _nameCtrl.text = profile.name;
     _firstNameCtrl.text = profile.firstName ?? '';
     _lastNameCtrl.text = profile.lastName ?? '';
     _emailCtrl.text = profile.email;
     _phoneCtrl.text = profile.phone;
     _dobCtrl.text = profile.dateOfBirth ?? '';
     _ageCtrl.text = profile.age.toString();
     _genderCtrl.text = profile.gender;
     _bloodGroupCtrl.text = profile.bloodGroup ?? '';
     _cityCtrl.text = profile.city ?? '';
     _countryCtrl.text = profile.country ?? '';
     _emergencyContactCtrl.text = profile.emergencyContact ?? '';
    });
   }
  } catch (e) {
   debugPrint('Failed to load profile for settings: $e');
  }
 }

 @override
 void dispose() {
  _nameCtrl.dispose();
  _firstNameCtrl.dispose();
  _lastNameCtrl.dispose();
  _emailCtrl.dispose();
  _phoneCtrl.dispose();
  _dobCtrl.dispose();
  _ageCtrl.dispose();
  _genderCtrl.dispose();
  _bloodGroupCtrl.dispose();
  _cityCtrl.dispose();
  _countryCtrl.dispose();
  _emergencyContactCtrl.dispose();
  _passCtrl.dispose();
  super.dispose();
 }

 bool _isSaving = false;

 Future<void> _saveChanges() async {
  final user = ref.read(currentUserProvider);
  if (user?.role.name == 'patient') {
   setState(() => _isSaving = true);
   try {
    final svc = ref.read(patientServiceProvider);
    await svc.updateProfile(
     name: _nameCtrl.text.trim(),
     firstName: _firstNameCtrl.text.trim(),
     lastName: _lastNameCtrl.text.trim(),
     dateOfBirth: _dobCtrl.text.trim(),
     age: int.tryParse(_ageCtrl.text.trim()),
     gender: _genderCtrl.text.trim(),
     phone: _phoneCtrl.text.trim(),
     city: _cityCtrl.text.trim(),
     country: _countryCtrl.text.trim(),
     bloodGroup: _bloodGroupCtrl.text.trim(),
     emergencyContact: _emergencyContactCtrl.text.trim(),
    );
    // Force refresh of patient profile
    try {
      ref.invalidate(patientProfileProvider);
    } catch (_) {}
    if (mounted) AppSnackbar.showSuccess(context, 'Profile updated successfully');
   } catch (e) {
    if (mounted) AppSnackbar.showError(context, 'Failed to save: $e');
   } finally {
    if (mounted) setState(() => _isSaving = false);
   }
  } else {
   AppSnackbar.showSuccess(context, 'Settings saved');
  }
  if (mounted) Navigator.pop(context);
 }

 @override
 Widget build(BuildContext context) {
  return Scaffold(
   backgroundColor: AppColors.background,
   appBar: AppBar(
    backgroundColor: AppColors.backgroundSecondary,
    elevation: 0,
    title: const Text('Profile & Settings', style: TextStyle(color: AppColors.textPrimary)),
    iconTheme: const IconThemeData(color: AppColors.textPrimary),
   ),
   body: SingleChildScrollView(
    padding: const EdgeInsets.all(24.0),
    child: Column(
     crossAxisAlignment: CrossAxisAlignment.start,
     children: [
      Text('Account Information', style: AppTextStyles.headingSmall),
      const SizedBox(height: 16),
      GlassCard(
       padding: const EdgeInsets.all(20),
       child: Column(
        children: [
         _buildTextField('Full Name', _nameCtrl, Icons.person_outline),
         const SizedBox(height: 16),
         Row(
          children: [
           Expanded(child: _buildTextField('First Name', _firstNameCtrl, Icons.person_outline)),
           const SizedBox(width: 16),
           Expanded(child: _buildTextField('Last Name', _lastNameCtrl, Icons.person_outline)),
          ],
         ),
         const SizedBox(height: 16),
         _buildTextField('Email Address', _emailCtrl, Icons.email_outlined),
         const SizedBox(height: 16),
         _buildTextField('Phone Number', _phoneCtrl, Icons.phone_outlined),
         const SizedBox(height: 16),
         Row(
          children: [
           Expanded(child: _buildTextField('Age', _ageCtrl, Icons.calendar_today_outlined)),
           const SizedBox(width: 16),
           Expanded(child: _buildTextField('Gender', _genderCtrl, Icons.people_outline)),
          ],
         ),
         const SizedBox(height: 16),
         Row(
          children: [
           Expanded(child: _buildDatePicker('Date of Birth', _dobCtrl, Icons.cake_outlined)),
           const SizedBox(width: 16),
           Expanded(child: _buildTextField('Blood Group', _bloodGroupCtrl, Icons.water_drop_outlined)),
          ],
         ),
         const SizedBox(height: 16),
         Row(
          children: [
           Expanded(child: _buildTextField('City', _cityCtrl, Icons.location_city_outlined)),
           const SizedBox(width: 16),
           Expanded(child: _buildTextField('Country', _countryCtrl, Icons.public_outlined)),
          ],
         ),
         const SizedBox(height: 16),
         _buildTextField('Emergency Contact', _emergencyContactCtrl, Icons.phone_in_talk_outlined),
        ],
       ),
      ),
      const SizedBox(height: 32),
      Text('Security', style: AppTextStyles.headingSmall),
      const SizedBox(height: 16),
      GlassCard(
       padding: const EdgeInsets.all(20),
       child: Column(
        children: [
         _buildTextField('New Password', _passCtrl, Icons.lock_outline, obscureText: true),
         const SizedBox(height: 8),
         Text(
          'Leave blank to keep your current password.',
          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
         ),
        ],
       ),
      ),
      const SizedBox(height: 32),
      Text('App Preferences', style: AppTextStyles.headingSmall),
      const SizedBox(height: 16),
      GlassCard(
       padding: const EdgeInsets.all(20),
       child: Column(
        children: [
         Material(
          type: MaterialType.transparency,
          child: SwitchListTile(
           title: Text('Push Notifications', style: AppTextStyles.bodyMedium),
           value: true,
           onChanged: (val) {},
           activeThumbColor: AppColors.primary,
           contentPadding: EdgeInsets.zero,
          ),
         ),
         const Divider(color: AppColors.border),
         Material(
          type: MaterialType.transparency,
          child: SwitchListTile(
           title: Text('Email Updates', style: AppTextStyles.bodyMedium),
           value: false,
           onChanged: (val) {},
           activeThumbColor: AppColors.primary,
           contentPadding: EdgeInsets.zero,
          ),
         ),
        ],
       ),
      ),
      const SizedBox(height: 40),
      SizedBox(
       width: double.infinity,
       child: ElevatedButton(
        onPressed: _saveChanges,
        style: ElevatedButton.styleFrom(
         backgroundColor: AppColors.primary,
         foregroundColor: Colors.white,
         padding: const EdgeInsets.symmetric(vertical: 16),
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isSaving
          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
       ),
      ),
     ],
    ),
   ),
  );
 }

 Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool obscureText = false}) {
  return Column(
   crossAxisAlignment: CrossAxisAlignment.start,
   children: [
    Text(label, style: AppTextStyles.labelMedium),
    const SizedBox(height: 8),
    TextField(
     controller: controller,
     obscureText: obscureText,
     style: const TextStyle(color: AppColors.textPrimary),
     decoration: InputDecoration(
      prefixIcon: Icon(icon, color: AppColors.primaryLight, size: 20),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
       borderRadius: BorderRadius.circular(12),
       borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      enabledBorder: OutlineInputBorder(
       borderRadius: BorderRadius.circular(12),
       borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
       borderRadius: BorderRadius.circular(12),
       borderSide: const BorderSide(color: AppColors.primary),
      ),
     ),
    ),
   ],
  );
 }

 Widget _buildDatePicker(String label, TextEditingController controller, IconData icon) {
  return Column(
   crossAxisAlignment: CrossAxisAlignment.start,
   children: [
    Text(label, style: AppTextStyles.labelMedium),
    const SizedBox(height: 8),
    TextField(
     controller: controller,
     readOnly: true,
     onTap: () async {
      final date = await showDatePicker(
       context: context,
       initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
       firstDate: DateTime(1900),
       lastDate: DateTime.now(),
       builder: (context, child) {
        return Theme(
         data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
           primary: AppColors.primary,
           onPrimary: Colors.white,
           surface: AppColors.surface,
           onSurface: AppColors.textPrimary,
          ),
          dialogTheme: const DialogThemeData(backgroundColor: AppColors.backgroundSecondary),
         ),
         child: child!,
        );
       },
      );
      if (date != null) {
       controller.text = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      }
     },
     style: const TextStyle(color: AppColors.textPrimary),
     decoration: InputDecoration(
      prefixIcon: Icon(icon, color: AppColors.primaryLight, size: 20),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
       borderRadius: BorderRadius.circular(12),
       borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      enabledBorder: OutlineInputBorder(
       borderRadius: BorderRadius.circular(12),
       borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
       borderRadius: BorderRadius.circular(12),
       borderSide: const BorderSide(color: AppColors.primary),
      ),
     ),
    ),
   ],
  );
 }
}
