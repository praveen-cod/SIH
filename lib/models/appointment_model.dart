import 'package:equatable/equatable.dart';

/// Appointment status
enum AppointmentStatus {
 confirmed,
 pending,
 completed,
 cancelled;

 String get label {
  switch (this) {
   case AppointmentStatus.confirmed:
    return 'Approved';
   case AppointmentStatus.pending:
    return 'Pending Approval';
   case AppointmentStatus.completed:
    return 'Completed';
   case AppointmentStatus.cancelled:
    return 'Declined';
  }
 }
}

/// Appointment model
class AppointmentModel extends Equatable {
 final String id;
 final String patientId;
 final String patientName;
 final String doctorId;
 final String doctorName;
 final String specialty;
 final DateTime dateTime;
 final AppointmentStatus status;
 final String? notes;

 const AppointmentModel({
  required this.id,
  required this.patientId,
  required this.patientName,
  required this.doctorId,
  required this.doctorName,
  required this.specialty,
  required this.dateTime,
  required this.status,
  this.notes,
 });

 @override
 List<Object?> get props => [id, patientId, doctorId, dateTime, status];
}

/// Doctor availability model
enum AvailabilityStatus { available, busy, offline }

/// Doctor profile extension model
class DoctorProfile extends Equatable {
 final String userId;
 final String specialty;
 final String qualification;
 final int totalPatients;
 final int yearsExperience;
 final double rating;
 final AvailabilityStatus availability;

 const DoctorProfile({
  required this.userId,
  required this.specialty,
  required this.qualification,
  required this.totalPatients,
  required this.yearsExperience,
  required this.rating,
  this.availability = AvailabilityStatus.available,
 });

 @override
 List<Object?> get props => [userId, specialty, availability];
}

/// Patient profile extension
class PatientProfile extends Equatable {
 final String userId;
 final int age;
 final String gender;
 final String? emergencyContact;
 final String bloodType;

 const PatientProfile({
  required this.userId,
  required this.age,
  required this.gender,
  this.emergencyContact,
  this.bloodType = 'Unknown',
 });

 @override
 List<Object?> get props => [userId, age, gender];
}

/// Real-time Doctor Availability Slot model
class DoctorSlotModel extends Equatable {
 final int id;
 final String doctorId;
 final String date;
 final String startTime;
 final String endTime;
 final String status;

 const DoctorSlotModel({
  required this.id,
  required this.doctorId,
  required this.date,
  required this.startTime,
  required this.endTime,
  required this.status,
 });

 factory DoctorSlotModel.fromJson(Map<String, dynamic> json) {
  return DoctorSlotModel(
   id: json['id'] as int? ?? 0,
   doctorId: json['doctor_id'] as String? ?? '',
   date: json['date'] as String? ?? '',
   startTime: json['start_time'] as String? ?? '',
   endTime: json['end_time'] as String? ?? '',
   status: json['status'] as String? ?? 'AVAILABLE',
  );
 }

 @override
 List<Object?> get props => [id, doctorId, date, startTime, status];
}

/// Recommended Doctor model returned by DoctorMatchingService
class RecommendedDoctorModel extends Equatable {
 final String doctorId;
 final String name;
 final String specialization;
 final String qualification;
 final int experience;
 final String department;
 final String status;
 final List<DoctorSlotModel> availableSlots;
 final String? recommendationRationale;

 const RecommendedDoctorModel({
  required this.doctorId,
  required this.name,
  required this.specialization,
  required this.qualification,
  required this.experience,
  required this.department,
  required this.status,
  required this.availableSlots,
  this.recommendationRationale,
 });

 factory RecommendedDoctorModel.fromJson(Map<String, dynamic> json) {
  final slotsList = (json['available_slots'] as List<dynamic>?)
      ?.map((s) => DoctorSlotModel.fromJson(s as Map<String, dynamic>))
      .toList() ??
    [];

  return RecommendedDoctorModel(
   doctorId: json['doctor_id'] as String? ?? '',
   name: json['name'] as String? ?? '',
   specialization: json['specialization'] as String? ?? '',
   qualification: json['qualification'] as String? ?? '',
   experience: json['experience'] as int? ?? 0,
   department: json['department'] as String? ?? '',
   status: json['status'] as String? ?? 'ACTIVE',
   availableSlots: slotsList,
   recommendationRationale: json['recommendation_rationale'] as String?,
  );
 }

