import '../../domain/models/debt_item.dart';
import '../../domain/models/obligation_item.dart';
import '../../domain/models/income_stream.dart';
import '../../domain/models/expense.dart';

abstract class FinanceRepository {
  // ── Debts ──────────────────────────────────────────────────────────────────
  List<DebtItem> getDebts();
  Future<void> saveDebt(DebtItem debt);
  Future<void> updateDebt(DebtItem debt);
  Future<void> deleteDebt(String id);

  // ── Obligations ────────────────────────────────────────────────────────────
  List<ObligationItem> getObligations();
  Future<void> saveObligation(ObligationItem obligation);
  Future<void> updateObligation(ObligationItem obligation);
  Future<void> deleteObligation(String id);

  // ── Income Streams ─────────────────────────────────────────────────────────
  List<IncomeStream> getIncomeStreams();
  Future<void> saveIncomeStream(IncomeStream income);
  Future<void> updateIncomeStream(IncomeStream income);
  Future<void> deleteIncomeStream(String id);

  // ── Expenses ───────────────────────────────────────────────────────────────
  List<Expense> getExpenses();
  Future<void> saveExpense(Expense expense);
  Future<void> updateExpense(Expense expense);
  Future<void> deleteExpense(String id);
}
