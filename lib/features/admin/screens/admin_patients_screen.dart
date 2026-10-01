import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/glass_card.dart';

class AdminPatientItem {
 final String patientId;
 final String name;
 final String email;
 final String phone;
 final int? age;
 final String? gender;
 final String? bloodGroup;
 final String? address;
 final String? emergencyContact;

 AdminPatientItem({
  required this.patientId,
  required this.name,
  required this.email,
  required this.phone,
  this.age,
  this.gender,
  this.bloodGroup,
  this.address,
  this.emergencyContact,
 });

 factory AdminPatientItem.fromJson(Map<String, dynamic> json) {
  return AdminPatientItem(
   patientId: json['patient_id']?.toString() ?? '',
   name: json['name']?.toString() ?? 'Patient',
   email: json['email']?.toString() ?? '',
   phone: json['phone']?.toString() ?? '',
   age: (json['age'] as num?)?.toInt(),
   gender: json['gender']?.toString(),
   bloodGroup: json['blood_group']?.toString(),
   address: json['address']?.toString(),
   emergencyContact: json['emergency_contact']?.toString(),
  );
 }
}

/// Screen for Admin to view all registered platform patients
class AdminPatientsScreen extends ConsumerStatefulWidget {
 const AdminPatientsScreen({super.key});

 @override
 ConsumerState<AdminPatientsScreen> createState() => _AdminPatientsScreenState();
}

class _AdminPatientsScreenState extends ConsumerState<AdminPatientsScreen> {
 List<AdminPatientItem> _patients = [];
 bool _isLoading = true;
 String? _errorMessage;
 String _searchQuery = '';
 final TextEditingController _searchCtrl = TextEditingController();

 @override
 void initState() {
  super.initState();
  _fetchPatients();
 }

 @override
 void dispose() {
  _searchCtrl.dispose();
  super.dispose();
 }

 Future<void> _fetchPatients() async {
  setState(() {
   _isLoading = true;
   _errorMessage = null;
  });

  try {
   final client = ref.read(apiClientProvider);
   final response =
     await client.get('/api/admin/patients', requireAuth: true);

   if (response is List) {
    final list = response
      .map((item) =>
        AdminPatientItem.fromJson(item as Map<String, dynamic>))
      .toList();

    if (mounted) {
     setState(() {
      _patients = list;
      _isLoading = false;
     });
    }
   } else {
    if (mounted) {
     setState(() {
      _isLoading = false;
     });
    }
   }
  } catch (e) {
   if (mounted) {
    setState(() {
     _errorMessage = 'Failed to load patients: $e';
     _isLoading = false;
    });
   }
  }
 }

