import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central environment configuration for HealthCall AI
/// Imports and resolves the backend URL directly from the .env file.
class EnvConfig {
 static const String _defaultFallbackUrl = 'http://10.209.83.140:8000';

 /// Compile-time define fallback (e.g. from --dart-define-from-file=.env)
 static const String _compileTimeUrl = String.fromEnvironment(
  'BACKEND_API_URL',
  defaultValue: String.fromEnvironment('API_BASE_URL', defaultValue: ''),
 );

 /// Helper to sanitize any URL by trimming whitespace and trailing slashes
 static String cleanUrl(String url) {
  var u = url.trim();
  while (u.endsWith('/')) {
   u = u.substring(0, u.length - 1);
  }
  return u;
 }

 /// Active Backend API Base URL imported directly from .env
 static String get backendUrl {
  // 1. Check flutter_dotenv (loaded at runtime from .env asset)
  try {
   if (dotenv.isInitialized) {
    final envVal = dotenv.env['BACKEND_API_URL'] ?? dotenv.env['API_BASE_URL'];
    if (envVal != null && envVal.trim().isNotEmpty) {
     return cleanUrl(envVal);
    }
   }
  } catch (e) {
   debugPrint('EnvConfig: Error reading dotenv: $e');
  }

  // 2. Check compile-time environment definition
  if (_compileTimeUrl.trim().isNotEmpty) {
   return cleanUrl(_compileTimeUrl);
  }

  // 3. Fallback to default local host address
  return cleanUrl(_defaultFallbackUrl);
 }

 /// Active consultations endpoint URL derived from backendUrl
 static String get consultationsUrl => '$backendUrl/api/consultations';
}
