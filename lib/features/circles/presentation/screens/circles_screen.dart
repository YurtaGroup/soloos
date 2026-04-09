import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../theme/app_theme.dart';
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
    final vm = context.watch<CirclesViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(ls.t('circles_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: () => _showCreateDialog(context, vm),
          ),
        ],
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : vm.circles.isEmpty
              ? _EmptyState(
                  onCreateCircle: () => _showCreateDialog(context, vm),
                  onJoinCircle: () => _showJoinDialog(context, vm),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Join with code button
                    GestureDetector(
                      onTap: () => _showJoinDialog(context, vm),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.link_rounded, color: AppColors.primary, size: 20),
                            const SizedBox(width: 10),
                            Text(ls.t('circles_join_code'),
                                style: const TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                    ...vm.circles.map((c) => _CircleCard(
                          circle: c,
                          onTap: () => _showDetailSheet(context, vm, c),
                        )),
                  ],
                ),
    );
  }

  void _showCreateDialog(BuildContext context, CirclesViewModel vm) {
    final nameCtrl = TextEditingController();
    String emoji = '';
    final selectedModules = <String>{};

    showModalBottomSheet(
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
            left: 20, right: 20, top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ls.t('circles_create'), style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(hintText: ls.t('circles_name_hint')),
              ),
              const SizedBox(height: 16),
              Text(ls.t('circles_modules_label'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _ModuleChip(label: 'Finance', module: 'finance', icon: Icons.account_balance_wallet_outlined,
                      selected: selectedModules.contains('finance'),
                      onTap: () => setModal(() => selectedModules.contains('finance') ? selectedModules.remove('finance') : selectedModules.add('finance'))),
                  _ModuleChip(label: 'Work', module: 'work', icon: Icons.work_outline_rounded,
                      selected: selectedModules.contains('work'),
                      onTap: () => setModal(() => selectedModules.contains('work') ? selectedModules.remove('work') : selectedModules.add('work'))),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty || selectedModules.isEmpty) return;
                    await vm.createCircle(
                      name: nameCtrl.text,
                      emoji: emoji.isEmpty ? '' : emoji,
                      modules: selectedModules.toList(),
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text(ls.t('circles_create_btn')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showJoinDialog(BuildContext context, CirclesViewModel vm) {
    final codeCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20, right: 20, top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ls.t('circles_join'), style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: codeCtrl,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(hintText: ls.t('circles_code_hint')),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (codeCtrl.text.trim().isEmpty) return;
                  final ok = await vm.joinWithCode(codeCtrl.text);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(ok ? ls.t('circles_joined') : (vm.error ?? 'Failed to join'))),
                    );
                  }
                },
                child: Text(ls.t('circles_join_btn')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailSheet(BuildContext context, CirclesViewModel vm, Circle circle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: AppColors.textMuted, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(circle.emoji.isEmpty ? '' : circle.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(circle.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                      Text('${circle.members.length} members', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Shared modules
            Text(ls.t('circles_shared_modules'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: circle.modules.map((m) => Chip(
                    label: Text(m[0].toUpperCase() + m.substring(1)),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    labelStyle: const TextStyle(color: AppColors.primary, fontSize: 12),
                    side: BorderSide.none,
                  )).toList(),
            ),
            const SizedBox(height: 20),

            // Members
            Text(ls.t('circles_members'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            ...circle.members.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                        child: Text(
                          m.email.isNotEmpty ? m.email[0].toUpperCase() : '?',
                          style: const TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(m.email, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: m.role == 'owner' ? AppColors.accent.withValues(alpha: 0.15) : AppColors.surface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(m.role, style: TextStyle(
                            color: m.role == 'owner' ? AppColors.accent : AppColors.textMuted,
                            fontSize: 11, fontWeight: FontWeight.w500)),
                      ),
                      if (m.role != 'owner')
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textMuted),
                          color: AppColors.card,
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
                                  const Icon(Icons.flag_outlined, size: 18, color: AppColors.accent),
                                  const SizedBox(width: 8),
                                  Text(ls.t('circles_report'), style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'block',
                              child: Row(
                                children: [
                                  const Icon(Icons.block_rounded, size: 18, color: AppColors.accentRed),
                                  const SizedBox(width: 8),
                                  Text(ls.t('circles_block'), style: const TextStyle(color: AppColors.accentRed, fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                )),

            // Actions
            const SizedBox(height: 20),
            if (circle.isOwner) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final code = await vm.generateInvite(circle.id);
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    if (code != null && context.mounted) {
                      Share.share('Join my "${circle.name}" circle on Solo OS!\n\nInvite code: $code');
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(vm.error ?? 'Failed to generate invite')),
                      );
                    }
                  },
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: Text(ls.t('circles_invite')),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGreen),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await vm.deleteCircle(circle.id);
                },
                icon: const Icon(Icons.delete_outline, color: AppColors.accentRed, size: 18),
                label: Text(ls.t('circles_delete'), style: const TextStyle(color: AppColors.accentRed)),
              ),
            ] else ...[
              TextButton.icon(
                onPressed: () async {
                  final myMembership = circle.members.where((m) => m.role != 'owner').toList();
                  if (myMembership.isNotEmpty) {
                    Navigator.pop(ctx);
                    await vm.removeMember(circle.id, myMembership.first.id);
                  }
                },
                icon: const Icon(Icons.exit_to_app_rounded, color: AppColors.accentRed, size: 18),
                label: Text(ls.t('circles_leave'), style: const TextStyle(color: AppColors.accentRed)),
              ),
            ],
          ],
        ),
      ),
    );
  }
  void _showReportDialog(BuildContext context, CirclesViewModel vm, String circleId, CircleMember member) {
    final reasonCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20, right: 20, top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ls.t('circles_report_title'),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(member.email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              autofocus: true,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(hintText: ls.t('circles_report_hint')),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (reasonCtrl.text.trim().isEmpty) return;
                  final ok = await vm.reportMember(circleId, member.id, reasonCtrl.text);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(ok ? ls.t('circles_report_sent') : (vm.error ?? 'Failed'))),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                child: Text(ls.t('circles_report_btn')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockConfirm(BuildContext context, CirclesViewModel vm, String circleId, CircleMember member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(ls.t('circles_block'),
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(ls.t('circles_block_confirm'),
            style: const TextStyle(color: AppColors.textSecondary)),
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
                  SnackBar(content: Text(ok ? ls.t('circles_blocked') : (vm.error ?? 'Failed'))),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.accentRed),
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
  const _EmptyState({required this.onCreateCircle, required this.onJoinCircle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('👥', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(ls.t('circles_empty_title'), style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(ls.t('circles_empty_sub'), textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: onCreateCircle, child: Text(ls.t('circles_create_btn'))),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onJoinCircle,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: BorderSide(color: AppColors.textMuted.withValues(alpha: 0.3)),
                ),
                child: Text(ls.t('circles_join_btn')),
              ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Text(circle.emoji.isEmpty ? '' : circle.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(circle.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                  Text('${circle.members.length} members · ${circle.modules.join(", ")}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            if (circle.isOwner)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                child: const Text('Owner', style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
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
  const _ModuleChip({required this.label, required this.module, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.primary : AppColors.textMuted.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? AppColors.primary : AppColors.textMuted),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: selected ? AppColors.primary : AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
