import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/glass_card.dart';

/// Admin Screen to Provision Accredited Doctor Accounts into HealthCall AI SQLite
class AdminAddDoctorScreen extends ConsumerStatefulWidget {
 const AdminAddDoctorScreen({super.key});

 @override
 ConsumerState<AdminAddDoctorScreen> createState() => _AdminAddDoctorScreenState();
}

class _AdminAddDoctorScreenState extends ConsumerState<AdminAddDoctorScreen> {
 final _formKey = GlobalKey<FormState>();

 final _nameCtrl = TextEditingController();
 final _emailCtrl = TextEditingController();
 final _passCtrl = TextEditingController(text: 'Doctor@1234');
 final _phoneCtrl = TextEditingController(text: '+91 ');
 final _expCtrl = TextEditingController(text: '8');
 final _qualCtrl = TextEditingController(text: 'MBBS, MD');
 final _licCtrl = TextEditingController();
 final _deptCtrl = TextEditingController(text: 'Outpatient');
 final _feeCtrl = TextEditingController(text: '500');

 String _selectedSpecialization = 'General Physician';
 bool _isSubmitting = false;

 final List<String> _specializations = [
  'General Physician',
  'Cardiologist',
  'Dermatologist',
  'Pediatrician',
  'Orthopedic',
  'ENT',
  'Neurologist',
  'Gynecologist',
  'Psychiatrist',
  'Pulmonologist',
 ];

 @override
 void dispose() {
  _nameCtrl.dispose();
  _emailCtrl.dispose();
  _passCtrl.dispose();
  _phoneCtrl.dispose();
  _expCtrl.dispose();
  _qualCtrl.dispose();
  _licCtrl.dispose();
  _deptCtrl.dispose();
  _feeCtrl.dispose();
  super.dispose();
 }

