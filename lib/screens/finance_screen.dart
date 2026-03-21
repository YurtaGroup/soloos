import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../services/locale_service.dart';
import '../models/app_models.dart';
import '../widgets/common_widgets.dart';
import 'package:uuid/uuid.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final _storage = StorageService();
  late List<Transaction> _txns;

  final _categories = {
    TransactionType.income: ['Freelance', 'Product', 'Consulting', 'Investment', 'Other'],
    TransactionType.expense: ['Tools', 'Marketing', 'Learning', 'Office', 'Food', 'Transport', 'Other'],
  };

  @override
  void initState() {
    super.initState();
    _txns = _storage.getTransactions();
  }

  void _reload() => setState(() => _txns = _storage.getTransactions());

  double get _balance => _txns.fold(0, (s, t) => t.type == TransactionType.income ? s + t.amount : s - t.amount);
  double get _monthIncome {
    final now = DateTime.now();
    return _txns
        .where((t) => t.type == TransactionType.income && t.date.month == now.month && t.date.year == now.year)
        .fold(0, (s, t) => s + t.amount);
  }

  double get _monthExpenses {
    final now = DateTime.now();
    return _txns
        .where((t) => t.type == TransactionType.expense && t.date.month == now.month && t.date.year == now.year)
        .fold(0, (s, t) => s + t.amount);
  }

  Future<void> _addTransaction(TransactionType type) async {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String category = _categories[type]!.first;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type == TransactionType.income ? '💰 Add Income' : '💸 Add Expense',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(hintText: 'Description'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixText: '\$ ',
                  prefixStyle: TextStyle(
                    color: type == TransactionType.income ? AppColors.accentGreen : AppColors.accentRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: category,
                style: const TextStyle(color: AppColors.textPrimary),
                dropdownColor: AppColors.card,
                decoration: const InputDecoration(hintText: 'Category'),
                items: _categories[type]!
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setModal(() => category = v ?? category),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountCtrl.text);
                    if (titleCtrl.text.trim().isEmpty || amount == null) return;
                    final txns = _storage.getTransactions()
                      ..add(Transaction(
                        id: const Uuid().v4(),
                        title: titleCtrl.text.trim(),
                        amount: amount,
                        type: type,
                        category: category,
                      ));
                    await _storage.saveTransactions(txns);
                    if (ctx.mounted) Navigator.pop(ctx);
                    _reload();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: type == TransactionType.income
                        ? AppColors.accentGreen
                        : AppColors.accentRed,
                  ),
                  child: Text('Add ${type == TransactionType.income ? 'Income' : 'Expense'}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recentTxns = _txns.reversed.take(20).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Finance')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Balance card
          GradientCard(
            colors: _balance >= 0
                ? [const Color(0xFF065F46), const Color(0xFF0284C7)]
                : [const Color(0xFF7F1D1D), const Color(0xFF7C3AED)],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Balance',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  '\$${_balance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('↑ Income', style: TextStyle(color: Colors.white54, fontSize: 11)),
                          Text(
                            '\$${_monthIncome.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('↓ Expenses', style: TextStyle(color: Colors.white54, fontSize: 11)),
                          Text(
                            '\$${_monthExpenses.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      DateFormat('MMM yyyy').format(DateTime.now()),
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick add buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _addTransaction(TransactionType.income),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline, color: AppColors.accentGreen, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Add Income',
                          style: TextStyle(color: AppColors.accentGreen, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _addTransaction(TransactionType.expense),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.accentRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accentRed.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.remove_circle_outline, color: AppColors.accentRed, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Add Expense',
                          style: TextStyle(color: AppColors.accentRed, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Transactions
          if (recentTxns.isEmpty)
            const EmptyState(
              emoji: '💰',
              title: 'No transactions',
              subtitle: 'Start tracking your income and expenses.',
            )
          else ...[
            const Text(
              'Recent Transactions',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            ...recentTxns.map((t) => _TransactionTile(
                  txn: t,
                  onDelete: () async {
                    _txns.remove(t);
                    await _storage.saveTransactions(_txns);
                    _reload();
                  },
                )),
          ],
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction txn;
  final VoidCallback onDelete;

  const _TransactionTile({required this.txn, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isIncome = txn.type == TransactionType.income;
    final color = isIncome ? AppColors.accentGreen : AppColors.accentRed;

    return Dismissible(
      key: Key(txn.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: AppColors.accentRed.withOpacity(0.2),
        child: const Icon(Icons.delete_outline, color: AppColors.accentRed),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                color: color,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    txn.title,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  ),
                  Text(
                    '${txn.category} · ${DateFormat('MMM d').format(txn.date)}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : '-'}\$${txn.amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