 @override
 List<Object?> get props => [doctorId, name, specialization, availableSlots];
}

/// Clinical Appointment model matching SQLite appointments table
class ClinicalAppointmentModel extends Equatable {
 final int id;
 final String appointmentId;
 final String patientId;
 final String? patientName;
 final String doctorId;
 final String? doctorName;
 final String? doctorSpecialization;
 final String? consultationId;
 final int? availabilityId;
 final String appointmentDate;
 final String startTime;
 final String endTime;
 final String consultationType;
 final String reason;
 final String status; // REQUESTED, APPROVED, REJECTED, CANCELLED, COMPLETED
 final String? patientNotes;
 final String? doctorNotes;
 final String? rejectionReason;
 final DateTime createdAt;

 const ClinicalAppointmentModel({
  required this.id,
  required this.appointmentId,
  required this.patientId,
  this.patientName,
  required this.doctorId,
  this.doctorName,
  this.doctorSpecialization,
  this.consultationId,
  this.availabilityId,
  required this.appointmentDate,
  required this.startTime,
  required this.endTime,
  required this.consultationType,
  required this.reason,
  required this.status,
  this.patientNotes,
  this.doctorNotes,
  this.rejectionReason,
  required this.createdAt,
 });

 factory ClinicalAppointmentModel.fromJson(Map<String, dynamic> json) {
  return ClinicalAppointmentModel(
   id: json['id'] as int? ?? 0,
   appointmentId: json['appointment_id'] as String? ?? '',
   patientId: json['patient_id'] as String? ?? '',
   patientName: json['patient_name'] as String?,
   doctorId: json['doctor_id'] as String? ?? '',
   doctorName: json['doctor_name'] as String?,
   doctorSpecialization: json['doctor_specialization'] as String?,
   consultationId: json['consultation_id'] as String?,
   availabilityId: json['availability_id'] as int?,
   appointmentDate: json['appointment_date'] as String? ?? '',
   startTime: json['start_time'] as String? ?? '',
   endTime: json['end_time'] as String? ?? '',
   consultationType: json['consultation_type'] as String? ?? 'Video',
   reason: json['reason'] as String? ?? '',
   status: json['status'] as String? ?? 'REQUESTED',
   patientNotes: json['patient_notes'] as String?,
   doctorNotes: json['doctor_notes'] as String?,
   rejectionReason: json['rejection_reason'] as String?,
   createdAt: json['created_at'] != null
     ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
     : DateTime.now(),
  );
 }

 /// Converts clinical database model into patient UI model
 AppointmentModel toAppointmentModel() {
  DateTime dt;
  try {
   final parts = appointmentDate.split('-');
   final timeParts = startTime.split(':');
   dt = DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
    int.parse(timeParts[0]),
    int.parse(timeParts[1]),
   );
  } catch (_) {
   dt = createdAt;
  }

  AppointmentStatus st;
  switch (status.toUpperCase()) {
   case 'APPROVED':
    st = AppointmentStatus.confirmed;
    break;
   case 'COMPLETED':
    st = AppointmentStatus.completed;
    break;
   case 'REJECTED':
   case 'CANCELLED':
    st = AppointmentStatus.cancelled;
    break;
   default:
    st = AppointmentStatus.pending;
    break;
  }

  return AppointmentModel(
   id: appointmentId,
   patientId: patientId,
   patientName: patientName ?? 'Patient',
   doctorId: doctorId,
   doctorName: doctorName ?? 'Dr. Specialist',
   specialty: doctorSpecialization ?? 'General Physician',
   dateTime: dt,
   status: st,
   notes: reason,
  );
 }

 @override
 List<Object?> get props => [appointmentId, patientId, doctorId, status];
}

