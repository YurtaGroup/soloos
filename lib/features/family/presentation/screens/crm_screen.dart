// lib/features/family/presentation/screens/crm_screen.dart
//
// Quiet OS — Week 4 Phase A: CRM tab.
//
// Attio-style dense table, not a Trello kanban. Each row is a
// Contact + CrmExtras composite. Stage displayed as a pill.
// Filter strip: All / Active / Proposal / Won / Lost.
// Pipeline value header always visible above the filter.
//
// All CRM data is LOCAL in Phase A. Backend sync ships in Week 5.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/tokens.dart';
import '../../../../theme/text_styles.dart';
import '../../../../theme/atoms/section_label.dart';
import '../../../../theme/atoms/mono_text.dart';
import '../../../../theme/atoms/app_button.dart';
import '../../../../theme/atoms/app_input.dart';
import '../../../../theme/atoms/app_pill.dart';

import '../../domain/models/contact.dart';
import '../../domain/models/crm_extras.dart';
import '../viewmodels/contacts_view_model.dart';
import 'crm_detail_screen.dart';

// ---------------------------------------------------------------------------
// STAGE METADATA
// ---------------------------------------------------------------------------

const _stageOrder = [
  'prospect',
  'discovery',
  'proposal',
  'negotiation',
  'won',
  'lost',
  'none',
];

String _stageLabel(String stage) {
  switch (stage) {
    case 'prospect':
      return 'Prospect';
    case 'discovery':
      return 'Discovery';
    case 'proposal':
      return 'Proposal';
    case 'negotiation':
      return 'Negotiation';
    case 'won':
      return 'Won';
    case 'lost':
      return 'Lost';
    default:
      return 'None';
  }
}

AppPillVariant _stageVariant(String stage) {
  switch (stage) {
    case 'won':
      return AppPillVariant.lime;
    case 'lost':
      return AppPillVariant.danger;
    case 'none':
      return AppPillVariant.neutral;
    default:
      // Active stages: neutral pill, distinguished by the label text
      return AppPillVariant.neutral;
  }
}

// ---------------------------------------------------------------------------
// PRIVATE — stage badge (AppPill composition; not a new atom)
// ---------------------------------------------------------------------------

class _StageBadge extends StatelessWidget {
  const _StageBadge({required this.stage});

  final String stage;

  @override
  Widget build(BuildContext context) {
    return AppPill(
      label: _stageLabel(stage),
      variant: _stageVariant(stage),
    );
  }
}

// ---------------------------------------------------------------------------
// PRIVATE — segmented filter strip
// ---------------------------------------------------------------------------

const _filterLabels = ['All', 'Active', 'Proposal', 'Won', 'Lost'];

