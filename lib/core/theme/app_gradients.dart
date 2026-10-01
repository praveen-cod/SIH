import 'package:flutter/material.dart';

/// Centralized gradients for HealthCall AI
class AppGradients {
 AppGradients._();

 static const LinearGradient primary = LinearGradient(
  colors: [Color(0xFF2D8EFF), Color(0xFF8B5CF6)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
 );

 static const LinearGradient electricBlue = LinearGradient(
  colors: [Color(0xFF00D4FF), Color(0xFF2D8EFF)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
 );

 static const LinearGradient violetPurple = LinearGradient(
  colors: [Color(0xFF7B5EA7), Color(0xFF5A3D8A)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
 );

 static const LinearGradient cardDark = LinearGradient(
  colors: [Color(0xFF1A2840), Color(0xFF131F38)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
 );

 static const LinearGradient cardElevated = LinearGradient(
  colors: [Color(0xFF203250), Color(0xFF16233E)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
 );

 static const LinearGradient emergency = LinearGradient(
  colors: [Color(0xFFEF4444), Color(0xFF991B1B)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
 );

 static const LinearGradient success = LinearGradient(
  colors: [Color(0xFF22C55E), Color(0xFF15803D)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
 );

 static const LinearGradient warning = LinearGradient(
  colors: [Color(0xFFF59E0B), Color(0xFFB45309)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
 );

 static const LinearGradient glowingBorder = LinearGradient(
  colors: [Color(0x802D8EFF), Color(0x308B5CF6), Color(0x101E3050)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
 );
}
