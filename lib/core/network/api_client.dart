import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env_config.dart';

/// Central API Client for HealthCall AI
/// Handles base URL routing, JWT authorization injection, UTF-8 parsing, and status code errors.
class ApiClient {
  static const String publicHostedUrl = 'https://witch-exists-headers-assistance.trycloudflare.com';
  static const String defaultLocalUrl = 'http://127.0.0.1:8000';
  static const String defaultAndroidEmulatorUrl = 'http://10.0.2.2:8000';
  static const String lanUrl = 'http://10.209.83.140:8000';

  /// Clean helper to strip trailing slashes
  static String cleanUrl(String url) => EnvConfig.cleanUrl(url);

  static String? _customActiveBaseUrl;

  /// Currently active base URL for backend API calls imported from .env
  static String get activeBaseUrl => _customActiveBaseUrl ?? EnvConfig.backendUrl;
  static set activeBaseUrl(String url) => _customActiveBaseUrl = cleanUrl(url);

  static const String tokenKey = 'healthcall_jwt_token';
  static const String userRoleKey = 'healthcall_user_role';
  static const String userIdKey = 'healthcall_user_id';
  static const String userNameKey = 'healthcall_user_name';

  final http.Client _httpClient;

  ApiClient({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  /// Retrieves the stored JWT token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  /// Saves session data
  static Future<void> saveSession({
    required String token,
    required String role,
    required String userId,
    required String name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
    await prefs.setString(userRoleKey, role);
    await prefs.setString(userIdKey, userId);
    await prefs.setString(userNameKey, name);
  }

  /// Clears session data
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(userRoleKey);
    await prefs.remove(userIdKey);
    await prefs.remove(userNameKey);
  }

  /// Prepares standard headers with optional JWT
  Future<Map<String, String>> _getHeaders({bool requireAuth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
      'bypass-tunnel-reminder': 'true',
    };

    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    } else if (requireAuth) {
      debugPrint('Warning: Authorization token required but not present in local storage.');
    }
    return headers;
  }

  Uri _buildUri(String endpoint, [Map<String, String>? queryParams]) {
    final base = cleanUrl(activeBaseUrl);
    final normalizedEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final urlStr = '$base$normalizedEndpoint';
    final uri = Uri.parse(urlStr);
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams, bool requireAuth = false}) async {
    final uri = _buildUri(endpoint, queryParams);
    final headers = await _getHeaders(requireAuth: requireAuth);

    try {
      final response = await _httpClient.get(uri, headers: headers).timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } catch (e) {
      debugPrint('ApiClient GET $uri failed: $e');
      rethrow;
    }
  }

  Future<dynamic> post(String endpoint, {dynamic body, bool requireAuth = false}) async {
    final uri = _buildUri(endpoint);
    final headers = await _getHeaders(requireAuth: requireAuth);

    try {
      final response = await _httpClient
          .post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } catch (e) {
      debugPrint('ApiClient POST $uri failed: $e');
      rethrow;
    }
  }

  Future<dynamic> put(String endpoint, {dynamic body, bool requireAuth = false}) async {
    final uri = _buildUri(endpoint);
    final headers = await _getHeaders(requireAuth: requireAuth);

    try {
      final response = await _httpClient
          .put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } catch (e) {
      debugPrint('ApiClient PUT $uri failed: $e');
      rethrow;
    }
  }

  Future<dynamic> delete(String endpoint, {bool requireAuth = false}) async {
    final uri = _buildUri(endpoint);
    final headers = await _getHeaders(requireAuth: requireAuth);

    try {
      final response = await _httpClient.delete(uri, headers: headers).timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } catch (e) {
      debugPrint('ApiClient DELETE $uri failed: $e');
      rethrow;
    }
  }

  dynamic _processResponse(http.Response response) {
    final statusCode = response.statusCode;
    final bodyString = utf8.decode(response.bodyBytes);

    dynamic decoded;
    try {
      decoded = jsonDecode(bodyString);
    } catch (_) {
      decoded = bodyString;
    }

    if (statusCode >= 200 && statusCode < 300) {
      return decoded;
    }

    String errorMessage = 'Request failed with status $statusCode';
    if (decoded is Map<String, dynamic> && decoded.containsKey('detail')) {
      errorMessage = decoded['detail'].toString();
    }

    throw ApiException(statusCode: statusCode, message: errorMessage);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => message;
}

/// Riverpod Provider for ApiClient
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
