import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../services/api_service.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/models/debt_item.dart';
import '../../domain/models/obligation_item.dart';
import '../../domain/models/income_stream.dart';
import '../../domain/models/expense.dart';
import '../viewmodels/finance_view_model.dart';
import '../widgets/parse_confirm_sheet.dart';
import '../widgets/quick_add_bar.dart';
import '../widgets/debt_card.dart';
import '../widgets/manual_forms.dart';

class FinanceDashboardScreen extends StatelessWidget {
  const FinanceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FinanceViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Scope toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                for (final entry in [
                  ('all', 'All'),
                  ('personal', 'Personal'),
                  ('business', 'Business'),
                  ('family', 'Family'),
                ])
                  Expanded(
                    child: GestureDetector(
                      onTap: () => vm.setScopeFilter(entry.$1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: vm.scopeFilter == entry.$1
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : AppColors.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: vm.scopeFilter == entry.$1
                                ? AppColors.primary.withValues(alpha: 0.4)
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          entry.$2,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: vm.scopeFilter == entry.$1
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: vm.scopeFilter == entry.$1
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                _CashFlowHeader(vm: vm),
                if (vm.scopeFilter == 'family' && ApiService.isAuthenticated)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: GestureDetector(
                        onTap: () => _showPartnerSheet(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.person_add_rounded, color: AppColors.primary, size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Family Finance Sharing',
                                        style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                                    Text('Invite your partner to shared family expenses',
                                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (vm.overdueDebts.isNotEmpty) _SliverOverdueAlert(vm: vm),
                _SliverSection(title: '💡 Recommended Next Payment', child: _RecommendedCard(vm: vm)),
                _SliverSection(title: '📅 Due This Week', child: _DueThisWeek(vm: vm)),
                _SliverSection(
                  title: '💰 Recurring Income',
                  trailing: '\$${_fmt(vm.totalMonthlyIncome)}/mo',
                  child: _IncomeList(incomes: vm.recurringIncomeStreams, emptyMsg: 'No recurring income'),
                ),
                if (vm.oneTimeIncomes.isNotEmpty)
                  _SliverSection(
                    title: '💵 One-Time Income',
                    trailing: '\$${_fmt(vm.totalOneTimeIncomeThisMonth)} this month',
                    child: _IncomeList(incomes: vm.oneTimeIncomes, emptyMsg: 'No one-time income', isOneTime: true),
                  ),
                _SliverSection(
                  title: '💸 Recent Expenses',
                  trailing: '\$${_fmt(vm.totalMonthlyExpenses)} this month',
                  child: _ExpenseList(vm: vm),
                ),
                _SliverSection(title: '🏋️ Debts', child: _DebtsList(vm: vm)),
                _SliverSection(title: '📋 Monthly Obligations', child: _ObligationsList(vm: vm)),
                _SliverSection(
                  title: '📱 Subscriptions',
                  trailing: '${vm.subscriptions.length} active',
                  child: _SubscriptionsList(vm: vm),
                ),
                _SliverSection(
                  title: '📊 Monthly Summary',
                  child: _MonthlySummary(vm: vm),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
          QuickAddBar(
            isLoading: vm.isParsingInput,
            onManualAdd: () => _showManualAddSheet(context),
            onSubmit: (text) async {
              await vm.parseInput(text);
              if (vm.pendingInput != null && context.mounted) {
                _showConfirmSheet(context, vm);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showPartnerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _PartnerSheet(),
    );
  }

  void _showManualAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ManualTypePickerSheet(
        onDebt: () {
          Navigator.pop(context);
          _showForm(context, (ctx) => ManualDebtForm(
            onSave: (debt) {
              ctx.read<FinanceViewModel>().addDebt(debt);
              Navigator.pop(ctx);
            },
          ));
        },
        onObligation: () {
          Navigator.pop(context);
          _showForm(context, (ctx) => ManualObligationForm(
            onSave: (o) {
              ctx.read<FinanceViewModel>().addObligation(o);
              Navigator.pop(ctx);
            },
          ));
        },
        onIncome: () {
          Navigator.pop(context);
          _showForm(context, (ctx) => ManualIncomeForm(
            onSave: (income) {
              ctx.read<FinanceViewModel>().addIncomeStream(income);
              Navigator.pop(ctx);
            },
          ));
        },
        onExpense: () {
          Navigator.pop(context);
          _showForm(context, (ctx) => ManualExpenseForm(
            onSave: (expense) {
              ctx.read<FinanceViewModel>().addExpense(expense);
              Navigator.pop(ctx);
            },
          ));
        },
      ),
    );
  }

  void _showForm(BuildContext context, Widget Function(BuildContext) builder) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => builder(ctx),
    );
  }

  void _showConfirmSheet(BuildContext context, FinanceViewModel vm) {
    final pending = vm.pendingInput!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ParseConfirmSheet(
        parsed: pending,
        onConfirmDebt: (debt) {
          Navigator.pop(context);
          vm.confirmParsedDebt(debt);
        },
        onConfirmObligation: (obligation) {
          Navigator.pop(context);
          vm.confirmParsedObligation(obligation);
        },
        onConfirmIncome: (income) {
          Navigator.pop(context);
          vm.confirmParsedIncome(income);
        },
        onConfirmExpense: (expense) {
          Navigator.pop(context);
          vm.confirmParsedExpense(expense);
        },
        onCancel: () {
          Navigator.pop(context);
          vm.clearPendingInput();
        },
      ),
    );
  }
}

// ── Cash flow header ─────────────────────────────────────────────────────────

class _CashFlowHeader extends StatelessWidget {
  final FinanceViewModel vm;
  const _CashFlowHeader({required this.vm});

  @override
  Widget build(BuildContext context) {
    final cashFlow = vm.monthlyCashFlow;
    final isPositive = cashFlow >= 0;

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1030), Color(0xFF0F0A20)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('💰 Finance', style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
                if (vm.overdueDebts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accentRed.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '⚠️ ${vm.overdueDebts.length} overdue',
                      style: const TextStyle(color: AppColors.accentRed, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Cash flow hero
            Text(
              'Monthly Cash Flow',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              '${isPositive ? '+' : '-'}\$${_fmt(cashFlow.abs())}',
              style: TextStyle(
                color: isPositive ? AppColors.accentGreen : AppColors.accentRed,
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            // Metric chips row
            Row(
              children: [
                _MetricChip(
                  label: 'Income',
                  value: '\$${_fmt(vm.totalMonthlyIncome)}',
                  color: AppColors.accentGreen,
                ),
                const SizedBox(width: 8),
                _MetricChip(
                  label: 'Bills',
                  value: '\$${_fmt(vm.totalMonthlyObligations)}',
                  color: AppColors.accentBlue,
                ),
                const SizedBox(width: 8),
                _MetricChip(
                  label: 'Spent',
                  value: '\$${_fmt(vm.totalMonthlyExpenses)}',
                  color: AppColors.accent,
                ),
              ],
            ),
            if (vm.totalDebt > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  _MetricChip(
                    label: 'Total Debt',
                    value: '\$${_fmt(vm.totalDebt)}',
                    color: AppColors.accentRed,
                  ),
                  const SizedBox(width: 8),
                  _MetricChip(
                    label: 'Subscriptions',
                    value: '\$${_fmt(vm.totalMonthlySubscriptions)}/mo',
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MetricChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 10)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 14, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ── Overdue alert ────────────────────────────────────────────────────────────

class _SliverOverdueAlert extends StatelessWidget {
  final FinanceViewModel vm;
  const _SliverOverdueAlert({required this.vm});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.accentRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.accentRed.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Text('🚨', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${vm.overdueDebts.length} overdue debt${vm.overdueDebts.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                        color: AppColors.accentRed,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                  Text(
                    'Total: \$${_fmt(vm.overdueDebts.fold(0.0, (s, d) => s + d.remainingAmount))}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section wrapper ──────────────────────────────────────────────────────────

class _SliverSection extends StatelessWidget {
  final String title;
  final String? trailing;
  final Widget child;
  const _SliverSection({required this.title, this.trailing, required this.child});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                if (trailing != null)
                  Text(trailing!,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

// ── Recommended card ─────────────────────────────────────────────────────────

class _RecommendedCard extends StatelessWidget {
  final FinanceViewModel vm;
  const _RecommendedCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final rec = vm.recommendedNextPayment;
    if (rec == null) {
      return const _EmptyState(icon: '✅', message: 'No payments due');
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(rec.category.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rec.title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600)),
                Text(
                  rec.dueDate != null
                      ? 'Due ${rec.dueDate!.month}/${rec.dueDate!.day}'
                      : 'No due date',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${_fmt(rec.remainingAmount)}',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
              if (rec.monthlyPaymentGoal != null)
                Text('\$${_fmt(rec.monthlyPaymentGoal!)}/mo',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Due this week ────────────────────────────────────────────────────────────

class _DueThisWeek extends StatelessWidget {
  final FinanceViewModel vm;
  const _DueThisWeek({required this.vm});

  @override
  Widget build(BuildContext context) {
    final items = <_DueItem>[
      ...vm.dueThisWeekDebts.map((d) => _DueItem(d.category.emoji, d.title,
          '\$${_fmt(d.remainingAmount)}', 'debt')),
      ...vm.obligationsDueThisWeek.map((o) => _DueItem(
          o.category.emoji, o.title, '\$${_fmt(o.amount)}', 'obligation')),
    ];
    if (items.isEmpty) {
      return const _EmptyState(icon: '📅', message: 'Nothing due this week');
    }
    return Column(
      children: items.map((i) => _DueThisWeekTile(item: i)).toList(),
    );
  }
}

class _DueItem {
  final String emoji;
  final String title;
  final String amount;
  final String type;
  _DueItem(this.emoji, this.title, this.amount, this.type);
}

class _DueThisWeekTile extends StatelessWidget {
  final _DueItem item;
  const _DueThisWeekTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(item.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(item.title,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13)),
          ),
          Text(item.amount,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Income list ──────────────────────────────────────────────────────────────

class _IncomeList extends StatelessWidget {
  final List<IncomeStream> incomes;
  final String emptyMsg;
  final bool isOneTime;
  const _IncomeList({required this.incomes, required this.emptyMsg, this.isOneTime = false});

  @override
  Widget build(BuildContext context) {
    if (incomes.isEmpty) {
      return _EmptyState(icon: '💰', message: emptyMsg);
    }
    return Column(
      children: incomes.map((i) => _IncomeTile(income: i, isOneTime: isOneTime)).toList(),
    );
  }
}

class _IncomeTile extends StatelessWidget {
  final IncomeStream income;
  final bool isOneTime;
  const _IncomeTile({required this.income, this.isOneTime = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(income.category.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(income.title,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 14)),
                Text(
                  isOneTime
                      ? (income.date != null
                          ? '${income.date!.month}/${income.date!.day}'
                          : 'One-time')
                      : income.frequency.label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('+\$${_fmt(income.amount)}',
                  style: const TextStyle(
                      color: AppColors.accentGreen,
                      fontWeight: FontWeight.w600)),
              if (!isOneTime && income.frequency != ObligationFrequency.monthly)
                Text('\$${_fmt(income.monthlyIncome)}/mo',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Expense list ─────────────────────────────────────────────────────────────

class _ExpenseList extends StatelessWidget {
  final FinanceViewModel vm;
  const _ExpenseList({required this.vm});

  @override
  Widget build(BuildContext context) {
    final recent = vm.thisMonthExpenses;
    if (recent.isEmpty) {
      return const _EmptyState(icon: '💸', message: 'No expenses this month');
    }
    // Show latest 5
    final shown = recent.length > 5 ? recent.sublist(recent.length - 5) : recent;
    return Column(
      children: shown.reversed.map((e) => _ExpenseTile(expense: e)).toList(),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  const _ExpenseTile({required this.expense});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(expense.category.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(expense.title,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 14)),
                Text(
                  '${expense.date.month}/${expense.date.day}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Text('-\$${_fmt(expense.amount)}',
              style: const TextStyle(
                  color: AppColors.accentRed, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Debts list ───────────────────────────────────────────────────────────────

class _DebtsList extends StatelessWidget {
  final FinanceViewModel vm;
  const _DebtsList({required this.vm});

  @override
  Widget build(BuildContext context) {
    if (vm.activeDebts.isEmpty) {
      return const _EmptyState(icon: '✅', message: 'No active debts');
    }
    return Column(
      children: vm.activeDebts
          .map((debt) => DebtCard(
                debt: debt,
                onPayment: (amount) => context.read<FinanceViewModel>()
                    .recordDebtPayment(debt.id, amount),
                onDelete: () =>
                    context.read<FinanceViewModel>().deleteDebt(debt.id),
              ))
          .toList(),
    );
  }
}

// ── Obligations list ────────────────────────────────────────────────────────

class _ObligationsList extends StatelessWidget {
  final FinanceViewModel vm;
  const _ObligationsList({required this.vm});

  @override
  Widget build(BuildContext context) {
    final nonSubs = vm.activeObligations.where((o) => !o.isSubscription).toList();
    if (nonSubs.isEmpty) {
      return const _EmptyState(icon: '📋', message: 'No obligations added');
    }
    return Column(
      children: nonSubs.map((o) => _ObligationTile(o: o)).toList(),
    );
  }
}

// ── Subscriptions list ──────────────────────────────────────────────────────

class _SubscriptionsList extends StatelessWidget {
  final FinanceViewModel vm;
  const _SubscriptionsList({required this.vm});

  @override
  Widget build(BuildContext context) {
    if (vm.subscriptions.isEmpty) {
      return const _EmptyState(icon: '📱', message: 'No subscriptions');
    }
    return Column(
      children: vm.subscriptions.map((o) => _ObligationTile(o: o)).toList(),
    );
  }
}

class _ObligationTile extends StatelessWidget {
  final ObligationItem o;
  const _ObligationTile({required this.o});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(o.category.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o.title,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 14)),
                Text(o.frequency.label,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${_fmt(o.amount)}',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
              if (o.frequency != ObligationFrequency.monthly)
                Text('\$${_fmt(o.monthlyCost)}/mo',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ──────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Text(message,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _MonthlySummary extends StatelessWidget {
  final FinanceViewModel vm;
  const _MonthlySummary({required this.vm});

  @override
  Widget build(BuildContext context) {
    final income = vm.totalMonthlyIncome + vm.totalOneTimeIncomeThisMonth;
    final bills = vm.totalMonthlyObligations;
    final spent = vm.totalMonthlyExpenses;
    final total = income + bills + spent;
    // Avoid division by zero
    final incomeRatio = total > 0 ? income / total : 0.0;
    final billsRatio = total > 0 ? bills / total : 0.0;
    final spentRatio = total > 0 ? spent / total : 0.0;
    final savings = income - bills - spent;
    final savingsRate = income > 0 ? (savings / income * 100) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Visual bar breakdown
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 10,
            child: Row(
              children: [
                if (incomeRatio > 0)
                  Flexible(
                    flex: (incomeRatio * 100).round().clamp(1, 100),
                    child: Container(color: AppColors.accentGreen),
                  ),
                if (billsRatio > 0)
                  Flexible(
                    flex: (billsRatio * 100).round().clamp(1, 100),
                    child: Container(color: AppColors.accentBlue),
                  ),
                if (spentRatio > 0)
                  Flexible(
                    flex: (spentRatio * 100).round().clamp(1, 100),
                    child: Container(color: AppColors.accent),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Legend rows
        _SummaryRow(color: AppColors.accentGreen, label: 'Total Income', value: '\$${_fmt(income)}'),
        _SummaryRow(color: AppColors.accentBlue, label: 'Bills & Obligations', value: '-\$${_fmt(bills)}'),
        _SummaryRow(color: AppColors.accent, label: 'Expenses', value: '-\$${_fmt(spent)}'),
        const Divider(color: AppColors.textMuted, height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              savings >= 0 ? 'Net Savings' : 'Net Deficit',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            Text(
              '${savings >= 0 ? '+' : '-'}\$${_fmt(savings.abs())}',
              style: TextStyle(
                color: savings >= 0 ? AppColors.accentGreen : AppColors.accentRed,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        if (income > 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: savingsRate >= 20
                  ? AppColors.accentGreen.withValues(alpha: 0.1)
                  : AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  savingsRate >= 20 ? Icons.trending_up_rounded : Icons.info_outline_rounded,
                  size: 14,
                  color: savingsRate >= 20 ? AppColors.accentGreen : AppColors.accent,
                ),
                const SizedBox(width: 6),
                Text(
                  'Savings rate: ${savingsRate.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: savingsRate >= 20 ? AppColors.accentGreen : AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],

        // Expense category breakdown
        if (vm.thisMonthExpenses.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('By Category', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          ..._expensesByCategory(),
        ],
      ],
    );
  }

  List<Widget> _expensesByCategory() {
    final byCategory = <String, double>{};
    for (final e in vm.thisMonthExpenses) {
      byCategory[e.category.name] = (byCategory[e.category.name] ?? 0) + e.amount;
    }
    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(5).map((entry) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Text(
              '${entry.key[0].toUpperCase()}${entry.key.substring(1)}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const Spacer(),
            Text(
              '\$${_fmt(entry.value)}',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _SummaryRow extends StatelessWidget {
  final Color color;
  final String label, value;
  const _SummaryRow({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _PartnerSheet extends StatefulWidget {
  const _PartnerSheet();
  @override
  State<_PartnerSheet> createState() => _PartnerSheetState();
}

class _PartnerSheetState extends State<_PartnerSheet> {
  List<Map<String, dynamic>> _partners = [];
  bool _loading = true;
  String? _error;
  final _codeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPartners();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPartners() async {
    try {
      final data = await ApiService.directRequest('GET', '/api/finance/partners');
      setState(() {
        _partners = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to load partners';
      });
    }
  }

  Future<void> _generateInvite() async {
    try {
      final data = await ApiService.directRequest('POST', '/api/finance/partners/invite');
      final code = data['code'] as String;
      if (mounted) {
        Share.share('Join my family finances on Solo OS! Use this code: $code');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate invite')),
        );
      }
    }
  }

  Future<void> _joinWithCode() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    try {
      await ApiService.directRequest('POST', '/api/finance/partners/join', body: {'code': code});
      _codeCtrl.clear();
      await _loadPartners();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Joined! You can now see shared family finances.')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 36, height: 4, decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            )),
          ),
          const SizedBox(height: 20),
          const Text('Family Finance Partners',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('People who can see and add to your family expenses',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 20),

          // Current partners
          if (_loading)
            const Center(child: CircularProgressIndicator(strokeWidth: 2))
          else if (_partners.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Text('👨‍👩‍👧', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 12),
                  Expanded(child: Text('No partners yet. Invite someone to get started!',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                ],
              ),
            )
          else
            ...(_partners.map((p) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      (p['displayName'] as String? ?? p['email'] as String? ?? '?')[0].toUpperCase(),
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p['displayName'] ?? '',
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                        Text(p['email'] ?? '',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ))),

          const SizedBox(height: 16),

          // Invite button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _generateInvite,
              icon: const Icon(Icons.share_rounded, size: 18),
              label: const Text('Invite Partner', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Join with code
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Enter invite code',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _joinWithCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.card,
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                  ),
                  child: const Text('Join', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),

          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.accentRed, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

String _fmt(double v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
  return v.toStringAsFixed(0);
}
