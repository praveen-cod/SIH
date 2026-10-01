import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

Future<void> main() async {
 WidgetsFlutterBinding.ensureInitialized();
 try {
  await dotenv.load(fileName: ".env");
 } catch (e) {
  debugPrint('Warning: Could not load .env file: $e');
 }
 runApp(
  const ProviderScope(
   child: HealthCallApp(),
  ),
 );
}

class HealthCallApp extends ConsumerWidget {
 const HealthCallApp({super.key});

 @override
 Widget build(BuildContext context, WidgetRef ref) {
  final router = ref.watch(appRouterProvider);
  final themeMode = ref.watch(themeModeProvider);

  return MaterialApp.router(
   title: 'HealthCall AI',
   debugShowCheckedModeBanner: false,
   theme: AppTheme.lightTheme,
   darkTheme: AppTheme.darkTheme,
   themeMode: themeMode,
   routerConfig: router,
  );
 }
}
