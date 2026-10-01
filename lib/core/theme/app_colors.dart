import 'package:flutter/material.dart';

/// Centralized color palette for HealthCall AI (Claymorphism Edition)
class AppColors {
 AppColors._();

 // Clay Backgrounds
 static const Color backgroundLight = Color(0xFFF0F5F9); // Soft light grey-blue
 static const Color backgroundDark = Color(0xFF2C3136); // Soft dark grey

 static const Color surfaceLight = Color(0xFFF0F5F9);
 static const Color surfaceDark = Color(0xFF2C3136);

 // Primary - Electric Blue (Softened for clay)
 static const Color primary = Color(0xFF3B82F6);
 static const Color primaryLight = Color(0xFF60A5FA);
 static const Color primaryDark = Color(0xFF2563EB);

 // Secondary - Purple/Violet
 static const Color secondary = Color(0xFF8B5CF6);
 static const Color secondaryLight = Color(0xFFA78BFA);
 static const Color secondaryDark = Color(0xFF7C3AED);

 // Accent - Cyan/Teal
 static const Color accent = Color(0xFF06B6D4);
 static const Color accentPurple = Color(0xFFC084FC);

 // Semantic Colors
 static const Color success = Color(0xFF22C55E);
 static const Color warning = Color(0xFFF59E0B);
 static const Color error = Color(0xFFEF4444);
 static const Color info = Color(0xFF3B82F6);

 // Text (Light Theme)
 static const Color textPrimaryLight = Color(0xFF1E293B);
 static const Color textSecondaryLight = Color(0xFF475569);
 static const Color textMutedLight = Color(0xFF64748B);

 // Text (Dark Theme)
 static const Color textPrimaryDark = Color(0xFFF8FAFC);
 static const Color textSecondaryDark = Color(0xFFCBD5E1);
 static const Color textMutedDark = Color(0xFF94A3B8);

 // Roles specific
 static const Color patientPrimary = Color(0xFF3B82F6);
 static const Color doctorPrimary = Color(0xFF10B981);
 static const Color adminPrimary = Color(0xFF8B5CF6);

 // Compatibility / Common Colors mapped to Light Theme
 static const Color background = backgroundLight;
 static const Color backgroundSecondary = Color(0xFFFFFFFF);
 static const Color backgroundTertiary = Color(0xFFF8FAFC);
 static const Color surface = surfaceLight;
 static const Color border = Color(0xFFE2E8F0);
 static const Color borderLight = Color(0xFFF1F5F9);
 static const Color errorLight = Color(0xFFFCA5A5);
 static const Color online = Color(0xFF10B981);
 
 static const Color textPrimary = textPrimaryLight;
 static const Color textSecondary = textSecondaryLight;
 static const Color textMuted = textMutedLight;
 static const Color textDisabled = Color(0xFF94A3B8);

 static const List<Color> primaryGradient = [primary, accent];
}
