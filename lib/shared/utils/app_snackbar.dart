import 'package:flutter/material.dart';

/// High-contrast notification helper for HealthCall AI
/// Ensures text/content is 100% clearly readable across all screens and themes.
class AppSnackbar {
 AppSnackbar._();

 /// Approval / Success: Solid vibrant Green with crisp bold Black text & icon
 static void showSuccess(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
   SnackBar(
    content: Row(
     children: [
      const Icon(Icons.check_circle_rounded, color: Colors.black, size: 22),
      const SizedBox(width: 10),
      Expanded(
       child: Text(
        message,
        style: const TextStyle(
         color: Colors.black,
         fontWeight: FontWeight.w700,
         fontSize: 14,
        ),
       ),
      ),
     ],
    ),
    backgroundColor: const Color(0xFF22C55E), // Vibrant Green
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    duration: const Duration(seconds: 3),
   ),
  );
 }

 /// Wrong / Error / Decline: Solid vibrant Red with crisp bold Black text & icon
 static void showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
   SnackBar(
    content: Row(
     children: [
      const Icon(Icons.cancel_rounded, color: Colors.black, size: 22),
      const SizedBox(width: 10),
      Expanded(
       child: Text(
        message,
        style: const TextStyle(
         color: Colors.black,
         fontWeight: FontWeight.w700,
         fontSize: 14,
        ),
       ),
      ),
     ],
    ),
    backgroundColor: const Color(0xFFEF4444), // Vibrant Red
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    duration: const Duration(seconds: 3),
   ),
  );
 }

 /// Warning / Info: Solid vibrant Amber with crisp bold Black text & icon
 static void showWarning(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
   SnackBar(
    content: Row(
     children: [
      const Icon(Icons.info_rounded, color: Colors.black, size: 22),
      const SizedBox(width: 10),
      Expanded(
       child: Text(
        message,
        style: const TextStyle(
         color: Colors.black,
         fontWeight: FontWeight.w700,
         fontSize: 14,
        ),
       ),
      ),
     ],
    ),
    backgroundColor: const Color(0xFFF59E0B), // Vibrant Amber
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    duration: const Duration(seconds: 3),
   ),
  );
 }
}
