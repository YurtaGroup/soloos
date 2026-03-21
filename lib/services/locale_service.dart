import 'package:flutter/material.dart';
import 'storage_service.dart';
import '../l10n/app_strings.dart';

class LocaleService extends ChangeNotifier {
  static final LocaleService _instance = LocaleService._internal();
  factory LocaleService() => _instance;
  LocaleService._internal();

  final _storage = StorageService();

  String _locale = 'en';
  String get locale => _locale;

  static const List<_LangOption> languages = [
    _LangOption('en', 'English', '🇺🇸'),
    _LangOption('ru', 'Русский', '🇷🇺'),
    _LangOption('ky', 'Кыргызча', '🇰🇬'),
  ];

  Future<void> init() async {
    _locale = _storage.prefs.getString('locale') ?? 'en';
  }

  Future<void> setLocale(String locale) async {
    _locale = locale;
    await _storage.prefs.setString('locale', locale);
    notifyListeners();
  }

  /// Translate a key, with optional named param substitution.
  /// e.g. t('in_days', {'n': '3'}) → 'in 3d'
  String t(String key, [Map<String, String>? params]) {
    String value = appStrings[_locale]?[key] ?? appStrings['en']?[key] ?? key;
    if (params != null) {
      params.forEach((k, v) => value = value.replaceAll('{$k}', v));
    }
    return value;
  }

  Locale get flutterLocale {
    switch (_locale) {
      case 'ru':
        return const Locale('ru', 'RU');
      case 'ky':
        return const Locale('ky', 'KG');
      default:
        return const Locale('en', 'US');
    }
  }
}

class _LangOption {
  final String code, name, flag;
  const _LangOption(this.code, this.name, this.flag);
}

/// Shorthand: access the singleton anywhere without context
final ls = LocaleService();
