import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Single source of truth for Pro status and engagement streak.
///
/// Uses RevenueCat for real subscription management on iOS/Android.
/// Falls back to local trial tracking when RevenueCat is not configured.
class ProService extends ChangeNotifier {
  static final ProService _instance = ProService._internal();
  factory ProService() => _instance;
  ProService._internal();

  SharedPreferences? _prefs;

  bool _isPro = false;
  int _streakDays = 0;
  int _totalDaysActive = 0;
  DateTime? _trialEndsAt;
  bool _revenueCatReady = false;

  // ── RevenueCat config ─────────────────────────────────────────
  // Set these in RevenueCat dashboard → API Keys
  static const _iosApiKey = 'test_DhNYipyoUnwqgTmNPUqXdpgwHPs';
  static const _androidApiKey = 'test_DhNYipyoUnwqgTmNPUqXdpgwHPs';

  // Product identifiers (must match App Store Connect / Google Play Console)
  static const entitlementId = 'pro';
  static const monthlyProductId = 'solo_os_pro_monthly';
  static const yearlyProductId = 'solo_os_pro_yearly';

  // ── Getters ────────────────────────────────────────────────────

  bool get isPro => _isPro;
  int get streakDays => _streakDays;
  int get totalDaysActive => _totalDaysActive;
  DateTime? get trialEndsAt => _trialEndsAt;
  bool get revenueCatReady => _revenueCatReady;

  bool get isTrialActive =>
      _trialEndsAt != null && _trialEndsAt!.isAfter(DateTime.now());

  bool get hasAccess => _isPro || isTrialActive;

  /// Days remaining in trial, or 0 if no active trial.
  int get trialDaysLeft {
    if (_trialEndsAt == null) return 0;
    final diff = _trialEndsAt!.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  String get streakEmoji {
    if (_streakDays >= 30) return '🏆';
    if (_streakDays >= 14) return '🔥';
    if (_streakDays >= 7) return '⚡';
    if (_streakDays >= 3) return '✨';
    return '🌱';
  }

  // ── Init ───────────────────────────────────────────────────────

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _isPro = _prefs!.getBool('is_pro') ?? false;
    _streakDays = _prefs!.getInt('streak_days') ?? 0;
    _totalDaysActive = _prefs!.getInt('total_days_active') ?? 0;

    final trialStr = _prefs!.getString('trial_ends_at');
    if (trialStr != null) {
      _trialEndsAt = DateTime.tryParse(trialStr);
    }

    await _updateStreak();
    await _initRevenueCat();
    notifyListeners();
  }

  Future<void> _initRevenueCat() async {
    // Skip if API keys aren't configured yet
    if (_iosApiKey.contains('YOUR_') && _androidApiKey.contains('YOUR_')) {
      return;
    }

    try {
      final apiKey = defaultTargetPlatform == TargetPlatform.iOS
          ? _iosApiKey
          : _androidApiKey;

      await Purchases.configure(
        PurchasesConfiguration(apiKey),
      );

      _revenueCatReady = true;

      // Check current entitlements
      await _refreshProStatus();

      // Listen for future changes
      Purchases.addCustomerInfoUpdateListener((info) {
        _checkEntitlements(info);
      });
    } catch (e) {
      debugPrint('RevenueCat init failed: $e');
    }
  }

  Future<void> _refreshProStatus() async {
    try {
      final info = await Purchases.getCustomerInfo();
      _checkEntitlements(info);
    } catch (e) {
      debugPrint('RevenueCat refresh failed: $e');
    }
  }

  void _checkEntitlements(CustomerInfo info) {
    final isActive = info.entitlements.all[entitlementId]?.isActive ?? false;
    if (isActive != _isPro) {
      _isPro = isActive;
      _prefs?.setBool('is_pro', _isPro);
      notifyListeners();
    }
  }

  // ── Streak tracking ────────────────────────────────────────────

