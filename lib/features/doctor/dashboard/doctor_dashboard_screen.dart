import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../models/doctor_dashboard_models.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/doctor_repository.dart';
import '../../../shared/widgets/app_navigation.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/reusable_dashboard_components.dart';
import '../widgets/doctor_appointment_card.dart';
import '../widgets/patient_requests_card.dart';
import '../widgets/doctor_availability_card.dart';
import '../widgets/doctor_performance_card.dart';
import '../../../services/appointment_service.dart';
import '../../../models/consultation_model.dart';
import '../../../models/appointment_model.dart';
import '../../../shared/utils/app_snackbar.dart';

class DoctorDashboardScreen extends ConsumerStatefulWidget {
  final bool enableLiveTimer;

  const DoctorDashboardScreen({
    super.key,
    this.enableLiveTimer = true,
  });

  @override
  ConsumerState<DoctorDashboardScreen> createState() =>
      _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends ConsumerState<DoctorDashboardScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isAvailable = true;
  bool _isLoading = false;
  String? _errorMessage;

  DoctorDashboardStats? _stats;
  List<DoctorAppointment>? _appointments;
  List<PatientRequest>? _requests;
  List<RecentPatientSummary>? _recentPatients;
  DoctorPerformance? _performance;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(doctorRepositoryProvider);
      final apptService = ref.read(appointmentServiceProvider);

