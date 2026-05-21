import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/tokens.dart';
import '../../../../theme/text_styles.dart';
import '../../../../theme/atoms/app_card.dart';
import '../../../../theme/atoms/app_button.dart';
import '../../../../theme/atoms/app_row.dart';
import '../../../../theme/atoms/app_pill.dart';
import '../../../../services/locale_service.dart';
import '../viewmodels/circles_view_model.dart';
import '../../domain/models/circle.dart';

class CirclesScreen extends StatefulWidget {
  const CirclesScreen({super.key});

  @override
  State<CirclesScreen> createState() => _CirclesScreenState();
}

class _CirclesScreenState extends State<CirclesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CirclesViewModel>().loadCircles();
  }

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    final vm = context.watch<CirclesViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(ls.t('circles_title'), style: TextStyles.displayMd(context)),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: c.textSecondary),
            onPressed: () => _showCreateDialog(context, vm),
          ),
        ],
      ),
      body: vm.loading
          ? Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: c.accent,
              ),
            )
          : vm.circles.isEmpty
              ? _EmptyState(
                  onCreateCircle: () => _showCreateDialog(context, vm),
                  onJoinCircle: () => _showJoinDialog(context, vm),
                )
              : ListView(
                  padding: const EdgeInsets.all(SpaceTokens.s16),
                  children: [
                    // Join with code
                    AppCard(
                      padding: EdgeInsets.zero,
                      onTap: () => _showJoinDialog(context, vm),
                      child: AppRow(
                        title: ls.t('circles_join_code'),
                        leading: Icon(Icons.link_rounded,
                            size: 20, color: c.textSecondary),
                        showDivider: false,
                        trailing: Icon(Icons.chevron_right_rounded,
                            size: 18, color: c.textSecondary),
                      ),
                    ),
                    const SizedBox(height: SpaceTokens.s12),
                    ...vm.circles.map((circle) => Padding(
                          padding: const EdgeInsets.only(
                              bottom: SpaceTokens.s8),
                          child: _CircleCard(
                            circle: circle,
                            onTap: () =>
                                _showDetailSheet(context, vm, circle),
                          ),
                        )),
                  ],
                ),
    );
  }

  void _showCreateDialog(BuildContext context, CirclesViewModel vm) {
    final c = QColors.of(context);
    final nameCtrl = TextEditingController();
    String emoji = '';
    final selectedModules = <String>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: RadiusTokens.lg),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + SpaceTokens.s24,
            left: SpaceTokens.s16,
            right: SpaceTokens.s16,
            top: SpaceTokens.s24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ls.t('circles_create'),
                  style: TextStyles.displayMd(ctx)),
              const SizedBox(height: SpaceTokens.s16),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: TextStyles.bodyMd(ctx),
                decoration:
                    InputDecoration(hintText: ls.t('circles_name_hint')),
              ),
              const SizedBox(height: SpaceTokens.s16),
              Text(ls.t('circles_modules_label'),
                  style: TextStyles.bodySm(ctx)
                      .copyWith(color: c.textSecondary)),
              const SizedBox(height: SpaceTokens.s8),
              Wrap(
                spacing: SpaceTokens.s8,
                children: [
                  _ModuleChip(
                    label: 'Finance',
                    module: 'finance',
                    icon: Icons.account_balance_wallet_outlined,
                    selected: selectedModules.contains('finance'),
                    onTap: () => setModal(() => selectedModules.contains('finance')
                        ? selectedModules.remove('finance')
                        : selectedModules.add('finance')),
                  ),
                  _ModuleChip(
                    label: 'Work',
                    module: 'work',
                    icon: Icons.work_outline_rounded,
                    selected: selectedModules.contains('work'),
                    onTap: () => setModal(() => selectedModules.contains('work')
                        ? selectedModules.remove('work')
                        : selectedModules.add('work')),
                  ),
                ],
              ),
              const SizedBox(height: SpaceTokens.s16),
              AppButton(
                label: ls.t('circles_create_btn'),
                isFullWidth: true,
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty ||
                      selectedModules.isEmpty) return;
                  await vm.createCircle(
                    name: nameCtrl.text,
                    emoji: emoji,
                    modules: selectedModules.toList(),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showJoinDialog(BuildContext context, CirclesViewModel vm) {
    final c = QColors.of(context);
    final codeCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: RadiusTokens.lg),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + SpaceTokens.s24,
          left: SpaceTokens.s16,
          right: SpaceTokens.s16,
          top: SpaceTokens.s24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ls.t('circles_join'), style: TextStyles.displayMd(ctx)),
            const SizedBox(height: SpaceTokens.s16),
            TextField(
              controller: codeCtrl,
              autofocus: true,
              style: TextStyles.bodyMd(ctx),
              decoration:
                  InputDecoration(hintText: ls.t('circles_code_hint')),
            ),
            const SizedBox(height: SpaceTokens.s16),
            AppButton(
              label: ls.t('circles_join_btn'),
              isFullWidth: true,
              onPressed: () async {
                if (codeCtrl.text.trim().isEmpty) return;
                final ok = await vm.joinWithCode(codeCtrl.text);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok
                          ? ls.t('circles_joined')
                          : (vm.error ?? 'Failed to join')),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailSheet(
      BuildContext context, CirclesViewModel vm, Circle circle) {
    final c = QColors.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: RadiusTokens.lg),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(SpaceTokens.s16),
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
            Row(
              children: [
                if (circle.emoji.isNotEmpty) ...[
                  Text(circle.emoji,
                      style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: SpaceTokens.s12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(circle.name,
                          style: TextStyles.displayMd(ctx)),
                      Text('${circle.members.length} members',
                          style: TextStyles.bodySm(ctx)
                              .copyWith(color: c.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: SpaceTokens.s16),

            // Shared modules
            Text(ls.t('circles_shared_modules'),
                style: TextStyles.bodySm(ctx)
                    .copyWith(color: c.textSecondary, fontWeight: FontWeight.w500)),
            const SizedBox(height: SpaceTokens.s8),
            Wrap(
              spacing: SpaceTokens.s8,
              children: circle.modules
                  .map((m) => AppPill(
                      label: '${m[0].toUpperCase()}${m.substring(1)}',
                      variant: AppPillVariant.neutral))
                  .toList(),
            ),
            const SizedBox(height: SpaceTokens.s16),

            // Members
            Text(ls.t('circles_members'),
                style: TextStyles.bodySm(ctx)
                    .copyWith(color: c.textSecondary, fontWeight: FontWeight.w500)),
            const SizedBox(height: SpaceTokens.s8),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: circle.members.asMap().entries.map((entry) {
                  final i = entry.key;
                  final m = entry.value;
                  return AppRow(
                    title: m.email,
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: c.surfaceMuted,
                      child: Text(
                        m.email.isNotEmpty ? m.email[0].toUpperCase() : '?',
                        style: TextStyles.bodySm(ctx)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    showDivider: i < circle.members.length - 1,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppPill(
                          label: m.role,
                          variant: m.role == 'owner'
                              ? AppPillVariant.lime
                              : AppPillVariant.neutral,
                        ),
                        if (m.role != 'owner') ...[
                          const SizedBox(width: SpaceTokens.s4),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert_rounded,
                                size: 18, color: c.textSecondary),
                            color: c.surface,
                            onSelected: (action) {
                              Navigator.pop(ctx);
                              if (action == 'report') {
                                _showReportDialog(context, vm, circle.id, m);
                              } else if (action == 'block') {
                                _showBlockConfirm(context, vm, circle.id, m);
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'report',
                                child: Row(
                                  children: [
                                    Icon(Icons.flag_outlined,
                                        size: 18, color: c.warn),
                                    const SizedBox(width: SpaceTokens.s8),
                                    Text(ls.t('circles_report'),
                                        style: TextStyles.bodyMd(ctx)),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'block',
                                child: Row(
                                  children: [
                                    Icon(Icons.block_rounded,
                                        size: 18, color: c.danger),
                                    const SizedBox(width: SpaceTokens.s8),
                                    Text(ls.t('circles_block'),
                                        style: TextStyles.bodyMd(ctx)
                                            .copyWith(color: c.danger)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            // Actions
            const SizedBox(height: SpaceTokens.s16),
            if (circle.isOwner) ...[
              AppButton(
                label: ls.t('circles_invite'),
                isFullWidth: true,
                leadingIcon: const Icon(Icons.share_outlined),
                onPressed: () async {
                  final code = await vm.generateInvite(circle.id);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  if (code != null && context.mounted) {
                    Share.share(
                        'Join my "${circle.name}" circle on Solo OS.\n\nInvite code: $code');
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text(vm.error ?? 'Failed to generate invite')),
                    );
                  }
                },
              ),
              const SizedBox(height: SpaceTokens.s8),
              AppButton(
                label: ls.t('circles_delete'),
                variant: AppButtonVariant.ghost,
                isFullWidth: true,
                leadingIcon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await vm.deleteCircle(circle.id);
                },
              ),
            ] else ...[
              AppButton(
                label: ls.t('circles_leave'),
                variant: AppButtonVariant.ghost,
                isFullWidth: true,
                leadingIcon: const Icon(Icons.exit_to_app_rounded),
                onPressed: () async {
                  final myMembership =
                      circle.members.where((m) => m.role != 'owner').toList();
                  if (myMembership.isNotEmpty) {
                    Navigator.pop(ctx);
                    await vm.removeMember(circle.id, myMembership.first.id);
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context, CirclesViewModel vm,
      String circleId, CircleMember member) {
    final c = QColors.of(context);
    final reasonCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: RadiusTokens.lg),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + SpaceTokens.s24,
          left: SpaceTokens.s16,
          right: SpaceTokens.s16,
          top: SpaceTokens.s24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ls.t('circles_report_title'),
                style: TextStyles.displayMd(ctx)),
            const SizedBox(height: SpaceTokens.s4),
            Text(member.email,
                style: TextStyles.bodyMd(ctx)
                    .copyWith(color: c.textSecondary)),
            const SizedBox(height: SpaceTokens.s16),
            TextField(
              controller: reasonCtrl,
              autofocus: true,
              maxLines: 3,
              style: TextStyles.bodyMd(ctx),
              decoration:
                  InputDecoration(hintText: ls.t('circles_report_hint')),
            ),
            const SizedBox(height: SpaceTokens.s16),
            AppButton(
              label: ls.t('circles_report_btn'),
              isFullWidth: true,
              onPressed: () async {
                if (reasonCtrl.text.trim().isEmpty) return;
                final ok = await vm.reportMember(
                    circleId, member.id, reasonCtrl.text);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(ok
                            ? ls.t('circles_report_sent')
                            : (vm.error ?? 'Failed'))),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockConfirm(BuildContext context, CirclesViewModel vm,
      String circleId, CircleMember member) {
    final c = QColors.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ls.t('circles_block')),
        content: Text(ls.t('circles_block_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ls.t('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await vm.blockMember(circleId, member.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(ok
                          ? ls.t('circles_blocked')
                          : (vm.error ?? 'Failed'))),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: c.danger),
            child: Text(ls.t('circles_block_btn')),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateCircle;
  final VoidCallback onJoinCircle;
  const _EmptyState(
      {required this.onCreateCircle, required this.onJoinCircle});

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SpaceTokens.s32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined, size: 48, color: c.textSecondary),
            const SizedBox(height: SpaceTokens.s16),
            Text(ls.t('circles_empty_title'),
                style: TextStyles.displayMd(context)),
            const SizedBox(height: SpaceTokens.s8),
            Text(ls.t('circles_empty_sub'),
                textAlign: TextAlign.center,
                style: TextStyles.bodyMd(context)
                    .copyWith(color: c.textSecondary)),
            const SizedBox(height: SpaceTokens.s24),
            AppButton(
              label: ls.t('circles_create_btn'),
              isFullWidth: true,
              onPressed: onCreateCircle,
            ),
            const SizedBox(height: SpaceTokens.s8),
            AppButton(
              label: ls.t('circles_join_btn'),
              variant: AppButtonVariant.secondary,
              isFullWidth: true,
              onPressed: onJoinCircle,
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleCard extends StatelessWidget {
  final Circle circle;
  final VoidCallback onTap;
  const _CircleCard({required this.circle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: AppRow(
        title: circle.name,
        subtitle: '${circle.members.length} members · ${circle.modules.join(", ")}',
        leading: circle.emoji.isNotEmpty
            ? Text(circle.emoji, style: const TextStyle(fontSize: 22))
            : Icon(Icons.group_outlined, size: 22, color: c.textSecondary),
        showDivider: false,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (circle.isOwner)
              Padding(
                padding: const EdgeInsets.only(right: SpaceTokens.s4),
                child: AppPill(label: 'Owner', variant: AppPillVariant.lime),
              ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: c.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _ModuleChip extends StatelessWidget {
  final String label, module;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ModuleChip(
      {required this.label,
      required this.module,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: MotionTokens.duration,
        curve: MotionTokens.curve,
        padding: const EdgeInsets.symmetric(
            horizontal: SpaceTokens.s12, vertical: SpaceTokens.s8),
        decoration: BoxDecoration(
          color: selected
              ? c.accent.withValues(alpha: 0.12)
              : c.surfaceMuted,
          borderRadius: RadiusTokens.smAll,
          border: Border.all(
              color: selected ? c.accent : c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: selected ? c.textPrimary : c.textSecondary),
            const SizedBox(width: SpaceTokens.s4),
            Text(label,
                style: TextStyles.bodyMd(context).copyWith(
                  color: selected ? c.textPrimary : c.textSecondary,
                  fontWeight: FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }
}
