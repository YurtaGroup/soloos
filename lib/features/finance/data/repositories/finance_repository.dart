import '../../domain/models/debt_item.dart';
import '../../domain/models/obligation_item.dart';

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
}
