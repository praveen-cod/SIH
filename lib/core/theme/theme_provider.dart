import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
 return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
 ThemeModeNotifier() : super(ThemeMode.light);

 Future<void> initTheme() async {
  state = ThemeMode.light;
 }

 Future<void> toggleTheme() async {
  // Light theme is enforced globally
  state = ThemeMode.light;
 }
}
