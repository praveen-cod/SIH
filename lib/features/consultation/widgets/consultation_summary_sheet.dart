import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/consultation_model.dart';
import '../../../repositories/consultation_repository.dart';
import '../../../shared/widgets/glass_card.dart';

/// Modal bottom sheet displaying structured consultation summary with in-place Patient Editing
class ConsultationSummarySheet extends ConsumerStatefulWidget {
 final ConsultationSummaryModel summary;
 final void Function(ConsultationSummaryModel summary) onBookDoctor;
 final void Function(ConsultationSummaryModel updated)? onSummaryUpdated;

 const ConsultationSummarySheet({
  super.key,
  required this.summary,
  required this.onBookDoctor,
  this.onSummaryUpdated,
 });

 @override
 ConsumerState<ConsultationSummarySheet> createState() =>
   _ConsultationSummarySheetState();
}

class _ConsultationSummarySheetState
  extends ConsumerState<ConsultationSummarySheet> {
 late ConsultationSummaryModel _currentSummary;
 bool _isEditing = false;

 late TextEditingController _complaintController;
 late TextEditingController _durationController;
 late TextEditingController _notesController;
 final TextEditingController _newSymptomController = TextEditingController();
 late List<String> _symptoms;
 late String _severity;
 bool _wasEdited = false;

 final List<String> _severityOptions = [
  'Mild',
  'Moderate',
  'Severe',
  'Critical',
 ];

 @override
 void initState() {
  super.initState();
  _currentSummary = widget.summary;
  _initControllers();
 }

 void _initControllers() {
  _complaintController =
    TextEditingController(text: _currentSummary.chiefComplaint);
  _durationController =
    TextEditingController(text: _currentSummary.duration ?? '');
  _notesController = TextEditingController(
    text: _currentSummary.clinicalSummary ?? '');
  _symptoms = List<String>.from(_currentSummary.symptoms);
  _severity = (_currentSummary.severity?.isNotEmpty ?? false)
    ? _currentSummary.severity!
    : 'Moderate';
  if (!_severityOptions.contains(_severity)) {
   _severityOptions.insert(0, _severity);
  }
 }

 @override
 void dispose() {
  _complaintController.dispose();
  _durationController.dispose();
  _notesController.dispose();
  _newSymptomController.dispose();
  super.dispose();
 }

 void _saveEdits() {
  final updatedComplaint = _complaintController.text.trim().isNotEmpty
    ? _complaintController.text.trim()
    : _currentSummary.chiefComplaint;
  final updatedDuration = _durationController.text.trim().isNotEmpty
    ? _durationController.text.trim()
    : _currentSummary.duration;
  final updatedNotes = _notesController.text.trim().isNotEmpty
    ? _notesController.text.trim()
    : _currentSummary.clinicalSummary;

  final updated = _currentSummary.copyWith(
   chiefComplaint: updatedComplaint,
   symptoms: _symptoms,
   duration: updatedDuration,
   severity: _severity,
   clinicalSummary: updatedNotes,
  );

  setState(() {
   _currentSummary = updated;
   _isEditing = false;
   _wasEdited = true;
  });

  ref.read(consultationProvider.notifier).updateSummary(updated);
  widget.onSummaryUpdated?.call(updated);

  ScaffoldMessenger.of(context).showSnackBar(
   SnackBar(
    content: const Row(
     children: [
      Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
      SizedBox(width: 8),
      Text('Intake summary updated successfully!'),
     ],
    ),
    backgroundColor: AppColors.surface,
    duration: const Duration(seconds: 2),
    behavior: SnackBarBehavior.floating,
   ),
  );
 }

 void _addSymptom() {
  final text = _newSymptomController.text.trim();
  if (text.isNotEmpty && !_symptoms.contains(text)) {
   setState(() {
    _symptoms.add(text);
   });
   _newSymptomController.clear();
  }
 }

 void _removeSymptom(String s) {
  setState(() {
   _symptoms.remove(s);
  });
 }

 @override
 Widget build(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  final screenWidth = mediaQuery.size.width;
  final maxSheetWidth = screenWidth > 660 ? 620.0 : screenWidth;

  return Center(
   child: ConstrainedBox(
    constraints: BoxConstraints(maxWidth: maxSheetWidth),
    child: Container(
     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
     decoration: const BoxDecoration(
      color: AppColors.backgroundSecondary,
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      border: Border(
       top: BorderSide(color: AppColors.border, width: 1.5),
      ),
     ),
     child: SafeArea(
      child: SingleChildScrollView(
       child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         Center(
          child: Container(
           width: 40,
           height: 4,
           decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(2),
           ),
          ),
         ),
         const SizedBox(height: 18),

         // Header with Edit Toggle
         Row(
          children: [
           Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
             color: AppColors.primary.withValues(alpha: 0.15),
             borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
             _isEditing
               ? Icons.edit_note_rounded
               : Icons.assignment_turned_in_rounded,
             color: AppColors.primary,
             size: 22,
            ),
           ),
           const SizedBox(width: 12),
           Expanded(
            child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
              Text(
               _isEditing
                 ? 'Edit Consultation Summary'
                 : 'Pre-Consultation Summary',
               style: AppTextStyles.headingSmall
                 .copyWith(fontSize: 17),
              ),
              Text(
               _isEditing
                 ? 'Review or adjust AI-extracted medical details'
                 : 'Structured medical intake record',
               style: AppTextStyles.caption,
              ),
             ],
            ),
           ),
           TextButton.icon(
            onPressed: () {
             setState(() {
              _isEditing = !_isEditing;
             });
            },
            icon: Icon(
             _isEditing ? Icons.close_rounded : Icons.edit_rounded,
             size: 16,
             color: AppColors.primary,
            ),
            label: Text(
             _isEditing ? 'Cancel' : 'Edit',
             style: AppTextStyles.labelMedium
               .copyWith(color: AppColors.primary),
            ),
            style: TextButton.styleFrom(
             padding: const EdgeInsets.symmetric(
               horizontal: 10, vertical: 6),
             backgroundColor:
               AppColors.primary.withValues(alpha: 0.1),
             shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
             ),
            ),
           ),
          ],
         ),
         const SizedBox(height: 16),

         // Patient Edits Notice Banner
         if (_wasEdited)
          Container(
           margin: const EdgeInsets.only(bottom: 14),
           padding: const EdgeInsets.symmetric(
             horizontal: 12, vertical: 8),
           decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.3)),
           ),
           child: Row(
            children: [
             const Icon(Icons.check_circle_outline_rounded,
               color: AppColors.success, size: 16),
             const SizedBox(width: 8),
             Expanded(
              child: Text(
               'Summary verified & modified by patient',
               style: AppTextStyles.caption.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
               ),
              ),
             ),
            ],
           ),
          ),

         // Emergency Banner if flagged
         if (_currentSummary.isEmergency)
          Container(
           margin: const EdgeInsets.only(bottom: 16),
           padding: const EdgeInsets.all(12),
           decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.error.withValues(alpha: 0.4)),
           ),
           child: Row(
            children: [
             const Icon(Icons.warning_rounded,
               color: AppColors.error, size: 20),
             const SizedBox(width: 10),
             Expanded(
              child: Text(
               'Emergency Flagged: Urgent medical evaluation advised',
               style: AppTextStyles.caption.copyWith(
                color: AppColors.errorLight,
                fontWeight: FontWeight.w600,
               ),
              ),
             ),
            ],
           ),
          ),

         // Content: Either Edit Form OR Clean Summary Card
         if (_isEditing)
          _buildEditForm()
         else
          _buildSummaryContent(),

         const SizedBox(height: 20),

         // Action Buttons
         if (!_isEditing)
          Column(
           crossAxisAlignment: CrossAxisAlignment.stretch,
           children: [
            Container(
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
             child: Material(
              color: Colors.transparent,
              child: InkWell(
               borderRadius: BorderRadius.circular(14),
               onTap: () {
                Navigator.pop(context);
                widget.onBookDoctor(_currentSummary);
               },
               child: const Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 15, horizontal: 16),
                child: Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                  Icon(Icons.calendar_month_rounded,
                    color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Flexible(
                   child: Text(
                    'Book Doctor Appointment',
                    style: TextStyle(
                     color: Colors.white,
                     fontSize: 14.5,
                     fontWeight: FontWeight.w600,
                     letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                   ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded,
                    color: Colors.white70, size: 16),
                 ],
                ),
               ),
              ),
             ),
            ),
            const SizedBox(height: 10),
            TextButton(
             onPressed: () => Navigator.pop(context),
             style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              foregroundColor: AppColors.textMuted,
             ),
             child: Text(
              'Close Summary',
              style: AppTextStyles.labelLarge.copyWith(
               color: AppColors.textSecondary,
               fontSize: 13.5,
              ),
             ),
            ),
           ],
          ),
        ],
       ),
      ),
     ),
    ),
   ),
  );
 }

 Widget _buildSummaryContent() {
  return Column(
   crossAxisAlignment: CrossAxisAlignment.start,
   children: [
    // Patient Info Card
    GlassCard(
     padding: const EdgeInsets.all(16),
     margin: const EdgeInsets.only(bottom: 12),
     child: Row(
      children: [
       CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
        child: Text(
         _currentSummary.patientName.isNotEmpty
           ? _currentSummary.patientName[0].toUpperCase()
           : 'P',
         style: AppTextStyles.headingSmall.copyWith(
          color: AppColors.primary,
         ),
        ),
       ),
       const SizedBox(width: 14),
       Expanded(
        child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
          Text(
           _currentSummary.patientName,
           style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
           ),
          ),
          const SizedBox(height: 2),
          Text(
           '${_currentSummary.age != null ? '${_currentSummary.age} yrs' : 'Age unspecified'} • ${_currentSummary.gender ?? 'Gender unspecified'}',
           style: AppTextStyles.caption,
          ),
         ],
        ),
       ),
      ],
     ),
    ),

    // Chief Complaint
    _InfoRow(
     label: 'Chief Complaint',
     value: _currentSummary.chiefComplaint,
     icon: Icons.medical_information_outlined,
    ),

    // Symptoms List
    Padding(
     padding: const EdgeInsets.symmetric(vertical: 8),
     child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       Text('Extracted Symptoms', style: AppTextStyles.caption),
       const SizedBox(height: 6),
       Wrap(
        spacing: 8,
        runSpacing: 6,
        children: _currentSummary.symptoms.map((s) {
         return Container(
          padding: const EdgeInsets.symmetric(
           horizontal: 10,
           vertical: 5,
          ),
          decoration: BoxDecoration(
           color: AppColors.surfaceLight,
           borderRadius: BorderRadius.circular(20),
           border: Border.all(color: AppColors.border),
          ),
          child: Text(
           s,
           style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textPrimary,
            fontSize: 12,
           ),
          ),
         );
        }).toList(),
       ),
      ],
     ),
    ),

    // Duration & Severity
    Row(
     children: [
      Expanded(
       child: _InfoRow(
        label: 'Duration',
        value: _currentSummary.duration ?? 'Not collected',
        icon: Icons.timer_outlined,
       ),
      ),
      const SizedBox(width: 12),
      Expanded(
       child: _InfoRow(
        label: 'Severity',
        value: _currentSummary.severity ?? 'Not collected',
        icon: Icons.speed_rounded,
        valueColor: (_currentSummary.severity?.toLowerCase().contains('severe') ?? false)
          ? AppColors.error
          : ((_currentSummary.severity?.toLowerCase().contains('moderate') ?? false)
            ? AppColors.warning
            : AppColors.success),
       ),
      ),
     ],
    ),
    const SizedBox(height: 14),

    // Recommended Specialist Badge
    if (_currentSummary.recommendedSpecialist != null &&
      _currentSummary.recommendedSpecialist!.isNotEmpty)
     Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
       color: AppColors.primary.withValues(alpha: 0.12),
       borderRadius: BorderRadius.circular(12),
       border:
         Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
       children: [
        const Icon(Icons.medical_services_outlined,
          color: AppColors.primary, size: 18),
        const SizedBox(width: 10),
        Text(
         'Recommended Specialist:',
         style: AppTextStyles.caption
           .copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 6),
        Expanded(
         child: Text(
          _currentSummary.recommendedSpecialist!,
          style: AppTextStyles.bodyMedium.copyWith(
           color: AppColors.primary,
           fontWeight: FontWeight.bold,
          ),
         ),
        ),
       ],
      ),
     ),

    // AI Clinical Assessment Summary
    if (_currentSummary.clinicalSummary != null &&
      _currentSummary.clinicalSummary!.isNotEmpty)
     Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
       color: AppColors.surface,
       borderRadius: BorderRadius.circular(14),
       border: Border.all(color: AppColors.border),
      ),
      child: Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
        Row(
         children: [
          const Icon(Icons.auto_awesome,
            color: AppColors.primary, size: 16),
          const SizedBox(width: 8),
          Text(
           'AI CLINICAL ASSESSMENT',
           style: AppTextStyles.caption.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
           ),
          ),
         ],
        ),
        const SizedBox(height: 8),
        Text(
         _currentSummary.clinicalSummary!,
         style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textPrimary,
          height: 1.45,
         ),
        ),
       ],
      ),
     ),

    // Preliminary Guidance
    if (_currentSummary.preliminaryGuidance != null &&
      _currentSummary.preliminaryGuidance!.isNotEmpty)
     Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
       color: AppColors.info.withValues(alpha: 0.1),
       borderRadius: BorderRadius.circular(12),
       border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
      ),
      child: Row(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
        const Icon(Icons.lightbulb_outline_rounded,
          color: AppColors.info, size: 18),
        const SizedBox(width: 10),
        Expanded(
         child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           Text(
            'Preliminary Care Guidance',
            style: AppTextStyles.caption.copyWith(
             color: AppColors.info,
             fontWeight: FontWeight.w700,
            ),
           ),
           const SizedBox(height: 3),
           Text(
            _currentSummary.preliminaryGuidance!,
            style: AppTextStyles.bodySmall.copyWith(
             color: AppColors.textSecondary,
             fontSize: 11.5,
             height: 1.4,
            ),
           ),
          ],
         ),
        ),
       ],
      ),
     ),
   ],
  );
 }

 Widget _buildEditForm() {
  return Container(
   padding: const EdgeInsets.all(16),
   decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
   ),
   child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
     Text(
      'Chief Complaint',
      style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
     ),
     const SizedBox(height: 6),
     TextField(
      controller: _complaintController,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
       filled: true,
       fillColor: AppColors.backgroundSecondary,
       hintText: 'e.g. Fever with headache',
       contentPadding:
         const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
       border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
       ),
       focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary),
       ),
      ),
     ),
     const SizedBox(height: 14),

     // Symptoms Editor
     Text(
      'Symptoms',
      style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
     ),
     const SizedBox(height: 8),
     Wrap(
      spacing: 8,
      runSpacing: 6,
      children: _symptoms.map((s) {
       return Chip(
        label: Text(s, style: const TextStyle(fontSize: 12)),
        backgroundColor: AppColors.surfaceLight,
        deleteIcon: const Icon(Icons.close_rounded, size: 14),
        onDeleted: () => _removeSymptom(s),
        shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.circular(20),
         side: const BorderSide(color: AppColors.border),
        ),
       );
      }).toList(),
     ),
     const SizedBox(height: 8),
     Row(
      children: [
       Expanded(
        child: TextField(
         controller: _newSymptomController,
         style: AppTextStyles.bodySmall,
         decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.backgroundSecondary,
          hintText: 'Add another symptom...',
          hintStyle: AppTextStyles.caption,
          contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
           borderRadius: BorderRadius.circular(10),
           borderSide: const BorderSide(color: AppColors.border),
          ),
         ),
         onSubmitted: (_) => _addSymptom(),
        ),
       ),
       const SizedBox(width: 8),
       IconButton.filled(
        onPressed: _addSymptom,
        icon: const Icon(Icons.add, size: 18),
        style: IconButton.styleFrom(
         backgroundColor: AppColors.primary,
         foregroundColor: Colors.white,
        ),
       ),
      ],
     ),
     const SizedBox(height: 16),

     // Duration & Severity
     Row(
      children: [
       Expanded(
        child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
          Text('Duration',
            style: AppTextStyles.labelMedium
              .copyWith(color: AppColors.primary)),
          const SizedBox(height: 6),
          TextField(
           controller: _durationController,
           style: AppTextStyles.bodyMedium,
           decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.backgroundSecondary,
            hintText: 'e.g. 3 days',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
             borderRadius: BorderRadius.circular(10),
             borderSide: const BorderSide(color: AppColors.border),
            ),
           ),
          ),
         ],
        ),
       ),
       const SizedBox(width: 12),
       Expanded(
        child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
          Text('Severity',
            style: AppTextStyles.labelMedium
              .copyWith(color: AppColors.primary)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
           initialValue: _severity,
           dropdownColor: AppColors.surface,
           style: AppTextStyles.bodyMedium,
           decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.backgroundSecondary,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
             borderRadius: BorderRadius.circular(10),
             borderSide: const BorderSide(color: AppColors.border),
            ),
           ),
           items: _severityOptions.map((opt) {
            return DropdownMenuItem(
             value: opt,
             child: Text(opt),
            );
           }).toList(),
           onChanged: (val) {
            if (val != null) setState(() => _severity = val);
           },
          ),
         ],
        ),
       ),
      ],
     ),
     const SizedBox(height: 16),

     // Additional Notes
     Text(
      'Additional Patient Notes',
      style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
     ),
     const SizedBox(height: 6),
     TextField(
      controller: _notesController,
      maxLines: 3,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
       filled: true,
       fillColor: AppColors.backgroundSecondary,
       hintText: 'Any extra details for the consulting doctor...',
       contentPadding: const EdgeInsets.all(12),
       border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
       ),
      ),
     ),
     const SizedBox(height: 18),

     // Save / Cancel row
     Row(
      children: [
       Expanded(
        child: OutlinedButton(
         onPressed: () => setState(() => _isEditing = false),
         style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          foregroundColor: AppColors.textMuted,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(10),
          ),
         ),
         child: const Text('Cancel'),
        ),
       ),
       const SizedBox(width: 12),
       Expanded(
        flex: 2,
        child: ElevatedButton.icon(
         onPressed: _saveEdits,
         icon: const Icon(Icons.check_rounded, size: 18),
         label: const Text('Save Changes'),
         style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
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
  );
 }
}

class _InfoRow extends StatelessWidget {
 final String label;
 final String value;
 final IconData icon;
 final Color? valueColor;

 const _InfoRow({
  required this.label,
  required this.value,
  required this.icon,
  this.valueColor,
 });

 @override
 Widget build(BuildContext context) {
  return Container(
   margin: const EdgeInsets.symmetric(vertical: 6),
   padding: const EdgeInsets.all(12),
   decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppColors.border),
   ),
   child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
     Row(
      children: [
       Icon(icon, size: 14, color: AppColors.textMuted),
       const SizedBox(width: 6),
       Text(label, style: AppTextStyles.caption),
      ],
     ),
     const SizedBox(height: 4),
     Text(
      value,
      style: AppTextStyles.bodyMedium.copyWith(
       color: valueColor ?? AppColors.textPrimary,
       fontWeight: FontWeight.w600,
      ),
     ),
    ],
   ),
  );
 }
}