 Future<void> _handleProvisionDoctor() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isSubmitting = true);

  try {
   final client = ApiClient();
   final body = {
    'name': _nameCtrl.text.trim(),
    'email': _emailCtrl.text.trim().toLowerCase(),
    'password': _passCtrl.text.trim(),
    'specialization': _selectedSpecialization,
    'experience_years': int.tryParse(_expCtrl.text.trim()) ?? 5,
    'qualification': _qualCtrl.text.trim(),
    'license_number': _licCtrl.text.trim().isNotEmpty
      ? _licCtrl.text.trim()
      : 'MCI-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
    'department': _deptCtrl.text.trim(),
    'phone': _phoneCtrl.text.trim(),
   };

   final response = await client.post(
    '/api/admin/doctors',
    body: body,
    requireAuth: true,
   );

   if (!mounted) return;

   final doctorId = (response is Map<String, dynamic> && response['doctor_id'] != null)
     ? response['doctor_id'].toString()
     : 'HC-D-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

   _showSuccessDialog(doctorId);
  } catch (e) {
   if (!mounted) return;
   ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
     content: Text('Failed to provision doctor: $e'),
     backgroundColor: AppColors.error,
    ),
   );
  } finally {
   if (mounted) setState(() => _isSubmitting = false);
  }
 }

 void _showSuccessDialog(String doctorId) {
  showDialog(
   context: context,
   barrierDismissible: false,
   builder: (ctx) => Dialog(
    backgroundColor: AppColors.backgroundSecondary,
    insetPadding: const EdgeInsets.symmetric(horizontal: 20),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: ConstrainedBox(
     constraints: const BoxConstraints(maxWidth: 420),
     child: Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
       mainAxisSize: MainAxisSize.min,
       children: [
        Container(
         width: 64,
         height: 64,
         decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.15),
          shape: BoxShape.circle,
         ),
         child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 36),
        ),
        const SizedBox(height: 18),
        Text('Doctor Account Provisioned', style: AppTextStyles.headingSmall),
        const SizedBox(height: 8),
        Text(
         'Accredited medical practitioner record has been written to the SQLite database.',
         textAlign: TextAlign.center,
         style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),
        Container(
         width: double.infinity,
         padding: const EdgeInsets.all(14),
         decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
         ),
         child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           _row('Assigned ID', doctorId, isPrimary: true),
           const SizedBox(height: 6),
           _row('Full Name', _nameCtrl.text.trim()),
           const SizedBox(height: 6),
           _row('Specialty', _selectedSpecialization),
           const SizedBox(height: 6),
           _row('Email', _emailCtrl.text.trim()),
          ],
         ),
        ),
        const SizedBox(height: 22),
        SizedBox(
         width: double.infinity,
         child: ElevatedButton(
          onPressed: () {
           Navigator.pop(ctx);
           context.pop();
          },
          style: ElevatedButton.styleFrom(
           backgroundColor: AppColors.primary,
           foregroundColor: Colors.white,
           padding: const EdgeInsets.symmetric(vertical: 14),
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Return to Admin Dashboard', style: TextStyle(fontWeight: FontWeight.w600)),
         ),
        ),
       ],
      ),
     ),
    ),
   ),
  );
 }

 Widget _row(String label, String value, {bool isPrimary = false}) {
  return Row(
   crossAxisAlignment: CrossAxisAlignment.start,
   children: [
    SizedBox(
     width: 90,
     child: Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
    ),
    const SizedBox(width: 8),
    Expanded(
     child: Text(
      value,
      textAlign: TextAlign.end,
      style: AppTextStyles.caption.copyWith(
       color: isPrimary ? AppColors.primary : AppColors.textPrimary,
       fontWeight: FontWeight.w600,
      ),
     ),
    ),
   ],
  );
 }

 @override
 Widget build(BuildContext context) {
  return Scaffold(
   backgroundColor: AppColors.background,
   appBar: AppBar(
    backgroundColor: AppColors.background,
    elevation: 0,
    leading: IconButton(
     icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
     onPressed: () => context.pop(),
    ),
    title: Text(
     'Provision Doctor',
     style: AppTextStyles.headingSmall.copyWith(fontSize: 18),
    ),
    centerTitle: false,
   ),
   body: SafeArea(
    child: Center(
     child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: SingleChildScrollView(
       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
       physics: const BouncingScrollPhysics(),
       child: Form(
        key: _formKey,
        child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
          // Banner header
          GlassCard(
           padding: const EdgeInsets.all(18),
           child: Row(
            children: [
             Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
               gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF06B6D4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
               ),
               borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 26),
             ),
             const SizedBox(width: 14),
             Expanded(
              child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                Text(
                 'Doctor Account Provisioning',
                 style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                 'Only administrators can create doctor credentials. Doctors have no public signup.',
                 style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, fontSize: 12),
                ),
               ],
              ),
             ),
            ],
           ),
          ).animate().fadeIn(duration: 350.ms),

          const SizedBox(height: 20),

          Text('PRACTITIONER DETAILS', style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1.2)),
          const SizedBox(height: 12),

          // Doctor Name
          CustomTextField(
           label: 'Doctor Full Name',
           hint: 'e.g. Dr. Priya Patel, MD',
           controller: _nameCtrl,
           prefixIcon: Icons.person_outline_rounded,
           validator: (val) {
            if (val == null || val.trim().isEmpty) return 'Doctor name is required';
            return null;
           },
          ),
          const SizedBox(height: 14),

          // Specialization Dropdown
          Text('Medical Specialization', style: AppTextStyles.labelMedium),
          const SizedBox(height: 6),
          Container(
           padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
           decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
           ),
           child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
             value: _selectedSpecialization,
             isExpanded: true,
             dropdownColor: AppColors.backgroundSecondary,
             style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
             icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
             items: _specializations.map((s) {
              return DropdownMenuItem(
               value: s,
               child: Row(
                children: [
                 const Icon(Icons.medical_services_outlined, size: 18, color: AppColors.primary),
                 const SizedBox(width: 10),
                 Text(s),
                ],
               ),
              );
             }).toList(),
             onChanged: (val) {
              if (val != null) setState(() => _selectedSpecialization = val);
             },
            ),
           ),
          ),
          const SizedBox(height: 14),

          // Qualifications & Experience Row
          Row(
           children: [
            Expanded(
             flex: 6,
             child: CustomTextField(
              label: 'Qualifications',
              hint: 'e.g. MBBS, MD, FRCS',
              controller: _qualCtrl,
              prefixIcon: Icons.school_outlined,
              validator: (val) {
               if (val == null || val.trim().isEmpty) return 'Required';
               return null;
              },
             ),
            ),
            const SizedBox(width: 10),
            Expanded(
             flex: 4,
             child: CustomTextField(
              label: 'Exp (Years)',
              hint: '8',
              controller: _expCtrl,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.history_edu_outlined,
              validator: (val) {
               if (val == null || val.trim().isEmpty) return 'Required';
               return null;
              },
             ),
            ),
           ],
          ),
          const SizedBox(height: 14),

          // License Number & Department Row
          Row(
           children: [
            Expanded(
             flex: 5,
             child: CustomTextField(
              label: 'Medical License #',
              hint: 'MCI-84920',
              controller: _licCtrl,
              prefixIcon: Icons.badge_outlined,
             ),
            ),
            const SizedBox(width: 10),
            Expanded(
             flex: 5,
             child: CustomTextField(
              label: 'Department',
              hint: 'Outpatient / Cardiology',
              controller: _deptCtrl,
              prefixIcon: Icons.apartment_outlined,
             ),
            ),
           ],
          ),

          const SizedBox(height: 24),
          Text('CREDENTIALS & ACCESS', style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1.2)),
          const SizedBox(height: 12),

          // Email Address
          CustomTextField(
           label: 'Professional Email',
           hint: 'dr.priya@healthcall.ai',
           controller: _emailCtrl,
           keyboardType: TextInputType.emailAddress,
           prefixIcon: Icons.email_outlined,
           validator: (val) {
            if (val == null || val.trim().isEmpty) return 'Email is required';
            if (!val.contains('@')) return 'Enter a valid email address';
            return null;
           },
          ),
          const SizedBox(height: 14),

          // Temporary Password
          CustomTextField(
           label: 'Temporary Password',
           hint: 'Minimum 6 characters',
           controller: _passCtrl,
           isPassword: true,
           prefixIcon: Icons.lock_outline_rounded,
           validator: (val) {
            if (val == null || val.trim().length < 6) return 'At least 6 characters required';
            return null;
           },
          ),
          const SizedBox(height: 14),

          // Phone & Fee
          Row(
           children: [
            Expanded(
             flex: 6,
             child: CustomTextField(
              label: 'Contact Phone',
              hint: '+91 98400 12345',
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
             ),
            ),
            const SizedBox(width: 10),
            Expanded(
             flex: 4,
             child: CustomTextField(
              label: 'Fee (₹)',
              hint: '500',
              controller: _feeCtrl,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.currency_rupee_rounded,
             ),
            ),
           ],
          ),

          const SizedBox(height: 32),

          // Submit Button
          SizedBox(
           width: double.infinity,
           height: 52,
           child: Container(
            decoration: BoxDecoration(
             borderRadius: BorderRadius.circular(14),
             gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF06B6D4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
             ),
             boxShadow: [
              BoxShadow(
               color: AppColors.primary.withValues(alpha: 0.35),
               blurRadius: 14,
               offset: const Offset(0, 4),
              ),
             ],
            ),
            child: ElevatedButton(
             onPressed: _isSubmitting ? null : _handleProvisionDoctor,
             style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
             ),
             child: _isSubmitting
               ? const SizedBox(
                 width: 22,
                 height: 22,
                 child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
               : Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                  const Icon(Icons.person_add_alt_1_rounded, size: 20, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                   'Provision Doctor Account',
                   style: AppTextStyles.labelLarge.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                   ),
                  ),
                 ],
                ),
            ),
           ),
          ),
          const SizedBox(height: 32),
         ],
        ),
       ),
      ),
     ),
    ),
   ),
  );
 }
}
