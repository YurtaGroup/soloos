import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../theme/app_theme.dart';
import '../../../../services/storage_service.dart';
import '../../../../services/locale_service.dart';
import '../../../../services/google_calendar_service.dart';
import '../../../../services/pro_service.dart';
import '../../../../services/notification_service.dart';
import '../../../../services/theme_service.dart';
import '../../../../services/analytics_service.dart';
import '../../../home/presentation/screens/onboarding_screen.dart';
import '../../../admin/presentation/screens/admin_dashboard_screen.dart';
import 'calendar_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = StorageService();
  final _notifs = NotificationService();
  final _nameCtrl = TextEditingController();
  final _apiKeyCtrl = TextEditingController();
  bool _apiKeyVisible = false;
  late bool _digestEnabled;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = _storage.userName;
    _apiKeyCtrl.text = _storage.apiKey;
    _digestEnabled = _notifs.digestEnabled;
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final auth = LocalAuthentication();
    _biometricAvailable = await auth.canCheckBiometrics || await auth.isDeviceSupported();
    _biometricEnabled = _storage.prefs.getBool('biometric_enabled') ?? false;
    if (mounted) setState(() {});
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

          // ── Appearance ──────────────────────────────────────
          _Section(title: loc.t('appearance_section'), children: [
            Row(
              children: [
                Icon(
                  context.watch<ThemeService>().isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: AppColors.accent,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc.t('theme_label'),
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
                      Text(
                        context.watch<ThemeService>().isDark ? loc.t('theme_dark') : loc.t('theme_light'),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: context.watch<ThemeService>().isDark,
                  activeColor: AppColors.primary,
                  onChanged: (_) => context.read<ThemeService>().toggle(),
                ),
              ],
            ),
          ]),
          const SizedBox(height: 14),

          // ── Security ──────────────────────────────────────
          if (_biometricAvailable)
            _Section(title: loc.t('security_section'), children: [
              Row(
                children: [
                  const Icon(Icons.fingerprint_rounded, color: AppColors.accentGreen, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.t('biometric_label'),
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                        Text(loc.t('biometric_sub'),
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _biometricEnabled,
                    activeColor: AppColors.primary,
                    onChanged: (val) async {
                      if (val) {
                        // Verify biometric before enabling
                        final auth = LocalAuthentication();
                        final ok = await auth.authenticate(
                          localizedReason: loc.t('biometric_reason'),
                          options: const AuthenticationOptions(biometricOnly: true),
                        );
                        if (!ok) return;
                      }
                      await _storage.prefs.setBool('biometric_enabled', val);
                      setState(() => _biometricEnabled = val);
                    },
                  ),
                ],
              ),
            ]),
          if (_biometricAvailable) const SizedBox(height: 14),

          // ── Subscription ──────────────────────────────────────
          _buildSubscriptionSection(loc),
          const SizedBox(height: 14),

          // ── Notifications ─────────────────────────────────────
          _Section(title: loc.t('notifications_section'), children: [
            Row(
              children: [
                const Icon(Icons.notifications_active_rounded,
                    color: AppColors.accent, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc.t('daily_digest_title'),
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
                      Text(loc.t('daily_digest_sub'),
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _digestEnabled,
                  activeColor: AppColors.primary,
                  onChanged: (val) async {
                    await _notifs.toggleDailyDigest(val);
                    setState(() => _digestEnabled = val);
                    if (val && mounted) {
                      _snack(loc.t('daily_digest_enabled'));
                    }
                  },
                ),
              ],
            ),
          ]),
          const SizedBox(height: 14),

          // ── Share & Invite ─────────────────────────────────────
          _Section(title: loc.t('share_section'), children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Share.share(
                    'I\'m using Solo OS to run my solopreneur life — '
                    'finances, projects, habits, and AI ideas all in one place. '
                    'Try it free for 30 days!\n\n'
                    'https://soloos.app',
                  );
                },
                icon: const Icon(Icons.share_rounded, size: 18),
                label: Text(loc.t('share_btn')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.t('share_sub'),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              textAlign: TextAlign.center,
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

          // ── Admin (only for you) ──────────────────────────────
          _Section(title: 'COMMAND CENTER', children: [
            GestureDetector(
              onTap: () {
                AnalyticsService().featureUsed('admin_dashboard');
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
              },
              child: const Row(
                children: [
                  Icon(Icons.dashboard_rounded, color: AppColors.accent, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Admin Dashboard',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                        Text('Users, metrics, analytics',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                ],
              ),
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

  Widget _buildSubscriptionSection(LocaleService loc) {
    final pro = ProService();
    final isActive = pro.hasAccess;
    final isPro = pro.isPro;
    final trialDays = pro.trialDaysLeft;

    return _Section(
      title: loc.t('subscription_section'),
      children: [
        if (isPro) ...[
          const Row(
            children: [
              Icon(Icons.workspace_premium_rounded, color: AppColors.accent, size: 24),
              SizedBox(width: 10),
              Text('Solo OS Pro', style: TextStyle(color: AppColors.accent, fontSize: 16, fontWeight: FontWeight.w700)),
              Spacer(),
              Text('Active', style: TextStyle(color: AppColors.accentGreen, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ] else if (isActive) ...[
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: AppColors.primaryLight, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Free Trial', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                    Text('$trialDays days remaining', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showUpgradeSheet(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Upgrade to Pro', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ] else ...[
          const Text(
            'Your trial has ended. Upgrade to unlock all features.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showUpgradeSheet(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Unlock Solo OS Pro', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ],
    );
  }

  void _showUpgradeSheet() {
    final pro = ProService();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Solo OS Pro',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Unlimited AI, unlimited ideas, unlimited growth.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 24),
            _PricingTile(
              title: 'Monthly',
              price: '\$9.99/mo',
              isPopular: false,
              onTap: () async {
                Navigator.pop(ctx);
                if (pro.revenueCatReady) {
                  _snack('Processing purchase...');
                  final ok = await pro.purchase(ProService.monthlyProductId);
                  if (ok && mounted) {
                    _snack('Welcome to Solo OS Pro!');
                    setState(() {});
                  } else if (mounted) {
                    _snack('Purchase not completed.');
                  }
                } else {
                  _snack('In-app purchases are being set up. Your trial continues!');
                }
              },
            ),
            const SizedBox(height: 10),
            _PricingTile(
              title: 'Yearly',
              price: '\$79.99/yr',
              subtitle: 'Save 33%',
              isPopular: true,
              onTap: () async {
                Navigator.pop(ctx);
                if (pro.revenueCatReady) {
                  _snack('Processing purchase...');
                  final ok = await pro.purchase(ProService.yearlyProductId);
                  if (ok && mounted) {
                    _snack('Welcome to Solo OS Pro!');
                    setState(() {});
                  } else if (mounted) {
                    _snack('Purchase not completed.');
                  }
                } else {
                  _snack('In-app purchases are being set up. Your trial continues!');
                }
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                _snack('Restoring purchases...');
                final ok = await pro.restorePurchases();
                if (mounted) {
                  _snack(ok ? 'Pro restored!' : 'No previous purchases found.');
                  setState(() {});
                }
              },
              child: const Text('Restore Purchases',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ),
            const SizedBox(height: 8),
          ],
        ),
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

class _PricingTile extends StatelessWidget {
  final String title, price;
  final String? subtitle;
  final bool isPopular;
  final VoidCallback onTap;

  const _PricingTile({
    required this.title,
    required this.price,
    this.subtitle,
    required this.isPopular,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isPopular ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPopular ? AppColors.primary : AppColors.textMuted.withOpacity(0.3),
            width: isPopular ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                      if (isPopular) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('BEST', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),
                  if (subtitle != null)
                    Text(subtitle!, style: const TextStyle(color: AppColors.accentGreen, fontSize: 11)),
                ],
              ),
            ),
            Text(price, style: TextStyle(
              color: isPopular ? AppColors.primary : AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            )),
          ],
        ),
      ),
    );
  }
}
