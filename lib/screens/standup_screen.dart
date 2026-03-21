import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../services/locale_service.dart';
import '../services/claude_service.dart';
import '../models/app_models.dart';
import '../widgets/common_widgets.dart';
import 'package:uuid/uuid.dart';

class StandupScreen extends StatefulWidget {
  const StandupScreen({super.key});

  @override
  State<StandupScreen> createState() => _StandupScreenState();
}

class _StandupScreenState extends State<StandupScreen> {
  final _storage = StorageService();
  final _claude = ClaudeService();
  final _winsCtrl = TextEditingController();
  final _challengesCtrl = TextEditingController();
  final _prioritiesCtrl = TextEditingController();
  bool _loading = false;
  String? _aiResponse;
  late List<StandupLog> _logs;

  @override
  void initState() {
    super.initState();
    _logs = _storage.getStandupLogs();
  }

  @override
  void dispose() {
    _winsCtrl.dispose();
    _challengesCtrl.dispose();
    _prioritiesCtrl.dispose();
    super.dispose();
  }

  bool get _hasFilledIn =>
      _winsCtrl.text.trim().isNotEmpty ||
      _challengesCtrl.text.trim().isNotEmpty ||
      _prioritiesCtrl.text.trim().isNotEmpty;

  Future<void> _submit() async {
    if (!_hasFilledIn) return;
    setState(() {
      _loading = true;
      _aiResponse = null;
    });

    final aiResp = await _claude.analyzeStandup(
      wins: _winsCtrl.text.trim(),
      challenges: _challengesCtrl.text.trim(),
      priorities: _prioritiesCtrl.text.trim(),
    );

    final log = StandupLog(
      id: const Uuid().v4(),
      wins: _winsCtrl.text.trim(),
      challenges: _challengesCtrl.text.trim(),
      priorities: _prioritiesCtrl.text.trim(),
      aiResponse: aiResp,
    );

    final logs = _storage.getStandupLogs()..insert(0, log);
    await _storage.saveStandupLogs(logs);

    if (mounted) {
      setState(() {
        _loading = false;
        _aiResponse = aiResp;
        _logs = _storage.getStandupLogs();
      });
    }
  }

  void _clear() {
    _winsCtrl.clear();
    _challengesCtrl.clear();
    _prioritiesCtrl.clear();
    setState(() => _aiResponse = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daily Standup'),
        actions: [
          if (_aiResponse != null)
            TextButton(
              onPressed: _clear,
              child: const Text('New', style: TextStyle(color: AppColors.primary)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      color: AppColors.primary, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('EEEE, MMMM d').format(DateTime.now()),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_aiResponse == null) ...[
              // Input form
              _StandupField(
                controller: _winsCtrl,
                emoji: '✅',
                title: 'Wins',
                hint: 'What went well? What did you ship?',
                color: AppColors.accentGreen,
              ),
              const SizedBox(height: 14),
              _StandupField(
                controller: _challengesCtrl,
                emoji: '🚧',
                title: 'Challenges',
                hint: 'What\'s blocking you? What felt hard?',
                color: AppColors.accentRed,
              ),
              const SizedBox(height: 14),
              _StandupField(
                controller: _prioritiesCtrl,
                emoji: '🎯',
                title: 'Priorities',
                hint: 'Top 1-3 things for tomorrow.',
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),

              if (_loading)
                const Center(child: AiThinkingWidget(message: 'AI is analyzing your standup...'))
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _hasFilledIn ? _submit : null,
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text(
                      'Submit & Get AI Analysis',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
            ] else ...[
              // AI Response
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E1B4B), Color(0xFF1C1917)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: AppColors.primaryLight, size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          'AI Executive Analysis',
                          style: TextStyle(
                            color: AppColors.primaryLight,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _aiResponse!,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        height: 1.7,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Your inputs summary
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Log',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_winsCtrl.text.isNotEmpty)
                      _LogSummaryRow('✅ Wins', _winsCtrl.text, AppColors.accentGreen),
                    if (_challengesCtrl.text.isNotEmpty)
                      _LogSummaryRow('🚧 Challenges', _challengesCtrl.text, AppColors.accentRed),
                    if (_prioritiesCtrl.text.isNotEmpty)
                      _LogSummaryRow('🎯 Priorities', _prioritiesCtrl.text, AppColors.primary),
                  ],
                ),
              ),
            ],

            // Past logs
            if (_logs.isNotEmpty) ...[
              const SizedBox(height: 28),
              const Text(
                'History',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              ..._logs.take(5).map((log) => _LogHistoryCard(log: log)),
            ],
          ],
        ),
      ),
    );
  }
}

class _StandupField extends StatelessWidget {
  final TextEditingController controller;
  final String emoji, title, hint;
  final Color color;

  const _StandupField({
    required this.controller,
    required this.emoji,
    required this.title,
    required this.hint,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextField(
            controller: controller,
            maxLines: 3,
            minLines: 2,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogSummaryRow extends StatelessWidget {
  final String label, value;
  final Color color;

  const _LogSummaryRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _LogHistoryCard extends StatelessWidget {
  final StandupLog log;
  const _LogHistoryCard({required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('MMM d, yyyy').format(log.date),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          if (log.aiResponse.isNotEmpty)
            Text(
              log.aiResponse.substring(0, log.aiResponse.length > 120 ? 120 : log.aiResponse.length),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.5),
            ),
        ],
      ),
    );
  }
}
