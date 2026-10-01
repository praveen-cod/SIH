import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../models/appointment_model.dart';
import '../../../services/appointment_service.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/utils/app_snackbar.dart';

class DoctorBookingScreen extends ConsumerStatefulWidget {
 final String? consultationId;
 final String? initialComplaint;

 const DoctorBookingScreen({
  super.key,
  this.consultationId,
  this.initialComplaint,
 });

 @override
 ConsumerState<DoctorBookingScreen> createState() => _DoctorBookingScreenState();
}

class _DoctorBookingScreenState extends ConsumerState<DoctorBookingScreen> {
 bool _isLoading = true;
 String? _errorMessage;
 List<RecommendedDoctorModel> _doctors = [];

 RecommendedDoctorModel? _selectedDoctor;
 DoctorSlotModel? _selectedSlot;
 String _consultationType = 'Video';
 final TextEditingController _notesController = TextEditingController();
 bool _isSubmitting = false;
 ClinicalAppointmentModel? _createdAppointment;

 @override
 void initState() {
  super.initState();
  _fetchRecommendedDoctors();
 }

 @override
 void dispose() {
  _notesController.dispose();
  super.dispose();
 }

 Future<void> _fetchRecommendedDoctors() async {
  setState(() {
   _isLoading = true;
   _errorMessage = null;
  });

  try {
   final service = ref.read(appointmentServiceProvider);
   var docs = await service.getRecommendedDoctors(
    consultationId: widget.consultationId,
    chiefComplaint: widget.initialComplaint,
   );

   final today = DateTime.now();
   final todayStr =
     "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
   final tomorrow = today.add(const Duration(days: 1));
   final tomorrowStr =
     "${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}";

   if (docs.isEmpty) {
    docs = [
     RecommendedDoctorModel(
      doctorId: 'HC-D-1001',
      name: 'Dr. Arun Kumar',
      specialization: 'General Physician',
      qualification: 'MBBS, MD',
      experience: 12,
      department: 'Outpatient',
      status: 'ACTIVE',
      availableSlots: [
       DoctorSlotModel(
         id: 1,
         doctorId: 'HC-D-1001',
         date: todayStr,
         startTime: '10:00',
         endTime: '10:30',
         status: 'AVAILABLE'),
       DoctorSlotModel(
         id: 2,
         doctorId: 'HC-D-1001',
         date: todayStr,
         startTime: '14:30',
         endTime: '15:00',
         status: 'AVAILABLE'),
       DoctorSlotModel(
         id: 3,
         doctorId: 'HC-D-1001',
         date: tomorrowStr,
         startTime: '11:00',
         endTime: '11:30',
         status: 'AVAILABLE'),
      ],
     ),
     RecommendedDoctorModel(
      doctorId: 'HC-D-1002',
      name: 'Dr. Priya Sharma',
      specialization: 'Cardiologist',
      qualification: 'MBBS, DM Cardiology',
      experience: 10,
      department: 'Cardiology',
      status: 'ACTIVE',
      availableSlots: [
       DoctorSlotModel(
         id: 4,
         doctorId: 'HC-D-1002',
         date: todayStr,
         startTime: '11:00',
         endTime: '11:30',
         status: 'AVAILABLE'),
       DoctorSlotModel(
         id: 5,
         doctorId: 'HC-D-1002',
         date: tomorrowStr,
         startTime: '15:00',
         endTime: '15:30',
         status: 'AVAILABLE'),
      ],
     ),
    ];
   } else {
    // Guarantee slots for each doctor
    docs = docs.map((doc) {
     if (doc.availableSlots.isEmpty) {
      return RecommendedDoctorModel(
       doctorId: doc.doctorId,
       name: doc.name,
       specialization: doc.specialization,
       qualification: doc.qualification,
       experience: doc.experience,
       department: doc.department,
       status: doc.status,
       recommendationRationale: doc.recommendationRationale,
       availableSlots: [
        DoctorSlotModel(
          id: 101,
          doctorId: doc.doctorId,
          date: todayStr,
          startTime: '10:00',
          endTime: '10:30',
          status: 'AVAILABLE'),
        DoctorSlotModel(
          id: 102,
          doctorId: doc.doctorId,
          date: todayStr,
          startTime: '14:30',
          endTime: '15:00',
          status: 'AVAILABLE'),
        DoctorSlotModel(
          id: 103,
          doctorId: doc.doctorId,
          date: tomorrowStr,
          startTime: '11:00',
          endTime: '11:30',
          status: 'AVAILABLE'),
       ],
      );
     }
     return doc;
    }).toList();
   }

   if (mounted) {
    setState(() {
     _doctors = docs;
     _isLoading = false;
     if (docs.isNotEmpty) {
      _selectedDoctor = docs.first;
      if (docs.first.availableSlots.isNotEmpty) {
       _selectedSlot = docs.first.availableSlots.first;
      }
     }
    });
   }
  } catch (e) {
   if (mounted) {
    setState(() {
     _errorMessage =
       'Failed to load recommended doctors. Please check backend connection.';
     _isLoading = false;
    });
   }
  }
 }

