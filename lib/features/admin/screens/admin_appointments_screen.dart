import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/glass_card.dart';

class AdminAppointmentItem {
  final String appointmentId;
  final String patientId;
  final String? patientName;
  final String doctorId;
  final String? doctorName;
  final String? doctorSpecialization;
  final String? consultationId;
  final String appointmentDate;
  final String startTime;
  final String endTime;
  final String consultationType;
  final String reason;
  final String status;
  final String? patientNotes;
  final String? rejectionReason;
  final String createdAt;

  AdminAppointmentItem({
    required this.appointmentId,
    required this.patientId,
    this.patientName,
    required this.doctorId,
    this.doctorName,
    this.doctorSpecialization,
    this.consultationId,
    required this.appointmentDate,
    required this.startTime,
    required this.endTime,
    required this.consultationType,
    required this.reason,
    required this.status,
    this.patientNotes,
    this.rejectionReason,
    required this.createdAt,
  });

  factory AdminAppointmentItem.fromJson(Map<String, dynamic> json) {
    return AdminAppointmentItem(
      appointmentId: json['appointment_id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      patientName: json['patient_name']?.toString(),
      doctorId: json['doctor_id']?.toString() ?? '',
      doctorName: json['doctor_name']?.toString(),
      doctorSpecialization: json['doctor_specialization']?.toString(),
      consultationId: json['consultation_id']?.toString(),
      appointmentDate: json['appointment_date']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      consultationType: json['consultation_type']?.toString() ?? 'Video',
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? 'REQUESTED',
      patientNotes: json['patient_notes']?.toString(),
      rejectionReason: json['rejection_reason']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

/// Screen for Admin to view and filter all platform appointments across doctors and patients
class AdminAppointmentsScreen extends ConsumerStatefulWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  ConsumerState<AdminAppointmentsScreen> createState() =>
      _AdminAppointmentsScreenState();
}

class _AdminAppointmentsScreenState
    extends ConsumerState<AdminAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AdminAppointmentItem> _appointments = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _fetchAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = ref.read(apiClientProvider);
      final response =
          await client.get('/api/admin/appointments', requireAuth: true);

      if (response is List) {
        final list = response
            .map((item) =>
                AdminAppointmentItem.fromJson(item as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (mounted) {
          setState(() {
            _appointments = list;
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
          _errorMessage = 'Failed to load appointments: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _appointments.where((a) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return a.appointmentId.toLowerCase().contains(q) ||
          (a.patientName?.toLowerCase().contains(q) ?? false) ||
          (a.doctorName?.toLowerCase().contains(q) ?? false) ||
          a.patientId.toLowerCase().contains(q) ||
          a.doctorId.toLowerCase().contains(q) ||
          a.reason.toLowerCase().contains(q);
    }).toList();

    final requested =
        filtered.where((a) => a.status.toUpperCase() == 'REQUESTED').toList();
    final approved =
        filtered.where((a) => a.status.toUpperCase() == 'APPROVED').toList();
    final cancelled = filtered
        .where((a) =>
            a.status.toUpperCase() == 'REJECTED' ||
            a.status.toUpperCase() == 'CANCELLED')
        .toList();
    final completed =
        filtered.where((a) => a.status.toUpperCase() == 'COMPLETED').toList();

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
          title: Text('Platform Appointments', style: AppTextStyles.headingMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textMuted),
            onPressed: _fetchAppointments,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            Tab(text: 'All (${filtered.length})'),
            Tab(text: 'Requested (${requested.length})'),
            Tab(text: 'Approved (${approved.length})'),
            Tab(text: 'Cancelled (${cancelled.length})'),
            Tab(text: 'Completed (${completed.length})'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: TextField(
                controller: _searchCtrl,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Search by patient, doctor, reason, or appointment ID...',
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

            // Tabs Content
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
                                onPressed: _fetchAppointments,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildAppointmentList(filtered),
                            _buildAppointmentList(requested),
                            _buildAppointmentList(approved),
                            _buildAppointmentList(cancelled),
                            _buildAppointmentList(completed),
                          ],
                        ),
            ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildAppointmentList(List<AdminAppointmentItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_month_outlined,
                size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text('No appointments found', style: AppTextStyles.bodyMedium),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAppointments,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final a = items[index];
          return _buildAppointmentCard(a)
              .animate()
              .fadeIn(duration: 250.ms, delay: Duration(milliseconds: index * 30));
        },
      ),
    );
  }

  Widget _buildAppointmentCard(AdminAppointmentItem a) {
    final status = a.status.toUpperCase();
    Color statusColor = AppColors.warning;
    String statusLabel = 'REQUESTED';

    if (status == 'APPROVED') {
      statusColor = AppColors.success;
      statusLabel = 'APPROVED';
    } else if (status == 'REJECTED' || status == 'CANCELLED') {
      statusColor = AppColors.error;
      statusLabel = status == 'REJECTED' ? 'DECLINED' : 'CANCELLED';
    } else if (status == 'COMPLETED') {
      statusColor = AppColors.primary;
      statusLabel = 'COMPLETED';
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ID: ${a.appointmentId}',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Patient',
                        style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    const SizedBox(height: 2),
                    Text(
                      a.patientName ?? a.patientId,
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Doctor',
                        style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    const SizedBox(height: 2),
                    Text(
                      a.doctorName ?? a.doctorId,
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Schedule',
                        style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    const SizedBox(height: 2),
                    Text(
                      '${a.appointmentDate} ${a.startTime}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (a.reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Reason: ${a.reason}',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
