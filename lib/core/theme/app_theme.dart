import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Main application theme for HealthCall AI (Claymorphism Edition)
class AppTheme {
 AppTheme._();

 static ThemeData get lightTheme {
  return ThemeData(
   useMaterial3: true,
   brightness: Brightness.light,
   scaffoldBackgroundColor: AppColors.backgroundLight,
   colorScheme: const ColorScheme.light(
    surface: AppColors.surfaceLight,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    error: AppColors.error,
    onSurface: AppColors.textPrimaryLight,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onError: Colors.white,
   ),
   fontFamily: GoogleFonts.inter().fontFamily,
   textTheme: const TextTheme(
    displayLarge: AppTextStyles.displayLarge,
    displayMedium: AppTextStyles.displayMedium,
    displaySmall: AppTextStyles.displaySmall,
    headlineLarge: AppTextStyles.headingLarge,
    headlineMedium: AppTextStyles.headingMedium,
    headlineSmall: AppTextStyles.headingSmall,
    bodyLarge: AppTextStyles.bodyLarge,
    bodyMedium: AppTextStyles.bodyMedium,
    bodySmall: AppTextStyles.bodySmall,
    labelLarge: AppTextStyles.labelLarge,
    labelMedium: AppTextStyles.labelMedium,
    labelSmall: AppTextStyles.labelSmall,
   ).apply(
    bodyColor: AppColors.textPrimaryLight,
    displayColor: AppColors.textPrimaryLight,
   ),
   appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.backgroundLight,
    foregroundColor: AppColors.textPrimaryLight,
    elevation: 0,
    scrolledUnderElevation: 0,
    iconTheme: IconThemeData(color: AppColors.textPrimaryLight),
   ),
   iconTheme: const IconThemeData(color: AppColors.textSecondaryLight),
   navigationDrawerTheme: const NavigationDrawerThemeData(
    backgroundColor: AppColors.surfaceLight,
    indicatorColor: AppColors.primaryLight,
   ),
   bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.surfaceLight,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.textMutedLight,
    showUnselectedLabels: true,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
   ),
  );
 }

 static ThemeData get darkTheme {
  return ThemeData(
   useMaterial3: true,
   brightness: Brightness.dark,
   scaffoldBackgroundColor: AppColors.backgroundDark,
   colorScheme: const ColorScheme.dark(
    surface: AppColors.surfaceDark,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    error: AppColors.error,
    onSurface: AppColors.textPrimaryDark,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onError: Colors.white,
   ),
   fontFamily: GoogleFonts.inter().fontFamily,
   textTheme: const TextTheme(
    displayLarge: AppTextStyles.displayLarge,
    displayMedium: AppTextStyles.displayMedium,
    displaySmall: AppTextStyles.displaySmall,
    headlineLarge: AppTextStyles.headingLarge,
    headlineMedium: AppTextStyles.headingMedium,
    headlineSmall: AppTextStyles.headingSmall,
    bodyLarge: AppTextStyles.bodyLarge,
    bodyMedium: AppTextStyles.bodyMedium,
    bodySmall: AppTextStyles.bodySmall,
    labelLarge: AppTextStyles.labelLarge,
    labelMedium: AppTextStyles.labelMedium,
    labelSmall: AppTextStyles.labelSmall,
   ).apply(
    bodyColor: AppColors.textPrimaryDark,
    displayColor: AppColors.textPrimaryDark,
   ),
   appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.backgroundDark,
    foregroundColor: AppColors.textPrimaryDark,
    elevation: 0,
    scrolledUnderElevation: 0,
    iconTheme: IconThemeData(color: AppColors.textPrimaryDark),
   ),
   iconTheme: const IconThemeData(color: AppColors.textSecondaryDark),
   navigationDrawerTheme: const NavigationDrawerThemeData(
    backgroundColor: AppColors.surfaceDark,
    indicatorColor: AppColors.primaryDark,
   ),
   bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.surfaceDark,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.textMutedDark,
    showUnselectedLabels: true,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
   ),
  );
 }
}
