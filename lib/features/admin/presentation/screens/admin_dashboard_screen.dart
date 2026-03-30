import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
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
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.directRequest('GET', '/api/admin/dashboard');
      setState(() { _data = Map<String, dynamic>.from(data); _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _loadUsers() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.directRequest('GET', '/api/admin/users?limit=100');
      setState(() {
        _users = List.from(data['users'] ?? []);
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Command Center'),
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
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.accentRed, size: 48),
                        const SizedBox(height: 16),
                        Text(_error!, style: const TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadDashboard, child: const Text('Retry')),
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
        padding: const EdgeInsets.all(16),
        children: [
          // ── Users ──
          _SectionHeader('USERS'),
          Row(
            children: [
              _MetricCard('Total', '${users['total'] ?? 0}', Icons.people_rounded, AppColors.primary),
              const SizedBox(width: 8),
              _MetricCard('DAU', '${users['dau'] ?? 0}', Icons.today_rounded, AppColors.accentGreen),
              const SizedBox(width: 8),
              _MetricCard('WAU', '${users['wau'] ?? 0}', Icons.date_range_rounded, AppColors.accentBlue),
              const SizedBox(width: 8),
              _MetricCard('MAU', '${users['mau'] ?? 0}', Icons.calendar_month_rounded, AppColors.accent),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _MetricCard('This Week', '+${users['this_week'] ?? 0}', Icons.trending_up_rounded, AppColors.accentGreen),
              const SizedBox(width: 8),
              _MetricCard('This Month', '+${users['this_month'] ?? 0}', Icons.show_chart_rounded, AppColors.primaryLight),
            ],
          ),
          const SizedBox(height: 20),

          // ── Content ──
          _SectionHeader('CONTENT'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
          const SizedBox(height: 20),

          // ── Analytics ──
          _SectionHeader('ANALYTICS'),
          Row(
            children: [
              _MetricCard('Today', '${analytics['events_today'] ?? 0}', Icons.bolt_rounded, AppColors.accent),
              const SizedBox(width: 8),
              _MetricCard('This Week', '${analytics['events_this_week'] ?? 0}', Icons.analytics_rounded, AppColors.primary),
            ],
          ),
          if (topEvents.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Top Events (7d)', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...topEvents.take(10).map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${e['event']}',
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                          ),
                        ),
                        Text(
                          '${e['count']}',
                          style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          // ── Recent Signups ──
          if (recentSignups.isNotEmpty) ...[
            _SectionHeader('RECENT SIGNUPS'),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: recentSignups.map<Widget>((u) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: (u['onboarded'] ?? false) ? AppColors.accentGreen : AppColors.textMuted,
                        child: Text(
                          (u['name'] ?? u['email'] ?? '?').toString().substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (u['name']?.toString().isNotEmpty ?? false) ? u['name'] : u['email'] ?? '',
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _timeAgo(u['joined']),
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      if (u['onboarded'] == true)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accentGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Onboarded', style: TextStyle(color: AppColors.accentGreen, fontSize: 9, fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildUsers() {
    if (_users == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users!.length,
        itemBuilder: (context, i) {
          final u = _users![i] as Map<String, dynamic>;
          final counts = u['counts'] as Map<String, dynamic>? ?? {};

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        (u['name']?.toString().isNotEmpty ?? false)
                            ? u['name'].toString().substring(0, 1).toUpperCase()
                            : (u['email'] ?? '?').toString().substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (u['name']?.toString().isNotEmpty ?? false) ? u['name'] : u['email'] ?? '',
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(u['email'] ?? '', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Lv.${u['level'] ?? 1}', style: const TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w700)),
                        Text('${u['xp'] ?? 0} XP', style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _CountChip('Projects', counts['projects']),
                    _CountChip('Tasks', counts['tasks']),
                    _CountChip('Habits', counts['habits']),
                    _CountChip('Ideas', counts['ideas']),
                    _CountChip('Standups', counts['standupLogs']),
                    _CountChip('Events', counts['analyticsEvents']),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'Joined ${_timeAgo(u['joined'])}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                    const Spacer(),
                    if (u['is_admin'] == true)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Admin', style: TextStyle(color: AppColors.accent, fontSize: 9, fontWeight: FontWeight.w600)),
                      ),
                    if (u['onboarded'] == true) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Onboarded', style: TextStyle(color: AppColors.accentGreen, fontSize: 9, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
              ],
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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? AppColors.primary : AppColors.textMuted,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _MetricCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: ${count ?? 0}',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
      ),
    );
  }
}
