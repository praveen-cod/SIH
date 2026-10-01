class PatientProfileModel {
  final int id;
  final String patientId;
  final String? patientCode;
  final String? firstName;
  final String? lastName;
  final String name;
  final String? dateOfBirth;
  final int age;
  final String gender;
  final String phone;
  final String email;
  final String? city;
  final String? country;
  final String? bloodGroup;
  final String? emergencyContact;
  
  final Map<String, dynamic>? demographics;
  final List<dynamic>? medicalHistory;
  final List<dynamic>? medications;
  final List<dynamic>? labResults;
  final List<dynamic>? vitalSigns;
  final List<dynamic>? diagnoses;
  final List<dynamic>? documents;
  final List<dynamic>? allergies;
  final List<dynamic>? procedures;
  final List<dynamic>? familyHistory;
  final Map<String, dynamic>? reproductiveStatus;

  PatientProfileModel({
    required this.id,
    required this.patientId,
    this.patientCode,
    this.firstName,
    this.lastName,
    required this.name,
    this.dateOfBirth,
    required this.age,
    required this.gender,
    required this.phone,
    required this.email,
    this.city,
    this.country,
    this.bloodGroup,
    this.emergencyContact,
    this.demographics,
    this.medicalHistory,
    this.medications,
    this.labResults,
    this.vitalSigns,
    this.diagnoses,
    this.documents,
    this.allergies,
    this.procedures,
    this.familyHistory,
    this.reproductiveStatus,
  });

  factory PatientProfileModel.fromJson(Map<String, dynamic> json) {
    return PatientProfileModel(
      id: json['id'],
      patientId: json['patient_id'],
      patientCode: json['patient_code'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      name: json['name'] ?? '',
      dateOfBirth: json['date_of_birth'],
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      city: json['city'],
      country: json['country'],
      bloodGroup: json['blood_group'],
      emergencyContact: json['emergency_contact'],
      demographics: json['demographics'],
      medicalHistory: json['medical_history'],
      medications: json['medications'],
      labResults: json['lab_results'],
      vitalSigns: json['vital_signs'],
      diagnoses: json['diagnoses'],
      documents: json['documents'],
      allergies: json['allergies'],
      procedures: json['procedures'],
      familyHistory: json['family_history'],
      reproductiveStatus: json['reproductive_status'],
    );
  }
}