 @override
 Widget build(BuildContext context) {
  final filteredPatients = _patients.where((p) {
   if (_searchQuery.isEmpty) return true;
   final q = _searchQuery.toLowerCase();
   return p.name.toLowerCase().contains(q) ||
     p.patientId.toLowerCase().contains(q) ||
     p.phone.toLowerCase().contains(q) ||
     p.email.toLowerCase().contains(q);
  }).toList();

  return PopScope(
   canPop: context.canPop(),
   onPopInvokedWithResult: (didPop, result) {
    if (!didPop) {
     context.go(AppRoutes.adminDashboard);
    }
   },
   child: Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
     backgroundColor: AppColors.backgroundSecondary,
     elevation: 0,
     leading: IconButton(
      icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
      onPressed: () {
       if (context.canPop()) {
        context.pop();
       } else {
        context.go(AppRoutes.adminDashboard);
       }
      },
     ),
     title: Text('Registered Patients', style: AppTextStyles.headingMedium),
    actions: [
     IconButton(
      icon: const Icon(Icons.refresh_rounded, color: AppColors.textMuted),
      onPressed: _fetchPatients,
     ),
     const SizedBox(width: 8),
    ],
   ),
   body: SafeArea(
    child: Column(
     children: [
      // Search field
      Padding(
       padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
       child: TextField(
        controller: _searchCtrl,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
         hintText: 'Search patients by name, ID, or phone...',
         hintStyle: AppTextStyles.caption,
         prefixIcon:
           const Icon(Icons.search, color: AppColors.textMuted, size: 20),
         suffixIcon: _searchQuery.isNotEmpty
           ? IconButton(
             icon: const Icon(Icons.clear, size: 18),
             onPressed: () {
              _searchCtrl.clear();
              setState(() => _searchQuery = '');
             },
            )
           : null,
         filled: true,
         fillColor: AppColors.surface,
         contentPadding:
           const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
         border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
         ),
        ),
        onChanged: (val) {
         setState(() => _searchQuery = val.trim());
        },
       ),
      ),

      // Patient List
      Expanded(
       child: _isLoading
         ? const Center(
           child: CircularProgressIndicator(color: AppColors.primary),
          )
         : _errorMessage != null
           ? Center(
             child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
               const Icon(Icons.error_outline_rounded,
                 color: AppColors.error, size: 48),
               const SizedBox(height: 12),
               Text(_errorMessage!,
                 style: AppTextStyles.bodyMedium),
               const SizedBox(height: 16),
               ElevatedButton(
                onPressed: _fetchPatients,
                child: const Text('Retry'),
               ),
              ],
             ),
            )
           : filteredPatients.isEmpty
             ? Center(
               child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                 const Icon(Icons.person_off_outlined,
                   size: 48, color: AppColors.textMuted),
                 const SizedBox(height: 12),
                 Text(
                  _searchQuery.isEmpty
                    ? 'No registered patients found'
                    : 'No patients matching "$_searchQuery"',
                  style: AppTextStyles.bodyMedium,
                 ),
                ],
               ),
              )
             : RefreshIndicator(
               onRefresh: _fetchPatients,
               color: AppColors.primary,
               backgroundColor: AppColors.surface,
               child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
                itemCount: filteredPatients.length,
                separatorBuilder: (_, _) =>
                  const SizedBox(height: 10),
                itemBuilder: (context, index) {
                 final p = filteredPatients[index];
                 return _buildPatientCard(p)
                   .animate()
                   .fadeIn(
                     duration: 250.ms,
                     delay: Duration(
                       milliseconds: index * 30));
                },
               ),
              ),
      ),
     ],
    ),
   ),
  ),
 );
 }

 Widget _buildPatientCard(AdminPatientItem p) {
  return GlassCard(
   padding: const EdgeInsets.all(16),
   child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
     Row(
      children: [
       CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
        child: Text(
         p.name.isNotEmpty ? p.name[0].toUpperCase() : 'P',
         style: const TextStyle(
           color: AppColors.primary, fontWeight: FontWeight.bold),
        ),
       ),
       const SizedBox(width: 12),
       Expanded(
        child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
          Text(
           p.name,
           style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
           ),
          ),
          Text(
           'ID: ${p.patientId}',
           style: AppTextStyles.caption
             .copyWith(color: AppColors.primaryLight),
          ),
         ],
        ),
       ),
       if (p.bloodGroup != null && p.bloodGroup!.isNotEmpty)
        Container(
         padding:
           const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
         decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border:
            Border.all(color: AppColors.error.withValues(alpha: 0.3)),
         ),
         child: Text(
          '🩸 ${p.bloodGroup}',
          style: const TextStyle(
           color: AppColors.errorLight,
           fontWeight: FontWeight.bold,
           fontSize: 11,
          ),
         ),
        ),
      ],
     ),
     const SizedBox(height: 12),
     const Divider(height: 1, color: AppColors.border),
     const SizedBox(height: 10),

     Row(
      children: [
       Expanded(
        child: _metaInfo('Age', p.age != null ? '${p.age} yrs' : 'N/A'),
       ),
       Expanded(
        child: _metaInfo('Gender', p.gender ?? 'Unspecified'),
       ),
       Expanded(
        child: _metaInfo('Phone', p.phone),
       ),
      ],
     ),
     const SizedBox(height: 8),

     Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
       Expanded(
        child: Text(
         p.email,
         style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
         overflow: TextOverflow.ellipsis,
        ),
       ),
       if (p.emergencyContact != null &&
         p.emergencyContact!.isNotEmpty) ...[
        const SizedBox(width: 8),
        Text(
         'Emergency: ${p.emergencyContact}',
         style: AppTextStyles.caption
           .copyWith(color: AppColors.warning),
        ),
       ],
      ],
     ),
    ],
   ),
  );
 }

 Widget _metaInfo(String label, String value) {
  return Column(
   crossAxisAlignment: CrossAxisAlignment.start,
   children: [
    Text(label,
      style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
    const SizedBox(height: 2),
    Text(value,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary)),
   ],
  );
 }
}