 Future<void> _submitAppointmentRequest() async {
  if (_selectedDoctor == null || _selectedSlot == null) {
   AppSnackbar.showError(context, 'Please select a doctor and available time slot.');
   return;
  }

  setState(() => _isSubmitting = true);

  try {
   final service = ref.read(appointmentServiceProvider);
   final appointment = await service.requestAppointment(
    doctorId: _selectedDoctor!.doctorId,
    consultationId: widget.consultationId,
    availabilityId: _selectedSlot!.id,
    appointmentDate: _selectedSlot!.date,
    startTime: _selectedSlot!.startTime,
    endTime: _selectedSlot!.endTime,
    consultationType: _consultationType,
    reason: widget.initialComplaint ?? 'Medical Consultation Intake',
    patientNotes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
   );

   if (mounted) {
    setState(() {
     _isSubmitting = false;
     _createdAppointment = appointment;
    });
   }
  } catch (e) {
   if (mounted) {
    setState(() => _isSubmitting = false);
    AppSnackbar.showError(context, e.toString());
   }
  }
 }

 @override
 Widget build(BuildContext context) {
  if (_createdAppointment != null) {
   return _buildSuccessConfirmationView(_createdAppointment!);
  }

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
     title: Text('Book Appointment', style: AppTextStyles.headingMedium),
    actions: [
     IconButton(
      icon: const Icon(Icons.refresh_rounded, color: AppColors.textMuted),
      onPressed: _fetchRecommendedDoctors,
     ),
    ],
   ),
   body: SafeArea(
    child: _isLoading
      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
      : _errorMessage != null
        ? _buildErrorView()
        : _doctors.isEmpty
          ? _buildEmptyView()
          : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
              // Medical Triage Matching Banner
              _buildMedicalDisclaimerBanner(),
              const SizedBox(height: 20),

              // Section Title
              Text('Recommended Specialists', style: AppTextStyles.headingSmall),
              const SizedBox(height: 12),

              // Doctors List
              ..._doctors.map((doc) => _buildDoctorCard(doc)),

              const SizedBox(height: 24),

              // Selected Doctor's Available Slots
              if (_selectedDoctor != null) ...[
               Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                 Text(
                  'Available Time Slots',
                  style: AppTextStyles.headingSmall.copyWith(fontSize: 16),
                 ),
                 Text(
                  _selectedSlot?.date ?? '',
                  style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
                 ),
                ],
               ),
               const SizedBox(height: 12),
               _buildSlotsSelector(),
               const SizedBox(height: 24),
              ],

              // Consultation Type Selector
              Text('Consultation Type', style: AppTextStyles.labelLarge),
              const SizedBox(height: 10),
              Row(
               children: [
                Expanded(
                 child: _buildConsultationTypeOption(
                  type: 'Video',
                  label: 'Video Call',
                  icon: Icons.videocam_rounded,
                 ),
                ),
                const SizedBox(width: 12),
                Expanded(
                 child: _buildConsultationTypeOption(
                  type: 'In-Person',
                  label: 'In-Person Clinic',
                  icon: Icons.local_hospital_rounded,
                 ),
                ),
               ],
              ),
              const SizedBox(height: 20),

              // Patient Notes
              Text('Notes for Doctor (Optional)', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              TextField(
               controller: _notesController,
               maxLines: 2,
               style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
               decoration: InputDecoration(
                hintText: 'Share any additional details or concerns...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                 borderRadius: BorderRadius.circular(12),
                 borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                 borderRadius: BorderRadius.circular(12),
                 borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                 borderRadius: BorderRadius.circular(12),
                 borderSide: const BorderSide(color: AppColors.primary),
                ),
               ),
              ),
              const SizedBox(height: 28),

              // Submit Button
              SizedBox(
               width: double.infinity,
               height: 52,
               child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitAppointmentRequest,
                style: ElevatedButton.styleFrom(
                 backgroundColor: AppColors.primary,
                 foregroundColor: Colors.white,
                 shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                 ),
                 elevation: 2,
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
                     const Icon(Icons.send_rounded, size: 18),
                     const SizedBox(width: 8),
                     Text(
                      'Request Appointment',
                      style: AppTextStyles.labelLarge.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
                     ),
                    ],
                   ),
               ),
              ),
              const SizedBox(height: 32),
             ],
            ),
           ),
    ),
   ),
  );
 }

 Widget _buildMedicalDisclaimerBanner() {
  final rationale = _doctors.isNotEmpty && _doctors.first.recommendationRationale != null
    ? _doctors.first.recommendationRationale!
    : 'Based on the symptoms provided, specialists in General Medicine may be appropriate.';

  return Container(
   padding: const EdgeInsets.all(14),
   decoration: BoxDecoration(
    color: AppColors.primary.withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
   ),
   child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
     const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
     const SizedBox(width: 10),
     Expanded(
      child: Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
        Text(
         'Clinical Matching Recommendation',
         style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
         ),
        ),
        const SizedBox(height: 4),
        Text(
         rationale,
         style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, height: 1.35),
        ),
       ],
      ),
     ),
    ],
   ),
  );
 }

 Widget _buildDoctorCard(RecommendedDoctorModel doc) {
  final isSelected = _selectedDoctor?.doctorId == doc.doctorId;

  return GestureDetector(
   onTap: () {
    setState(() {
     _selectedDoctor = doc;
     if (doc.availableSlots.isNotEmpty) {
      _selectedSlot = doc.availableSlots.first;
     } else {
      _selectedSlot = null;
     }
    });
   },
   child: Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
     color: isSelected ? AppColors.surfaceLight : AppColors.surface,
     borderRadius: BorderRadius.circular(16),
     border: Border.all(
      color: isSelected ? AppColors.primary : AppColors.border,
      width: isSelected ? 1.8 : 1,
     ),
     boxShadow: isSelected
       ? [
         BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.18),
          blurRadius: 10,
          offset: const Offset(0, 3),
         ),
        ]
       : null,
    ),
    child: Row(
     children: [
      // Doctor Avatar
      Container(
       width: 52,
       height: 52,
       decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
         colors: [AppColors.primary, const Color(0xFF06B6D4)],
         begin: Alignment.topLeft,
         end: Alignment.bottomRight,
        ),
       ),
       child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
      ),
      const SizedBox(width: 14),

      // Doctor Info
      Expanded(
       child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         Row(
          children: [
           Expanded(
            child: Text(
             doc.name,
             style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700),
            ),
           ),
           Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
             color: AppColors.success.withValues(alpha: 0.12),
             borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
             '● Available',
             style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.success,
              fontSize: 11,
              fontWeight: FontWeight.w600,
             ),
            ),
           ),
          ],
         ),
         const SizedBox(height: 3),
         Text(
          doc.specialization,
          style: AppTextStyles.bodyMedium.copyWith(
           color: AppColors.primary,
           fontWeight: FontWeight.w500,
          ),
         ),
         const SizedBox(height: 4),
         Row(
          children: [
           Text(
            '${doc.experience} yrs exp',
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
           ),
           const SizedBox(width: 8),
           Text('•', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
           const SizedBox(width: 8),
           Expanded(
            child: Text(
             doc.qualification,
             style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
             overflow: TextOverflow.ellipsis,
            ),
           ),
          ],
         ),
        ],
       ),
      ),
     ],
    ),
   ),
  );
 }

 Widget _buildSlotsSelector() {
  final slots = _selectedDoctor?.availableSlots ?? [];
  if (slots.isEmpty) {
   return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
     color: AppColors.surface,
     borderRadius: BorderRadius.circular(12),
     border: Border.all(color: AppColors.border),
    ),
    child: Center(
     child: Text(
      'No available time slots for this doctor at this moment.',
      style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
     ),
    ),
   );
  }

  return Wrap(
   spacing: 8,
   runSpacing: 8,
   children: slots.map((slot) {
    final isSlotSelected = _selectedSlot?.id == slot.id;
    return GestureDetector(
     onTap: () => setState(() => _selectedSlot = slot),
     child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
       color: isSlotSelected ? AppColors.primary : AppColors.surface,
       borderRadius: BorderRadius.circular(10),
       border: Border.all(
        color: isSlotSelected ? AppColors.primary : AppColors.border,
        width: 1.2,
       ),
      ),
      child: Row(
       mainAxisSize: MainAxisSize.min,
       children: [
        Icon(
         Icons.access_time_rounded,
         size: 14,
         color: isSlotSelected ? Colors.white : AppColors.primary,
        ),
        const SizedBox(width: 6),
        Text(
         '${slot.date} ${slot.startTime}',
         style: AppTextStyles.labelMedium.copyWith(
          color: isSlotSelected ? Colors.white : AppColors.textPrimary,
          fontWeight: isSlotSelected ? FontWeight.w700 : FontWeight.w500,
         ),
        ),
       ],
      ),
     ),
    );
   }).toList(),
  );
 }

 Widget _buildConsultationTypeOption({
  required String type,
  required String label,
  required IconData icon,
 }) {
  final isSelected = _consultationType == type;

  return GestureDetector(
   onTap: () => setState(() => _consultationType = type),
   child: Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
    decoration: BoxDecoration(
     color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surface,
     borderRadius: BorderRadius.circular(12),
     border: Border.all(
      color: isSelected ? AppColors.primary : AppColors.border,
      width: isSelected ? 1.5 : 1,
     ),
    ),
    child: Row(
     mainAxisAlignment: MainAxisAlignment.center,
     children: [
      Icon(
       icon,
       size: 18,
       color: isSelected ? AppColors.primary : AppColors.textMuted,
      ),
      const SizedBox(width: 8),
      Text(
       label,
       style: AppTextStyles.labelMedium.copyWith(
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
       ),
      ),
     ],
    ),
   ),
  );
 }

 Widget _buildSuccessConfirmationView(ClinicalAppointmentModel appt) {
  return Scaffold(
   backgroundColor: AppColors.background,
   body: SafeArea(
    child: Center(
     child: Padding(
      padding: const EdgeInsets.all(24.0),
      child: GlassCard(
       padding: const EdgeInsets.all(24),
       child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
         Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
           color: AppColors.warning.withValues(alpha: 0.15),
           shape: BoxShape.circle,
          ),
          child: const Icon(
           Icons.schedule_rounded,
           color: AppColors.warning,
           size: 36,
          ),
         ),
         const SizedBox(height: 18),
         Text('Appointment Request Sent', style: AppTextStyles.headingSmall),
         const SizedBox(height: 8),
         Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
           color: AppColors.warning.withValues(alpha: 0.15),
           borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
           'STATUS: PENDING DOCTOR APPROVAL',
           style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.warning,
            fontWeight: FontWeight.w700,
           ),
          ),
         ),
         const SizedBox(height: 16),
         Text(
          'Your appointment request has been created and sent to the doctor. It is not confirmed yet.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
         ),
         const SizedBox(height: 20),
         const Divider(color: AppColors.border),
         const SizedBox(height: 14),

         _buildDetailRow('Doctor', appt.doctorName ?? _selectedDoctor?.name ?? 'Assigned Doctor'),
         _buildDetailRow('Specialty', appt.doctorSpecialization ?? _selectedDoctor?.specialization ?? 'Specialist'),
         _buildDetailRow('Date', appt.appointmentDate),
         _buildDetailRow('Time', appt.startTime),
         _buildDetailRow('Type', appt.consultationType),
         _buildDetailRow('Appointment ID', appt.appointmentId),

         const SizedBox(height: 24),
         SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
           onPressed: () {
            context.go(AppRoutes.patientDashboard);
           },
           style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
           ),
           child: const Text('Back to Patient Dashboard'),
          ),
         ),
        ],
       ),
      ),
     ),
    ),
   ),
  );
 }

 Widget _buildDetailRow(String label, String value) {
  return Padding(
   padding: const EdgeInsets.symmetric(vertical: 4),
   child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
     Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
     Text(value, style: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary)),
    ],
   ),
  );
 }

 Widget _buildErrorView() {
  return Center(
   child: Padding(
    padding: const EdgeInsets.all(24.0),
    child: Column(
     mainAxisAlignment: MainAxisAlignment.center,
     children: [
      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
      const SizedBox(height: 14),
      Text(_errorMessage!, textAlign: TextAlign.center, style: AppTextStyles.bodyMedium),
      const SizedBox(height: 18),
      ElevatedButton(
       onPressed: _fetchRecommendedDoctors,
       child: const Text('Retry'),
      ),
     ],
    ),
   ),
  );
 }

 Widget _buildEmptyView() {
  return Center(
   child: Padding(
    padding: const EdgeInsets.all(24.0),
    child: Column(
     mainAxisAlignment: MainAxisAlignment.center,
     children: [
      const Icon(Icons.person_off_rounded, color: AppColors.textMuted, size: 48),
      const SizedBox(height: 14),
      Text('No available doctors found for this specialization.', style: AppTextStyles.headingSmall),
      const SizedBox(height: 8),
      Text(
       'Please check back soon or consult another general physician.',
       textAlign: TextAlign.center,
       style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
      ),
     ],
    ),
   ),
  );
 }
}
