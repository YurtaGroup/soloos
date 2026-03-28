import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common_widgets.dart';
import '../../../../shared/widgets/paywall_screen.dart';
import '../../domain/models/standup_log.dart';
import '../viewmodels/standup_view_model.dart';

class StandupScreen extends StatefulWidget {
  const StandupScreen({super.key});

  @override
  State<StandupScreen> createState() => _StandupScreenState();
}

class _StandupScreenState extends State<StandupScreen> {
  final _winsCtrl = TextEditingController();
  final _challengesCtrl = TextEditingController();
  final _prioritiesCtrl = TextEditingController();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  String? _activeField; // 'wins', 'challenges', 'priorities'
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _winsCtrl.addListener(_onTextChanged);
    _challengesCtrl.addListener(_onTextChanged);
    _prioritiesCtrl.addListener(_onTextChanged);
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        setState(() => _isListening = false);
      },
    );
    setState(() {});
  }

  void _onTextChanged() => setState(() {});

  @override
  void dispose() {
    _winsCtrl.removeListener(_onTextChanged);
    _challengesCtrl.removeListener(_onTextChanged);
    _prioritiesCtrl.removeListener(_onTextChanged);
    _winsCtrl.dispose();
    _challengesCtrl.dispose();
    _prioritiesCtrl.dispose();
    _speech.stop();
    super.dispose();
  }

  bool get _hasFilledIn =>
      _winsCtrl.text.trim().isNotEmpty ||
      _challengesCtrl.text.trim().isNotEmpty ||
      _prioritiesCtrl.text.trim().isNotEmpty;

  Future<void> _submit(StandupViewModel vm) async {
    if (!_hasFilledIn) return;

    // Check free-tier limit before submitting
    final limitCheck = await vm.checkAiLimit();
    if (limitCheck != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PaywallScreen(feature: 'ai_calls')),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    await vm.submit(
      wins: _winsCtrl.text,
      challenges: _challengesCtrl.text,
      priorities: _prioritiesCtrl.text,
    );
  }

  void _clear(StandupViewModel vm) {
    _winsCtrl.clear();
    _challengesCtrl.clear();
    _prioritiesCtrl.clear();
    vm.clearResponse();
  }

  void _toggleListening(String field) async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition not available on this device'),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }

    HapticFeedback.selectionClick();

    if (_isListening && _activeField == field) {
      await _speech.stop();
      setState(() {
        _isListening = false;
        _activeField = null;
      });
      return;
    }

    // Stop any current listening first
    if (_isListening) await _speech.stop();

    setState(() {
      _isListening = true;
      _activeField = field;
    });

    final controller = field == 'wins'
        ? _winsCtrl
        : field == 'challenges'
            ? _challengesCtrl
            : _prioritiesCtrl;

    await _speech.listen(
      onResult: (result) {
        setState(() {
          final existing = controller.text;
          if (existing.isNotEmpty && !existing.endsWith(' ')) {
            controller.text = '$existing ${result.recognizedWords}';
          } else {
            controller.text = existing + result.recognizedWords;
          }
          controller.selection = TextSelection.fromPosition(
            TextPosition(offset: controller.text.length),
          );
        });
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StandupViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daily Standup'),
        actions: [
          if (vm.aiResponse != null)
            TextButton(
              onPressed: () => _clear(vm),
              child: const Text('New', style: TextStyle(color: AppColors.primary)),
            ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

              if (vm.aiResponse == null) ...[
                _StandupField(
                  controller: _winsCtrl,
                  emoji: '✅',
                  title: 'Wins',
                  hint: 'What went well? What did you ship?',
                  color: AppColors.accentGreen,
                  isListening: _isListening && _activeField == 'wins',
                  speechAvailable: _speechAvailable,
                  onMicTap: () => _toggleListening('wins'),
                ),
                const SizedBox(height: 14),
                _StandupField(
                  controller: _challengesCtrl,
                  emoji: '🚧',
                  title: 'Challenges',
                  hint: 'What\'s blocking you? What felt hard?',
                  color: AppColors.accentRed,
                  isListening: _isListening && _activeField == 'challenges',
                  speechAvailable: _speechAvailable,
                  onMicTap: () => _toggleListening('challenges'),
                ),
                const SizedBox(height: 14),
                _StandupField(
                  controller: _prioritiesCtrl,
                  emoji: '🎯',
                  title: 'Priorities',
                  hint: 'Top 1-3 things for tomorrow.',
                  color: AppColors.primary,
                  isListening: _isListening && _activeField == 'priorities',
                  speechAvailable: _speechAvailable,
                  onMicTap: () => _toggleListening('priorities'),
                ),
                const SizedBox(height: 24),

                if (vm.loading)
                  const Center(child: AiThinkingWidget(message: 'AI is analyzing your standup...'))
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _hasFilledIn ? () => _submit(vm) : null,
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
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: AppColors.primaryLight, size: 16),
                          SizedBox(width: 8),
                          Text(
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
                        vm.aiResponse!,
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

              if (vm.logs.isNotEmpty) ...[
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
                ...vm.logs.take(5).map((log) => _LogHistoryCard(log: log)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StandupField extends StatelessWidget {
  final TextEditingController controller;
  final String emoji, title, hint;
  final Color color;
  final bool isListening;
  final bool speechAvailable;
  final VoidCallback onMicTap;

  const _StandupField({
    required this.controller,
    required this.emoji,
    required this.title,
    required this.hint,
    required this.color,
    required this.isListening,
    required this.speechAvailable,
    required this.onMicTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isListening ? color : color.withOpacity(0.2),
          width: isListening ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 6),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onMicTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isListening
                          ? color.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: isListening
                          ? color
                          : speechAvailable
                              ? AppColors.textMuted
                              : AppColors.textMuted.withOpacity(0.3),
                      size: 20,
                    ),
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
            cursorColor: color,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
              filled: false,
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
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  DateFormat('MMM d, yyyy').format(log.date),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textMuted),
              ],
            ),
            const SizedBox(height: 6),
            if (log.aiResponse.isNotEmpty)
              Text(
                log.aiResponse.substring(0, log.aiResponse.length > 120 ? 120 : log.aiResponse.length),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.5),
              ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.textMuted, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              DateFormat('EEEE, MMMM d, yyyy').format(log.date),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),

            if (log.wins.isNotEmpty) ...[
              _DetailSection(emoji: '✅', title: 'Wins', content: log.wins, color: AppColors.accentGreen),
              const SizedBox(height: 14),
            ],
            if (log.challenges.isNotEmpty) ...[
              _DetailSection(emoji: '🚧', title: 'Challenges', content: log.challenges, color: AppColors.accentRed),
              const SizedBox(height: 14),
            ],
            if (log.priorities.isNotEmpty) ...[
              _DetailSection(emoji: '🎯', title: 'Priorities', content: log.priorities, color: AppColors.primary),
              const SizedBox(height: 14),
            ],

            if (log.aiResponse.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: AppColors.primaryLight, size: 16),
                        SizedBox(width: 6),
                        Text('AI Analysis',
                            style: TextStyle(color: AppColors.primaryLight, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(log.aiResponse,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.7)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String emoji, title, content;
  final Color color;
  const _DetailSection({required this.emoji, required this.title, required this.content, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$emoji $title', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(content, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
      ],
    );
  }
}
