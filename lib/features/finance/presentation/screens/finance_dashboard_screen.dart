import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/models/debt_item.dart';
import '../../domain/models/obligation_item.dart';
import '../viewmodels/finance_view_model.dart';
import '../widgets/parse_confirm_sheet.dart';
import '../widgets/quick_add_bar.dart';
import '../widgets/debt_card.dart';

class FinanceDashboardScreen extends StatelessWidget {
  const FinanceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FinanceViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showManualAddSheet(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                _SliverHeader(vm: vm),
                if (vm.overdueDebts.isNotEmpty) _SliverOverdueAlert(vm: vm),
                _SliverSection(title: '💡 Recommended Next Payment', child: _RecommendedCard(vm: vm)),
                _SliverSection(title: '📅 Due This Week', child: _DueThisWeek(vm: vm)),
                _SliverSection(title: '🏋️ Debts', child: _DebtsList(vm: vm)),
                _SliverSection(title: '📋 Monthly Obligations', child: _ObligationsList(vm: vm)),
                _SliverSection(
                  title: '📱 Subscriptions',
                  trailing: '${vm.subscriptions.length} active',
                  child: _SubscriptionsList(vm: vm),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
          QuickAddBar(
            isLoading: vm.isParsingInput,
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

  void _showManualAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ManualTypePickerSheet(
        onDebt: () {
          Navigator.pop(context);
          _showManualDebtForm(context);
        },
        onObligation: () {
          Navigator.pop(context);
          _showManualObligationForm(context);
        },
      ),
    );
  }

  void _showManualDebtForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ManualDebtForm(
        onSave: (debt) {
          context.read<FinanceViewModel>().addDebt(debt);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showManualObligationForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ManualObligationForm(
        onSave: (obligation) {
          context.read<FinanceViewModel>().addObligation(obligation);
          Navigator.pop(context);
        },
      ),
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
        onCancel: () {
          Navigator.pop(context);
          vm.clearPendingInput();
        },
      ),
    );
  }
}

// ── Header: hero metrics ────────────────────────────────────────────────────

