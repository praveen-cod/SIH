import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../models/appointment_model.dart';
import '../../../models/consultation_model.dart';
import '../../../services/appointment_service.dart';
import '../../../shared/widgets/glass_card.dart';

/// Screen for patients to view all their booked, pending, and past appointments
class PatientAppointmentsScreen extends ConsumerStatefulWidget {
 const PatientAppointmentsScreen({super.key});

 @override
 ConsumerState<PatientAppointmentsScreen> createState() =>
   _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState
  extends ConsumerState<PatientAppointmentsScreen>
  with SingleTickerProviderStateMixin {
 late TabController _tabController;
 List<ClinicalAppointmentModel> _appointments = [];
 bool _isLoading = true;
 String? _errorMessage;

 @override
 void initState() {
  super.initState();
  _tabController = TabController(length: 4, vsync: this);
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
   final appts = await service.getPatientAppointments().timeout(
      const Duration(seconds: 8),
      onTimeout: () => <ClinicalAppointmentModel>[],
     );

   if (mounted) {
    setState(() {
     _appointments = appts;
     _isLoading = false;
    });
   }
  } catch (e) {
   if (mounted) {
    setState(() {
     _errorMessage = 'Unable to load appointments. Please check connection.';
     _isLoading = false;
    });
   }
  }
 }