  Future<void> _updateStreak() async {
    if (_prefs == null) return;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastActive = _prefs!.getString('last_active_date') ?? '';

    if (lastActive == today) return; // Already counted today

    final yesterday = DateFormat('yyyy-MM-dd')
        .format(DateTime.now().subtract(const Duration(days: 1)));

    if (lastActive == yesterday) {
      // Consecutive day — extend streak
      _streakDays += 1;
    } else if (lastActive.isEmpty) {
      // First ever session
      _streakDays = 1;
    } else {
      // Streak broken
      _streakDays = 1;
    }

    _totalDaysActive += 1;
    await _prefs!.setString('last_active_date', today);
    await _prefs!.setInt('streak_days', _streakDays);
    await _prefs!.setInt('total_days_active', _totalDaysActive);
    notifyListeners();
  }

  // ── Pro / Trial management ─────────────────────────────────────

  /// Starts a 30-day free trial. Returns false if trial already used.
  Future<bool> startTrial() async {
    if (_prefs == null) return false;
    final alreadyUsed = _prefs!.getBool('trial_used') ?? false;
    if (alreadyUsed || _isPro) return false;

    _trialEndsAt = DateTime.now().add(const Duration(days: 30));
    await _prefs!.setString('trial_ends_at', _trialEndsAt!.toIso8601String());
    await _prefs!.setBool('trial_used', true);
    notifyListeners();
    return true;
  }

  /// Purchase a subscription via RevenueCat.
  /// Returns true if purchase succeeded.
  Future<bool> purchase(String productId) async {
    if (!_revenueCatReady) return false;

    try {
      final offerings = await Purchases.getOfferings();
      final packages = offerings.current?.availablePackages ?? [];

      StoreProduct? product;
      for (final pkg in packages) {
        if (pkg.storeProduct.identifier == productId) {
          product = pkg.storeProduct;
          break;
        }
      }

      if (product == null) {
        debugPrint('Product $productId not found in offerings');
        return false;
      }

      final result = await Purchases.purchaseStoreProduct(product);
      final isActive =
          result.entitlements.all[entitlementId]?.isActive ?? false;

      if (isActive) {
        _isPro = true;
        _trialEndsAt = null;
        await _prefs?.setBool('is_pro', true);
        notifyListeners();
        return true;
      }
      return false;
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        return false; // User cancelled — not an error
      }
      debugPrint('Purchase error: $e');
      return false;
    } catch (e) {
      debugPrint('Purchase error: $e');
      return false;
    }
  }

  /// Restore previous purchases (for reinstalls / device switches).
  Future<bool> restorePurchases() async {
    if (!_revenueCatReady) return false;

    try {
      final info = await Purchases.restorePurchases();
      _checkEntitlements(info);
      return _isPro;
    } catch (e) {
      debugPrint('Restore failed: $e');
      return false;
    }
  }

  /// Get available offerings for display.
  Future<Offerings?> getOfferings() async {
    if (!_revenueCatReady) return null;
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('Get offerings failed: $e');
      return null;
    }
  }

  /// Manual activation (for promo codes, backend webhook, etc.)
  Future<void> activatePro() async {
    _isPro = true;
    _trialEndsAt = null;
    await _prefs?.setBool('is_pro', true);
    notifyListeners();
  }

  /// Dev/demo helper — toggle Pro for testing.
  Future<void> toggleProForDemo() async {
    _isPro = !_isPro;
    await _prefs?.setBool('is_pro', _isPro);
    notifyListeners();
  }

  // ── Plan limits (Free tier) ────────────────────────────────────

  static const int freeAiCallsPerDay = 3;
  static const int freeActiveIdeas = 3;
  static const int freeStandupHistory = 7; // days
  static const int freeContactsLimit = 20;

  Future<int> aiCallsUsedToday() async {
    if (_prefs == null) return 0;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final key = 'ai_calls_$today';
    return _prefs!.getInt(key) ?? 0;
  }

  Future<void> recordAiCall() async {
    if (_prefs == null) return;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final key = 'ai_calls_$today';
    final current = _prefs!.getInt(key) ?? 0;
    await _prefs!.setInt(key, current + 1);
  }

  Future<bool> canMakeAiCall() async {
    if (hasAccess) return true;
    final used = await aiCallsUsedToday();
    return used < freeAiCallsPerDay;
  }
}
