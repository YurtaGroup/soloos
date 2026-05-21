import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/tokens.dart';
import '../../../../theme/text_styles.dart';
import '../../../../theme/atoms/app_card.dart';
import '../../../../theme/atoms/app_button.dart';
import '../../../../models/app_models.dart';
import '../../../../widgets/common_widgets.dart';
import '../../../../shared/widgets/paywall_screen.dart';
import '../viewmodels/ideas_view_model.dart';
import '../../../../shared/widgets/app_bottom_sheet.dart';

class IdeasScreen extends StatefulWidget {
  const IdeasScreen({super.key});

  @override
  State<IdeasScreen> createState() => _IdeasScreenState();
}

class _IdeasScreenState extends State<IdeasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showAddDialog(BuildContext context, IdeasViewModel vm) async {
    if (vm.atActiveLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Max 3 active ideas. Archive one to focus more.'),
        ),
      );
      return;
    }

    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    await AppBottomSheet.show(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New Idea', style: TextStyles.displayMd(ctx)),
          const SizedBox(height: SpaceTokens.s16),
          TextField(
            controller: titleCtrl,
            autofocus: true,
            style: TextStyles.bodyMd(ctx),
            decoration: const InputDecoration(hintText: 'Idea title'),
          ),
          const SizedBox(height: SpaceTokens.s12),
          TextField(
            controller: descCtrl,
            maxLines: 3,
            style: TextStyles.bodyMd(ctx),
            decoration: const InputDecoration(
              hintText: 'Describe it briefly.',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: SpaceTokens.s16),
          AppButton(
            label: 'Add Idea',
            isFullWidth: true,
            onPressed: () async {
              final added = await vm.addIdea(
                title: titleCtrl.text,
                description: descCtrl.text,
              );
              if (added && ctx.mounted) Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    final vm = context.watch<IdeasViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Ideas Pipeline', style: TextStyles.displayMd(context)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: c.accent,
          labelColor: c.textPrimary,
          unselectedLabelColor: c.textSecondary,
          tabs: [
            Tab(text: 'Active (${vm.activeIdeas.length}/3)'),
            Tab(text: 'Archive (${vm.archivedIdeas.length})'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: c.textSecondary),
            onPressed: () => _showAddDialog(context, vm),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _IdeasList(
            ideas: vm.activeIdeas,
            emptyEmoji: '',
            emptyTitle: 'No active ideas',
            emptySubtitle: 'Add up to 3 ideas you are actively pursuing.',
            onAddTap: () => _showAddDialog(context, vm),
          ),
          _IdeasList(
            ideas: vm.archivedIdeas,
            emptyEmoji: '',
            emptyTitle: 'Archive is empty',
            emptySubtitle: 'Archived ideas live here.',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'ideas_fab',
        onPressed: () => _showAddDialog(context, vm),
        backgroundColor: c.primaryButton,
        foregroundColor: c.primaryButtonLabel,
        elevation: 0,
        child: const Icon(Icons.lightbulb_outline_rounded),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Private widgets
// ─────────────────────────────────────────────────────────────────

class _IdeasList extends StatelessWidget {
  const _IdeasList({
    required this.ideas,
    required this.emptyEmoji,
    required this.emptyTitle,
    required this.emptySubtitle,
    this.onAddTap,
  });

  final List<Idea> ideas;
  final String emptyEmoji;
  final String emptyTitle;
  final String emptySubtitle;
  final VoidCallback? onAddTap;

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    if (ideas.isEmpty) {
      return EmptyState(
        emoji: emptyEmoji,
        title: emptyTitle,
        subtitle: emptySubtitle,
        onAction: onAddTap,
        actionLabel: 'New Idea',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(SpaceTokens.s16),
      itemCount: ideas.length,
      itemBuilder: (ctx, i) {
        final idea = ideas[i];
        return Dismissible(
          key: ValueKey(idea.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: SpaceTokens.s16),
            margin: const EdgeInsets.only(bottom: SpaceTokens.s12),
            decoration: BoxDecoration(
              color: c.danger.withValues(alpha: 0.12),
              borderRadius: RadiusTokens.smAll,
            ),
            child: Icon(Icons.delete_outline, color: c.danger),
          ),
          confirmDismiss: (_) async {
            return await showDialog<bool>(
              context: ctx,
              builder: (d) => AlertDialog(
                title: const Text('Delete idea?'),
                content: Text(idea.title),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(d, false),
                      child: const Text('Cancel')),
                  TextButton(
                    onPressed: () => Navigator.pop(d, true),
                    style: TextButton.styleFrom(foregroundColor: c.danger),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ) ??
                false;
          },
          onDismissed: (_) => ctx.read<IdeasViewModel>().deleteIdea(idea.id),
          child: _IdeaCard(idea: idea),
        );
      },
    );
  }
}

class _IdeaCard extends StatefulWidget {
  const _IdeaCard({required this.idea});
  final Idea idea;

  @override
  State<_IdeaCard> createState() => _IdeaCardState();
}

class _IdeaCardState extends State<_IdeaCard> {
  bool _expanded = false;

  Future<void> _pickPlatformAndGenerateScript(
      BuildContext context, IdeasViewModel vm) async {
    String? platform;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose Platform'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['YouTube', 'Twitter/X', 'LinkedIn', 'Instagram', 'TikTok']
              .map((p) => ListTile(
                    title: Text(p),
                    onTap: () {
                      platform = p;
                      Navigator.pop(ctx);
                    },
                  ))
              .toList(),
        ),
      ),
    );
    if (platform != null) {
      await vm.generateScript(widget.idea, platform!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    final vm = context.watch<IdeasViewModel>();
    final idea = widget.idea;
    final isValidating = vm.isValidating(idea.id);
    final isScripting = vm.isScripting(idea.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: SpaceTokens.s12),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _expanded = !_expanded);
              },
              child: Padding(
                padding: const EdgeInsets.all(SpaceTokens.s16),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline_rounded,
                        color: c.accent, size: 18),
                    const SizedBox(width: SpaceTokens.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            idea.title,
                            style: TextStyles.bodyMd(context)
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (idea.description.isNotEmpty)
                            Text(
                              idea.description,
                              style: TextStyles.bodySm(context)
                                  .copyWith(color: c.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: MotionTokens.duration,
                      child: Icon(Icons.keyboard_arrow_down,
                          color: c.textSecondary),
                    ),
                  ],
                ),
              ),
            ),

            // ── Expanded body ────────────────────────────────────────
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(height: 1, color: c.border),
                  Padding(
                    padding: const EdgeInsets.all(SpaceTokens.s12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _ActionBtn(
                              label: isValidating ? 'Validating.' : 'Validate',
                              icon: Icons.smart_toy_outlined,
                              color: c.accent,
                              onTap: isValidating
                                  ? null
                                  : () async {
                                      final limit = await vm.checkAiLimit();
                                      if (limit != null && context.mounted) {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const PaywallScreen(
                                                        feature: 'ai_calls')));
                                        return;
                                      }
                                      vm.validateIdea(idea);
                                    },
                            ),
                            const SizedBox(width: SpaceTokens.s8),
                            _ActionBtn(
                              label: isScripting ? 'Scripting.' : 'Script',
                              icon: Icons.edit_outlined,
                              color: c.textPrimary,
                              onTap: isScripting
                                  ? null
                                  : () async {
                                      final limit = await vm.checkAiLimit();
                                      if (limit != null && context.mounted) {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const PaywallScreen(
                                                        feature: 'ai_calls')));
                                        return;
                                      }
                                      _pickPlatformAndGenerateScript(
                                          context, vm);
                                    },
                            ),
                            const SizedBox(width: SpaceTokens.s8),
                            if (idea.status == IdeaStatus.active)
                              _ActionBtn(
                                label: 'Archive',
                                icon: Icons.archive_outlined,
                                color: c.textSecondary,
                                onTap: () => vm.updateStatus(
                                    idea.id, IdeaStatus.archived),
                              )
                            else
                              _ActionBtn(
                                label: 'Activate',
                                icon: Icons.unarchive_outlined,
                                color: c.success,
                                onTap: () =>
                                    vm.updateStatus(idea.id, IdeaStatus.active),
                              ),
                          ],
                        ),
                        if (idea.aiScript != null) ...[
                          const SizedBox(height: SpaceTokens.s12),
                          Text('Content Script',
                              style: TextStyles.bodySm(context).copyWith(
                                  color: c.textSecondary,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: SpaceTokens.s4),
                          Container(
                            padding: const EdgeInsets.all(SpaceTokens.s12),
                            decoration: BoxDecoration(
                              color: c.surfaceMuted,
                              borderRadius: RadiusTokens.smAll,
                            ),
                            child: Text(
                              idea.aiScript!,
                              style: TextStyles.bodyMd(context)
                                  .copyWith(height: 1.6),
                            ),
                          ),
                        ],
                        if (idea.notes.isNotEmpty) ...[
                          const SizedBox(height: SpaceTokens.s12),
                          ...idea.notes.map((note) => Container(
                                margin: const EdgeInsets.only(
                                    bottom: SpaceTokens.s8),
                                padding: const EdgeInsets.all(SpaceTokens.s8),
                                decoration: BoxDecoration(
                                  color: c.surfaceMuted,
                                  borderRadius: RadiusTokens.smAll,
                                ),
                                child: Text(
                                  note,
                                  style: TextStyles.bodySm(context)
                                      .copyWith(color: c.textSecondary,
                                          height: 1.5),
                                ),
                              )),
                        ],
                        if (isValidating || isScripting)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: SpaceTokens.s8),
                            child:
                                AiThinkingWidget(message: 'AI is working.'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: MotionTokens.duration,
              sizeCurve: Curves.easeOutCubic,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: MotionTokens.duration,
        curve: MotionTokens.curve,
        padding: const EdgeInsets.symmetric(
            horizontal: SpaceTokens.s8, vertical: SpaceTokens.s4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: RadiusTokens.smAll,
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: onTap == null ? c.textDisabled : color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyles.bodySm(context).copyWith(
                color: onTap == null ? c.textDisabled : color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
