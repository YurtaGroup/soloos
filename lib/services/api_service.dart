import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

/// Drop-in replacement for SupabaseService.
/// Talks to the Next.js backend via REST + JWT tokens.
/// Includes retry with exponential backoff and circuit breaker.
class ApiService {
  static final _storage = StorageService();
  static const _secure = FlutterSecureStorage();
  static String? _accessToken;
  static String? _refreshToken;
  static String? _userId;
  static String? _email;
  static bool _initialized = false;

  // ── Retry & Circuit Breaker config ────────────────────────────────────────
  static const _maxRetries = 2;
  static const _requestTimeout = Duration(seconds: 15);
  static int _consecutiveFailures = 0;
  static DateTime? _circuitOpenUntil;
  static const _circuitThreshold = 5; // open after 5 consecutive failures
  static const _circuitCooldown = Duration(seconds: 30);

  static String get _baseUrl =>
      dotenv.env['API_BASE_URL'] ??
      (kDebugMode ? 'http://localhost:3000' : 'https://solo-os-fastapi.onrender.com');

  // ── State ─────────────────────────────────────────────────────────────────

  static bool get isAuthenticated => _initialized && _accessToken != null;
  static String? get userId => _userId;
  static String? get email => _email;

  /// Call once at startup to restore tokens from secure storage.
  static Future<void> init() async {
    // Fire-and-forget warm-up ping (wakes Render from cold start)
    http.get(Uri.parse('$_baseUrl/api/health')).ignore();

    // Migrate from plain SharedPreferences to secure storage (one-time)
    await _migrateToSecureStorage();

    _accessToken = await _secure.read(key: 'api_access_token');
    _refreshToken = await _secure.read(key: 'api_refresh_token');
    _userId = await _secure.read(key: 'api_user_id');
    _email = await _secure.read(key: 'api_email');
    _initialized = true;

    // Validate token if present
    if (_accessToken != null) {
      try {
        await _request('GET', '/api/auth/me');
      } catch (_) {
        // Token expired — try refresh
        try {
          await _doRefresh();
        } catch (_) {
          // Refresh failed — clear session
          await _clearSession();
        }
      }
    }
  }

  /// One-time migration from SharedPreferences to FlutterSecureStorage.
  static Future<void> _migrateToSecureStorage() async {
    final migrated = _storage.prefs.getBool('secure_storage_migrated') ?? false;
    if (migrated) return;

    for (final key in ['api_access_token', 'api_refresh_token', 'api_user_id', 'api_email']) {
      final value = _storage.prefs.getString(key);
      if (value != null) {
        await _secure.write(key: key, value: value);
        await _storage.prefs.remove(key); // Remove from plain storage
      }
    }
    await _storage.prefs.setBool('secure_storage_migrated', true);
  }

