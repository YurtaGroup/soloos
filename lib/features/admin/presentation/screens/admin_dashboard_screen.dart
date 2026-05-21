import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/tokens.dart';
import '../../../../theme/text_styles.dart';
import '../../../../theme/atoms/section_label.dart';
import '../../../../theme/atoms/app_card.dart';
import '../../../../theme/atoms/app_pill.dart';
import '../../../../theme/atoms/mono_text.dart';
import '../../../../services/api_service.dart';

/// The founder's command center.
/// Shows real-time SaaS metrics — users, engagement, content, AI usage.
/// Only accessible to admin users.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _data;
  List<dynamic>? _users;
  bool _loading = true;
  String? _error;
  int _tab = 0; // 0 = dashboard, 1 = users

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.directRequest('GET', '/api/admin/dashboard');
      setState(() {
        _data = Map<String, dynamic>.from(data);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data =
          await ApiService.directRequest('GET', '/api/admin/users?limit=100');
      setState(() {
        _users = List.from(data['users'] ?? []);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Command Center', style: TextStyles.displayMd(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _tab == 0 ? _loadDashboard : _loadUsers,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            children: [
              _TabButton('Dashboard', _tab == 0, () {
                setState(() => _tab = 0);
                if (_data == null) _loadDashboard();
              }),
              _TabButton('Users', _tab == 1, () {
                setState(() => _tab = 1);
                if (_users == null) _loadUsers();
              }),
            ],
          ),
        ),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: c.accent))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(SpaceTokens.s24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            color: c.danger, size: 40),
                        const SizedBox(height: SpaceTokens.s16),
                        Text(_error!,
                            style: TextStyles.bodyMd(context)
                                .copyWith(color: c.textSecondary),
                            textAlign: TextAlign.center),
                        const SizedBox(height: SpaceTokens.s16),
                        TextButton(
                          onPressed: _loadDashboard,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _tab == 0
                  ? _buildDashboard()
                  : _buildUsers(),
    );
  }

  Widget _buildDashboard() {
    if (_data == null) return const SizedBox.shrink();
    final users = _data!['users'] as Map<String, dynamic>? ?? {};
    final content = _data!['content'] as Map<String, dynamic>? ?? {};
    final analytics = _data!['analytics'] as Map<String, dynamic>? ?? {};
    final tasks = content['tasks'] as Map<String, dynamic>? ?? {};
    final topEvents = analytics['top_events'] as List? ?? [];
    final recentSignups = _data!['recent_signups'] as List? ?? [];

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        padding: const EdgeInsets.all(SpaceTokens.s16),
        children: [
          // ── Users ──
          SectionLabel('Users'),
          Row(
            children: [
              _MetricCard('Total', '${users['total'] ?? 0}',
                  Icons.people_outline_rounded),
              const SizedBox(width: SpaceTokens.s8),
              _MetricCard('DAU', '${users['dau'] ?? 0}',
                  Icons.today_rounded),
              const SizedBox(width: SpaceTokens.s8),
              _MetricCard('WAU', '${users['wau'] ?? 0}',
                  Icons.date_range_rounded),
              const SizedBox(width: SpaceTokens.s8),
              _MetricCard('MAU', '${users['mau'] ?? 0}',
                  Icons.calendar_month_rounded),
            ],
          ),
          const SizedBox(height: SpaceTokens.s8),
          Row(
            children: [
              _MetricCard('This Week', '+${users['this_week'] ?? 0}',
                  Icons.trending_up_rounded),
              const SizedBox(width: SpaceTokens.s8),
              _MetricCard('This Month', '+${users['this_month'] ?? 0}',
                  Icons.show_chart_rounded),
            ],
          ),
          const SizedBox(height: SpaceTokens.s24),

          // ── Content ──
          SectionLabel('Content'),
          Wrap(
            spacing: SpaceTokens.s8,
            runSpacing: SpaceTokens.s8,
            children: [
              _SmallMetric('Projects', '${content['projects'] ?? 0}'),
              _SmallMetric('Tasks', '${tasks['total'] ?? 0} (${tasks['completed'] ?? 0} done)'),
              _SmallMetric('Habits', '${content['habits'] ?? 0}'),
              _SmallMetric('Ideas', '${content['ideas'] ?? 0}'),
              _SmallMetric('Standups', '${content['standups'] ?? 0}'),
              _SmallMetric('Contacts', '${content['contacts'] ?? 0}'),
              _SmallMetric('Expenses', '${content['expenses'] ?? 0}'),
              _SmallMetric('Debts', '${content['debts'] ?? 0}'),
              _SmallMetric('Circles', '${content['circles'] ?? 0}'),
            ],
          ),
          const SizedBox(height: SpaceTokens.s24),

          // ── Analytics ──
          SectionLabel('Analytics'),
          Row(
            children: [
              _MetricCard('Today', '${analytics['events_today'] ?? 0}',
                  Icons.bolt_rounded),
              const SizedBox(width: SpaceTokens.s8),
              _MetricCard('This Week', '${analytics['events_this_week'] ?? 0}',
                  Icons.analytics_rounded),
            ],
          ),
          if (topEvents.isNotEmpty) ...[
            const SizedBox(height: SpaceTokens.s12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionLabel('Top Events (7d)',
                      bottomPadding: SpaceTokens.s8),
                  ...topEvents.take(10).map((e) => Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: SpaceTokens.s4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text('${e['event']}',
                                  style: TextStyles.bodyMd(context)),
                            ),
                            MonoText('${e['count']}',
                                weight: FontWeight.w700),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
          const SizedBox(height: SpaceTokens.s24),

          // ── Recent Signups ──
          if (recentSignups.isNotEmpty) ...[
            SectionLabel('Recent Signups'),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: recentSignups.map<Widget>((entry) {
                  final u = entry as Map<String, dynamic>;
                  final onboarded = u['onboarded'] == true;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: SpaceTokens.s16,
                        vertical: SpaceTokens.s12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: onboarded
                              ? QColors.of(context).success.withValues(alpha: 0.15)
                              : QColors.of(context).surfaceMuted,
                          child: Text(
                            (u['name'] ?? u['email'] ?? '?')
                                .toString()
                                .substring(0, 1)
                                .toUpperCase(),
                            style: TextStyles.bodySm(context)
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: SpaceTokens.s8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (u['name']?.toString().isNotEmpty ?? false)
                                    ? u['name']
                                    : u['email'] ?? '',
                                style: TextStyles.bodyMd(context),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _timeAgo(u['joined']),
                                style: TextStyles.bodySm(context).copyWith(
                                    color: QColors.of(context).textSecondary),
                              ),
                            ],
                          ),
                        ),
                        if (onboarded)
                          AppPill(
                              label: 'Onboarded',
                              variant: AppPillVariant.success),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: SpaceTokens.s32),
        ],
      ),
    );
  }

  Widget _buildUsers() {
    if (_users == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(SpaceTokens.s16),
        itemCount: _users!.length,
        itemBuilder: (context, i) {
          final c = QColors.of(context);
          final u = _users![i] as Map<String, dynamic>;
          final counts = u['counts'] as Map<String, dynamic>? ?? {};

          return Padding(
            padding: const EdgeInsets.only(bottom: SpaceTokens.s8),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: c.surfaceMuted,
                        child: Text(
                          (u['name']?.toString().isNotEmpty ?? false)
                              ? u['name'].toString().substring(0, 1).toUpperCase()
                              : (u['email'] ?? '?')
                                  .toString()
                                  .substring(0, 1)
                                  .toUpperCase(),
                          style: TextStyles.bodySm(context)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: SpaceTokens.s8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (u['name']?.toString().isNotEmpty ?? false)
                                  ? u['name']
                                  : u['email'] ?? '',
                              style: TextStyles.bodyMd(context)
                                  .copyWith(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(u['email'] ?? '',
                                style: TextStyles.bodySm(context)
                                    .copyWith(color: c.textSecondary)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          MonoText('Lv.${u['level'] ?? 1}',
                              weight: FontWeight.w700, color: c.accent),
                          MonoText('${u['xp'] ?? 0} XP',
                              size: 10, color: c.textSecondary),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: SpaceTokens.s8),
                  Wrap(
                    spacing: SpaceTokens.s4,
                    runSpacing: SpaceTokens.s4,
                    children: [
                      _CountChip('Projects', counts['projects']),
                      _CountChip('Tasks', counts['tasks']),
                      _CountChip('Habits', counts['habits']),
                      _CountChip('Ideas', counts['ideas']),
                      _CountChip('Standups', counts['standupLogs']),
                      _CountChip('Events', counts['analyticsEvents']),
                    ],
                  ),
                  const SizedBox(height: SpaceTokens.s4),
                  Row(
                    children: [
                      Text(
                        'Joined ${_timeAgo(u['joined'])}',
                        style: TextStyles.bodySm(context)
                            .copyWith(color: c.textSecondary),
                      ),
                      const Spacer(),
                      if (u['is_admin'] == true)
                        Padding(
                          padding: const EdgeInsets.only(right: SpaceTokens.s4),
                          child: AppPill(
                              label: 'Admin',
                              variant: AppPillVariant.warn),
                        ),
                      if (u['onboarded'] == true)
                        AppPill(
                            label: 'Onboarded',
                            variant: AppPillVariant.success),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _timeAgo(dynamic dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr.toString());
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabButton(this.label, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: SpaceTokens.s12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? c.accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyles.bodyMd(context).copyWith(
              color: selected ? c.textPrimary : c.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _MetricCard(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    return Expanded(
      child: AppCard(
        dense: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: c.textSecondary, size: 16),
            const SizedBox(height: SpaceTokens.s4),
            MonoText(value, size: 20, weight: FontWeight.w700),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyles.bodySm(context)
                    .copyWith(color: c.textSecondary, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _SmallMetric extends StatelessWidget {
  final String label, value;
  const _SmallMetric(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: SpaceTokens.s8, vertical: SpaceTokens.s4),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: RadiusTokens.smAll,
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MonoText(value, size: 13, weight: FontWeight.w600),
          Text(label,
              style: TextStyles.bodySm(context)
                  .copyWith(color: c.textSecondary, fontSize: 10)),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final dynamic count;
  const _CountChip(this.label, this.count);

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: SpaceTokens.s8, vertical: 3),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: RadiusTokens.smAll,
      ),
      child: Text(
        '$label: ${count ?? 0}',
        style: TextStyles.bodySm(context)
            .copyWith(color: c.textSecondary, fontSize: 10),
      ),
    );
  }
}
