import 'package:flutter/material.dart';

/// Centralized shadows for HealthCall AI
class AppShadows {
 AppShadows._();

 static const List<BoxShadow> card = [
  BoxShadow(
   color: Color(0x60000000),
   blurRadius: 20,
   offset: Offset(0, 8),
  ),
 ];

 static const List<BoxShadow> cardElevated = [
  BoxShadow(
   color: Color(0x80000000),
   blurRadius: 28,
   offset: Offset(0, 12),
  ),
  BoxShadow(
   color: Color(0x152D8EFF),
   blurRadius: 16,
   offset: Offset(0, 2),
  ),
 ];

 static List<BoxShadow> glow(Color color, {double opacity = 0.25, double blur = 20}) {
  return [
   BoxShadow(
    color: color.withValues(alpha: opacity),
    blurRadius: blur,
    offset: const Offset(0, 4),
   ),
   const BoxShadow(
    color: Color(0x40000000),
    blurRadius: 12,
    offset: Offset(0, 4),
   ),
  ];
 }

 static const List<BoxShadow> primaryGlow = [
  BoxShadow(
   color: Color(0x402D8EFF),
   blurRadius: 24,
   spreadRadius: 0,
   offset: Offset(0, 6),
  ),
 ];

 static const List<BoxShadow> emergencyGlow = [
  BoxShadow(
   color: Color(0x50EF4444),
   blurRadius: 20,
   spreadRadius: 1,
   offset: Offset(0, 4),
  ),
 ];
}
