import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/utils/app_snackbar.dart';

/// Doctor data model for Admin Management
class AdminDoctorItem {
  final String doctorId;
  final String name;
  final String email;
  final String? phone;
  final String specialization;
  final String qualification;
  final int experience;
  final String department;
  final String status;
  final double? consultationFee;

  AdminDoctorItem({
    required this.doctorId,
    required this.name,
    required this.email,
    this.phone,
    required this.specialization,
    required this.qualification,
    required this.experience,
    required this.department,
    required this.status,
    this.consultationFee,
  });

  factory AdminDoctorItem.fromJson(Map<String, dynamic> json) {
    return AdminDoctorItem(
      doctorId: json['doctor_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Doctor',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      specialization: json['specialization']?.toString() ?? 'General Physician',
      qualification: json['qualification']?.toString() ?? 'MBBS',
      experience: (json['experience'] as num?)?.toInt() ?? 0,
      department: json['department']?.toString() ?? 'Outpatient',
      status: json['status']?.toString() ?? 'ACTIVE',
      consultationFee: (json['consultation_fee'] as num?)?.toDouble(),
    );
  }
}

/// Screen allowing Admin to view all doctors, add new doctors, and edit/update existing doctors
class AdminDoctorsScreen extends ConsumerStatefulWidget {
  const AdminDoctorsScreen({super.key});

  @override
  ConsumerState<AdminDoctorsScreen> createState() => _AdminDoctorsScreenState();
}

class _AdminDoctorsScreenState extends ConsumerState<AdminDoctorsScreen> {
  List<AdminDoctorItem> _doctors = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

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
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchDoctors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = ref.read(apiClientProvider);
      final response = await client.get('/api/admin/doctors', requireAuth: true);