 void _showSummaryDetails(String appointmentId) async {
  showDialog(
   context: context,
   builder: (ctx) {
    return FutureBuilder<ConsultationSummaryModel?>(
     future: ref
       .read(appointmentServiceProvider)
       .getAppointmentConsultationSummary(appointmentId),
     builder: (context, snapshot) {
      final summary = snapshot.data;
      final isLoading = snapshot.connectionState == ConnectionState.waiting;

      return Dialog(
       backgroundColor: AppColors.backgroundSecondary,
       shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
       ),
       child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
         padding: const EdgeInsets.all(20),
         child: SingleChildScrollView(
          child: Column(
           mainAxisSize: MainAxisSize.min,
           crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
             const Row(
              children: [
               Icon(Icons.assignment_turned_in_rounded,
                 color: AppColors.primary, size: 20),
               SizedBox(width: 8),
               Text('Consultation Summary',
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
           const SizedBox(height: 12),
           if (isLoading)
            const Center(
             child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(
                color: AppColors.primary),
             ),
            )
           else if (summary != null) ...[
            _summaryRow('Chief Complaint', summary.chiefComplaint),
            const SizedBox(height: 8),
            if (summary.symptoms.isNotEmpty) ...[
             const Text('Symptoms:',
               style: TextStyle(
                 fontSize: 12, color: AppColors.textMuted)),
             const SizedBox(height: 4),
             Wrap(
              spacing: 6,
              runSpacing: 4,
              children: summary.symptoms
                .map((s) => Chip(
                   label: Text(s,
                     style: const TextStyle(fontSize: 11)),
                   backgroundColor: AppColors.surface,
                  ))
                .toList(),
             ),
             const SizedBox(height: 8),
            ],
            if (summary.duration != null) _summaryRow('Duration', summary.duration!),
            const SizedBox(height: 6),
            if (summary.severity != null) _summaryRow('Severity', summary.severity!),
            if (summary.clinicalSummary != null) ...[
             const SizedBox(height: 8),
             _summaryRow('Clinical Assessment',
               summary.clinicalSummary!),
            ],
           ] else ...[
            const Padding(
             padding: EdgeInsets.all(16.0),
             child: Text(
              'No AI intake summary attached to this appointment.',
              style: TextStyle(color: AppColors.textSecondary),
             ),
            ),
           ],
          ],
         ),
        ),
       ),
      ),
     );
     },
    );
   },
  );
 }

 Widget _summaryRow(String label, String value) {
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
  final bookedAppointments = _appointments
    .where((a) => a.status.toUpperCase() == 'APPROVED')
    .toList();
  final requestedAppointments = _appointments
    .where((a) => a.status.toUpperCase() == 'REQUESTED')
    .toList();
  final pastAppointments = _appointments
    .where((a) =>
      a.status.toUpperCase() == 'COMPLETED' ||
      a.status.toUpperCase() == 'CANCELLED' ||
      a.status.toUpperCase() == 'REJECTED')
    .toList();

  return PopScope(
   canPop: context.canPop(),
   onPopInvokedWithResult: (didPop, result) {
    if (!didPop) {
     context.go(AppRoutes.patientDashboard);
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
        context.go(AppRoutes.patientDashboard);
       }
      },
     ),
     title: Text('My Appointments', style: AppTextStyles.headingMedium),
    actions: [
     IconButton(
      icon: const Icon(Icons.refresh_rounded, color: AppColors.textMuted),
      onPressed: _loadAppointments,
     ),
     TextButton(
      onPressed: () => context.push(AppRoutes.bookDoctor),
      child: const Text(
       '+ Book New',
       style: TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
       ),
      ),
     ),
     const SizedBox(width: 8),
    ],
    bottom: TabBar(
     controller: _tabController,
     indicatorColor: AppColors.primary,
     indicatorWeight: 3,
     labelColor: AppColors.primary,
     unselectedLabelColor: AppColors.textMuted,
     labelStyle:
       const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
     tabs: [
      Tab(text: 'All (${_appointments.length})'),
      Tab(text: 'Booked (${bookedAppointments.length})'),
      Tab(text: 'Pending (${requestedAppointments.length})'),
      Tab(text: 'Past (${pastAppointments.length})'),
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
           _buildList(_appointments),
           _buildList(bookedAppointments),
           _buildList(requestedAppointments),
           _buildList(pastAppointments),
          ],
         ),
   ),
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
       decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
       ),
       child: const Icon(Icons.event_note_rounded,
         color: AppColors.textMuted, size: 40),
      ),
      const SizedBox(height: 16),
      Text('No appointments found', style: AppTextStyles.headingSmall),
      const SizedBox(height: 8),
      Text(
       'Your appointments in this category will show up here.',
       style: AppTextStyles.caption,
      ),
      const SizedBox(height: 20),
      ElevatedButton.icon(
       onPressed: () => context.push(AppRoutes.bookDoctor),
       icon: const Icon(Icons.calendar_month_rounded, size: 18),
       label: const Text('Book Doctor Appointment'),
       style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
       ),
      ),
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
     return _buildAppointmentCard(appt)
       .animate()
       .fadeIn(duration: 300.ms, delay: Duration(milliseconds: index * 40));
    },
   ),
  );
 }

 Widget _buildAppointmentCard(ClinicalAppointmentModel appt) {
  final status = appt.status.toUpperCase();
  Color statusColor = AppColors.warning;
  String statusLabel = 'Pending Doctor Approval';
  IconData statusIcon = Icons.schedule_rounded;

  if (status == 'APPROVED') {
   statusColor = AppColors.success;
   statusLabel = 'Booked & Confirmed';
   statusIcon = Icons.check_circle_rounded;
  } else if (status == 'REJECTED' || status == 'CANCELLED') {
   statusColor = AppColors.error;
   statusLabel = status == 'REJECTED' ? 'Declined by Doctor' : 'Cancelled';
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
     // Top Row: Doctor Info & Status Badge
     Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
        child: const Icon(Icons.medical_services_rounded,
          color: AppColors.primary, size: 20),
       ),
       const SizedBox(width: 12),
       Expanded(
        child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
          Text(
           appt.doctorName ?? 'Doctor ${appt.doctorId}',
           style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
           ),
          ),
          Text(
           appt.doctorSpecialization ?? 'Specialist',
           style: AppTextStyles.caption
             .copyWith(color: AppColors.primaryLight),
          ),
         ],
        ),
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
          Flexible(
           child: Text(
            statusLabel,
            style: TextStyle(
             color: statusColor,
             fontWeight: FontWeight.w700,
             fontSize: 11,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
           ),
          ),
         ],
        ),
       ),
      ],
     ),
     const SizedBox(height: 14),
     const Divider(height: 1, color: AppColors.border),
     const SizedBox(height: 12),

     // Date & Time details
     Row(
      children: [
       Expanded(
        child: _miniInfo(Icons.calendar_today_rounded, 'Date',
          appt.appointmentDate),
       ),
       Expanded(
        child: _miniInfo(
          Icons.access_time_rounded, 'Time', appt.startTime),
       ),
       Expanded(
        child: _miniInfo(appt.consultationType == 'Video'
          ? Icons.videocam_rounded
          : Icons.local_hospital_rounded,
          'Type', appt.consultationType),
       ),
      ],
     ),

     // Reason / Intake complaint
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
         const Text('Consultation Reason / Symptoms:',
           style: TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
         const SizedBox(height: 2),
         Text(
          appt.reason,
          style: const TextStyle(
            fontSize: 12.5, color: AppColors.textSecondary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
         ),
        ],
       ),
      ),
     ],

     if (appt.rejectionReason != null && appt.rejectionReason!.isNotEmpty) ...[
      const SizedBox(height: 8),
      Container(
       width: double.infinity,
       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
       decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
       ),
       child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         const Icon(Icons.info_outline, color: AppColors.error, size: 15),
         const SizedBox(width: 6),
         Expanded(
          child: Text(
           'Doctor note: ${appt.rejectionReason}',
           style: const TextStyle(
             fontSize: 11.5, color: AppColors.errorLight),
          ),
         ),
        ],
       ),
      ),
     ],

     const SizedBox(height: 12),

     // Actions row
     Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
       Expanded(
        child: Text(
         'ID: ${appt.appointmentId}',
         style: AppTextStyles.caption.copyWith(fontSize: 11),
         maxLines: 1,
         overflow: TextOverflow.ellipsis,
        ),
       ),
       if (appt.consultationId != null &&
         appt.consultationId!.isNotEmpty)
        TextButton.icon(
         onPressed: () => _showSummaryDetails(appt.appointmentId),
         icon: const Icon(Icons.description_outlined, size: 15),
         label: const Text('View AI Summary',
           style: TextStyle(fontSize: 12)),
         style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: 8, vertical: 4),
         ),
        ),
      ],
     ),
    ],
   ),
  );
 }

 Widget _miniInfo(IconData icon, String title, String val) {
  return Row(
   children: [
    Icon(icon, size: 14, color: AppColors.primary),
    const SizedBox(width: 6),
    Column(
     crossAxisAlignment: CrossAxisAlignment.start,
     children: [
      Text(title,
        style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
      Text(val,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary)),
     ],
    ),
   ],
  );
 }
}
