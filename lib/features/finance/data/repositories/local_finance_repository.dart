import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/debt_item.dart';
import '../../domain/models/obligation_item.dart';
import 'finance_repository.dart';

class LocalFinanceRepository implements FinanceRepository {
  static const _debtsKey = 'finance_debts';
  static const _obligationsKey = 'finance_obligations';

  SharedPreferences get _prefs {
    if (__prefs == null) throw Exception('LocalFinanceRepository not initialized');
    return __prefs!;
  }

  SharedPreferences? __prefs;

  Future<void> init() async {
    __prefs = await SharedPreferences.getInstance();
  }

  // ── Debts ──────────────────────────────────────────────────────────────────

  @override
  List<DebtItem> getDebts() {
    final raw = _prefs.getString(_debtsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => DebtItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveDebt(DebtItem debt) async {
    final debts = getDebts()..add(debt);
    await _persist(_debtsKey, debts.map((d) => d.toJson()).toList());
  }

  @override
  Future<void> updateDebt(DebtItem updated) async {
    final debts = getDebts().map((d) => d.id == updated.id ? updated : d).toList();
    await _persist(_debtsKey, debts.map((d) => d.toJson()).toList());
  }

  @override
  Future<void> deleteDebt(String id) async {
    final debts = getDebts()..removeWhere((d) => d.id == id);
    await _persist(_debtsKey, debts.map((d) => d.toJson()).toList());
  }

  // ── Obligations ────────────────────────────────────────────────────────────

  @override
  List<ObligationItem> getObligations() {
    final raw = _prefs.getString(_obligationsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => ObligationItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveObligation(ObligationItem obligation) async {
    final obligations = getObligations()..add(obligation);
    await _persist(_obligationsKey, obligations.map((o) => o.toJson()).toList());
  }

  @override
  Future<void> updateObligation(ObligationItem updated) async {
    final obligations = getObligations()
        .map((o) => o.id == updated.id ? updated : o)
        .toList();
    await _persist(_obligationsKey, obligations.map((o) => o.toJson()).toList());
  }

  @override
  Future<void> deleteObligation(String id) async {
    final obligations = getObligations()..removeWhere((o) => o.id == id);
    await _persist(_obligationsKey, obligations.map((o) => o.toJson()).toList());
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<void> _persist(String key, List<dynamic> data) =>
      _prefs.setString(key, jsonEncode(data));
}
