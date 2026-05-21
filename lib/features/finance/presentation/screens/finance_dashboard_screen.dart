import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../services/api_service.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/tokens.dart';
import '../../../../theme/text_styles.dart';
import '../../../../theme/atoms/section_label.dart';
import '../../../../theme/atoms/app_card.dart';
import '../../../../theme/atoms/app_button.dart';
import '../../../../theme/atoms/app_row.dart';
import '../../../../theme/atoms/app_pill.dart';
import '../../../../theme/atoms/app_input.dart';
import '../../../../theme/atoms/mono_text.dart';
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
    final c = QColors.of(context);
    final vm = context.watch<FinanceViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Finance', style: TextStyles.displayMd(context)),
        actions: [
          IconButton(
            icon: Icon(Icons.people_outline_rounded, color: c.textSecondary, size: 22),
            onPressed: () {
              if (!ApiService.isAuthenticated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sign in to share finances with family')),
                );
                return;
              }
              _showPartnerSheet(context);
            },
            tooltip: 'Family partners',
          ),
        ],
      ),
      body: Column(
        children: [
          // Scope toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(
                SpaceTokens.s16, SpaceTokens.s8, SpaceTokens.s16, 0),
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
                      child: AnimatedContainer(
                        duration: MotionTokens.duration,
                        curve: MotionTokens.curve,
                        padding: const EdgeInsets.symmetric(
                            vertical: SpaceTokens.s8),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 2),
                        decoration: BoxDecoration(
                          color: vm.scopeFilter == entry.$1
                              ? c.accent.withValues(alpha: 0.12)
                              : c.surfaceMuted,
                          borderRadius: RadiusTokens.smAll,
                          border: Border.all(
                            color: vm.scopeFilter == entry.$1
                                ? c.accent
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          entry.$2,
                          textAlign: TextAlign.center,
                          style: TextStyles.bodySm(context).copyWith(
                            color: vm.scopeFilter == entry.$1
                                ? c.textPrimary
                                : c.textSecondary,
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
                if (vm.scopeFilter == 'family')
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          SpaceTokens.s16, SpaceTokens.s12, SpaceTokens.s16, 0),
                      child: AppCard(
                        padding: EdgeInsets.zero,
                        onTap: () => _showPartnerSheet(context),
                        child: AppRow(
                          title: 'Family Finance Sharing',
                          subtitle: 'Invite your partner to shared family expenses',
                          leading: Icon(Icons.person_add_outlined,
                              size: 20, color: c.textSecondary),
                          showDivider: false,
                          trailing: Icon(Icons.chevron_right_rounded,
                              size: 18, color: c.textSecondary),
                        ),
                      ),
                    ),
                  ),
                if (vm.overdueDebts.isNotEmpty) _SliverOverdueAlert(vm: vm),
                _SliverSection(title: 'Recommended Next Payment', child: _RecommendedCard(vm: vm)),
                _SliverSection(title: 'Due This Week', child: _DueThisWeek(vm: vm)),
                _SliverSection(
                  title: 'Recurring Income',
                  trailing: '\$${_fmt(vm.totalMonthlyIncome)}/mo',
                  child: _IncomeList(incomes: vm.recurringIncomeStreams, emptyMsg: 'No recurring income'),
                ),
                if (vm.oneTimeIncomes.isNotEmpty)
                  _SliverSection(
                    title: 'One-Time Income',
                    trailing: '\$${_fmt(vm.totalOneTimeIncomeThisMonth)} this month',
                    child: _IncomeList(incomes: vm.oneTimeIncomes, emptyMsg: 'No one-time income', isOneTime: true),
                  ),
                _SliverSection(
                  title: 'Recent Expenses',
                  trailing: '\$${_fmt(vm.totalMonthlyExpenses)} this month',
                  child: _ExpenseList(vm: vm),
                ),
                _SliverSection(title: 'Debts', child: _DebtsList(vm: vm)),
                _SliverSection(title: 'Monthly Obligations', child: _ObligationsList(vm: vm)),
                _SliverSection(
                  title: 'Subscriptions',
                  trailing: '${vm.subscriptions.length} active',
                  child: _SubscriptionsList(vm: vm),
                ),
                _SliverSection(
                  title: 'Monthly Summary',
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
    final c = QColors.of(context);
    final cashFlow = vm.monthlyCashFlow;
    final isPositive = cashFlow >= 0;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            SpaceTokens.s16, SpaceTokens.s16, SpaceTokens.s16, 0),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Monthly Cash Flow',
                      style: TextStyles.bodySm(context)
                          .copyWith(color: c.textSecondary)),
                  if (vm.overdueDebts.isNotEmpty)
                    AppPill(
                      label: '${vm.overdueDebts.length} overdue',
                      variant: AppPillVariant.danger,
                      leadingDot: true,
                    ),
                ],
              ),
              const SizedBox(height: SpaceTokens.s4),
              MonoText(
                '${isPositive ? '+' : '-'}\$${_fmt(cashFlow.abs())}',
                size: 28,
                weight: FontWeight.w700,
                color: isPositive ? c.success : c.danger,
              ),
              const SizedBox(height: SpaceTokens.s16),
              // Metric chips row
              Row(
                children: [
                  _MetricChip(
                    label: 'Income',
                    value: '\$${_fmt(vm.totalMonthlyIncome)}',
                    color: c.success,
                  ),
                  const SizedBox(width: SpaceTokens.s8),
                  _MetricChip(
                    label: 'Bills',
                    value: '\$${_fmt(vm.totalMonthlyObligations)}',
                    color: c.textSecondary,
                  ),
                  const SizedBox(width: SpaceTokens.s8),
                  _MetricChip(
                    label: 'Spent',
                    value: '\$${_fmt(vm.totalMonthlyExpenses)}',
                    color: c.accent,
                  ),
                ],
              ),
              if (vm.totalDebt > 0) ...[
                const SizedBox(height: SpaceTokens.s8),
                Row(
                  children: [
                    _MetricChip(
                      label: 'Total Debt',
                      value: '\$${_fmt(vm.totalDebt)}',
                      color: c.danger,
                    ),
                    const SizedBox(width: SpaceTokens.s8),
                    _MetricChip(
                      label: 'Subscriptions',
                      value: '\$${_fmt(vm.totalMonthlySubscriptions)}/mo',
                      color: c.textSecondary,
                    ),
                  ],
                ),
              ],
            ],
          ),
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
    final c = QColors.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: SpaceTokens.s8, vertical: SpaceTokens.s8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: RadiusTokens.smAll,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyles.bodySm(context)
                    .copyWith(color: c.textSecondary, fontSize: 10)),
            const SizedBox(height: 2),
            MonoText(value,
                size: 13,
                weight: FontWeight.w600,
                color: color,
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
    final c = QColors.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            SpaceTokens.s16, SpaceTokens.s12, SpaceTokens.s16, 0),
        child: AppCard(
          color: c.danger.withValues(alpha: 0.06),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  size: 20, color: c.dangerFg),
              const SizedBox(width: SpaceTokens.s8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vm.overdueDebts.length} overdue debt${vm.overdueDebts.length > 1 ? 's' : ''}',
                      style: TextStyles.bodyMd(context).copyWith(
                          color: c.dangerFg, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Total: \$${_fmt(vm.overdueDebts.fold(0.0, (s, d) => s + d.remainingAmount))}',
                      style: TextStyles.bodySm(context)
                          .copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
    final c = QColors.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            SpaceTokens.s16, SpaceTokens.s24, SpaceTokens.s16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SectionLabel(title, bottomPadding: 0),
                if (trailing != null)
                  MonoText(trailing!, size: 11, color: c.textSecondary),
              ],
            ),
            const SizedBox(height: SpaceTokens.s8),
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
    final c = QColors.of(context);
    final rec = vm.recommendedNextPayment;
    if (rec == null) {
      return _EmptyState(icon: Icons.check_circle_outline_rounded, message: 'No payments due');
    }
    return AppCard(
      child: Row(
        children: [
          Text(rec.category.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: SpaceTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rec.title,
                    style: TextStyles.bodyMd(context)
                        .copyWith(fontWeight: FontWeight.w600)),
                Text(
                  rec.dueDate != null
                      ? 'Due ${rec.dueDate!.month}/${rec.dueDate!.day}'
                      : 'No due date',
                  style: TextStyles.bodySm(context)
                      .copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MonoText('\$${_fmt(rec.remainingAmount)}',
                  size: 15, weight: FontWeight.w700),
              if (rec.monthlyPaymentGoal != null)
                MonoText('\$${_fmt(rec.monthlyPaymentGoal!)}/mo',
                    size: 11, color: c.textSecondary),
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
      ...vm.dueThisWeekDebts.map((d) =>
          _DueItem(d.category.emoji, d.title, '\$${_fmt(d.remainingAmount)}')),
      ...vm.obligationsDueThisWeek.map((o) =>
          _DueItem(o.category.emoji, o.title, '\$${_fmt(o.amount)}')),
    ];
    if (items.isEmpty) {
      return _EmptyState(icon: Icons.calendar_today_outlined, message: 'Nothing due this week');
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return AppRow(
            title: '${item.emoji}  ${item.title}',
            showDivider: i < items.length - 1,
            trailing: MonoText(item.amount),
          );
        }).toList(),
      ),
    );
  }
}

