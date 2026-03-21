import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../services/locale_service.dart';
import '../services/google_calendar_service.dart';
import 'onboarding_screen.dart';
import 'calendar_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = StorageService();
  final _nameCtrl = TextEditingController();
  final _apiKeyCtrl = TextEditingController();
  bool _apiKeyVisible = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = _storage.userName;
    _apiKeyCtrl.text = _storage.apiKey;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleService>();
    final calService = context.watch<GoogleCalendarService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(loc.t('settings_title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Profile ──────────────────────────────────────────
          _Section(title: loc.t('profile_section'), children: [
            _FieldRow(
              label: loc.t('your_name'),
              controller: _nameCtrl,
              saveLabel: loc.t('save'),
              onSaved: () async {
                await _storage.setUserName(_nameCtrl.text.trim());
                if (mounted) _snack(loc.t('name_saved'));
              },
            ),
          ]),
          const SizedBox(height: 14),

          // ── Language ─────────────────────────────────────────
          _Section(title: loc.t('language_section'), children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.t('language_label'),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 10),
                Row(
                  children: LocaleService.languages.map((lang) {
                    final selected = loc.locale == lang.code;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => context.read<LocaleService>().setLocale(lang.code),
                        child: Container(
                          margin: EdgeInsets.only(right: lang.code != 'ky' ? 8 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primary.withOpacity(0.15) : AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected ? AppColors.primary : AppColors.textMuted.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(lang.flag, style: const TextStyle(fontSize: 20)),
                              const SizedBox(height: 4),
                              Text(
                                lang.name,
                                style: TextStyle(
                                  color: selected ? AppColors.primary : AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ]),
          const SizedBox(height: 14),

          // ── AI Settings ───────────────────────────────────────
          _Section(title: loc.t('ai_settings'), children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.t('api_key_label'),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _apiKeyCtrl,
                        obscureText: !_apiKeyVisible,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: loc.t('api_key_hint'),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _apiKeyVisible ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.textMuted,
                              size: 18,
                            ),
                            onPressed: () => setState(() => _apiKeyVisible = !_apiKeyVisible),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        await _storage.setApiKey(_apiKeyCtrl.text.trim());
                        if (mounted) _snack(loc.t('api_key_saved'));
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                      child: Text(loc.t('save')),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(loc.t('api_key_help'),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ]),
          const SizedBox(height: 14),

          // ── Google Calendar ───────────────────────────────────
          _Section(title: loc.t('google_calendar_section'), children: [
            Row(
              children: [
                const Icon(Icons.calendar_month_rounded, color: AppColors.accentBlue, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        calService.isSignedIn ? loc.t('connected') : loc.t('not_connected'),
                        style: TextStyle(
                          color: calService.isSignedIn ? AppColors.accentGreen : AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (calService.isSignedIn)
                        Text(calService.userEmail,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CalendarScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: Text(
                    calService.isSignedIn ? loc.t('see_all') : loc.t('connect_google_cal'),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ]),
          const SizedBox(height: 14),

          // ── About ─────────────────────────────────────────────
          _Section(title: loc.t('about_section'), children: [
            _InfoRow(loc.t('version'), '1.0.0'),
            _InfoRow(loc.t('model'), 'Claude Opus 4.6'),
            _InfoRow(loc.t('storage'), loc.t('storage_val')),
          ]),
          const SizedBox(height: 14),

          // ── Danger Zone ───────────────────────────────────────
          _Section(title: loc.t('danger_zone'), children: [
            TextButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.card,
                    title: Text(loc.t('reset_confirm_title'),
                        style: const TextStyle(color: AppColors.textPrimary)),
                    content: Text(loc.t('reset_confirm_body'),
                        style: const TextStyle(color: AppColors.textSecondary)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(loc.t('cancel')),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(foregroundColor: AppColors.accentRed),
                        child: Text(loc.t('reset_all')),
                      ),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  await _storage.prefs.clear();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                      (_) => false,
                    );
                  }
                }
              },
              icon: const Icon(Icons.delete_forever_outlined, color: AppColors.accentRed),
              label: Text(loc.t('reset_all'),
                  style: const TextStyle(color: AppColors.accentRed)),
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label, saveLabel;
  final TextEditingController controller;
  final VoidCallback onSaved;
  const _FieldRow({
    required this.label,
    required this.saveLabel,
    required this.controller,
    required this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onSaved,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
              child: Text(saveLabel),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          Text(value, style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
        ],
      ),
    );
  }
}