      final statsFuture = repo.getDashboardStats();
      final apptsFuture = repo.getTodayAppointments();
      final requestsFuture = repo.getPendingRequests();
      final patientsFuture = repo.getRecentPatients();
      final perfFuture = repo.getDoctorPerformance();
      final liveRequestsFuture = apptService
          .getDoctorPendingRequests()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => <ClinicalAppointmentModel>[],
          )
          .catchError((_) => <ClinicalAppointmentModel>[]);
      final liveApptsFuture = apptService
          .getDoctorAppointments(status: 'APPROVED')
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => <ClinicalAppointmentModel>[],
          )
          .catchError((_) => <ClinicalAppointmentModel>[]);

      final results = await Future.wait([
        statsFuture,
        apptsFuture,
        requestsFuture,
        patientsFuture,
        perfFuture,
        liveRequestsFuture,
        liveApptsFuture,
      ]);

      final liveRequests = results[5] as List<ClinicalAppointmentModel>;
      final liveAppts = results[6] as List<ClinicalAppointmentModel>;
      List<PatientRequest> combinedRequests = results[2] as List<PatientRequest>;
      List<DoctorAppointment> combinedAppts = results[1] as List<DoctorAppointment>;

      if (liveRequests.isNotEmpty) {
        combinedRequests = liveRequests.map((appt) {
          return PatientRequest(
            id: appt.appointmentId,
            patientId: appt.patientId,
            reason: appt.reason,
            requestedAgo: 'Today',
            urgency: 'normal',
            consultationId: appt.consultationId,
            appointmentDate: appt.appointmentDate,
            startTime: appt.startTime,
          );
        }).toList();
      }

      if (liveAppts.isNotEmpty) {
        combinedAppts = liveAppts.map((a) {
          DateTime dt;
          try {
            final p = a.appointmentDate.split('-');
            final tp = a.startTime.split(':');
            dt = DateTime(
              int.parse(p[0]),
              int.parse(p[1]),
              int.parse(p[2]),
              int.parse(tp[0]),
              int.parse(tp[1]),
            );
          } catch (_) {
            dt = a.createdAt;
          }
          final hour = int.tryParse(a.startTime.split(':').first) ?? 9;
          final amPm = hour >= 12 ? 'PM' : 'AM';
          return DoctorAppointment(
            id: a.appointmentId,
            patientId: a.patientId,
            patientName: a.patientName ?? 'Patient ${a.patientId}',
            consultationType: a.consultationType,
            timeFormatted: '${a.startTime} $amPm',
            dateTime: dt,
            status: DoctorAppointmentStatus.upcoming,
          );
        }).toList();
      }

      if (mounted) {
        setState(() {
          _stats = results[0] as DoctorDashboardStats;
          _appointments = combinedAppts;
          _requests = combinedRequests;
          _recentPatients = results[3] as List<RecentPatientSummary>;
          _performance = results[4] as DoctorPerformance;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to connect to Clinical Practice Service.';
          _isLoading = false;
        });
      }
    }
  }

  void _toggleAvailability() async {
    final newStatus = !_isAvailable;
    setState(() => _isAvailable = newStatus);
    await ref.read(doctorRepositoryProvider).updateAvailability(newStatus);
    if (mounted) {
      if (newStatus) {
        AppSnackbar.showSuccess(
          context,
          'You are now marked as Available for consultations',
        );
      } else {
        AppSnackbar.showWarning(
          context,
          'You are now marked as Unavailable / Offline',
        );
      }
    }
  }

  void _handleAcceptRequest(String requestId) async {
    try {
      await ref.read(appointmentServiceProvider).approveAppointment(requestId);
    } catch (_) {
      await ref.read(doctorRepositoryProvider).acceptRequest(requestId);
    }
    setState(() {
      _requests = _requests?.where((r) => r.id != requestId).toList();
    });
    if (mounted) {
      AppSnackbar.showSuccess(
        context,
        'Appointment approved and confirmed. Slot marked as booked.',
      );
      _loadDashboardData();
    }
  }

  void _handleDeclineRequest(String requestId) async {
    try {
      await ref.read(appointmentServiceProvider).rejectAppointment(
        requestId,
        rejectionReason: 'Doctor unavailable due to urgent clinical duty.',
      );
    } catch (_) {
      await ref.read(doctorRepositoryProvider).declineRequest(requestId);
    }
    setState(() {
      _requests = _requests?.where((r) => r.id != requestId).toList();
    });
    if (mounted) {
      AppSnackbar.showError(
        context,
        'Appointment request declined. Time slot released back to available.',
      );
      _loadDashboardData();
    }
  }

  void _showAISummaryModal(PatientRequest req) async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return FutureBuilder<ConsultationSummaryModel?>(
          future: ref.read(appointmentServiceProvider).getAppointmentConsultationSummary(req.id),
          builder: (context, snapshot) {
            final summary = snapshot.data;
            final isLoading = snapshot.connectionState == ConnectionState.waiting;

            return Dialog(
              backgroundColor: AppColors.backgroundSecondary,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'AI Consultation Summary',
                                    style: AppTextStyles.headingSmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          'AI-generated patient intake summary. Clinical decisions remain the responsibility of the healthcare professional.',
                          style: AppTextStyles.caption.copyWith(color: AppColors.primaryLight, fontSize: 11),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                        )
                      else ...[
                        _DetailRow(label: 'Patient ID', value: req.patientId),
                        const SizedBox(height: 6),
                        _DetailRow(label: 'Patient Name', value: summary?.patientName ?? 'Alex Johnson'),
                        if (summary?.age != null) ...[
                          const SizedBox(height: 6),
                          _DetailRow(label: 'Age / Gender', value: '${summary!.age} yrs • ${summary.gender ?? "Unknown"}'),
                        ],
                        const SizedBox(height: 6),
                        _DetailRow(
                          label: 'Chief Complaint',
                          value: summary?.chiefComplaint ?? req.reason,
                        ),
                        if (summary != null && summary.symptoms.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text('Reported Symptoms:', style: AppTextStyles.labelSmall),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: summary.symptoms.map((s) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(s, style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary)),
                              );
                            }).toList(),
                          ),
                        ],
                        if (summary?.severity != null) ...[
                          const SizedBox(height: 8),
                          _DetailRow(label: 'Assessed Severity', value: summary!.severity),
                        ],
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _handleDeclineRequest(req.id);
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  foregroundColor: AppColors.error,
                                  side: const BorderSide(color: AppColors.error),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('Decline', style: TextStyle(fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 6,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _handleAcceptRequest(req.id);
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  backgroundColor: AppColors.success,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('Approve Appointment', style: TextStyle(fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAppointmentDetailModal(DoctorAppointment appointment) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundSecondary,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Appointment Details', style: AppTextStyles.headingSmall),
                    StatusBadge(
                      label: appointment.status.label,
                      color: appointment.status.color,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _DetailRow(label: 'Patient Name', value: appointment.patientName),
                      const Divider(height: 16, color: AppColors.border),
                      _DetailRow(label: 'Patient ID', value: appointment.patientId),
                      const Divider(height: 16, color: AppColors.border),
                      _DetailRow(label: 'Consultation Type', value: appointment.consultationType),
                      const Divider(height: 16, color: AppColors.border),
                      _DetailRow(label: 'Scheduled Time', value: appointment.timeFormatted),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          context.push('${AppRoutes.comingSoon}?title=Telehealth+Call');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.videocam_rounded, size: 18),
                        label: const Text('Start Call'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final doctorName = user?.name ?? 'Dr. Sarah Wilson';
    final greeting = _getGreeting();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: DoctorDrawer(
        userName: doctorName,
        specialty: 'Internal Medicine',
        onLogout: () async {
          final router = GoRouter.of(context);
          await ref.read(authProvider.notifier).logout();
          router.go(AppRoutes.login);
        },
      ),
      body: SafeArea(
        child: Stack(
          children: [
            _DoctorDashboardBackground(),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        // 1. Header
                        DashboardHeader(
                          scaffoldKey: _scaffoldKey,
                          notificationCount: _requests?.length ?? 4,
                        ).animate().fadeIn(duration: 400.ms),
                        const SizedBox(height: 20),

                        // Greeting + Availability Toggle
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$greeting, $doctorName 👋',
                                    style: AppTextStyles.headingLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Here's your practice overview.",
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            // Availability Toggle Button
                            GestureDetector(
                              onTap: _toggleAvailability,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _isAvailable
                                      ? AppColors.success.withValues(alpha: 0.14)
                                      : AppColors.textMuted.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _isAvailable
                                        ? AppColors.success.withValues(alpha: 0.35)
                                        : AppColors.textMuted.withValues(alpha: 0.35),
                                    width: 1,
                                  ),
                                  boxShadow: _isAvailable
                                      ? [
                                          BoxShadow(
                                            color: AppColors.success.withValues(alpha: 0.15),
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    PulseDot(
                                      color: _isAvailable
                                          ? AppColors.success
                                          : AppColors.textMuted,
                                      size: 7,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isAvailable ? 'Available' : 'Unavailable',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: _isAvailable
                                            ? AppColors.success
                                            : AppColors.textMuted,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                            .animate()
                            .fadeIn(delay: 150.ms, duration: 500.ms)
                            .slideX(begin: -0.05, end: 0),
                        const SizedBox(height: 24),

                        // Error / Loading / Content
                        if (_errorMessage != null)
                          ErrorStateWidget(
                            message: _errorMessage!,
                            onRetry: _loadDashboardData,
                          )
                        else if (_isLoading && _stats == null)
                          _buildSkeletons()
                        else if (_stats != null) ...[
                          // 2. Today's Overview Stat Cards
                          _SectionLabel(label: "Today's Clinical Overview", color: AppColors.primary),
                          const SizedBox(height: 12),
                          GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: 1.35,
                            children: [
                              StatCard(
                                label: "Today's Appointments",
                                value: '${_stats!.todayAppointments}',
                                icon: Icons.calendar_today_rounded,
                                accentColor: AppColors.primary,
                                change: _stats!.appointmentTrend,
                                isPositive: true,
                              ),
                              StatCard(
                                label: 'Pending Requests',
                                value: '${_requests?.length ?? _stats!.pendingRequests}',
                                icon: Icons.pending_actions_rounded,
                                accentColor: AppColors.warning,
                                statusBadge: (_requests?.isNotEmpty ?? false) ? 'Action Required' : null,
                                statusBadgeColor: AppColors.warning,
                              ),
                              StatCard(
                                label: 'Completed Today',
                                value: '${_stats!.completedToday}',
                                icon: Icons.check_circle_outline_rounded,
                                accentColor: AppColors.success,
                                isPositive: true,
                              ),
                              StatCard(
                                label: 'Total Patients',
                                value: '${_stats!.totalPatients}',
                                icon: Icons.group_rounded,
                                accentColor: AppColors.secondaryLight,
                                change: _stats!.patientTrend,
                                isPositive: true,
                              ),
                            ],
                          ).animate().fadeIn(delay: 250.ms, duration: 500.ms),
                          const SizedBox(height: 24),

                          // 3. Quick Actions
                          _SectionLabel(label: 'Quick Actions', color: AppColors.secondary),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: QuickActionCard(
                                  title: 'Appointments',
                                  icon: Icons.calendar_month_rounded,
                                  color: AppColors.primary,
                                  onTap: () => context.push(AppRoutes.doctorAppointments),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: QuickActionCard(
                                  title: 'Patients',
                                  icon: Icons.people_alt_outlined,
                                  color: AppColors.secondary,
                                  onTap: () => context.push('${AppRoutes.comingSoon}?title=Patients'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: QuickActionCard(
                                  title: 'Availability',
                                  icon: Icons.schedule_rounded,
                                  color: AppColors.success,
                                  onTap: () => context.push('${AppRoutes.comingSoon}?title=Availability'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: QuickActionCard(
                                  title: 'Prescriptions',
                                  icon: Icons.medication_outlined,
                                  color: AppColors.accent,
                                  onTap: () => context.push('${AppRoutes.comingSoon}?title=Prescriptions'),
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: 300.ms, duration: 450.ms),
                          const SizedBox(height: 28),

                          // 4. Today's Appointments
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _SectionLabel(label: "Today's Appointments", color: AppColors.primary),
                              GestureDetector(
                                onTap: () => context.push(AppRoutes.doctorAppointments),
                                child: Text(
                                  'View All (${_appointments?.length ?? 0})',
                                  style: AppTextStyles.link.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
                          const SizedBox(height: 12),
                          if (_appointments != null && _appointments!.isNotEmpty)
                            ..._appointments!.map(
                              (appt) => DoctorAppointmentCard(
                                appointment: appt,
                                onView: () => _showAppointmentDetailModal(appt),
                              ),
                            )
                          else
                            const EmptyStateWidget(
                              title: 'No Appointments Today',
                              subtitle: 'You have no more scheduled appointments for today.',
                              icon: Icons.event_available_rounded,
                            ),
                          const SizedBox(height: 28),

                          // 6. Patient Requests (Pending Requests)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _SectionLabel(label: 'Pending Requests', color: AppColors.warning),
                              GestureDetector(
                                onTap: () => context.push(AppRoutes.doctorAppointments),
                                child: Text(
                                  '${_requests?.length ?? 0} Pending',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
                          const SizedBox(height: 12),
                          if (_requests != null)
                            PatientRequestsCard(
                              requests: _requests!,
                              onAccept: _handleAcceptRequest,
                              onDecline: _handleDeclineRequest,
                              onViewSummary: _showAISummaryModal,
                            ),
                          const SizedBox(height: 28),

                          // 7. Recent Patients
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _SectionLabel(label: 'Recent Patients', color: AppColors.secondary),
                              GestureDetector(
                                onTap: () => context.push('${AppRoutes.comingSoon}?title=Patient+Records'),
                                child: Text(
                                  'All Records',
                                  style: AppTextStyles.link.copyWith(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: 550.ms, duration: 400.ms),
                          const SizedBox(height: 12),
                          if (_recentPatients != null)
                            ..._recentPatients!.map((patient) {
                              return _RecentPatientRow(patient: patient);
                            }),
                          const SizedBox(height: 28),

                          // 8. Doctor Availability & Schedule
                          DoctorAvailabilityCard(
                            isAvailable: _isAvailable,
                            onManage: () {
                              context.push('${AppRoutes.comingSoon}?title=Manage+Schedule');
                            },
                          ).animate().fadeIn(delay: 600.ms, duration: 450.ms),
                          const SizedBox(height: 28),

                          // 9. Doctor Performance
                          if (_performance != null)
                            DoctorPerformanceCard(performance: _performance!)
                                .animate()
                                .fadeIn(delay: 650.ms, duration: 450.ms),
                          const SizedBox(height: 36),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletons() {
    return Column(
      children: [
        Row(
          children: const [
            Expanded(child: SkeletonCard(height: 110)),
            SizedBox(width: 12),
            Expanded(child: SkeletonCard(height: 110)),
          ],
        ),
        const SizedBox(height: 16),
        const SkeletonCard(height: 140),
        const SizedBox(height: 16),
        const SkeletonCard(height: 90),
        const SizedBox(height: 16),
        const SkeletonCard(height: 90),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              softWrap: true,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentPatientRow extends StatelessWidget {
  final RecentPatientSummary patient;

  const _RecentPatientRow({required this.patient});

  @override
  Widget build(BuildContext context) {
    Color statusColor = AppColors.primary;
    if (patient.clinicalStatus == 'Improving') statusColor = AppColors.success;
    if (patient.clinicalStatus == 'Follow-up Needed') statusColor = AppColors.warning;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              patient.patientId,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${patient.age} yrs · ${patient.condition}',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  patient.clinicalStatus,
                  style: AppTextStyles.caption.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Last visit: ${patient.lastConsultation}',
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;

  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3.5,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(label, style: AppTextStyles.headingSmall.copyWith(fontSize: 16)),
      ],
    );
  }
}

class _DoctorDashboardBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            bottom: 150,
            left: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withValues(alpha: 0.03),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
