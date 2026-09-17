import 'package:flutter/material.dart';

/// Centralized color palette for HealthCall AI
class AppColors {
  AppColors._();

  // Backgrounds
  static const Color background = Color(0xFF060B18);
  static const Color backgroundSecondary = Color(0xFF0D1526);
  static const Color backgroundTertiary = Color(0xFF111D35);
  static const Color surface = Color(0xFF131F38);
  static const Color surfaceLight = Color(0xFF1A2840);

  // Primary - Electric Blue
  static const Color primary = Color(0xFF2D8EFF);
  static const Color primaryLight = Color(0xFF5AABFF);
  static const Color primaryDark = Color(0xFF1A6FD4);

  // Secondary - Purple/Violet
  static const Color secondary = Color(0xFF7B5EA7);
  static const Color secondaryLight = Color(0xFF9B7EC8);
  static const Color secondaryDark = Color(0xFF5A3D8A);

  // Accent - Cyan/Teal
  static const Color accent = Color(0xFF00D4FF);
  static const Color accentPurple = Color(0xFFAB82FF);

  // Gradients
  static const List<Color> primaryGradient = [
    Color(0xFF2D8EFF),
    Color(0xFF7B5EA7),
  ];
  static const List<Color> blueGradient = [
    Color(0xFF1A6FD4),
    Color(0xFF2D8EFF),
  ];
  static const List<Color> purpleGradient = [
    Color(0xFF5A3D8A),
    Color(0xFF7B5EA7),
  ];
  static const List<Color> darkGradient = [
    Color(0xFF060B18),
    Color(0xFF0D1526),
  ];
  static const List<Color> cardGradient = [
    Color(0xFF1A2840),
    Color(0xFF131F38),
  ];

  // Semantic Colors
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFF87171);
  static const Color info = Color(0xFF3B82F6);

  // Text
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF475569);
  static const Color textDisabled = Color(0xFF334155);

  // Border / Glass
  static const Color border = Color(0xFF1E3050);
  static const Color borderLight = Color(0xFF253D62);
  static const Color glassBorder = Color(0x302D8EFF);
  static const Color glassOverlay = Color(0x0AFFFFFF);

  // Status
  static const Color online = Color(0xFF22C55E);
  static const Color offline = Color(0xFF64748B);
  static const Color busy = Color(0xFFF59E0B);
  static const Color emergency = Color(0xFFEF4444);

  // Patient specific
  static const Color patientPrimary = Color(0xFF2D8EFF);

  // Doctor specific
  static const Color doctorPrimary = Color(0xFF10B981);
  static const Color doctorSecondary = Color(0xFF059669);

  // Admin specific
  static const Color adminPrimary = Color(0xFF7B5EA7);
  static const Color adminSecondary = Color(0xFF5A3D8A);
}
