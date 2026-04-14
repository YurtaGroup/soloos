import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/debt_item.dart';
import '../../domain/models/obligation_item.dart';
import '../../domain/models/income_stream.dart';
import '../../domain/models/expense.dart';
import 'finance_repository.dart';

class LocalFinanceRepository implements FinanceRepository {
  static const _debtsKey = 'finance_debts';
  static const _obligationsKey = 'finance_obligations';
  static const _incomeStreamsKey = 'finance_income_streams';
  static const _expensesKey = 'finance_expenses';

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

  // ── Income Streams ─────────────────────────────────────────────────────────

  @override
  List<IncomeStream> getIncomeStreams() {
    final raw = _prefs.getString(_incomeStreamsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => IncomeStream.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveIncomeStream(IncomeStream income) async {
    final list = getIncomeStreams()..add(income);
    await _persist(_incomeStreamsKey, list.map((i) => i.toJson()).toList());
  }

  @override
  Future<void> updateIncomeStream(IncomeStream updated) async {
    final list = getIncomeStreams()
        .map((i) => i.id == updated.id ? updated : i)
        .toList();
    await _persist(_incomeStreamsKey, list.map((i) => i.toJson()).toList());
  }

  @override
  Future<void> deleteIncomeStream(String id) async {
    final list = getIncomeStreams()..removeWhere((i) => i.id == id);
    await _persist(_incomeStreamsKey, list.map((i) => i.toJson()).toList());
  }

  // ── Expenses ───────────────────────────────────────────────────────────────

  @override
  List<Expense> getExpenses() {
    final raw = _prefs.getString(_expensesKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => Expense.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveExpense(Expense expense) async {
    final list = getExpenses()..add(expense);
    await _persist(_expensesKey, list.map((e) => e.toJson()).toList());
  }

  @override
  Future<void> updateExpense(Expense updated) async {
    final list = getExpenses()
        .map((e) => e.id == updated.id ? updated : e)
        .toList();
    await _persist(_expensesKey, list.map((e) => e.toJson()).toList());
  }

  @override
  Future<void> deleteExpense(String id) async {
    final list = getExpenses()..removeWhere((e) => e.id == id);
    await _persist(_expensesKey, list.map((e) => e.toJson()).toList());
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<void> _persist(String key, List<dynamic> data) =>
      _prefs.setString(key, jsonEncode(data));
}
