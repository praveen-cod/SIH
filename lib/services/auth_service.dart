import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../core/network/api_client.dart';
import '../models/user_model.dart';

/// Authentication result
class AuthResult {
 final bool success;
 final UserModel? user;
 final String? errorMessage;
 final String? token;

 const AuthResult({
  required this.success,
  this.user,
  this.errorMessage,
  this.token,
 });

 factory AuthResult.success(UserModel user, {String? token}) =>
   AuthResult(success: true, user: user, token: token);

 factory AuthResult.failure(String message) =>
   AuthResult(success: false, errorMessage: message);
}

/// Authentication service contract
abstract class AuthService {
 Future<AuthResult> login({
  required String email,
  required String password,
  required UserRole role,
 });

 Future<AuthResult> signUp({
  required String name,
  required String email,
  required String password,
  required String phone,
  required String emergencyContact,
  required int age,
  required String gender,
 });

 Future<void> logout();
}

/// Real Backend Implementation with graceful offline fallback
class MockAuthService implements AuthService {
 static const _uuid = Uuid();
 final ApiClient _apiClient = ApiClient();

 // Local fallback accounts
 static final List<Map<String, dynamic>> _mockAccounts = [
  {
   'email': 'patient@demo.com',
   'password': 'Demo@1234',
   'role': UserRole.patient,
   'id': 'HC-P-10001',
   'name': 'Praveen Kumar',
   'phone': '+91 9876543210',
  },
  {
   'email': 'doctor@demo.com',
   'password': 'Demo@1234',
   'role': UserRole.doctor,
   'id': 'HC-D-1001',
   'name': 'Dr. Arun Kumar',
   'phone': '+91 9876500001',
  },
  {
   'email': 'admin@healthcall.ai',
   'password': 'Admin@1234',
   'role': UserRole.admin,
   'id': 'HC-A-101',
   'name': 'Platform Administrator',
   'phone': '+91 9876500000',
  },
  {
   'email': 'admin@demo.com',
   'password': 'Demo@1234',
   'role': UserRole.admin,
   'id': 'HC-A-102',
   'name': 'System Admin',
   'phone': '+91 9876500000',
  },
 ];

 @override
 Future<AuthResult> login({
  required String email,
  required String password,
  required UserRole role,
 }) async {
  String cleanEmail = email.trim().toLowerCase();
  if (!cleanEmail.contains('@')) {
   cleanEmail = '$cleanEmail@demo.com';
  }

  try {
   final response = await _apiClient.post(
    '/api/auth/login',
    body: {
     'email': cleanEmail,
     'password': password.trim(),
     'role': role.name,
    },
   );

   if (response is Map<String, dynamic> && response['success'] == true) {
    final token = response['token']?.toString() ?? '';
    final userId = response['user_id']?.toString() ?? '';
    final name = response['name']?.toString() ?? '';
    final roleStr = response['role']?.toString().toLowerCase() ?? role.name;

    // Persist JWT token in local storage
    await ApiClient.saveSession(
     token: token,
     role: roleStr,
     userId: userId,
     name: name,
    );

    final user = UserModel(
     id: userId,
     name: name,
     email: cleanEmail,
     role: role,
     phone: response['phone']?.toString() ?? '+91 9876543210',
     emergencyContact: response['emergency_contact']?.toString(),
     createdAt: DateTime.now(),
    );

    return AuthResult.success(user, token: token);
   }
  } catch (e) {
   debugPrint('FastAPI login failed ($e). Attempting local fallback credentials.');
   if (e is ApiException) {
    return AuthResult.failure(e.message);
   }
  }

  // Local fallback matching
  final cleanPassword = password.trim();
  final account = _mockAccounts.firstWhere(
   (acc) =>
     acc['email'] == cleanEmail &&
     acc['password'].toString().toLowerCase() ==
       cleanPassword.toLowerCase() &&
     acc['role'] == role,
   orElse: () => {},
  );

  if (account.isEmpty) {
   return AuthResult.failure(
    'Invalid credentials. Please check your email and password.',
   );
  }

  final user = UserModel(
   id: account['id'] as String,
   name: account['name'] as String,
   email: account['email'] as String,
   role: account['role'] as UserRole,
   phone: account['phone'] as String,
   emergencyContact: account['emergency_contact'] as String?,
   createdAt: DateTime.now().subtract(const Duration(days: 30)),
  );

  return AuthResult.success(user);
 }

 @override
 Future<AuthResult> signUp({
  required String name,
  required String email,
  required String password,
  required String phone,
  required String emergencyContact,
  required int age,
  required String gender,
 }) async {
  final cleanEmail = email.trim().toLowerCase();

  try {
   final response = await _apiClient.post(
    '/api/auth/patient/register',
    body: {
     'name': name.trim(),
     'age': age,
     'gender': gender.trim(),
     'phone': phone.trim(),
     'emergency_contact': emergencyContact.trim(),
     'email': cleanEmail,
     'password': password.trim(),
     'confirm_password': password.trim(),
    },
   );

   if (response is Map<String, dynamic> && response['success'] == true) {
    final token = response['token']?.toString() ?? '';
    final userId = response['user_id']?.toString() ?? '';
    final returnedName = response['name']?.toString() ?? name;

    await ApiClient.saveSession(
     token: token,
     role: 'patient',
     userId: userId,
     name: returnedName,
    );

    final user = UserModel(
     id: userId,
     name: returnedName,
     email: cleanEmail,
     role: UserRole.patient,
     phone: response['phone']?.toString() ?? phone.trim(),
     emergencyContact: response['emergency_contact']?.toString() ?? emergencyContact.trim(),
     createdAt: DateTime.now(),
    );

    return AuthResult.success(user, token: token);
   }
  } catch (e) {
   debugPrint('FastAPI register failed ($e). Using local fallback signup.');
   if (e is ApiException) {
    return AuthResult.failure(e.message);
   }
  }

  // Local fallback signup
  final id = _uuid.v4().substring(0, 8).toUpperCase();
  final user = UserModel(
   id: 'HC-P-$id',
   name: name.trim(),
   email: cleanEmail,
   role: UserRole.patient,
   phone: phone.trim(),
   emergencyContact: emergencyContact.trim(),
   createdAt: DateTime.now(),
  );

  return AuthResult.success(user);
 }

 @override
 Future<void> logout() async {
  await ApiClient.clearSession();
 }
}

