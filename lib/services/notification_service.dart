import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';
import 'locale_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  static const _dailyDigestId = 1;
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
}