class _SegmentedFilter extends StatelessWidget {
  const _SegmentedFilter({
    required this.selected,
    required this.onSelect,
  });

  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    final isDark = QColors.isDark(context);

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: _filterLabels.length,
        separatorBuilder: (_, __) => const SizedBox(width: SpaceTokens.s8),
        itemBuilder: (context, i) {
          final label = _filterLabels[i];
          final isActive = label == selected;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onSelect(label);
            },
            child: AnimatedContainer(
              duration: MotionTokens.duration,
              curve: MotionTokens.curve,
              padding: const EdgeInsets.symmetric(
                horizontal: SpaceTokens.s12,
                vertical: SpaceTokens.s8,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? (isDark
                        ? ColorTokens.lime500.withValues(alpha: 0.15)
                        : ColorTokens.lime500.withValues(alpha: 0.12))
                    : Colors.transparent,
                borderRadius: RadiusTokens.pillAll,
                border: Border.all(
                  color: isActive ? c.accent : c.border,
                  width: 1,
                ),
              ),
              child: Text(
                label,
                style: TextStyles.bodySm(context).copyWith(
                  color: isActive ? c.textPrimary : c.textSecondary,
                  fontWeight:
                      isActive ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CRM ROW — composite: Contact + CrmExtras
// ---------------------------------------------------------------------------

class _CrmRow extends StatelessWidget {
  const _CrmRow({
    required this.contact,
    required this.extras,
    required this.onTap,
  });

  final Contact contact;
  final CrmExtras extras;
  final VoidCallback onTap;

  String _amountLabel() {
    if (extras.dealAmount == null) return r'$—';
    final fmt = NumberFormat.currency(symbol: r'$', decimalDigits: 0);
    return fmt.format(extras.dealAmount);
  }

  String _subtitle() {
    final parts = <String>[];
    if (extras.company != null && extras.company!.isNotEmpty) {
      parts.add(extras.company!);
    }
    if (contact.relationship.isNotEmpty && contact.relationship != 'friend') {
      parts.add(_capitalize(contact.relationship));
    }
    return parts.join(' · ');
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    final subtitle = _subtitle();
    final nextStepText = extras.nextStep;
    final stage = extras.dealStage;

    return InkWell(
      onTap: onTap,
      splashColor: c.border.withValues(alpha: 0.12),
      highlightColor: c.border.withValues(alpha: 0.06),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SpaceTokens.s16,
              vertical: SpaceTokens.s12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Name + subtitle ─────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        contact.name,
                        style: TextStyles.bodyMd(context).copyWith(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyles.bodySm(context).copyWith(
                            color: c.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: SpaceTokens.s12),

                // ── Stage + amount + next step ───────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StageBadge(stage: stage),
                    const SizedBox(height: 4),
                    MonoText(
                      _amountLabel(),
                      size: 13,
                      color: stage == 'none' || stage == 'lost'
                          ? c.textDisabled
                          : c.textPrimary,
                    ),
                    if (nextStepText != null &&
                        nextStepText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_forward,
                            size: 10,
                            color: c.accent,
                          ),
                          const SizedBox(width: 3),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 100),
                            child: Text(
                              nextStepText,
                              style: TextStyles.bodySm(context).copyWith(
                                color: c.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: c.border),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CRM SCREEN
// ---------------------------------------------------------------------------

class CrmScreen extends StatefulWidget {
  const CrmScreen({super.key});

  @override
  State<CrmScreen> createState() => _CrmScreenState();
}

class _CrmScreenState extends State<CrmScreen> {
  String _filter = 'All';

  List<Contact> _filteredContacts(ContactsViewModel vm) {
    switch (_filter) {
      case 'Active':
        return vm.contacts
            .where((c) => vm.extrasFor(c).isActive)
            .toList();
      case 'Proposal':
        return vm.contactsByStage('proposal').toList();
      case 'Won':
        return vm.contactsByStage('won').toList();
      case 'Lost':
        return vm.contactsByStage('lost').toList();
      default:
        return vm.contacts;
    }
  }

  // Sort: active stages first (by _stageOrder index), then won, lost, none
  List<Contact> _sortedContacts(List<Contact> contacts, ContactsViewModel vm) {
    final sorted = List<Contact>.from(contacts);
    sorted.sort((a, b) {
      final ai = _stageOrder.indexOf(vm.extrasFor(a).dealStage);
      final bi = _stageOrder.indexOf(vm.extrasFor(b).dealStage);
      final stageCompare = ai.compareTo(bi);
      if (stageCompare != 0) return stageCompare;
      return a.name.compareTo(b.name);
    });
    return sorted;
  }

  void _openNewContactSheet(BuildContext context, ContactsViewModel vm) {
    final nameCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String stage = 'prospect';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: QColors.of(context).surface,
      shape: const RoundedRectangleBorder(),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final c = QColors.of(ctx);
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + SpaceTokens.s16,
              left: SpaceTokens.s16,
              right: SpaceTokens.s16,
              top: SpaceTokens.s24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel('NEW CONTACT', bottomPadding: SpaceTokens.s16),
                AppInput(
                  controller: nameCtrl,
                  autofocus: true,
                  hintText: 'Name',
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: SpaceTokens.s12),
                AppInput(
                  controller: companyCtrl,
                  hintText: 'Company (optional)',
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: SpaceTokens.s12),
                AppInput(
                  controller: emailCtrl,
                  hintText: 'Email (optional)',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: SpaceTokens.s16),
                Text(
                  'Stage',
                  style: TextStyles.bodySm(ctx)
                      .copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: SpaceTokens.s8),
                Row(
                  children: [
                    'prospect',
                    'discovery',
                    'proposal',
                    'negotiation',
                  ].map((s) {
                    final isSelected = stage == s;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setSheet(() => stage = s),
                        child: AnimatedContainer(
                          duration: MotionTokens.duration,
                          margin: const EdgeInsets.only(
                              right: SpaceTokens.s4),
                          padding: const EdgeInsets.symmetric(
                            vertical: SpaceTokens.s8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? c.selectedRow
                                : Colors.transparent,
                            border: Border.all(
                              color:
                                  isSelected ? c.accent : c.border,
                            ),
                          ),
                          child: Text(
                            _stageLabel(s),
                            textAlign: TextAlign.center,
                            style:
                                TextStyles.bodySm(ctx).copyWith(
                              color: isSelected
                                  ? c.textPrimary
                                  : c.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: SpaceTokens.s24),
                AppButton(
                  label: 'Save contact',
                  isFullWidth: true,
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    // Create the Contact (birthday required — use a sentinel)
                    final added = await vm.addContact(
                      name: name,
                      emoji: '👤',
                      birthday: DateTime(1990, 1, 1),
                      relationship: 'client',
                    );
                    if (!added) return;
                    // Find the newly-created contact by name (last added)
                    final newContact = vm.contacts.firstWhere(
                      (c) => c.name == name,
                      orElse: () => vm.contacts.last,
                    );
                    final extras = CrmExtras(
                      contactId: newContact.id,
                      company: companyCtrl.text.trim().isEmpty
                          ? null
                          : companyCtrl.text.trim(),
                      email: emailCtrl.text.trim().isEmpty
                          ? null
                          : emailCtrl.text.trim(),
                      dealStage: stage,
                    );
                    await vm.upsertExtras(extras);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: SpaceTokens.s8),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    final topInset = MediaQuery.of(context).padding.top;
    final vm = context.watch<ContactsViewModel>();

    final filtered = _sortedContacts(_filteredContacts(vm), vm);
    final pipelineValue = vm.pipelineValue;
    final activeCount = vm.activeContactCount;

    final fmt =
        NumberFormat.currency(symbol: r'$', decimalDigits: 0);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── HEADER ──────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              SpaceTokens.s16,
              topInset + SpaceTokens.s8,
              SpaceTokens.s8,
              SpaceTokens.s16,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text('CRM',
                      style: TextStyles.displayMd(context)),
                ),
                IconButton(
                  icon: const Icon(
                      Icons.keyboard_outlined, size: 20),
                  color: c.textSecondary,
                  tooltip: 'Keyboard shortcuts',
                  onPressed: () =>
                      _showShortcutsSheet(context),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  color: c.textSecondary,
                  tooltip: 'New contact',
                  onPressed: () =>
                      _openNewContactSheet(context, vm),
                ),
              ],
            ),
          ),
        ),

        // ── PIPELINE VALUE HEADER ─────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              SpaceTokens.s16,
              0,
              SpaceTokens.s16,
              SpaceTokens.s16,
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pipeline value',
                      style: TextStyles.bodySm(context)
                          .copyWith(color: c.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    MonoText(
                      pipelineValue > 0
                          ? fmt.format(pipelineValue)
                          : r'$0',
                      size: 22,
                      weight: FontWeight.w600,
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    MonoText(
                      '$activeCount',
                      size: 22,
                      weight: FontWeight.w600,
                    ),
                    Text(
                      'active',
                      style: TextStyles.bodySm(context)
                          .copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── FILTER STRIP ─────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              SpaceTokens.s16,
              0,
              SpaceTokens.s16,
              SpaceTokens.s16,
            ),
            child: _SegmentedFilter(
              selected: _filter,
              onSelect: (f) => setState(() => _filter = f),
            ),
          ),
        ),

        // ── HAIRLINE ─────────────────────────────────────────
        SliverToBoxAdapter(
          child: Divider(height: 1, thickness: 1, color: c.border),
        ),

        // ── CONTACT ROWS ─────────────────────────────────────
        if (vm.contacts.isEmpty)
          SliverToBoxAdapter(
            child: _EmptyStateFull(
              onAdd: () => _openNewContactSheet(context, vm),
            ),
          )
        else if (filtered.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(SpaceTokens.s24),
              child: Text(
                'No contacts in this stage.',
                style: TextStyles.bodyMd(context)
                    .copyWith(color: c.textDisabled),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final contact = filtered[i];
                final extras = vm.extrasFor(contact);
                return _CrmRow(
                  contact: contact,
                  extras: extras,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CrmDetailScreen(
                        contact: contact,
                      ),
                    ),
                  ),
                );
              },
              childCount: filtered.length,
            ),
          ),

        const SliverToBoxAdapter(
          child: SizedBox(height: SpaceTokens.s48),
        ),
      ],
    );
  }

  void _showShortcutsSheet(BuildContext context) {
    final c = QColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(SpaceTokens.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Keyboard shortcuts',
                  style: TextStyles.displayMd(context)),
              const SizedBox(height: SpaceTokens.s24),
              _ShortcutRow(keys: '⌘ N', label: 'New contact'),
              _ShortcutRow(
                  keys: '⌘ /', label: 'Filter by stage'),
              _ShortcutRow(
                  keys: '↩',
                  label: 'Open contact detail'),
              _ShortcutRow(
                  keys: 'Esc', label: 'Dismiss sheet'),
              const SizedBox(height: SpaceTokens.s8),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// EMPTY STATE — no contacts at all
// ---------------------------------------------------------------------------

class _EmptyStateFull extends StatelessWidget {
  const _EmptyStateFull({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    return Padding(
      padding: const EdgeInsets.all(SpaceTokens.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel('CRM', bottomPadding: SpaceTokens.s8),
          Text(
            'Your pipeline is empty.',
            style: TextStyles.displayMd(context),
          ),
          const SizedBox(height: SpaceTokens.s8),
          Text(
            'Add a contact to start tracking deals.',
            style: TextStyles.bodyMd(context)
                .copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: SpaceTokens.s24),
          AppButton(
            label: 'Add your first contact',
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SHORTCUT ROW (matches Tasks pattern exactly)
// ---------------------------------------------------------------------------

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({required this.keys, required this.label});

  final String keys;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpaceTokens.s8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SpaceTokens.s8,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: c.border),
              borderRadius: RadiusTokens.smAll,
            ),
            child: MonoText(keys, size: 12, color: c.textSecondary),
          ),
          const SizedBox(width: SpaceTokens.s12),
          Text(
            label,
            style: TextStyles.bodyMd(context)
                .copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}