class _DueItem {
  final String emoji;
  final String title;
  final String amount;
  _DueItem(this.emoji, this.title, this.amount);
}

// ── Income list ──────────────────────────────────────────────────────────────

class _IncomeList extends StatelessWidget {
  final List<IncomeStream> incomes;
  final String emptyMsg;
  final bool isOneTime;
  const _IncomeList(
      {required this.incomes, required this.emptyMsg, this.isOneTime = false});

  @override
  Widget build(BuildContext context) {
    if (incomes.isEmpty) {
      return _EmptyState(icon: Icons.attach_money_rounded, message: emptyMsg);
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: incomes.asMap().entries.map((entry) {
          final i = entry.key;
          final income = entry.value;
          return _IncomeTile(income: income, isOneTime: isOneTime,
              showDivider: i < incomes.length - 1);
        }).toList(),
      ),
    );
  }
}

class _IncomeTile extends StatelessWidget {
  final IncomeStream income;
  final bool isOneTime;
  final bool showDivider;
  const _IncomeTile(
      {required this.income, this.isOneTime = false, this.showDivider = true});

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    final vm = context.read<FinanceViewModel>();
    return Dismissible(
      key: Key('income-${income.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: SpaceTokens.s16),
        color: c.danger.withValues(alpha: 0.12),
        child: Icon(Icons.delete_outline_rounded, color: c.danger),
      ),
      confirmDismiss: (_) => _confirmDelete(context, income.title),
      onDismissed: (_) => vm.deleteIncomeStream(income.id),
      child: AppRow(
        title: income.title,
        subtitle: isOneTime
            ? (income.date != null
                ? '${income.date!.month}/${income.date!.day}'
                : 'One-time')
            : income.frequency.label,
        leading: Text(income.category.emoji,
            style: const TextStyle(fontSize: 18)),
        showDivider: showDivider,
        trailing: MonoText('+\$${_fmt(income.amount)}',
            weight: FontWeight.w600, color: c.success),
        onTap: () => _showEditIncomeDialog(context, vm, income),
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
      return _EmptyState(icon: Icons.receipt_long_outlined, message: 'No expenses this month');
    }
    final shown =
        recent.length > 5 ? recent.sublist(recent.length - 5) : recent;
    final list = shown.reversed.toList();
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: list.asMap().entries.map((entry) {
          final i = entry.key;
          final expense = entry.value;
          return _ExpenseTile(expense: expense, showDivider: i < list.length - 1);
        }).toList(),
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final bool showDivider;
  const _ExpenseTile({required this.expense, this.showDivider = true});

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    final vm = context.read<FinanceViewModel>();
    return Dismissible(
      key: Key('expense-${expense.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: SpaceTokens.s16),
        color: c.danger.withValues(alpha: 0.12),
        child: Icon(Icons.delete_outline_rounded, color: c.danger),
      ),
      confirmDismiss: (_) => _confirmDelete(context, expense.title),
      onDismissed: (_) => vm.deleteExpense(expense.id),
      child: AppRow(
        title: expense.title,
        subtitle: '${expense.date.month}/${expense.date.day}',
        leading: Text(expense.category.emoji,
            style: const TextStyle(fontSize: 18)),
        showDivider: showDivider,
        trailing: MonoText('-\$${_fmt(expense.amount)}',
            weight: FontWeight.w600, color: c.danger),
        onTap: () => _showEditExpenseDialog(context, vm, expense),
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
      return _EmptyState(icon: Icons.check_circle_outline_rounded, message: 'No active debts');
    }
    return Column(
      children: vm.activeDebts
          .map((debt) => DebtCard(
                debt: debt,
                onPayment: (amount) =>
                    context.read<FinanceViewModel>().recordDebtPayment(debt.id, amount),
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
    final nonSubs =
        vm.activeObligations.where((o) => !o.isSubscription).toList();
    if (nonSubs.isEmpty) {
      return _EmptyState(icon: Icons.list_alt_outlined, message: 'No obligations added');
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: nonSubs.asMap().entries.map((entry) {
          final i = entry.key;
          final o = entry.value;
          return _ObligationTile(o: o, showDivider: i < nonSubs.length - 1);
        }).toList(),
      ),
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
      return _EmptyState(icon: Icons.subscriptions_outlined, message: 'No subscriptions');
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: vm.subscriptions.asMap().entries.map((entry) {
          final i = entry.key;
          final o = entry.value;
          return _ObligationTile(
              o: o, showDivider: i < vm.subscriptions.length - 1);
        }).toList(),
      ),
    );
  }
}

class _ObligationTile extends StatelessWidget {
  final ObligationItem o;
  final bool showDivider;
  const _ObligationTile({required this.o, this.showDivider = true});

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    return AppRow(
      title: o.title,
      subtitle: o.frequency.label,
      leading: Text(o.category.emoji, style: const TextStyle(fontSize: 16)),
      showDivider: showDivider,
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          MonoText('\$${_fmt(o.amount)}', weight: FontWeight.w600),
          if (o.frequency != ObligationFrequency.monthly)
            MonoText('\$${_fmt(o.monthlyCost)}/mo',
                size: 11, color: c.textSecondary),
        ],
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    return AppCard(
      child: Row(
        children: [
          Icon(icon, size: 18, color: c.textSecondary),
          const SizedBox(width: SpaceTokens.s8),
          Text(message,
              style: TextStyles.bodyMd(context).copyWith(color: c.textSecondary)),
        ],
      ),
    );
  }
}

// ── Monthly summary ─────────────────────────────────────────────────────────

class _MonthlySummary extends StatelessWidget {
  final FinanceViewModel vm;
  const _MonthlySummary({required this.vm});

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    final income = vm.totalMonthlyIncome + vm.totalOneTimeIncomeThisMonth;
    final bills = vm.totalMonthlyObligations;
    final spent = vm.totalMonthlyExpenses;
    final total = income + bills + spent;
    final incomeRatio = total > 0 ? income / total : 0.0;
    final billsRatio = total > 0 ? bills / total : 0.0;
    final spentRatio = total > 0 ? spent / total : 0.0;
    final savings = income - bills - spent;
    final savingsRate = income > 0 ? (savings / income * 100) : 0.0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Visual bar
          ClipRRect(
            borderRadius: RadiusTokens.smAll,
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  if (incomeRatio > 0)
                    Flexible(
                      flex: (incomeRatio * 100).round().clamp(1, 100),
                      child: Container(color: c.success),
                    ),
                  if (billsRatio > 0)
                    Flexible(
                      flex: (billsRatio * 100).round().clamp(1, 100),
                      child: Container(color: c.textSecondary),
                    ),
                  if (spentRatio > 0)
                    Flexible(
                      flex: (spentRatio * 100).round().clamp(1, 100),
                      child: Container(color: c.accent),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: SpaceTokens.s16),

          // Legend rows
          _SummaryRow(color: c.success, label: 'Total Income', value: '\$${_fmt(income)}'),
          _SummaryRow(color: c.textSecondary, label: 'Bills and Obligations', value: '-\$${_fmt(bills)}'),
          _SummaryRow(color: c.accent, label: 'Expenses', value: '-\$${_fmt(spent)}'),
          Divider(color: c.border, height: SpaceTokens.s24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                savings >= 0 ? 'Net Savings' : 'Net Deficit',
                style: TextStyles.bodyMd(context).copyWith(fontWeight: FontWeight.w600),
              ),
              MonoText(
                '${savings >= 0 ? '+' : '-'}\$${_fmt(savings.abs())}',
                size: 14,
                weight: FontWeight.w700,
                color: savings >= 0 ? c.success : c.danger,
              ),
            ],
          ),
          if (income > 0) ...[
            const SizedBox(height: SpaceTokens.s8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: SpaceTokens.s8, vertical: SpaceTokens.s4),
              decoration: BoxDecoration(
                color: savingsRate >= 20
                    ? c.success.withValues(alpha: 0.1)
                    : c.warn.withValues(alpha: 0.1),
                borderRadius: RadiusTokens.smAll,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    savingsRate >= 20
                        ? Icons.trending_up_rounded
                        : Icons.info_outline_rounded,
                    size: 13,
                    color: savingsRate >= 20 ? c.success : c.warn,
                  ),
                  const SizedBox(width: SpaceTokens.s4),
                  Text(
                    'Savings rate: ${savingsRate.toStringAsFixed(0)}%',
                    style: TextStyles.bodySm(context).copyWith(
                      color: savingsRate >= 20 ? c.success : c.warn,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Expense category breakdown
          if (vm.thisMonthExpenses.isNotEmpty) ...[
            const SizedBox(height: SpaceTokens.s16),
            SectionLabel('By Category', bottomPadding: SpaceTokens.s8),
            ..._expensesByCategory(context, c),
          ],
        ],
      ),
    );
  }

  List<Widget> _expensesByCategory(BuildContext context, QColorSet c) {
    final byCategory = <String, double>{};
    for (final e in vm.thisMonthExpenses) {
      byCategory[e.category.name] = (byCategory[e.category.name] ?? 0) + e.amount;
    }
    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(5).map((entry) {
      return Padding(
        padding: const EdgeInsets.only(bottom: SpaceTokens.s4),
        child: Row(
          children: [
            Text(
              '${entry.key[0].toUpperCase()}${entry.key.substring(1)}',
              style: TextStyles.bodySm(context).copyWith(color: c.textSecondary),
            ),
            const Spacer(),
            MonoText('\$${_fmt(entry.value)}', size: 12,
                weight: FontWeight.w500),
          ],
        ),
      );
    }).toList();
  }
}

