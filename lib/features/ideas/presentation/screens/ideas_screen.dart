import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_theme.dart';
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
          content: Text('⚡ Max 3 active ideas. Archive one to focus more.'),
          backgroundColor: AppColors.ideasColor,
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
          const Text(
            '💡 New Idea',
            style: TextStyle(
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
            decoration: const InputDecoration(hintText: 'Idea title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descCtrl,
            maxLines: 3,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Describe it briefly...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final added = await vm.addIdea(
                  title: titleCtrl.text,
                  description: descCtrl.text,
                );
                if (added && ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Add Idea'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<IdeasViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ideas Pipeline'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.ideasColor,
          labelColor: AppColors.ideasColor,
          unselectedLabelColor: AppColors.textMuted,
          tabs: [
            Tab(text: 'Active (${vm.activeIdeas.length}/3)'),
            Tab(text: 'Archive (${vm.archivedIdeas.length})'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.ideasColor),
            onPressed: () => _showAddDialog(context, vm),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _IdeasList(
            ideas: vm.activeIdeas,
            emptyEmoji: '💡',
            emptyTitle: 'No active ideas',
            emptySubtitle:
                'Add up to 3 ideas you\'re actively\npursuing. Quality over quantity.',
            onAddTap: () => _showAddDialog(context, vm),
          ),
          _IdeasList(
            ideas: vm.archivedIdeas,
            emptyEmoji: '📦',
            emptyTitle: 'Archive is empty',
            emptySubtitle: 'Archived ideas live here.',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'ideas_fab',
        onPressed: () => _showAddDialog(context, vm),
        backgroundColor: AppColors.ideasColor,
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
    if (ideas.isEmpty) {
      return EmptyState(
        emoji: emptyEmoji,
        title: emptyTitle,
        subtitle: emptySubtitle,
        onAction: onAddTap,
        actionLabel: '+ New Idea',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ideas.length,
      itemBuilder: (ctx, i) => _IdeaCard(idea: ideas[i]),
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
        backgroundColor: AppColors.card,
        title: const Text('Choose Platform',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children:
              ['YouTube', 'Twitter/X', 'LinkedIn', 'Instagram', 'TikTok']
                  .map((p) => ListTile(
                        title: Text(p,
                            style: const TextStyle(
                                color: AppColors.textPrimary)),
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
    final vm = context.watch<IdeasViewModel>();
    final idea = widget.idea;
    final isValidating = vm.isValidating(idea.id);
    final isScripting = vm.isScripting(idea.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ideasColor.withOpacity(0.2)),
      ),
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
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.ideasColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.lightbulb_outline_rounded,
                        color: AppColors.ideasColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          idea.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (idea.description.isNotEmpty)
                          Text(
                            idea.description,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textMuted,
                    ),
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
                const Divider(height: 1, color: Color(0xFF252535)),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _ActionBtn(
                            label: isValidating ? '...' : '🤖 Validate',
                            color: AppColors.ideasColor,
                            onTap: isValidating
                                ? null
                                : () async {
                                    final limit = await vm.checkAiLimit();
                                    if (limit != null && context.mounted) {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen(feature: 'ai_calls')));
                                      return;
                                    }
                                    vm.validateIdea(idea);
                                  },
                          ),
                          const SizedBox(width: 8),
                          _ActionBtn(
                            label: isScripting ? '...' : '✍️ Script',
                            color: AppColors.accentBlue,
                            onTap: isScripting
                                ? null
                                : () async {
                                    final limit = await vm.checkAiLimit();
                                    if (limit != null && context.mounted) {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen(feature: 'ai_calls')));
                                      return;
                                    }
                                    _pickPlatformAndGenerateScript(context, vm);
                                  },
                          ),
                          const SizedBox(width: 8),
                          if (idea.status == IdeaStatus.active)
                            _ActionBtn(
                              label: '📦 Archive',
                              color: AppColors.textSecondary,
                              onTap: () =>
                                  vm.updateStatus(idea.id, IdeaStatus.archived),
                            )
                          else
                            _ActionBtn(
                              label: '🔄 Activate',
                              color: AppColors.accentGreen,
                              onTap: () =>
                                  vm.updateStatus(idea.id, IdeaStatus.active),
                            ),
                        ],
                      ),
                      if (idea.aiScript != null) ...[
                        const SizedBox(height: 12),
                        const Text(
                          '📝 Content Script',
                          style: TextStyle(
                            color: AppColors.accentBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.accentBlue.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.accentBlue.withOpacity(0.2)),
                          ),
                          child: Text(
                            idea.aiScript!,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                      if (idea.notes.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ...idea.notes.map((note) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                note,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                              ),
                            )),
                      ],
                      if (isValidating || isScripting)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: AiThinkingWidget(
                              message: 'AI is working on it...'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.color,
    this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style:
              TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
