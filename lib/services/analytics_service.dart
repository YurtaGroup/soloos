import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'api_service.dart';

/// Lightweight analytics service that tracks user actions to the backend.
/// Batches events and flushes every 30s or when batch hits 20 events.
/// Falls back to local queue if offline — flushes on next app open.
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  static const _batchSize = 20;
  static const _flushInterval = Duration(seconds: 30);
  static const _localQueueKey = 'analytics_queue';

  final List<Map<String, dynamic>> _buffer = [];
  Timer? _timer;
  String? _sessionId;
  SharedPreferences? _prefs;
  bool _initialized = false;

  String get _baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';

  /// Call once at startup.
  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _sessionId = const Uuid().v4();
    _initialized = true;

    // Start periodic flush
    _timer = Timer.periodic(_flushInterval, (_) => flush());

    // Flush any events queued from previous session
    await _flushLocalQueue();

    // Track app open
    track('app_open', category: 'lifecycle');
  }

  /// Track a single event.
  void track(
    String event, {
    String category = 'general',
    Map<String, dynamic>? properties,
  }) {
    if (!_initialized) return;

    _buffer.add({
      'event': event,
      'category': category,
      'properties': properties ?? {},
      'sessionId': _sessionId,
      'platform': defaultTargetPlatform == TargetPlatform.iOS
          ? 'ios'
          : defaultTargetPlatform == TargetPlatform.android
              ? 'android'
              : 'other',
      'appVersion': '1.0.0',
    });

    if (_buffer.length >= _batchSize) {
      flush();
    }
  }

  // ── Convenience trackers ─────────────────────────────────────────

  void screenView(String screenName) =>
      track('screen_view', category: 'navigation', properties: {'screen': screenName});

  void featureUsed(String feature, {Map<String, dynamic>? extra}) =>
      track('feature_used', category: 'engagement', properties: {'feature': feature, ...?extra});

  void aiCall(String type) =>
      track('ai_call', category: 'ai', properties: {'type': type});

  void taskCompleted() => track('task_completed', category: 'work');
  void habitCompleted(String habitName) =>
      track('habit_completed', category: 'health', properties: {'habit': habitName});

  void projectCreated() => track('project_created', category: 'work');
  void ideaCreated() => track('idea_created', category: 'ideas');
  void expenseLogged(double amount, String currency) =>
      track('expense_logged', category: 'finance', properties: {'amount': amount, 'currency': currency});

  void standupSubmitted() => track('standup_submitted', category: 'work');
  void contactAdded() => track('contact_added', category: 'family');
  void circleCreated() => track('circle_created', category: 'social');
  void subscriptionViewed() => track('subscription_viewed', category: 'monetization');
  void subscriptionStarted(String plan) =>
      track('subscription_started', category: 'monetization', properties: {'plan': plan});

  // ── Flush logic ──────────────────────────────────────────────────

  Future<void> flush() async {
    if (_buffer.isEmpty) return;

    final batch = List<Map<String, dynamic>>.from(_buffer);
    _buffer.clear();

    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      // Add auth token if available
      if (ApiService.isAuthenticated) {
        try {
          await ApiService.directRequest('POST', '/api/analytics/track',
              body: {'events': batch});
          return;
        } catch (_) {
          // Fall through to unauthenticated attempt
        }
      }

      // Unauthenticated fallback
      final uri = Uri.parse('$_baseUrl/api/analytics/track');
      final res = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({'events': batch}),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode >= 400) {
        // Failed — save to local queue for retry
        await _saveToLocalQueue(batch);
      }
    } catch (e) {
      // Offline — save to local queue
      debugPrint('Analytics flush failed, queuing locally: $e');
      await _saveToLocalQueue(batch);
    }
  }

  Future<void> _saveToLocalQueue(List<Map<String, dynamic>> events) async {
    if (_prefs == null) return;
    final existing = _prefs!.getStringList(_localQueueKey) ?? [];
    for (final e in events) {
      existing.add(jsonEncode(e));
    }
    // Cap at 500 queued events
    if (existing.length > 500) {
      existing.removeRange(0, existing.length - 500);
    }
    await _prefs!.setStringList(_localQueueKey, existing);
  }

  Future<void> _flushLocalQueue() async {
    if (_prefs == null) return;
    final queued = _prefs!.getStringList(_localQueueKey);
    if (queued == null || queued.isEmpty) return;

    final events = queued
        .map((s) {
          try { return jsonDecode(s) as Map<String, dynamic>; }
          catch (_) { return null; }
        })
        .whereType<Map<String, dynamic>>()
        .toList();

    await _prefs!.remove(_localQueueKey);

    if (events.isNotEmpty) {
      _buffer.addAll(events);
      await flush();
    }
  }

  /// Call on app pause/close to flush remaining events.
  Future<void> dispose() async {
    _timer?.cancel();
    await flush();
  }
}
