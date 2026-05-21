// lib/features/family/presentation/screens/crm_detail_screen.dart
//
// Quiet OS — Week 4 Phase A: CRM contact detail.
//
// Push-route from CrmScreen row tap.
// Single scrollable column: stage picker, deal KVs, next step,
// contact methods, notes. Activity section is a Phase A placeholder.
//
// Editing:
//   - Stage: tappable pill → bottom sheet with 7 stages
//   - Next step: tappable row → sheet with text + date picker
//   - Last contacted: tappable → sheet with quick options
//   - Notes: inline editable AppInput (multi-line)
//   - Email/phone/company: "Edit details" sheet

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/tokens.dart';
import '../../../../theme/text_styles.dart';
import '../../../../theme/atoms/section_label.dart';
import '../../../../theme/atoms/mono_text.dart';
import '../../../../theme/atoms/app_button.dart';
import '../../../../theme/atoms/app_input.dart';
import '../../../../theme/atoms/app_pill.dart';

import '../../domain/models/contact.dart';
import '../viewmodels/contacts_view_model.dart';

// ---------------------------------------------------------------------------
// STAGE METADATA (duplicated locally — no cross-screen import needed)
// ---------------------------------------------------------------------------

const _allStages = [
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
    default:
      return AppPillVariant.neutral;
  }
}

// ---------------------------------------------------------------------------
// CRM DETAIL SCREEN
// ---------------------------------------------------------------------------

class CrmDetailScreen extends StatefulWidget {
  const CrmDetailScreen({super.key, required this.contact});

  final Contact contact;

  @override
  State<CrmDetailScreen> createState() => _CrmDetailScreenState();
}

class _CrmDetailScreenState extends State<CrmDetailScreen> {
  final _notesCtrl = TextEditingController();
  bool _notesDirty = false;

