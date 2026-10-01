import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/network/api_client.dart';
import '../../../core/routes/app_routes.dart';

class DoctorPatientsScreen extends ConsumerStatefulWidget {
 const DoctorPatientsScreen({super.key});

 @override
 ConsumerState<DoctorPatientsScreen> createState() => _DoctorPatientsScreenState();
}

class _DoctorPatientsScreenState extends ConsumerState<DoctorPatientsScreen> {
 bool _isLoading = true;
 List<dynamic> _patients = [];
 String? _error;

 @override
 void initState() {
  super.initState();
  _fetchPatients();
 }

 Future<void> _fetchPatients() async {
  try {
   final apiClient = ref.read(apiClientProvider);
   final response = await apiClient.get('/api/doctor/patients', requireAuth: true);
   
   if (mounted) {
    setState(() {
     _patients = response as List<dynamic>;
     _isLoading = false;
    });
   }
  } catch (e) {
   if (mounted) {
    setState(() {
     _error = e.toString();
     _isLoading = false;
    });
   }
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
     'Patients',
     style: AppTextStyles.headingMedium.copyWith(color: AppColors.textPrimary),
    ),
    centerTitle: true,
   ),
   body: _buildBody(),
  );
 }

 Widget _buildBody() {
  if (_isLoading) {
   return const Center(child: CircularProgressIndicator());
  }

  if (_error != null) {
   return Center(
    child: Column(
     mainAxisAlignment: MainAxisAlignment.center,
     children: [
      Text('Error: $_error', style: const TextStyle(color: AppColors.error)),
      const SizedBox(height: 16),
      ElevatedButton(
       onPressed: () {
        setState(() {
         _isLoading = true;
         _error = null;
        });
        _fetchPatients();
       },
       child: const Text('Retry'),
      ),
     ],
    ),
   );
  }

  if (_patients.isEmpty) {
   return const Center(
    child: Text('No patients found', style: AppTextStyles.bodyMedium),
   );
  }

  return RefreshIndicator(
   onRefresh: _fetchPatients,
   child: ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: _patients.length,
    itemBuilder: (context, index) {
     final patient = _patients[index];
     return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
       leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        child: const Icon(Icons.person, color: AppColors.primary),
       ),
       title: Text(patient['name'] ?? 'Unknown', style: AppTextStyles.labelLarge),
       subtitle: Text(
        '${patient['gender'] ?? 'Unknown'} • ${patient['age'] ?? '-'} years\n${patient['email'] ?? ''}',
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
       ),
       isThreeLine: true,
       trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
       onTap: () {
        final pId = patient['patient_id'];
        final pName = Uri.encodeComponent(patient['name'] ?? "Patient");
        context.push('${AppRoutes.doctorPatientProfile}/$pId?name=$pName');
       },
      ),
     );
    },
   ),
  );
 }
}
