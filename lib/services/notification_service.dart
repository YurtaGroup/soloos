import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';
import 'locale_service.dart';
import '../models/app_models.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  static const _dailyDigestId = 1;
  static const _birthdayIdBase = 1000; // IDs 1000+ reserved for birthdays
  static const _prefKey = 'daily_digest_enabled';

  bool _initialized = false;
  bool _digestEnabled = false;
  bool get digestEnabled => _digestEnabled;

  String get _userName {
    try { return StorageService().userName; } catch (_) { return ''; }
  }

  LocaleService get _loc {
    try { return LocaleService(); } catch (_) { return LocaleService(); }
  }

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    final prefs = await SharedPreferences.getInstance();
    _digestEnabled = prefs.getBool(_prefKey) ?? false;
    _initialized = true;

    if (_digestEnabled) {
      await _scheduleDailyDigest();
    }
  }

  Future<bool> requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? false;
    }

    return false;
  }

  Future<void> toggleDailyDigest(bool enabled) async {
    _digestEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);

    if (enabled) {
      await requestPermission();
      await _scheduleDailyDigest();
    } else {
      await _plugin.cancel(_dailyDigestId);
    }
  }

  Future<void> _scheduleDailyDigest() async {
    final loc = _loc;
    final name = _userName;
    final channelName = loc.t('notif_channel_name');
    final channelDesc = loc.t('notif_channel_desc');
    final title = '☀️ ${loc.t('notif_morning_title', {'name': name})}';
    final body = loc.t('notif_morning_body');

    final androidDetails = AndroidNotificationDetails(
      'daily_digest',
      channelName,
      channelDescription: channelDesc,
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      _dailyDigestId,
      title,
      body,
      _nextInstanceOf8am(),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOf8am() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 8);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  // ─── Birthday Notifications ───────────────────────────────────

  /// Schedule notifications for upcoming birthdays (within 7 days).
  /// Call this after contacts are loaded or modified.
  Future<void> scheduleBirthdayReminders(List<Contact> contacts) async {
    if (!_initialized) return;

    // Cancel all existing birthday notifications
    for (int i = 0; i < 100; i++) {
      await _plugin.cancel(_birthdayIdBase + i);
    }

    final loc = _loc;
    int idx = 0;

    for (final contact in contacts) {
      if (idx >= 100) break; // Max 100 birthday notifications

      final daysUntil = contact.daysUntilBirthday;
      if (daysUntil > 7 || daysUntil < 0) continue;

      final now = tz.TZDateTime.now(tz.local);
      final notifDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        9, // 9 AM
      ).add(Duration(days: daysUntil));

      // Skip if already in the past
      if (notifDate.isBefore(now)) continue;

      final title = daysUntil == 0
          ? '🎂 ${contact.name}\'s birthday is today!'
          : '🎂 ${contact.name}\'s birthday in $daysUntil day${daysUntil == 1 ? '' : 's'}';

      final body = daysUntil == 0
          ? 'Don\'t forget to wish them a happy birthday!'
          : 'Get a gift or send a message!';

      final androidDetails = AndroidNotificationDetails(
        'birthdays',
        loc.t('upcoming_birthdays'),
        channelDescription: 'Birthday reminders for your contacts',
        importance: Importance.high,
        priority: Priority.high,
      );
      const iosDetails = DarwinNotificationDetails();
      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _plugin.zonedSchedule(
        _birthdayIdBase + idx,
        title,
        body,
        notifDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      idx++;
    }
  }
}