      if (response is List) {
        final list = response
            .map((item) =>
                AdminDoctorItem.fromJson(item as Map<String, dynamic>))
            .toList();

        if (mounted) {
          setState(() {
            _doctors = list;
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
          _errorMessage = 'Failed to load doctors: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _showEditDoctorDialog(AdminDoctorItem doctor) {
    final nameCtrl = TextEditingController(text: doctor.name);
    final qualCtrl = TextEditingController(text: doctor.qualification);
    final expCtrl = TextEditingController(text: doctor.experience.toString());
    final deptCtrl = TextEditingController(text: doctor.department);
    final phoneCtrl = TextEditingController(text: doctor.phone ?? '');
    String selectedSpec = doctor.specialization;
    if (!_specializations.contains(selectedSpec)) {
      _specializations.insert(0, selectedSpec);
    }
    String selectedStatus = doctor.status.toUpperCase();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: AppColors.backgroundSecondary,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.edit_note_rounded,
                                color: AppColors.primary, size: 24),
                            const SizedBox(width: 8),
                            Text('Edit Doctor Details',
                                style: AppTextStyles.headingSmall
                                    .copyWith(fontSize: 18)),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: AppColors.textMuted),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('ID: ${doctor.doctorId} • ${doctor.email}',
                        style: AppTextStyles.caption),
                    const SizedBox(height: 18),

                    // Name
                    _formField(
                      label: 'Doctor Name',
                      ctrl: nameCtrl,
                      hint: 'Dr. Full Name',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 12),

                    // Specialization Dropdown
                    Text('Specialization',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: selectedSpec,
                      dropdownColor: AppColors.surface,
                      style: AppTextStyles.bodyMedium,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                      items: _specializations
                          .map((s) =>
                              DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedSpec = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Qualification & Experience
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _formField(
                            label: 'Qualification',
                            ctrl: qualCtrl,
                            hint: 'e.g. MBBS, MD',
                            icon: Icons.school_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: _formField(
                            label: 'Exp (Yrs)',
                            ctrl: expCtrl,
                            hint: 'e.g. 10',
                            icon: Icons.work_history_outlined,
                            isNumber: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Department & Status
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _formField(
                            label: 'Department',
                            ctrl: deptCtrl,
                            hint: 'e.g. Outpatient',
                            icon: Icons.domain_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Status',
                                  style: AppTextStyles.caption
                                      .copyWith(color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                value: selectedStatus,
                                dropdownColor: AppColors.surface,
                                style: AppTextStyles.bodyMedium,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.surface,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide:
                                        const BorderSide(color: AppColors.border),
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'ACTIVE', child: Text('ACTIVE')),
                                  DropdownMenuItem(
                                      value: 'INACTIVE', child: Text('INACTIVE')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setDialogState(() => selectedStatus = val);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Phone
                    _formField(
                      label: 'Phone Number',
                      ctrl: phoneCtrl,
                      hint: '+91 9876543210',
                      icon: Icons.phone_outlined,
                    ),
                    const SizedBox(height: 22),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSaving
                                ? null
                                : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textMuted,
                              side: const BorderSide(color: AppColors.border),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    setDialogState(() => isSaving = true);
                                    try {
                                      final body = {
                                        'name': nameCtrl.text.trim(),
                                        'specialization': selectedSpec,
                                        'qualification': qualCtrl.text.trim(),
                                        'experience': int.tryParse(
                                                expCtrl.text.trim()) ??
                                            doctor.experience,
                                        'department': deptCtrl.text.trim(),
                                        'status': selectedStatus,
                                        'phone': phoneCtrl.text.trim(),
                                      };

                                      final client =
                                          ref.read(apiClientProvider);
                                      await client.put(
                                        '/api/admin/doctors/${doctor.doctorId}',
                                        body: body,
                                        requireAuth: true,
                                      );

                                      if (ctx.mounted) {
                                        Navigator.pop(ctx);
                                        AppSnackbar.showSuccess(context,
                                            'Doctor ${doctor.name} updated successfully!');
                                        _fetchDoctors();
                                      }
                                    } catch (e) {
                                      setDialogState(() => isSaving = false);
                                      if (ctx.mounted) {
                                        AppSnackbar.showError(
                                            context, 'Update failed: $e');
                                      }
                                    }
                                  },
                            icon: isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.check_rounded, size: 18),
                            label: Text(isSaving ? 'Saving...' : 'Save Updates'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _formField({
    required String label,
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
            hintText: hint,
            hintStyle: AppTextStyles.caption,
            filled: true,
            fillColor: AppColors.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredDoctors = _doctors.where((d) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return d.name.toLowerCase().contains(q) ||
          d.specialization.toLowerCase().contains(q) ||
          d.doctorId.toLowerCase().contains(q) ||
          d.department.toLowerCase().contains(q);
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
          title: Text('Doctors Management', style: AppTextStyles.headingMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textMuted),
            onPressed: _fetchDoctors,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () async {
                await context.push(AppRoutes.adminAddDoctor);
                _fetchDoctors();
              },
              icon: const Icon(Icons.person_add_rounded, size: 16),
              label: const Text('Add Doctor', style: TextStyle(fontSize: 12.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search & Filter Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: TextField(
                controller: _searchCtrl,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Search by doctor name, specialty, or ID...',
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

            // Main Content
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
                                onPressed: _fetchDoctors,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : filteredDoctors.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.people_outline_rounded,
                                      size: 48, color: AppColors.textMuted),
                                  const SizedBox(height: 12),
                                  Text(
                                    _searchQuery.isEmpty
                                        ? 'No doctors registered yet'
                                        : 'No doctors matching "$_searchQuery"',
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchDoctors,
                              color: AppColors.primary,
                              backgroundColor: AppColors.surface,
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                itemCount: filteredDoctors.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final doc = filteredDoctors[index];
                                  return _buildDoctorCard(doc)
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

  Widget _buildDoctorCard(AdminDoctorItem doc) {
    final isActive = doc.status.toUpperCase() == 'ACTIVE';

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
                  doc.name.isNotEmpty ? doc.name[0].toUpperCase() : 'D',
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
                      doc.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${doc.specialization} • ${doc.qualification}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.primaryLight),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isActive ? AppColors.success : AppColors.error)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  doc.status.toUpperCase(),
                  style: TextStyle(
                    color: isActive ? AppColors.success : AppColors.error,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _metaInfo('ID', doc.doctorId),
              ),
              Expanded(
                child: _metaInfo('Experience', '${doc.experience} Years'),
              ),
              Expanded(
                child: _metaInfo('Department', doc.department),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                doc.email,
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
              ),
              ElevatedButton.icon(
                onPressed: () => _showEditDoctorDialog(doc),
                icon: const Icon(Icons.edit_rounded, size: 14),
                label: const Text('Edit Doctor', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
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
