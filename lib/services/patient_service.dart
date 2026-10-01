import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/patient_profile_model.dart';
import '../core/network/api_client.dart';

final patientServiceProvider = Provider((ref) => PatientService(ref));

class PatientService {
  final Ref _ref;

  PatientService(this._ref);

  Future<PatientProfileModel?> getPatientProfile() async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.get('/api/patients/me', requireAuth: true);
      return PatientProfileModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error fetching patient profile: $e');
    }
    return null;
  }

  Future<PatientProfileModel?> updateProfile({
    String? name,
    String? firstName,
    String? lastName,
    String? dateOfBirth,
    int? age,
    String? gender,
    String? phone,
    String? city,
    String? country,
    String? bloodGroup,
    String? emergencyContact,
  }) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (firstName != null) body['first_name'] = firstName;
      if (lastName != null) body['last_name'] = lastName;
      if (dateOfBirth != null && dateOfBirth.isNotEmpty) body['date_of_birth'] = dateOfBirth;
      if (age != null) body['age'] = age;
      if (gender != null) body['gender'] = gender;
      if (phone != null) body['phone'] = phone;
      if (city != null) body['city'] = city;
      if (country != null) body['country'] = country;
      if (bloodGroup != null) body['blood_group'] = bloodGroup;
      if (emergencyContact != null) body['emergency_contact'] = emergencyContact;
      final response = await apiClient.put('/api/patients/me', body: body, requireAuth: true);
      return PatientProfileModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error updating patient profile: $e');
    }
    return null;
  }

  Future<PatientProfileModel?> uploadPatientDocument({
    required String base64String,
    required String mimeType,
    required String fileName,
  }) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.post(
        '/api/patients/me/documents',
        body: {
          'file_base64': base64String,
          'mime_type': mimeType,
          'file_name': fileName,
          'document_type': 'Medical Document',
        },
        requireAuth: true,
      );
      return PatientProfileModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error uploading patient document: $e');
    }
    return null;
  }
}