class _SummaryRow extends StatelessWidget {
  final Color color;
  final String label, value;
  const _SummaryRow(
      {required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: SpaceTokens.s8),
      child: Row(
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: SpaceTokens.s8),
          Expanded(
              child: Text(label,
                  style: TextStyles.bodySm(context)
                      .copyWith(color: c.textSecondary))),
          MonoText(value, size: 13, weight: FontWeight.w500),
        ],
      ),
    );
  }
}

// ── Partner sheet ────────────────────────────────────────────────────────────

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
      final data =
          await ApiService.directRequest('GET', '/api/finance/partners');
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
      final data =
          await ApiService.directRequest('POST', '/api/finance/partners/invite');
      final code = data['code'] as String;
      if (mounted) {
        Share.share('Join my family finances on Solo OS. Use this code: $code');
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
      await ApiService.directRequest('POST', '/api/finance/partners/join',
          body: {'code': code});
      _codeCtrl.clear();
      await _loadPartners();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Joined. You can now see shared family finances.')),
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
    final c = QColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: RadiusTokens.lg),
      ),
      padding: const EdgeInsets.fromLTRB(SpaceTokens.s16, SpaceTokens.s12,
          SpaceTokens.s16, SpaceTokens.s32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: RadiusTokens.pillAll,
              ),
            ),
          ),
          const SizedBox(height: SpaceTokens.s16),
          Text('Family Finance Partners',
              style: TextStyles.displayMd(context)),
          const SizedBox(height: SpaceTokens.s4),
          Text('People who can see and add to your family expenses',
              style: TextStyles.bodyMd(context).copyWith(color: c.textSecondary)),
          const SizedBox(height: SpaceTokens.s16),

          // Current partners
          if (_loading)
            const Center(
                child: CircularProgressIndicator(strokeWidth: 2))
          else if (_partners.isEmpty)
            AppCard(
              child: Row(
                children: [
                  Icon(Icons.group_outlined, size: 20, color: c.textSecondary),
                  const SizedBox(width: SpaceTokens.s12),
                  Expanded(
                    child: Text(
                        'No partners yet. Invite someone to get started.',
                        style: TextStyles.bodyMd(context)
                            .copyWith(color: c.textSecondary)),
                  ),
                ],
              ),
            )
          else
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: _partners.asMap().entries.map((entry) {
                  final i = entry.key;
                  final p = entry.value;
                  final name = p['displayName'] as String? ?? '';
                  final email = p['email'] as String? ?? '?';
                  return AppRow(
                    title: name.isNotEmpty ? name : email,
                    subtitle: name.isNotEmpty ? email : null,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: c.accent.withValues(alpha: 0.15),
                      child: Text(
                        email[0].toUpperCase(),
                        style: TextStyles.bodySm(context)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    showDivider: i < _partners.length - 1,
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: SpaceTokens.s12),

          AppButton(
            label: 'Invite Partner',
            isFullWidth: true,
            leadingIcon: const Icon(Icons.share_outlined),
            onPressed: _generateInvite,
          ),

          const SizedBox(height: SpaceTokens.s12),

          Row(
            children: [
              Expanded(
                child: AppInput(
                  controller: _codeCtrl,
                  hintText: 'Enter invite code',
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _joinWithCode(),
                ),
              ),
              const SizedBox(width: SpaceTokens.s8),
              AppButton(
                label: 'Join',
                variant: AppButtonVariant.secondary,
                onPressed: _joinWithCode,
              ),
            ],
          ),

          if (_error != null) ...[
            const SizedBox(height: SpaceTokens.s8),
            Text(_error!,
                style: TextStyles.bodySm(context)
                    .copyWith(color: c.dangerFg)),
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

// ── Edit / Delete dialogs ────────────────────────────────────────────────────

Future<bool?> _confirmDelete(BuildContext context, String title) {
  final c = QColors.of(context);
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete?'),
      content: Text('Remove "$title"? This cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: c.danger),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

Future<void> _showEditExpenseDialog(
  BuildContext context,
  FinanceViewModel vm,
  Expense expense,
) async {
  final titleCtl = TextEditingController(text: expense.title);
  final amountCtl =
      TextEditingController(text: expense.amount.toStringAsFixed(2));
  ExpenseCategory category = expense.category;

  final result = await showDialog<_EditResult>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Edit expense'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtl,
                decoration: const InputDecoration(labelText: 'Title'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Amount', prefixText: '\$ '),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Category',
                    style: Theme.of(ctx).textTheme.labelMedium),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ExpenseCategory.values.map((c) {
                  final selected = c == category;
                  return ChoiceChip(
                    label: Text('${c.emoji} ${c.label}'),
                    selected: selected,
                    onSelected: (_) => setState(() => category = c),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _EditResult.delete),
            style: TextButton.styleFrom(
                foregroundColor: QColors.of(ctx).danger),
            child: const Text('Delete'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _EditResult.cancel),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, _EditResult.save),
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );

  if (result == _EditResult.save) {
    final newTitle = titleCtl.text.trim();
    final newAmount = double.tryParse(amountCtl.text.trim()) ?? expense.amount;
    if (newTitle.isEmpty) return;
    await vm.updateExpense(expense.copyWith(
      title: newTitle,
      amount: newAmount,
      category: category,
    ));
  } else if (result == _EditResult.delete) {
    if (!context.mounted) return;
    final confirm = await _confirmDelete(context, expense.title);
    if (confirm == true) await vm.deleteExpense(expense.id);
  }
}

Future<void> _showEditIncomeDialog(
  BuildContext context,
  FinanceViewModel vm,
  IncomeStream income,
) async {
  final titleCtl = TextEditingController(text: income.title);
  final amountCtl =
      TextEditingController(text: income.amount.toStringAsFixed(2));
  ObligationFrequency frequency = income.frequency;

  final result = await showDialog<_EditResult>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Edit income'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtl,
                decoration: const InputDecoration(labelText: 'Title'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Amount', prefixText: '\$ '),
              ),
              if (!income.isOneTime) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Frequency',
                      style: Theme.of(ctx).textTheme.labelMedium),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ObligationFrequency.values.map((f) {
                    final selected = f == frequency;
                    return ChoiceChip(
                      label: Text(f.label),
                      selected: selected,
                      onSelected: (_) => setState(() => frequency = f),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _EditResult.delete),
            style: TextButton.styleFrom(
                foregroundColor: QColors.of(ctx).danger),
            child: const Text('Delete'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _EditResult.cancel),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, _EditResult.save),
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );

  if (result == _EditResult.save) {
    final newTitle = titleCtl.text.trim();
    final newAmount = double.tryParse(amountCtl.text.trim()) ?? income.amount;
    if (newTitle.isEmpty) return;
    await vm.updateIncomeStream(income.copyWith(
      title: newTitle,
      amount: newAmount,
      frequency: frequency,
    ));
  } else if (result == _EditResult.delete) {
    if (!context.mounted) return;
    final confirm = await _confirmDelete(context, income.title);
    if (confirm == true) await vm.deleteIncomeStream(income.id);
  }
}

enum _EditResult { save, delete, cancel }