class _SliverHeader extends StatelessWidget {
  final FinanceViewModel vm;
  const _SliverHeader({required this.vm});

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 12),
            Text(
              '\$${_fmt(vm.totalDebt)}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 36,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Text('total debt remaining',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            Row(
              children: [
                _MetricChip(
                  label: 'Monthly obligations',
                  value: '\$${_fmt(vm.totalMonthlyObligations)}',
                  color: AppColors.accentBlue,
                ),
                const SizedBox(width: 8),
                _MetricChip(
                  label: 'Subscriptions',
                  value: '\$${_fmt(vm.totalMonthlySubscriptions)}',
                  color: AppColors.accent,
                ),
              ],
            ),
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
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(
              color: color, fontSize: 16, fontWeight: FontWeight.w700)),
            Text(label, style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// ── Overdue alert ───────────────────────────────────────────────────────────

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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accentRed.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Text('🚨', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Overdue debts',
                      style: TextStyle(color: AppColors.accentRed, fontWeight: FontWeight.w600)),
                  Text(
                    vm.overdueDebts.map((d) => d.title).join(', '),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
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

// ── Section wrapper ─────────────────────────────────────────────────────────

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
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    )),
                if (trailing != null)
                  Text(trailing!,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

// ── Recommended next payment ────────────────────────────────────────────────

class _RecommendedCard extends StatelessWidget {
  final FinanceViewModel vm;
  const _RecommendedCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final debt = vm.recommendedNextPayment;
    if (debt == null) {
      return const _EmptyState(icon: '✅', message: 'No active debts — great work!');
    }

    final goal = debt.monthlyPaymentGoal;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accentGreen.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Text('🎯', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(debt.title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  '${debt.creditorName} · ${debt.category.emoji} ${debt.category.label}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
                if (goal != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Pay \$${_fmt(goal)} this month',
                    style: const TextStyle(
                        color: AppColors.accentGreen, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${_fmt(debt.remainingAmount)}',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
              const Text('remaining',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Due this week ───────────────────────────────────────────────────────────

class _DueThisWeek extends StatelessWidget {
  final FinanceViewModel vm;
  const _DueThisWeek({required this.vm});

  @override
  Widget build(BuildContext context) {
    final items = [
      ...vm.dueThisWeekDebts.map((d) => _DueItem(
            title: d.title,
            amount: d.remainingAmount,
            currency: d.currency,
            dueDate: d.dueDate!,
            isDebt: true,
          )),
      ...vm.obligationsDueThisWeek.map((o) => _DueItem(
            title: o.title,
            amount: o.amount,
            currency: o.currency,
            dueDate: o.nextDueDate!,
            isDebt: false,
          )),
    ];

    if (items.isEmpty) {
      return const _EmptyState(icon: '🗓️', message: 'Nothing due this week');
    }

    items.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return Column(
      children: items
          .map((item) => _DueThisWeekTile(item: item))
          .toList(),
    );
  }
}

class _DueItem {
  final String title;
  final double amount;
  final String currency;
  final DateTime dueDate;
  final bool isDebt;
  const _DueItem({
    required this.title,
    required this.amount,
    required this.currency,
    required this.dueDate,
    required this.isDebt,
  });
}

class _DueThisWeekTile extends StatelessWidget {
  final _DueItem item;
  const _DueThisWeekTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final daysLeft = item.dueDate.difference(DateTime.now()).inDays;
    final urgentColor = daysLeft <= 2 ? AppColors.accentRed : AppColors.accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: urgentColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Text(item.isDebt ? '💳' : '📋',
              style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(item.title,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${_fmt(item.amount)}',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              Text(
                daysLeft == 0 ? 'Today' : 'In $daysLeft days',
                style: TextStyle(color: urgentColor, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Debts list ──────────────────────────────────────────────────────────────

class _DebtsList extends StatelessWidget {
  final FinanceViewModel vm;
  const _DebtsList({required this.vm});

  @override
  Widget build(BuildContext context) {
    if (vm.activeDebts.isEmpty) {
      return const _EmptyState(icon: '🎉', message: 'No active debts');
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
    final nonSubs = activeObligationsNonSub(vm);
    if (nonSubs.isEmpty) {
      return const _EmptyState(icon: '📋', message: 'No obligations added');
    }

    return Column(
      children: nonSubs.map((o) => _ObligationTile(o: o)).toList(),
    );
  }

  List<ObligationItem> activeObligationsNonSub(FinanceViewModel vm) =>
      vm.activeObligations.where((o) => !o.isSubscription).toList();
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

// ── Manual add type picker ───────────────────────────────────────────────────

class _ManualTypePickerSheet extends StatelessWidget {
  final VoidCallback onDebt;
  final VoidCallback onObligation;
  const _ManualTypePickerSheet(
      {required this.onDebt, required this.onObligation});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          const Text('Add to Finance',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _TypeButton(
                  icon: '💳',
                  label: 'Debt',
                  subtitle: 'I owe someone money',
                  color: AppColors.accentRed,
                  onTap: onDebt,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TypeButton(
                  icon: '📋',
                  label: 'Obligation',
                  subtitle: 'Recurring payment',
                  color: AppColors.accentBlue,
                  onTap: onObligation,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _TypeButton(
      {required this.icon,
      required this.label,
      required this.subtitle,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Manual debt form ─────────────────────────────────────────────────────────

class _ManualDebtForm extends StatefulWidget {
  final void Function(DebtItem) onSave;
  const _ManualDebtForm({required this.onSave});

  @override
  State<_ManualDebtForm> createState() => _ManualDebtFormState();
}

class _ManualDebtFormState extends State<_ManualDebtForm> {
  final _titleCtrl = TextEditingController();
  final _creditorCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  DebtCategory _category = DebtCategory.other;
  DebtPriority _priority = DebtPriority.medium;
  String _currency = 'USD';
  DateTime? _dueDate;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _creditorCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (title.isEmpty || amount <= 0) return;
    widget.onSave(DebtItem(
      title: title,
      creditorName: _creditorCtrl.text.trim(),
      category: _category,
      originalAmount: amount,
      currency: _currency,
      dueDate: _dueDate,
      priority: _priority,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: AppColors.textMuted,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const Text('💳 Add Debt',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              _label('Title *'),
              TextField(
                controller: _titleCtrl,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration:
                    const InputDecoration(hintText: 'e.g. Student Loan'),
              ),
              const SizedBox(height: 12),
              _label('Creditor / Who you owe'),
              TextField(
                controller: _creditorCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(hintText: 'e.g. Bank, John'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Amount *'),
                        TextField(
                          controller: _amountCtrl,
                          keyboardType: TextInputType.number,
                          style:
                              const TextStyle(color: AppColors.textPrimary),
                          decoration:
                              const InputDecoration(hintText: '0'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Currency'),
                      DropdownButton<String>(
                        value: _currency,
                        dropdownColor: AppColors.card,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 14),
                        underline: const SizedBox(),
                        items: ['USD', 'KGS'].map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c),
                            )).toList(),
                        onChanged: (v) =>
                            setState(() => _currency = v ?? 'USD'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _label('Category'),
              DropdownButtonFormField<DebtCategory>(
                value: _category,
                decoration: const InputDecoration(isDense: true),
                dropdownColor: AppColors.card,
                style:
                    const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                items: DebtCategory.values
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text('${c.emoji} ${c.label}'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 12),
              _label('Priority'),
              Row(
                children: DebtPriority.values.map((p) {
                  final selected = _priority == p;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _priority = p),
                      child: Container(
                        margin: EdgeInsets.only(
                            right: p != DebtPriority.high ? 8 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary.withOpacity(0.2)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textMuted),
                        ),
                        child: Text(
                          p.name[0].toUpperCase() + p.name.substring(1),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontSize: 12),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              _label('Due Date (optional)'),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate:
                        DateTime.now().add(const Duration(days: 365 * 10)),
                    builder: (ctx, child) => Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: const ColorScheme.dark(
                            primary: AppColors.primary),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setState(() => _dueDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.textMuted),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        _dueDate != null
                            ? '${_dueDate!.month}/${_dueDate!.day}/${_dueDate!.year}'
                            : 'Set due date',
                        style: TextStyle(
                            color: _dueDate != null
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                            fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('Save Debt'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Manual obligation form ───────────────────────────────────────────────────

class _ManualObligationForm extends StatefulWidget {
  final void Function(ObligationItem) onSave;
  const _ManualObligationForm({required this.onSave});

  @override
  State<_ManualObligationForm> createState() => _ManualObligationFormState();
}

class _ManualObligationFormState extends State<_ManualObligationForm> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  ObligationCategory _category = ObligationCategory.other;
  ObligationFrequency _frequency = ObligationFrequency.monthly;
  String _currency = 'USD';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (title.isEmpty || amount <= 0) return;
    widget.onSave(ObligationItem(
      title: title,
      category: _category,
      amount: amount,
      currency: _currency,
      frequency: _frequency,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: AppColors.textMuted,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const Text('📋 Add Obligation',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              _label('Title *'),
              TextField(
                controller: _titleCtrl,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration:
                    const InputDecoration(hintText: 'e.g. Spotify, Rent'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Amount *'),
                        TextField(
                          controller: _amountCtrl,
                          keyboardType: TextInputType.number,
                          style:
                              const TextStyle(color: AppColors.textPrimary),
                          decoration:
                              const InputDecoration(hintText: '0'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Currency'),
                      DropdownButton<String>(
                        value: _currency,
                        dropdownColor: AppColors.card,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 14),
                        underline: const SizedBox(),
                        items: ['USD', 'KGS'].map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c),
                            )).toList(),
                        onChanged: (v) =>
                            setState(() => _currency = v ?? 'USD'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _label('Category'),
              DropdownButtonFormField<ObligationCategory>(
                value: _category,
                decoration: const InputDecoration(isDense: true),
                dropdownColor: AppColors.card,
                style:
                    const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                items: ObligationCategory.values
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text('${c.emoji} ${c.label}'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 12),
              _label('Frequency'),
              DropdownButtonFormField<ObligationFrequency>(
                value: _frequency,
                decoration: const InputDecoration(isDense: true),
                dropdownColor: AppColors.card,
                style:
                    const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                items: ObligationFrequency.values
                    .map((f) => DropdownMenuItem(
                          value: f,
                          child: Text(f.label),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _frequency = v ?? _frequency),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('Save Obligation'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text,
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 12)),
    );

String _fmt(double v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
  return v.toStringAsFixed(0);
}