  @override
  void initState() {
    super.initState();
    _notesCtrl.text = widget.contact.notes;
    _notesCtrl.addListener(() {
      if (!_notesDirty) setState(() => _notesDirty = true);
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveNotes(ContactsViewModel vm) async {
    widget.contact.notes = _notesCtrl.text;
    await vm.logContact(widget.contact); // triggers a save/notify
    setState(() => _notesDirty = false);
  }

  // ── Sheets ────────────────────────────────────────────────────

  void _showStageSheet(BuildContext context, ContactsViewModel vm) {
    final extras = vm.extrasFor(widget.contact);
    showModalBottomSheet(
      context: context,
      backgroundColor: QColors.of(context).surface,
      shape: const RoundedRectangleBorder(),
      builder: (ctx) {
        final c = QColors.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              SpaceTokens.s16,
              SpaceTokens.s24,
              SpaceTokens.s16,
              SpaceTokens.s16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel('STAGE', bottomPadding: SpaceTokens.s16),
                ..._allStages.map((stage) {
                  final isSelected = stage == extras.dealStage;
                  return InkWell(
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      await vm.updateStage(widget.contact, stage);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: SpaceTokens.s12),
                      child: Row(
                        children: [
                          AppPill(
                            label: _stageLabel(stage),
                            variant: _stageVariant(stage),
                          ),
                          const Spacer(),
                          if (isSelected)
                            Icon(Icons.check,
                                size: 16, color: c.accent),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNextStepSheet(
      BuildContext context, ContactsViewModel vm) {
    final extras = vm.extrasFor(widget.contact);
    final stepCtrl =
        TextEditingController(text: extras.nextStep ?? '');
    DateTime? stepDate = extras.nextStepDate;

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
              bottom:
                  MediaQuery.of(ctx).viewInsets.bottom +
                      SpaceTokens.s16,
              left: SpaceTokens.s16,
              right: SpaceTokens.s16,
              top: SpaceTokens.s24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel('NEXT STEP',
                    bottomPadding: SpaceTokens.s16),
                AppInput(
                  controller: stepCtrl,
                  autofocus: true,
                  hintText: 'What needs to happen next?',
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: SpaceTokens.s12),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: stepDate ??
                          DateTime.now()
                              .add(const Duration(days: 1)),
                      firstDate: DateTime.now()
                          .subtract(const Duration(days: 365)),
                      lastDate: DateTime.now()
                          .add(const Duration(days: 365 * 2)),
                    );
                    if (picked != null) {
                      setSheet(() => stepDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpaceTokens.s12,
                      vertical: SpaceTokens.s12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: c.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 16, color: c.textSecondary),
                        const SizedBox(width: SpaceTokens.s8),
                        Expanded(
                          child: Text(
                            stepDate != null
                                ? DateFormat('EEE, MMM d, yyyy')
                                    .format(stepDate!)
                                : 'Due date (optional)',
                            style: TextStyles.bodyMd(ctx).copyWith(
                              color: stepDate != null
                                  ? c.textPrimary
                                  : c.textDisabled,
                            ),
                          ),
                        ),
                        if (stepDate != null)
                          GestureDetector(
                            onTap: () =>
                                setSheet(() => stepDate = null),
                            child: Icon(Icons.close,
                                size: 16, color: c.textSecondary),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: SpaceTokens.s24),
                AppButton(
                  label: 'Save',
                  isFullWidth: true,
                  onPressed: () async {
                    await vm.updateNextStep(
                      widget.contact,
                      stepCtrl.text.trim(),
                      stepDate,
                    );
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

  void _showLastContactedSheet(
      BuildContext context, ContactsViewModel vm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: QColors.of(context).surface,
      shape: const RoundedRectangleBorder(),
      builder: (ctx) {
        final c = QColors.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(SpaceTokens.s24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel('LAST CONTACT',
                    bottomPadding: SpaceTokens.s16),
                InkWell(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    await vm.logContact(widget.contact);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: SpaceTokens.s12),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 18, color: c.accent),
                        const SizedBox(width: SpaceTokens.s12),
                        Text(
                          'Mark as just contacted',
                          style: TextStyles.bodyMd(ctx)
                              .copyWith(color: c.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(height: 1, thickness: 1, color: c.border),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: widget.contact.lastContacted ??
                          DateTime.now(),
                      firstDate: DateTime.now()
                          .subtract(const Duration(days: 365 * 5)),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      widget.contact.lastContacted = picked;
                      await vm.logContact(widget.contact);
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: SpaceTokens.s12),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 18, color: c.textSecondary),
                        const SizedBox(width: SpaceTokens.s12),
                        Text(
                          'Pick a date',
                          style: TextStyles.bodyMd(ctx)
                              .copyWith(color: c.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditDetailsSheet(
      BuildContext context, ContactsViewModel vm) {
    final extras = vm.extrasFor(widget.contact);
    final companyCtrl =
        TextEditingController(text: extras.company ?? '');
    final emailCtrl =
        TextEditingController(text: extras.email ?? '');
    final phoneCtrl =
        TextEditingController(text: extras.phone ?? '');
    final amountCtrl = TextEditingController(
      text: extras.dealAmount != null
          ? extras.dealAmount!.toStringAsFixed(0)
          : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: QColors.of(context).surface,
      shape: const RoundedRectangleBorder(),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom:
                MediaQuery.of(ctx).viewInsets.bottom +
                    SpaceTokens.s16,
            left: SpaceTokens.s16,
            right: SpaceTokens.s16,
            top: SpaceTokens.s24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel('EDIT DETAILS',
                    bottomPadding: SpaceTokens.s16),
                AppInput(
                  controller: companyCtrl,
                  hintText: 'Company',
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: SpaceTokens.s12),
                AppInput(
                  controller: emailCtrl,
                  hintText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: SpaceTokens.s12),
                AppInput(
                  controller: phoneCtrl,
                  hintText: 'Phone',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: SpaceTokens.s12),
                AppInput(
                  controller: amountCtrl,
                  hintText: 'Deal amount (e.g. 4200)',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: SpaceTokens.s24),
                AppButton(
                  label: 'Save',
                  isFullWidth: true,
                  onPressed: () async {
                    final amount =
                        double.tryParse(amountCtrl.text.trim());
                    final updated = extras.copyWith(
                      company: companyCtrl.text.trim().isEmpty
                          ? null
                          : companyCtrl.text.trim(),
                      email: emailCtrl.text.trim().isEmpty
                          ? null
                          : emailCtrl.text.trim(),
                      phone: phoneCtrl.text.trim().isEmpty
                          ? null
                          : phoneCtrl.text.trim(),
                      dealAmount: amount,
                    );
                    await vm.upsertExtras(updated);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: SpaceTokens.s8),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Formatters ────────────────────────────────────────────────

  String _lastContactedLabel(Contact c) {
    if (c.lastContacted == null) return 'Never';
    final days = c.daysSinceContact;
    if (days == 0) return 'Today';
    if (days == 1) return 'Yesterday';
    return '$days days ago';
  }

  String _amountLabel(double? amount) {
    if (amount == null) return r'$—';
    return NumberFormat.currency(symbol: r'$', decimalDigits: 0)
        .format(amount);
  }

  String _nextStepTimeLabel(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('EEE, MMM d').format(dt);
  }

  // ── Tap actions ──────────────────────────────────────────────

  Future<void> _launchUrl(String raw) async {
    final uri = Uri.parse(raw);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    final vm = context.watch<ContactsViewModel>();

    // Re-read on every rebuild so stage/next-step updates are reflected.
    final extras = vm.extrasFor(widget.contact);
    final contact = widget.contact;

    final subtitle = <String>[];
    if (extras.company != null && extras.company!.isNotEmpty) {
      subtitle.add(extras.company!);
    }
    if (contact.relationship.isNotEmpty &&
        contact.relationship != 'friend') {
      final r = contact.relationship;
      subtitle.add(r[0].toUpperCase() + r.substring(1));
    }

    return Scaffold(
      backgroundColor: c.appBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── BACK + OVERFLOW ──────────────────────────────────
          SliverAppBar(
            backgroundColor: c.appBg,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: c.textSecondary),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.more_horiz_rounded,
                    size: 20, color: c.textSecondary),
                onPressed: () =>
                    _showEditDetailsSheet(context, vm),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(
                  height: 1, thickness: 1, color: c.border),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              SpaceTokens.s16,
              SpaceTokens.s24,
              SpaceTokens.s16,
              SpaceTokens.s48,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── NAME + SUBTITLE ────────────────────────────
                Text(
                  contact.name,
                  style: TextStyles.displayMd(context),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle.join(' · '),
                    style: TextStyles.bodyLg(context).copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: SpaceTokens.s16),

                // ── STAGE PICKER ───────────────────────────────
                GestureDetector(
                  onTap: () =>
                      _showStageSheet(context, vm),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppPill(
                        label: _stageLabel(extras.dealStage),
                        variant: _stageVariant(extras.dealStage),
                      ),
                      const SizedBox(width: SpaceTokens.s4),
                      Icon(Icons.expand_more_rounded,
                          size: 16, color: c.textSecondary),
                    ],
                  ),
                ),
                const SizedBox(height: SpaceTokens.s24),

                // ── DEAL SECTION ───────────────────────────────
                SectionLabel('DEAL', bottomPadding: SpaceTokens.s8),
                Divider(height: 1, thickness: 1, color: c.border),
                _KvRow(
                  label: 'Amount',
                  value: _amountLabel(extras.dealAmount),
                  isMono: true,
                ),
                _KvRow(
                  label: 'Last contact',
                  value: _lastContactedLabel(contact),
                  onTap: () =>
                      _showLastContactedSheet(context, vm),
                ),
                _KvRow(
                  label: 'Created',
                  value: DateFormat('MMM d')
                      .format(contact.birthday),
                  isLast: true,
                ),

                const SizedBox(height: SpaceTokens.s24),

                // ── NEXT STEP ──────────────────────────────────
                SectionLabel('NEXT STEP',
                    bottomPadding: SpaceTokens.s8),
                Divider(height: 1, thickness: 1, color: c.border),
                InkWell(
                  onTap: () =>
                      _showNextStepSheet(context, vm),
                  splashColor:
                      c.border.withValues(alpha: 0.12),
                  highlightColor:
                      c.border.withValues(alpha: 0.06),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: SpaceTokens.s12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.radio_button_unchecked_rounded,
                          size: 16,
                          color: c.textSecondary,
                        ),
                        const SizedBox(width: SpaceTokens.s12),
                        Expanded(
                          child: Text(
                            extras.nextStep != null &&
                                    extras.nextStep!.isNotEmpty
                                ? extras.nextStep!
                                : 'Add next step',
                            style: TextStyles.bodyMd(context)
                                .copyWith(
                              color:
                                  extras.nextStep != null &&
                                          extras
                                              .nextStep!.isNotEmpty
                                      ? c.textPrimary
                                      : c.textDisabled,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: SpaceTokens.s12),
                        MonoText(
                          _nextStepTimeLabel(extras.nextStepDate),
                          size: 12,
                          color: c.textSecondary,
                        ),
                        const SizedBox(width: SpaceTokens.s8),
                        Icon(Icons.edit_outlined,
                            size: 14, color: c.textDisabled),
                      ],
                    ),
                  ),
                ),
                Divider(height: 1, thickness: 1, color: c.border),

                const SizedBox(height: SpaceTokens.s24),

                // ── CONTACT INFO ───────────────────────────────
                SectionLabel('CONTACT',
                    bottomPadding: SpaceTokens.s8),
                Divider(height: 1, thickness: 1, color: c.border),

                if (extras.email != null &&
                    extras.email!.isNotEmpty)
                  _ContactInfoRow(
                    icon: Icons.mail_outline_rounded,
                    value: extras.email!,
                    onTap: () =>
                        _launchUrl('mailto:${extras.email}'),
                  ),
                if (extras.phone != null &&
                    extras.phone!.isNotEmpty)
                  _ContactInfoRow(
                    icon: Icons.phone_outlined,
                    value: extras.phone!,
                    onTap: () =>
                        _launchUrl('tel:${extras.phone}'),
                  ),
                if (extras.company != null &&
                    extras.company!.isNotEmpty)
                  _ContactInfoRow(
                    icon: Icons.business_outlined,
                    value: extras.company!,
                    onTap: null, // read-only; edit via sheet
                  ),
                if ((extras.email == null ||
                        extras.email!.isEmpty) &&
                    (extras.phone == null ||
                        extras.phone!.isEmpty) &&
                    (extras.company == null ||
                        extras.company!.isEmpty))
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: SpaceTokens.s12),
                    child: GestureDetector(
                      onTap: () =>
                          _showEditDetailsSheet(context, vm),
                      child: Text(
                        'Add email, phone or company →',
                        style: TextStyles.bodyMd(context)
                            .copyWith(color: c.textDisabled),
                      ),
                    ),
                  ),
                Divider(height: 1, thickness: 1, color: c.border),

                const SizedBox(height: SpaceTokens.s24),

                // ── NOTES ──────────────────────────────────────
                SectionLabel('NOTES',
                    bottomPadding: SpaceTokens.s8),
                Divider(height: 1, thickness: 1, color: c.border),
                const SizedBox(height: SpaceTokens.s12),
                AppInput(
                  controller: _notesCtrl,
                  hintText: 'Add notes…',
                  maxLines: null,
                  minLines: 3,
                  textInputAction: TextInputAction.newline,
                ),
                if (_notesDirty) ...[
                  const SizedBox(height: SpaceTokens.s12),
                  AppButton(
                    label: 'Save notes',
                    onPressed: () => _saveNotes(vm),
                  ),
                ],

                const SizedBox(height: SpaceTokens.s24),

                // ── ACTIVITY (placeholder) ─────────────────────
                SectionLabel('ACTIVITY',
                    bottomPadding: SpaceTokens.s8),
                Divider(height: 1, thickness: 1, color: c.border),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: SpaceTokens.s12),
                  child: Text(
                    'No activity yet.',
                    style: TextStyles.bodyMd(context).copyWith(
                      color: c.textDisabled,
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// KV ROW — label / value pair; hairline below
// ---------------------------------------------------------------------------

class _KvRow extends StatelessWidget {
  const _KvRow({
    required this.label,
    required this.value,
    this.onTap,
    this.isMono = false,
    this.isLast = false,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool isMono;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: SpaceTokens.s12),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyles.bodyMd(context)
                  .copyWith(color: c.textSecondary),
            ),
          ),
          const SizedBox(width: SpaceTokens.s8),
          Expanded(
            child: isMono
                ? MonoText(value, size: 14, weight: FontWeight.w500)
                : Text(
                    value,
                    style: TextStyles.bodyMd(context)
                        .copyWith(fontWeight: FontWeight.w500),
                  ),
          ),
          if (onTap != null)
            Icon(Icons.chevron_right_rounded,
                size: 16, color: c.textDisabled),
        ],
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        onTap != null
            ? InkWell(
                onTap: onTap,
                splashColor: c.border.withValues(alpha: 0.12),
                highlightColor: c.border.withValues(alpha: 0.06),
                child: content,
              )
            : content,
        if (!isLast)
          Divider(height: 1, thickness: 1, color: c.border),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// CONTACT INFO ROW — icon + value, tappable for mailto:/tel:
// ---------------------------------------------------------------------------

class _ContactInfoRow extends StatelessWidget {
  const _ContactInfoRow({
    required this.icon,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);

    final content = Padding(
      padding: const EdgeInsets.symmetric(
        vertical: SpaceTokens.s12,
        horizontal: 0,
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: c.textSecondary),
          const SizedBox(width: SpaceTokens.s12),
          Expanded(
            child: Text(
              value,
              style: TextStyles.bodyMd(context).copyWith(
                color:
                    onTap != null ? c.textPrimary : c.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        onTap != null
            ? InkWell(
                onTap: onTap,
                splashColor: c.border.withValues(alpha: 0.12),
                highlightColor: c.border.withValues(alpha: 0.06),
                child: content,
              )
            : content,
        Divider(height: 1, thickness: 1, color: c.border),
      ],
    );
  }
}