  // ── Auth ─────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final body = {
      'email': email,
      'password': password,
      if (displayName != null) 'displayName': displayName,
    };
    final res = await _requestNoAuth('POST', '/api/auth/register', body: body);
    await _saveSession(res);
    return res;
  }

  static Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    final body = {'email': email, 'password': password};
    final res = await _requestNoAuth('POST', '/api/auth/login', body: body);
    if (res.containsKey('error')) throw ApiException(res['error']);
    await _saveSession(res);
    return res;
  }

  static Future<Map<String, dynamic>> signInWithApple({
    required String identityToken,
    required String authorizationCode,
    String? email,
    String? displayName,
  }) async {
    final body = {
      'identityToken': identityToken,
      'authorizationCode': authorizationCode,
      if (email != null) 'email': email,
      if (displayName != null) 'displayName': displayName,
    };
    final res = await _requestNoAuth('POST', '/api/auth/apple', body: body);
    await _saveSession(res);
    return res;
  }

  static Future<void> signOut() async {
    await _clearSession();
  }

  /// Permanently delete the user's account and all server-side data.
  static Future<bool> deleteAccount() async {
    try {
      await directRequest('DELETE', '/api/auth/account');
      await _clearSession();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Generic CRUD (same interface as SupabaseService) ────────────────────

  /// Fetch all rows for the current user from a table.
  static Future<List<Map<String, dynamic>>> getAll(
    String table, {
    String orderBy = 'created_at',
    bool ascending = false,
  }) async {
    final path = _tablePath(table);
    final data = await _request('GET', path);
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }

  /// Insert a row. The backend auto-adds user_id from the JWT.
  static Future<Map<String, dynamic>> insert(
    String table,
    Map<String, dynamic> row,
  ) async {
    // Remove user_id — backend sets it from JWT
    row.remove('user_id');
    final path = _tablePath(table);
    final data = await _request('POST', path, body: row);
    return Map<String, dynamic>.from(data);
  }

  /// Update a row by id.
  static Future<void> update(
    String table,
    String id,
    Map<String, dynamic> fields,
  ) async {
    fields.remove('updated_at'); // backend handles this
    final path = '${_tablePath(table)}/$id';
    await _request('PATCH', path, body: fields);
  }

  /// Delete a row by id.
  static Future<void> delete(String table, String id) async {
    final path = '${_tablePath(table)}/$id';
    await _request('DELETE', path);
  }

  /// Upsert a row (POST — backend handles upsert for gamification tables).
  static Future<void> upsert(
    String table,
    Map<String, dynamic> row,
  ) async {
    row.remove('user_id');
    final path = _tablePath(table);
    await _request('POST', path, body: row);
  }

  // ── Habit completions (special nested routes) ───────────────────────────

  static Future<void> insertHabitCompletion(
      String habitId, String completedDate) async {
    await _request('POST', '/api/habits/$habitId/completions', body: {
      'completed_date': completedDate,
    });
  }

  static Future<void> deleteHabitCompletion(
      String habitId, String completedDate) async {
    await _request('DELETE', '/api/habits/$habitId/completions', body: {
      'completed_date': completedDate,
    });
  }

  /// Public access for custom endpoints (circles, invites, etc.)
  static Future<dynamic> directRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) =>
      _request(method, path, body: body);

  // ── Table → URL mapping ─────────────────────────────────────────────────

  static String _tablePath(String table) {
    const map = {
      'circles': '/api/circles',
      'profiles': '/api/profiles',
      'projects': '/api/projects',
      'tasks': '/api/tasks',
      'habits': '/api/habits',
      'habit_completions': '/api/habits', // use special methods above
      'standup_logs': '/api/standup-logs',
      'ideas': '/api/ideas',
      'contacts': '/api/contacts',
      'debts': '/api/debts',
      'obligations': '/api/obligations',
      'income_streams': '/api/income-streams',
      'expenses': '/api/expenses',
      'family_people': '/api/family/people',
      'family_reminders': '/api/family/reminders',
      'relationship_notes': '/api/family/notes',
      'gamification_events': '/api/gamification/events',
      'daily_scores': '/api/gamification/daily-scores',
      'streaks': '/api/gamification/streaks',
      'daily_missions': '/api/gamification/missions',
      'ai_coach_suggestions': '/api/gamification/suggestions',
      'user_progress': '/api/gamification/progress',
    };
    return map[table] ?? '/api/$table';
  }

  // ── HTTP internals (with retry + circuit breaker) ───────────────────────

  static Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    // Circuit breaker: fail fast if API is known-down
    if (_circuitOpenUntil != null && DateTime.now().isBefore(_circuitOpenUntil!)) {
      throw ApiException('API temporarily unavailable. Try again shortly.');
    }

    ApiException? lastError;

    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final result = await _doRequest(method, path, body: body);

        // Success — reset circuit breaker
        _consecutiveFailures = 0;
        _circuitOpenUntil = null;
        return result;
      } on ApiException catch (e) {
        // Don't retry client errors (4xx) except 401 (handled inside _doRequest)
        if (e.statusCode != null && e.statusCode! >= 400 && e.statusCode! < 500) {
          rethrow;
        }
        lastError = e;
      } on TimeoutException {
        lastError = ApiException('Request timed out', statusCode: 408);
      } catch (e) {
        lastError = ApiException('Network error: $e');
      }

      // Exponential backoff before retry (200ms, 800ms)
      if (attempt < _maxRetries) {
        await Future.delayed(Duration(milliseconds: 200 * (1 << attempt)));
      }
    }

    // All retries exhausted — update circuit breaker
    _consecutiveFailures++;
    if (_consecutiveFailures >= _circuitThreshold) {
      _circuitOpenUntil = DateTime.now().add(_circuitCooldown);
      debugPrint('Circuit breaker OPEN — API calls paused for ${_circuitCooldown.inSeconds}s');
    }

    throw lastError ?? ApiException('Request failed');
  }

  static Future<dynamic> _doRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
    };

    http.Response res;
    switch (method) {
      case 'GET':
        res = await http.get(uri, headers: headers).timeout(_requestTimeout);
        break;
      case 'POST':
        res = await http.post(uri, headers: headers, body: jsonEncode(body)).timeout(_requestTimeout);
        break;
      case 'PATCH':
        res = await http.patch(uri, headers: headers, body: jsonEncode(body)).timeout(_requestTimeout);
        break;
      case 'DELETE':
        if (body != null) {
          final request = http.Request('DELETE', uri)
            ..headers.addAll(headers)
            ..body = jsonEncode(body);
          final streamed = await http.Client().send(request).timeout(_requestTimeout);
          res = await http.Response.fromStream(streamed);
        } else {
          res = await http.delete(uri, headers: headers).timeout(_requestTimeout);
        }
        break;
      default:
        throw ApiException('Unsupported method: $method');
    }

    // Auto-refresh on 401
    if (res.statusCode == 401 && _refreshToken != null) {
      await _doRefresh();
      return _doRequest(method, path, body: body); // retry once with new token
    }

    if (res.statusCode >= 400) {
      final error = _tryParseError(res.body);
      throw ApiException(error ?? 'Request failed (${res.statusCode})', statusCode: res.statusCode);
    }

    if (res.body.isEmpty) return {};
    try {
      return jsonDecode(res.body);
    } on FormatException {
      throw ApiException('Invalid server response', statusCode: res.statusCode);
    }
  }

  static Future<dynamic> _requestNoAuth(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = {'Content-Type': 'application/json'};

    final res = await http.post(uri, headers: headers, body: jsonEncode(body));

    if (res.statusCode >= 400) {
      try {
        final parsed = jsonDecode(res.body);
        throw ApiException(parsed['detail'] ?? parsed['error'] ?? 'Request failed (${res.statusCode})', statusCode: res.statusCode);
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException('Server error (${res.statusCode})', statusCode: res.statusCode);
      }
    }

    try {
      return jsonDecode(res.body);
    } on FormatException {
      throw ApiException('Invalid server response');
    }
  }

  static Future<void> _doRefresh() async {
    final res = await _requestNoAuth('POST', '/api/auth/refresh', body: {
      'refreshToken': _refreshToken,
    });
    _accessToken = res['accessToken'];
    _refreshToken = res['refreshToken'];
    await _secure.write(key: 'api_access_token', value: _accessToken!);
    await _secure.write(key: 'api_refresh_token', value: _refreshToken!);
  }

  static Future<void> _saveSession(Map<String, dynamic> res) async {
    _accessToken = res['accessToken'];
    _refreshToken = res['refreshToken'];
    _userId = res['user']?['id'];
    _email = res['user']?['email'];
    await _secure.write(key: 'api_access_token', value: _accessToken!);
    await _secure.write(key: 'api_refresh_token', value: _refreshToken!);
    if (_userId != null) {
      await _secure.write(key: 'api_user_id', value: _userId!);
    }
    if (_email != null) {
      await _secure.write(key: 'api_email', value: _email!);
    }
  }

  static Future<void> _clearSession() async {
    _accessToken = null;
    _refreshToken = null;
    _userId = null;
    _email = null;
    await _secure.delete(key: 'api_access_token');
    await _secure.delete(key: 'api_refresh_token');
    await _secure.delete(key: 'api_user_id');
    await _secure.delete(key: 'api_email');
  }

  static String? _tryParseError(String body) {
    try {
      final json = jsonDecode(body);
      return (json['detail'] ?? json['error']) as String?;
    } catch (_) {
      return null;
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}
