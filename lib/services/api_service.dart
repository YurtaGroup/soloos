import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

/// Drop-in replacement for SupabaseService.
/// Talks to the Next.js backend via REST + JWT tokens.
class ApiService {
  static final _storage = StorageService();
  static String? _accessToken;
  static String? _refreshToken;
  static String? _userId;
  static String? _email;
  static bool _initialized = false;

  static String get _baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';

  // ── State ─────────────────────────────────────────────────────────────────

  static bool get isAuthenticated => _initialized && _accessToken != null;
  static String? get userId => _userId;
  static String? get email => _email;

  /// Call once at startup to restore tokens from local storage.
  static Future<void> init() async {
    _accessToken = _storage.prefs.getString('api_access_token');
    _refreshToken = _storage.prefs.getString('api_refresh_token');
    _userId = _storage.prefs.getString('api_user_id');
    _email = _storage.prefs.getString('api_email');
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

  static Future<void> signOut() async {
    await _clearSession();
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

  // ── Table → URL mapping ─────────────────────────────────────────────────

  static String _tablePath(String table) {
    const map = {
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

  // ── HTTP internals ──────────────────────────────────────────────────────

  static Future<dynamic> _request(
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
        res = await http.get(uri, headers: headers);
        break;
      case 'POST':
        res = await http.post(uri, headers: headers, body: jsonEncode(body));
        break;
      case 'PATCH':
        res = await http.patch(uri, headers: headers, body: jsonEncode(body));
        break;
      case 'DELETE':
        if (body != null) {
          final request = http.Request('DELETE', uri)
            ..headers.addAll(headers)
            ..body = jsonEncode(body);
          final streamed = await http.Client().send(request);
          res = await http.Response.fromStream(streamed);
        } else {
          res = await http.delete(uri, headers: headers);
        }
        break;
      default:
        throw ApiException('Unsupported method: $method');
    }

    // Auto-refresh on 401
    if (res.statusCode == 401 && _refreshToken != null) {
      await _doRefresh();
      return _request(method, path, body: body); // retry once
    }

    if (res.statusCode >= 400) {
      final error = _tryParseError(res.body);
      throw ApiException(error ?? 'Request failed (${res.statusCode})');
    }

    if (res.body.isEmpty) return {};
    return jsonDecode(res.body);
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
      final parsed = jsonDecode(res.body);
      throw ApiException(parsed['error'] ?? 'Request failed');
    }

    return jsonDecode(res.body);
  }

  static Future<void> _doRefresh() async {
    final res = await _requestNoAuth('POST', '/api/auth/refresh', body: {
      'refreshToken': _refreshToken,
    });
    _accessToken = res['accessToken'];
    _refreshToken = res['refreshToken'];
    await _storage.prefs.setString('api_access_token', _accessToken!);
    await _storage.prefs.setString('api_refresh_token', _refreshToken!);
  }

  static Future<void> _saveSession(Map<String, dynamic> res) async {
    _accessToken = res['accessToken'];
    _refreshToken = res['refreshToken'];
    _userId = res['user']?['id'];
    _email = res['user']?['email'];
    await _storage.prefs.setString('api_access_token', _accessToken!);
    await _storage.prefs.setString('api_refresh_token', _refreshToken!);
    if (_userId != null) {
      await _storage.prefs.setString('api_user_id', _userId!);
    }
    if (_email != null) {
      await _storage.prefs.setString('api_email', _email!);
    }
  }

  static Future<void> _clearSession() async {
    _accessToken = null;
    _refreshToken = null;
    _userId = null;
    _email = null;
    await _storage.prefs.remove('api_access_token');
    await _storage.prefs.remove('api_refresh_token');
    await _storage.prefs.remove('api_user_id');
    await _storage.prefs.remove('api_email');
  }

  static String? _tryParseError(String body) {
    try {
      final json = jsonDecode(body);
      return json['error'] as String?;
    } catch (_) {
      return null;
    }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}
