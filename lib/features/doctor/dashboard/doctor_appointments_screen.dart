import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/appointment_model.dart';
import '../../../models/consultation_model.dart';
import '../../../services/appointment_service.dart';
import '../../../shared/widgets/glass_card.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
// ignore: depend_on_referenced_packages
import 'package:zego_uikit/zego_uikit.dart';
import '../../../shared/utils/app_snackbar.dart';

/// Comprehensive Appointments Screen for Doctors
/// Shows all appointments, pending requests, accepted/booked, and canceled/declined requests.
/// Includes AI summary viewing and one-tap request acceptance.
class DoctorAppointmentsScreen extends ConsumerStatefulWidget {
 const DoctorAppointmentsScreen({super.key});

 @override
 ConsumerState<DoctorAppointmentsScreen> createState() =>
   _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState
  extends ConsumerState<DoctorAppointmentsScreen>
  with SingleTickerProviderStateMixin {
 late TabController _tabController;
 List<ClinicalAppointmentModel> _allAppointments = [];
 bool _isLoading = true;
 String? _errorMessage;

 @override
 void initState() {
  super.initState();
  _tabController = TabController(length: 5, vsync: this);
  _loadAppointments();
 }

 @override
 void dispose() {
  _tabController.dispose();
  super.dispose();
 }

 Future<void> _loadAppointments() async {
  setState(() {
   _isLoading = true;
   _errorMessage = null;
  });

  try {
   final service = ref.read(appointmentServiceProvider);
   final allFuture = service.getDoctorAppointments().timeout(
      const Duration(seconds: 5),
      onTimeout: () => <ClinicalAppointmentModel>[],
     );
   final requestsFuture = service.getDoctorPendingRequests().timeout(
      const Duration(seconds: 5),
      onTimeout: () => <ClinicalAppointmentModel>[],
     );

   final results = await Future.wait([allFuture, requestsFuture]);
   final allAppts = results[0];
   final reqAppts = results[1];

   // Merge and deduplicate by appointmentId
   final Map<String, ClinicalAppointmentModel> map = {};
   for (final a in allAppts) {
    map[a.appointmentId] = a;
   }
   for (final r in reqAppts) {
    map[r.appointmentId] = r;
   }

   if (mounted) {
    setState(() {
     _allAppointments = map.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
     _isLoading = false;
    });
   }
  } catch (e) {
   if (mounted) {
    setState(() {
     _errorMessage = 'Failed to fetch appointments. Please check connection.';
     _isLoading = false;
    });
   }
  }
 }

 Future<void> _handleAccept(String appointmentId) async {
  try {
   await ref.read(appointmentServiceProvider).approveAppointment(appointmentId);
   if (mounted) {
    AppSnackbar.showSuccess(context, 'Appointment request approved and confirmed!');
    _loadAppointments();
   }
  } catch (e) {
   // Optimistic local state update
   setState(() {
    final index =
      _allAppointments.indexWhere((a) => a.appointmentId == appointmentId);
    if (index != -1) {
     final old = _allAppointments[index];
     _allAppointments[index] = ClinicalAppointmentModel(
      id: old.id,
      appointmentId: old.appointmentId,
      patientId: old.patientId,
      patientName: old.patientName,
      doctorId: old.doctorId,
      doctorName: old.doctorName,
      doctorSpecialization: old.doctorSpecialization,
      consultationId: old.consultationId,
      availabilityId: old.availabilityId,
      appointmentDate: old.appointmentDate,
      startTime: old.startTime,
      endTime: old.endTime,
      consultationType: old.consultationType,
      reason: old.reason,
      status: 'APPROVED',
      createdAt: old.createdAt,
     );
    }
   });
   if (mounted) {
    AppSnackbar.showSuccess(
      context, 'Appointment request approved and marked as Booked.');
   }
  }
 }

 Future<void> _handleDecline(String appointmentId) async {
  try {
   await ref.read(appointmentServiceProvider).rejectAppointment(
      appointmentId,
      rejectionReason: 'Doctor unavailable due to clinical schedule.',
     );
   if (mounted) {
    AppSnackbar.showError(context, 'Appointment request declined.');
    _loadAppointments();
   }
  } catch (e) {
   setState(() {
    final index =
      _allAppointments.indexWhere((a) => a.appointmentId == appointmentId);
    if (index != -1) {
     final old = _allAppointments[index];
     _allAppointments[index] = ClinicalAppointmentModel(
      id: old.id,
      appointmentId: old.appointmentId,
      patientId: old.patientId,
      patientName: old.patientName,
      doctorId: old.doctorId,
      doctorName: old.doctorName,
      doctorSpecialization: old.doctorSpecialization,
      consultationId: old.consultationId,
      availabilityId: old.availabilityId,
      appointmentDate: old.appointmentDate,
      startTime: old.startTime,
      endTime: old.endTime,
      consultationType: old.consultationType,
      reason: old.reason,
      status: 'REJECTED',
      rejectionReason: 'Doctor unavailable due to clinical schedule.',
      createdAt: old.createdAt,
     );
    }
   });
   if (mounted) {
    AppSnackbar.showError(context, 'Appointment request declined.');
   }
  }
 }

 void _showAISummaryModal(ClinicalAppointmentModel appt) {
  showDialog(
   context: context,
   builder: (ctx) {
    return FutureBuilder<ConsultationSummaryModel?>(
     future: ref
       .read(appointmentServiceProvider)
       .getAppointmentConsultationSummary(appt.appointmentId),
     builder: (context, snapshot) {
      final summary = snapshot.data;
      final isLoading = snapshot.connectionState == ConnectionState.waiting;

      return Dialog(
       backgroundColor: AppColors.backgroundSecondary,
       insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
       child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
         padding: const EdgeInsets.all(20),
         child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
             const Row(
              children: [
               Icon(Icons.auto_awesome_rounded,
                 color: AppColors.primary, size: 22),
               SizedBox(width: 8),
               Text('Patient AI Intake Summary',
                 style: TextStyle(
                   fontWeight: FontWeight.bold,
                   fontSize: 16,
                   color: AppColors.textPrimary)),
              ],
             ),
             IconButton(
              icon: const Icon(Icons.close, color: AppColors.textMuted),
              onPressed: () => Navigator.pop(context),
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
             border: Border.all(
               color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: const Text(
             'Pre-consultation summary generated by HealthCall AI and confirmed by patient.',
             style: TextStyle(
               fontSize: 11, color: AppColors.primaryLight),
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
            _detailRow('Patient Name',
              summary?.patientName ?? appt.patientName ?? 'Patient ${appt.patientId}'),
            if (summary?.age != null) ...[
             const SizedBox(height: 6),
             _detailRow('Age & Gender',
               '${summary!.age} yrs • ${summary.gender ?? "Unspecified"}'),
            ],
            const SizedBox(height: 6),
            _detailRow('Chief Complaint',
              summary?.chiefComplaint ?? appt.reason),
            if (summary != null && summary.symptoms.isNotEmpty) ...[
             const SizedBox(height: 10),
             const Text('Symptoms:',
               style: TextStyle(
                 fontSize: 11.5, color: AppColors.textMuted)),
             const SizedBox(height: 4),
             Wrap(
              spacing: 6,
              runSpacing: 4,
              children: summary.symptoms
                .map((s) => Container(
                   padding: const EdgeInsets.symmetric(
                     horizontal: 8, vertical: 3),
                   decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border:
                      Border.all(color: AppColors.border),
                   ),
                   child: Text(s,
                     style: const TextStyle(
                       fontSize: 11,
                       color: AppColors.textPrimary)),
                  ))
                .toList(),
             ),
            ],
            if (summary?.duration != null) ...[
             const SizedBox(height: 8),
             _detailRow('Duration', summary!.duration!),
            ],
            if (summary?.severity != null) ...[
             const SizedBox(height: 6),
             _detailRow('Severity', summary!.severity!),
            ],
            if (summary?.clinicalSummary != null &&
              summary!.clinicalSummary!.isNotEmpty) ...[
             const SizedBox(height: 10),
             _detailRow(
               'AI Clinical Notes', summary.clinicalSummary!),
            ],
            if (summary?.preliminaryGuidance != null &&
              summary!.preliminaryGuidance!.isNotEmpty) ...[
             const SizedBox(height: 8),
             _detailRow(
               'Care Guidance', summary.preliminaryGuidance!),
            ],

            // AI Visual Assessment Section
            if (summary?.visualDominantEmotion != null) ...[
             const SizedBox(height: 16),
             const Divider(color: AppColors.border),
             const SizedBox(height: 12),
             const Row(
              children: [
               Icon(Icons.face_retouching_natural_rounded,
                 color: AppColors.primary, size: 20),
               SizedBox(width: 8),
               Text('AI Visual Observation',
                 style: TextStyle(
                   fontWeight: FontWeight.bold,
                   fontSize: 14,
                   color: AppColors.textPrimary)),
              ],
             ),
             const SizedBox(height: 10),
             _detailRow('Dominant Expression',
               summary!.visualDominantEmotion!.toUpperCase()),
             if (summary.visualAssessmentDurationSeconds != null) ...[
              const SizedBox(height: 6),
              _detailRow('Observation Duration',
                '${summary.visualAssessmentDurationSeconds} seconds'),
             ],
             if (summary.visualEmotionDistribution != null &&
               summary.visualEmotionDistribution!.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('Expression Distribution:',
                style: TextStyle(
                  fontSize: 11.5, color: AppColors.textMuted)),
              const SizedBox(height: 6),
              Wrap(
               spacing: 8,
               runSpacing: 6,
               children: summary.visualEmotionDistribution!.entries
                 .map((e) {
                final percentage = ((e.value as double) * 100).toStringAsFixed(0);
                return Container(
                 padding: const EdgeInsets.symmetric(
                   horizontal: 8, vertical: 4),
                 decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                 ),
                 child: Text('${e.key.toUpperCase()} $percentage%',
                   style: const TextStyle(
                     fontSize: 11,
                     fontWeight: FontWeight.w600,
                     color: AppColors.textPrimary)),
                );
               }).toList(),
              ),
             ],
            ],

            // If still in requested state, show action buttons directly in summary
            if (appt.status.toUpperCase() == 'REQUESTED') ...[
             const SizedBox(height: 20),
             Row(
              children: [
               Expanded(
                child: OutlinedButton(
                 onPressed: () {
                  Navigator.pop(context);
                  _handleDecline(appt.appointmentId);
                 },
                 style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                   borderRadius: BorderRadius.circular(10),
                  ),
                 ),
                 child: const Text('Decline Request'),
                ),
               ),
               const SizedBox(width: 12),
               Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                 onPressed: () {
                  Navigator.pop(context);
                  _handleAccept(appt.appointmentId);
                 },
                 icon: const Icon(Icons.check_rounded, size: 18),
                 label: const Text('Accept & Book'),
                 style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
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

 Widget _detailRow(String label, String value) {
  return Column(
   crossAxisAlignment: CrossAxisAlignment.start,
   children: [
    Text(label,
      style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
    const SizedBox(height: 2),
    Text(value,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary)),
   ],
  );
 }

 @override
 Widget build(BuildContext context) {
  final pendingRequests = _allAppointments
    .where((a) => a.status.toUpperCase() == 'REQUESTED')
    .toList();
  final acceptedAppointments = _allAppointments
    .where((a) => a.status.toUpperCase() == 'APPROVED')
    .toList();
  final cancelledAppointments = _allAppointments
    .where((a) =>
      a.status.toUpperCase() == 'REJECTED' ||
      a.status.toUpperCase() == 'CANCELLED')
    .toList();
  final completedAppointments = _allAppointments
    .where((a) => a.status.toUpperCase() == 'COMPLETED')
    .toList();

  return PopScope(
   canPop: context.canPop(),
   onPopInvokedWithResult: (didPop, result) {
    if (!didPop) {
     context.go(AppRoutes.doctorDashboard);
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
        context.go(AppRoutes.doctorDashboard);
       }
      },
     ),
     title: Text('Doctor Appointments', style: AppTextStyles.headingMedium),
    actions: [
     IconButton(
      icon: const Icon(Icons.refresh_rounded, color: AppColors.textMuted),
      onPressed: _loadAppointments,
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
      Tab(text: 'All (${_allAppointments.length})'),
      Tab(text: 'Requests (${pendingRequests.length})'),
      Tab(text: 'Accepted (${acceptedAppointments.length})'),
      Tab(text: 'Cancelled (${cancelledAppointments.length})'),
      Tab(text: 'Completed (${completedAppointments.length})'),
     ],
    ),
   ),
   body: SafeArea(
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
            Text(_errorMessage!, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 16),
            ElevatedButton(
             onPressed: _loadAppointments,
             child: const Text('Retry'),
            ),
           ],
          ),
         )
        : TabBarView(
          controller: _tabController,
          children: [
           _buildList(_allAppointments),
           _buildList(pendingRequests),
           _buildDayWiseList(acceptedAppointments),
           _buildList(cancelledAppointments),
           _buildList(completedAppointments),
          ],
         ),
   ),
   ),
  );
 }

 Widget _buildDayWiseList(List<ClinicalAppointmentModel> items) {
  if (items.isEmpty) {
   return Center(
    child: Column(
     mainAxisAlignment: MainAxisAlignment.center,
     children: [
      Container(
       padding: const EdgeInsets.all(16),
       decoration: const BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
       ),
       child: const Icon(Icons.calendar_today_outlined,
         color: AppColors.textMuted, size: 36),
      ),
      const SizedBox(height: 14),
      Text('No appointments in this category',
        style: AppTextStyles.headingSmall.copyWith(fontSize: 16)),
      const SizedBox(height: 6),
      Text('Appointment records will appear here.',
        style: AppTextStyles.caption),
     ],
    ),
   );
  }

  // Group items by appointmentDate
  final groupedItems = <String, List<ClinicalAppointmentModel>>{};
  for (var appt in items) {
   final date = appt.appointmentDate;
   if (!groupedItems.containsKey(date)) {
    groupedItems[date] = [];
   }
   groupedItems[date]!.add(appt);
  }

  // Sort dates
  final sortedDates = groupedItems.keys.toList()..sort();

  return RefreshIndicator(
   onRefresh: _loadAppointments,
   color: AppColors.primary,
   backgroundColor: AppColors.surface,
   child: ListView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    itemCount: sortedDates.length,
    itemBuilder: (context, dateIndex) {
     final date = sortedDates[dateIndex];
     final dailyAppts = groupedItems[date]!;

     return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 12, left: 4),
        child: Row(
         children: [
          const Icon(Icons.event_note_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
           date,
           style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
           ),
          ),
         ],
        ),
       ),
       ...dailyAppts.map((appt) {
        return Padding(
         padding: const EdgeInsets.only(bottom: 12),
         child: _buildDoctorCard(appt)
           .animate()
           .fadeIn(duration: 250.ms),
        );
       }),
      ],
     );
    },
   ),
  );
 }

 Widget _buildList(List<ClinicalAppointmentModel> items) {
  if (items.isEmpty) {
   return Center(
    child: Column(
     mainAxisAlignment: MainAxisAlignment.center,
     children: [
      Container(
       padding: const EdgeInsets.all(16),
       decoration: const BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
       ),
       child: const Icon(Icons.calendar_today_outlined,
         color: AppColors.textMuted, size: 36),
      ),
      const SizedBox(height: 14),
      Text('No appointments in this category',
        style: AppTextStyles.headingSmall.copyWith(fontSize: 16)),
      const SizedBox(height: 6),
      Text('Appointment records will appear here.',
        style: AppTextStyles.caption),
     ],
    ),
   );
  }

  return RefreshIndicator(
   onRefresh: _loadAppointments,
   color: AppColors.primary,
   backgroundColor: AppColors.surface,
   child: ListView.separated(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    itemCount: items.length,
    separatorBuilder: (_, _) => const SizedBox(height: 12),
    itemBuilder: (context, index) {
     final appt = items[index];
     return _buildDoctorCard(appt)
       .animate()
       .fadeIn(duration: 250.ms, delay: Duration(milliseconds: index * 30));
    },
   ),
  );
 }

 Widget _buildDoctorCard(ClinicalAppointmentModel appt) {
  final status = appt.status.toUpperCase();
  final isRequested = status == 'REQUESTED';

  Color statusColor = AppColors.warning;
  String statusLabel = 'Request Pending';
  IconData statusIcon = Icons.pending_actions_rounded;

  if (status == 'APPROVED') {
   statusColor = AppColors.success;
   statusLabel = 'Accepted & Booked';
   statusIcon = Icons.check_circle_rounded;
  } else if (status == 'REJECTED' || status == 'CANCELLED') {
   statusColor = AppColors.error;
   statusLabel = status == 'REJECTED' ? 'Declined' : 'Cancelled';
   statusIcon = Icons.cancel_rounded;
  } else if (status == 'COMPLETED') {
   statusColor = AppColors.primary;
   statusLabel = 'Completed';
   statusIcon = Icons.verified_rounded;
  }

  return GlassCard(
   padding: const EdgeInsets.all(16),
   child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
     // Header: Patient Name & Status
     Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
       Row(
        children: [
         CircleAvatar(
          backgroundColor: isRequested
            ? AppColors.warning.withValues(alpha: 0.15)
            : AppColors.primary.withValues(alpha: 0.15),
          child: Icon(
           isRequested
             ? Icons.person_search_rounded
             : Icons.person_rounded,
           color: isRequested ? AppColors.warning : AppColors.primary,
           size: 20,
          ),
         ),
         const SizedBox(width: 10),
         Expanded(
          child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
            Text(
             appt.patientName ?? 'Patient ${appt.patientId}',
             style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
             ),
             maxLines: 1,
             overflow: TextOverflow.ellipsis,
            ),
            Text(
             'ID: ${appt.patientId}',
             style: AppTextStyles.caption
               .copyWith(color: AppColors.textMuted),
             maxLines: 1,
             overflow: TextOverflow.ellipsis,
            ),
           ],
          ),
         ),
        ],
       ),
       Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
         color: statusColor.withValues(alpha: 0.12),
         borderRadius: BorderRadius.circular(8),
         border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        ),
        child: Row(
         mainAxisSize: MainAxisSize.min,
         children: [
          Icon(statusIcon, color: statusColor, size: 13),
          const SizedBox(width: 4),
          Text(
           statusLabel,
           style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.w700,
            fontSize: 11,
           ),
          ),
         ],
        ),
       ),
      ],
     ),
     const SizedBox(height: 12),
     const Divider(height: 1, color: AppColors.border),
     const SizedBox(height: 12),

     // Date, Time & Consultation Mode
     Row(
      children: [
       Expanded(
        child: Row(
         children: [
          const Icon(Icons.calendar_today_rounded,
            size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(appt.appointmentDate,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary)),
         ],
        ),
       ),
       Expanded(
        child: Row(
         children: [
          const Icon(Icons.access_time_rounded,
            size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(appt.startTime,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary)),
         ],
        ),
       ),
       Expanded(
        child: Row(
         children: [
          Icon(
            appt.consultationType == 'Video'
              ? Icons.videocam_rounded
              : Icons.local_hospital_rounded,
            size: 14,
            color: AppColors.primary),
          const SizedBox(width: 6),
          Text(appt.consultationType,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary)),
         ],
        ),
       ),
      ],
     ),

     // Complaint / Reason banner
     if (appt.reason.isNotEmpty) ...[
      const SizedBox(height: 10),
      Container(
       width: double.infinity,
       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
       decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
       ),
       child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         const Text('Chief Complaint / Symptoms:',
           style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
         const SizedBox(height: 2),
         Text(
          appt.reason,
          style: const TextStyle(
            fontSize: 12, color: AppColors.textSecondary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
         ),
        ],
       ),
      ),
     ],

     const SizedBox(height: 12),

     // Action Buttons
     Row(
      children: [
       // AI Summary Button
       Expanded(
        child: OutlinedButton.icon(
         onPressed: () => _showAISummaryModal(appt),
         icon: const Icon(Icons.auto_awesome, size: 14),
         label: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('View AI Summary',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
         ),
         style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(8),
          ),
         ),
        ),
       ),

       // If Requested, show Accept and Decline buttons
       if (isRequested) ...[
        const SizedBox(width: 8),
        IconButton(
         onPressed: () => _handleDecline(appt.appointmentId),
         icon: const Icon(Icons.close_rounded, color: AppColors.error),
         tooltip: 'Decline Request',
         style: IconButton.styleFrom(
          backgroundColor: AppColors.error.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(8),
          ),
         ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
         onPressed: () => _handleAccept(appt.appointmentId),
         icon: const Icon(Icons.check_rounded, size: 16),
         label: const Text('Accept',
           style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
         style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(8),
          ),
         ),
        ),
       ],
       
       // If Approved, show Video Call Button
       if (status == 'APPROVED') ...[
        const SizedBox(width: 8),
        Container(
         decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
         ),
         child: ZegoSendCallInvitationButton(
          isVideoCall: true,
          invitees: [
           ZegoUIKitUser(
            id: appt.patientId,
            name: appt.patientName ?? 'Patient ${appt.patientId}',
           ),
          ],
          iconSize: const Size(20, 20),
          buttonSize: const Size(40, 40),
         ),
        ),
       ],
      ],
     ),
      const SizedBox(height: 10),
      SizedBox(
       width: double.infinity,
       child: OutlinedButton.icon(
        onPressed: () {
         context.push('${AppRoutes.doctorPatientProfile}/${appt.patientId}?name=${Uri.encodeComponent(appt.patientName ?? "Patient")}');
        },
        icon: const Icon(Icons.person_rounded, size: 14),
        label: const Text('View Full Profile', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
         foregroundColor: AppColors.primary,
         side: const BorderSide(color: AppColors.primary),
         padding: const EdgeInsets.symmetric(vertical: 10),
         shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
         ),
        ),
       ),
      ),
     ],
   ),
  );
 }
}
