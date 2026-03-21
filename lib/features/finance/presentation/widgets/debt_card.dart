import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/models/debt_item.dart';

class DebtCard extends StatelessWidget {
  final DebtItem debt;
  final void Function(double amount) onPayment;
  final VoidCallback onDelete;

  const DebtCard({
    super.key,
    required this.debt,
    required this.onPayment,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final progress = debt.progressPercent;
    final isOverdue = debt.isOverdue;

    return Dismissible(
      key: Key('debt_${debt.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.accentRed.withOpacity(0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.accentRed),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onLongPress: () => _showPaymentDialog(context),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: isOverdue
                ? Border.all(color: AppColors.accentRed.withOpacity(0.4))
                : null,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(debt.category.emoji,
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                debt.title,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            _PriorityBadge(priority: debt.priority),
                          ],
                        ),
                        Text(
                          debt.creditorName,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${_fmt(debt.remainingAmount)}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'of \$${_fmt(debt.originalAmount)}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOverdue ? AppColors.accentRed : AppColors.accentGreen,
                  ),
                  minHeight: 4,
                ),
              ),
              if (debt.dueDate != null || debt.monthlyPaymentGoal != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (debt.dueDate != null)
                        Text(
                          isOverdue
                              ? '🔴 Overdue'
                              : '📅 Due ${_formatDate(debt.dueDate!)}',
                          style: TextStyle(
                            color: isOverdue
                                ? AppColors.accentRed
                                : AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      if (debt.monthlyPaymentGoal != null)
                        Text(
                          'Goal: \$${_fmt(debt.monthlyPaymentGoal!)}/mo',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              const Text(
                'Long-press to log payment',
                style: TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context) {
    final ctrl = TextEditingController(
        text: debt.monthlyPaymentGoal?.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Log Payment',
            style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Amount paid',
            prefixText: '\$',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(ctrl.text);
              if (amount != null && amount > 0) {
                onPayment(amount);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final DebtPriority priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (priority) {
      DebtPriority.high => ('HIGH', AppColors.accentRed),
      DebtPriority.medium => ('MED', AppColors.accent),
      DebtPriority.low => ('LOW', AppColors.textMuted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
    );
  }
}

String _fmt(double v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
  return v.toStringAsFixed(0);
}

String _formatDate(DateTime dt) {
  final now = DateTime.now();
  final diff = dt.difference(now).inDays;
  if (diff == 0) return 'today';
  if (diff == 1) return 'tomorrow';
  if (diff < 0) return '${-diff}d ago';
  return '${dt.month}/${dt.day}';
}
