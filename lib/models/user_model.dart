import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// User roles in the HealthCall AI system
enum UserRole {
 patient,
 doctor,
 admin;

 String get displayName {
  switch (this) {
   case UserRole.patient:
    return 'Patient';
   case UserRole.doctor:
    return 'Doctor';
   case UserRole.admin:
    return 'Admin';
  }
 }

 IconData get icon {
  switch (this) {
   case UserRole.patient:
    return Icons.person;
   case UserRole.doctor:
    return Icons.medical_services;
   case UserRole.admin:
    return Icons.admin_panel_settings;
  }
 }
}

/// Core user model
class UserModel extends Equatable {
 final String id;
 final String name;
 final String email;
 final UserRole role;
 final String? phone;
 final String? avatarUrl;
 final DateTime createdAt;
 final String? emergencyContact;
 final int? age;
 final String? gender;
 final String? bloodGroup;

 const UserModel({
  required this.id,
  required this.name,
  required this.email,
  required this.role,
  this.phone,
  this.avatarUrl,
  required this.createdAt,
  this.emergencyContact,
  this.age,
  this.gender,
  this.bloodGroup,
 });

 String get patientId => 'HC-${id.substring(0, 8).toUpperCase()}';

 @override
 List<Object?> get props => [id, name, email, role, emergencyContact, age, gender, bloodGroup];

 UserModel copyWith({
  String? id,
  String? name,
  String? email,
  UserRole? role,
  String? phone,
  String? avatarUrl,
  DateTime? createdAt,
  String? emergencyContact,
  int? age,
  String? gender,
  String? bloodGroup,
 }) {
  return UserModel(
   id: id ?? this.id,
   name: name ?? this.name,
   email: email ?? this.email,
   role: role ?? this.role,
   phone: phone ?? this.phone,
   avatarUrl: avatarUrl ?? this.avatarUrl,
   createdAt: createdAt ?? this.createdAt,
   emergencyContact: emergencyContact ?? this.emergencyContact,
   age: age ?? this.age,
   gender: gender ?? this.gender,
   bloodGroup: bloodGroup ?? this.bloodGroup,
  );
 }

 Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role.name,
    'phone': phone,
    'avatarUrl': avatarUrl,
    'createdAt': createdAt.toIso8601String(),
    'emergencyContact': emergencyContact,
    'age': age,
    'gender': gender,
    'bloodGroup': bloodGroup,
   };

 factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    role: UserRole.values.firstWhere((r) => r.name == json['role']),
    phone: json['phone'] as String?,
    avatarUrl: json['avatarUrl'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    emergencyContact: json['emergencyContact'] as String?,
    age: json['age'] as int?,
    gender: json['gender'] as String?,
    bloodGroup: json['bloodGroup'] as String?,
   );
}

/// Auth state model
class AuthState extends Equatable {
 final bool isAuthenticated;
 final bool isLoading;
 final UserModel? user;
 final String? errorMessage;

 const AuthState({
  this.isAuthenticated = false,
  this.isLoading = false,
  this.user,
  this.errorMessage,
 });

 const AuthState.initial() : this();

 AuthState copyWith({
  bool? isAuthenticated,
  bool? isLoading,
  UserModel? user,
  String? errorMessage,
  bool clearError = false,
  bool clearUser = false,
 }) {
  return AuthState(
   isAuthenticated: isAuthenticated ?? this.isAuthenticated,
   isLoading: isLoading ?? this.isLoading,
   user: clearUser ? null : (user ?? this.user),
   errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
 }

 @override
 List<Object?> get props => [isAuthenticated, isLoading, user, errorMessage];
}
