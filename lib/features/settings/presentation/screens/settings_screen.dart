import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/tokens.dart';
import '../../../../theme/text_styles.dart';
import '../../../../theme/atoms/section_label.dart';
import '../../../../theme/atoms/app_card.dart';
import '../../../../theme/atoms/app_button.dart';
import '../../../../theme/atoms/app_row.dart';
import '../../../../theme/atoms/app_pill.dart';
import '../../../../theme/atoms/app_input.dart';
import '../../../../theme/atoms/mono_text.dart';
import '../../../../services/storage_service.dart';
import '../../../../services/locale_service.dart';
import '../../../../services/google_calendar_service.dart';
import '../../../../services/pro_service.dart';
import '../../../../services/notification_service.dart';
import '../../../../services/theme_service.dart';
import '../../../../services/analytics_service.dart';
import '../../../../services/api_service.dart';
import '../../../auth/presentation/screens/auth_screen.dart';
import '../../../home/presentation/screens/onboarding_screen.dart';
import '../../../home/presentation/screens/dashboard_screen.dart';
import '../../../admin/presentation/screens/admin_dashboard_screen.dart';
import '../../../calendar/presentation/screens/calendar_settings_screen.dart';

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
  bool _analyticsEnabled = true;
  bool _aiConsentGiven = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = _storage.userName;
    _apiKeyCtrl.text = _storage.apiKey;
    _digestEnabled = _notifs.digestEnabled;
    _analyticsEnabled = AnalyticsService().enabled;
    _aiConsentGiven = _storage.aiConsentGiven;
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
    final c = QColors.of(context);
    final loc = context.watch<LocaleService>();
    final calService = context.watch<GoogleCalendarService>();

    return Scaffold(
      appBar: AppBar(title: Text(loc.t('settings_title'), style: TextStyles.displayMd(context))),
      body: ListView(
        padding: const EdgeInsets.all(SpaceTokens.s16),
        children: [

          // ── Profile ──────────────────────────────────────────
          SectionLabel(loc.t('profile_section')),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.t('your_name'),
                    style: TextStyles.bodySm(context).copyWith(color: c.textSecondary)),
                const SizedBox(height: SpaceTokens.s8),
                Row(
                  children: [
                    Expanded(
                      child: AppInput(
                        controller: _nameCtrl,
                        hintText: loc.t('your_name'),
                        textInputAction: TextInputAction.done,
                      ),
                    ),
                    const SizedBox(width: SpaceTokens.s8),
                    AppButton(
                      label: loc.t('save'),
                      size: AppButtonSize.sm,
                      onPressed: () async {
                        await _storage.setUserName(_nameCtrl.text.trim());
                        if (mounted) _snack(loc.t('name_saved'));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: SpaceTokens.s16),

          // ── Language ─────────────────────────────────────────
          SectionLabel(loc.t('language_section')),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.t('language_label'),
                    style: TextStyles.bodySm(context).copyWith(color: c.textSecondary)),
                const SizedBox(height: SpaceTokens.s8),
                Row(
                  children: LocaleService.languages.map((lang) {
                    final selected = loc.locale == lang.code;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => context.read<LocaleService>().setLocale(lang.code),
                        child: AnimatedContainer(
                          duration: MotionTokens.duration,
                          curve: MotionTokens.curve,
                          margin: EdgeInsets.only(right: lang.code != 'ky' ? SpaceTokens.s8 : 0),
                          padding: const EdgeInsets.symmetric(vertical: SpaceTokens.s8),
                          decoration: BoxDecoration(
                            color: selected ? c.accent.withValues(alpha: 0.12) : c.surfaceMuted,
                            borderRadius: RadiusTokens.smAll,
                            border: Border.all(
                              color: selected ? c.accent : c.border,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(lang.flag, style: const TextStyle(fontSize: 20)),
                              const SizedBox(height: SpaceTokens.s4),
                              Text(
                                lang.name,
                                style: TextStyles.bodySm(context).copyWith(
                                  color: selected ? c.textPrimary : c.textSecondary,
                                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
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
          ),
          const SizedBox(height: SpaceTokens.s16),

          // ── Appearance ──────────────────────────────────────
          SectionLabel(loc.t('appearance_section')),
          AppCard(
            padding: EdgeInsets.zero,
            child: AppRow(
              title: loc.t('theme_label'),
              subtitle: context.watch<ThemeService>().isDark
                  ? loc.t('theme_dark')
                  : loc.t('theme_light'),
              leading: Icon(
                context.watch<ThemeService>().isDark
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
                size: 20,
                color: c.textSecondary,
              ),
              showDivider: false,
              trailing: Switch.adaptive(
                value: context.watch<ThemeService>().isDark,
                activeThumbColor: c.accent,
                onChanged: (_) => context.read<ThemeService>().toggle(),
              ),
            ),
          ),
          const SizedBox(height: SpaceTokens.s16),

          // ── Security ──────────────────────────────────────
          if (_biometricAvailable) ...[
            SectionLabel(loc.t('security_section')),
            AppCard(
              padding: EdgeInsets.zero,
              child: AppRow(
                title: loc.t('biometric_label'),
                subtitle: loc.t('biometric_sub'),
                leading: Icon(Icons.fingerprint_rounded, size: 20, color: c.textSecondary),
                showDivider: false,
                trailing: Switch.adaptive(
                  value: _biometricEnabled,
                  activeThumbColor: c.accent,
                  onChanged: (val) async {
                    if (val) {
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
              ),
            ),
            const SizedBox(height: SpaceTokens.s16),
          ],

          // ── Account ──────────────────────────────────────────
          SectionLabel('Account'),
          AppCard(
            padding: EdgeInsets.zero,
            child: ApiService.isAuthenticated
                ? AppRow(
                    title: ApiService.email ?? 'Signed in',
                    subtitle: 'Syncing across devices',
                    leading: Icon(Icons.person_outlined, size: 20, color: c.textSecondary),
                    showDivider: false,
                    trailing: AppButton(
                      label: 'Sign Out',
                      variant: AppButtonVariant.ghost,
                      size: AppButtonSize.sm,
                      onPressed: () async {
                        await ApiService.signOut();
                        if (mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                            (route) => false,
                          );
                        }
                      },
                    ),
                  )
                : AppRow(
                    title: 'Sign In',
                    subtitle: 'Sync your data and invite collaborators',
                    leading: Icon(Icons.login_outlined, size: 20, color: c.textSecondary),
                    showDivider: false,
                    trailing: Icon(Icons.chevron_right_rounded, size: 18, color: c.textSecondary),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AuthScreen(
                            onAuthSuccess: () {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const DashboardScreen()),
                                (route) => false,
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: SpaceTokens.s16),

          // ── Subscription ──────────────────────────────────────
          _buildSubscriptionSection(loc, c),
          const SizedBox(height: SpaceTokens.s16),

          // ── Notifications ─────────────────────────────────────
          SectionLabel(loc.t('notifications_section')),
          AppCard(
            padding: EdgeInsets.zero,
            child: AppRow(
              title: loc.t('daily_digest_title'),
              subtitle: loc.t('daily_digest_sub'),
              leading: Icon(Icons.notifications_outlined, size: 20, color: c.textSecondary),
              showDivider: false,
              trailing: Switch.adaptive(
                value: _digestEnabled,
                activeThumbColor: c.accent,
                onChanged: (val) async {
                  await _notifs.toggleDailyDigest(val);
                  setState(() => _digestEnabled = val);
                  if (val && mounted) {
                    _snack(loc.t('daily_digest_enabled'));
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: SpaceTokens.s16),

          // ── Share ─────────────────────────────────────────────
          SectionLabel(loc.t('share_section')),
          AppCard(
            child: Column(
              children: [
                AppButton(
                  label: loc.t('share_btn'),
                  isFullWidth: true,
                  leadingIcon: const Icon(Icons.share_outlined),
                  onPressed: () {
                    Share.share(
                      'I\'m using Solo OS to run my solopreneur life — '
                      'finances, projects, habits, and AI ideas all in one place. '
                      'Try it free for 30 days!\n\nhttps://soloos.app',
                    );
                  },
                ),
                const SizedBox(height: SpaceTokens.s8),
                Text(
                  loc.t('share_sub'),
                  style: TextStyles.bodySm(context).copyWith(color: c.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: SpaceTokens.s16),

          // ── AI Settings ───────────────────────────────────────
          SectionLabel(loc.t('ai_settings')),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.t('api_key_label'),
                    style: TextStyles.bodySm(context).copyWith(color: c.textSecondary)),
                const SizedBox(height: SpaceTokens.s8),
                Row(
                  children: [
                    Expanded(
                      child: AppInput(
                        controller: _apiKeyCtrl,
                        hintText: loc.t('api_key_hint'),
                        obscureText: !_apiKeyVisible,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _apiKeyVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 18,
                          ),
                          onPressed: () => setState(() => _apiKeyVisible = !_apiKeyVisible),
                        ),
                      ),
                    ),
                    const SizedBox(width: SpaceTokens.s8),
                    AppButton(
                      label: loc.t('save'),
                      size: AppButtonSize.sm,
                      onPressed: () async {
                        await _storage.setApiKey(_apiKeyCtrl.text.trim());
                        if (mounted) _snack(loc.t('api_key_saved'));
                      },
                    ),
                  ],
                ),
                const SizedBox(height: SpaceTokens.s4),
                Text(loc.t('api_key_help'),
                    style: TextStyles.bodySm(context).copyWith(color: c.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: SpaceTokens.s16),

          // ── Google Calendar ───────────────────────────────────
          SectionLabel(loc.t('google_calendar_section')),
          AppCard(
            padding: EdgeInsets.zero,
            child: AppRow(
              title: calService.isSignedIn ? loc.t('connected') : loc.t('not_connected'),
              subtitle: calService.isSignedIn ? calService.userEmail : null,
              leading: Icon(Icons.calendar_month_outlined, size: 20, color: c.textSecondary),
              showDivider: false,
              trailing: AppButton(
                label: calService.isSignedIn ? loc.t('see_all') : loc.t('connect_google_cal'),
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.sm,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CalendarSettingsScreen()),
                ),
              ),
            ),
          ),
          const SizedBox(height: SpaceTokens.s16),

          // ── Admin (only for app owner) ─────────────────────────
          if (ApiService.email == 'timur.mone@gmail.com') ...[
            SectionLabel('Command Center'),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  AppRow(
                    title: 'Admin Dashboard',
                    subtitle: 'Users, metrics, analytics',
                    leading: Icon(Icons.dashboard_outlined, size: 20, color: c.textSecondary),
                    trailing: Icon(Icons.chevron_right_rounded, size: 18, color: c.textSecondary),
                    onTap: () {
                      AnalyticsService().featureUsed('admin_dashboard');
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
                    },
                  ),
                  AppRow(
                    title: 'Design preview',
                    subtitle: 'Quiet OS — tokens and atoms',
                    leading: Icon(Icons.palette_outlined, size: 20, color: c.textSecondary),
                    showDivider: false,
                    trailing: Icon(Icons.chevron_right_rounded, size: 18, color: c.textSecondary),
                    onTap: () => Navigator.pushNamed(context, '/ds-preview'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: SpaceTokens.s16),
          ],

          // ── Privacy ──────────────────────────────────────────────
          SectionLabel(loc.t('privacy_section')),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                AppRow(
                  title: loc.t('analytics_label'),
                  subtitle: loc.t('analytics_sub'),
                  leading: Icon(Icons.bar_chart_outlined, size: 20, color: c.textSecondary),
                  trailing: Switch.adaptive(
                    value: _analyticsEnabled,
                    activeThumbColor: c.accent,
                    onChanged: (val) async {
                      await AnalyticsService().setEnabled(val);
                      setState(() => _analyticsEnabled = val);
                      if (mounted) _snack(val ? loc.t('analytics_enabled') : loc.t('analytics_disabled'));
                    },
                  ),
                ),
                AppRow(
                  title: loc.t('ai_disclosure_title'),
                  subtitle: _aiConsentGiven ? 'Enabled' : 'Disabled',
                  leading: Icon(Icons.smart_toy_outlined, size: 20, color: c.textSecondary),
                  trailing: Switch.adaptive(
                    value: _aiConsentGiven,
                    activeThumbColor: c.accent,
                    onChanged: (val) async {
                      if (val) {
                        final accepted = await _showAiDisclosure();
                        if (accepted != true) return;
                      }
                      await _storage.setAiConsentGiven(val);
                      setState(() => _aiConsentGiven = val);
                    },
                  ),
                ),
                AppRow(
                  title: loc.t('privacy_policy'),
                  leading: Icon(Icons.privacy_tip_outlined, size: 20, color: c.textSecondary),
                  trailing: Icon(Icons.open_in_new_rounded, size: 14, color: c.textSecondary),
                  onTap: () => launchUrl(Uri.parse('https://soloos.app/privacy')),
                ),
                AppRow(
                  title: loc.t('terms_of_use'),
                  leading: Icon(Icons.description_outlined, size: 20, color: c.textSecondary),
                  showDivider: false,
                  trailing: Icon(Icons.open_in_new_rounded, size: 14, color: c.textSecondary),
                  onTap: () => launchUrl(Uri.parse('https://soloos.app/terms')),
                ),
              ],
            ),
          ),
          const SizedBox(height: SpaceTokens.s16),

          // ── About ─────────────────────────────────────────────
          SectionLabel(loc.t('about_section')),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                AppRow(
                  title: loc.t('version'),
                  trailing: MonoText('1.1.0', color: c.textSecondary),
                ),
                AppRow(
                  title: loc.t('model'),
                  trailing: MonoText('Claude Sonnet 4', color: c.textSecondary),
                ),
                AppRow(
                  title: loc.t('storage'),
                  showDivider: false,
                  trailing: MonoText(loc.t('storage_val'), color: c.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: SpaceTokens.s16),

          // ── Danger Zone ───────────────────────────────────────
          SectionLabel(loc.t('danger_zone')),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppButton(
                  label: loc.t('reset_all'),
                  variant: AppButtonVariant.ghost,
                  leadingIcon: const Icon(Icons.delete_forever_outlined),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(loc.t('reset_confirm_title')),
                        content: Text(loc.t('reset_confirm_body')),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(loc.t('cancel')),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: TextButton.styleFrom(foregroundColor: c.danger),
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
                ),
                if (ApiService.isAuthenticated) ...[
                  const SizedBox(height: SpaceTokens.s8),
                  Divider(color: c.border, height: 1),
                  const SizedBox(height: SpaceTokens.s8),
                  AppButton(
                    label: loc.t('delete_account'),
                    variant: AppButtonVariant.ghost,
                    leadingIcon: const Icon(Icons.person_off_outlined),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(loc.t('delete_account_title')),
                          content: Text(loc.t('delete_account_body')),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(loc.t('cancel')),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(foregroundColor: c.danger),
                              child: Text(loc.t('delete_account_confirm')),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && mounted) {
                        _snack(loc.t('loading'));
                        final ok = await ApiService.deleteAccount();
                        if (!mounted) return;
                        if (ok) {
                          await _storage.prefs.clear();
                          if (mounted) {
                            _snack(loc.t('delete_account_success'));
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                              (_) => false,
                            );
                          }
                        } else {
                          _snack(loc.t('delete_account_failed'));
                        }
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: SpaceTokens.s32),
        ],
      ),
    );
  }

  Widget _buildSubscriptionSection(LocaleService loc, QColorSet c) {
    final pro = ProService();
    final isActive = pro.hasAccess;
    final isPro = pro.isPro;
    final trialDays = pro.trialDaysLeft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(loc.t('subscription_section')),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isPro) ...[
                Row(
                  children: [
                    Icon(Icons.workspace_premium_outlined, color: c.accent, size: 22),
                    const SizedBox(width: SpaceTokens.s8),
                    Text('Solo OS Pro',
                        style: TextStyles.bodyLg(context).copyWith(
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    AppPill(label: 'Active', variant: AppPillVariant.lime),
                  ],
                ),
              ] else if (isActive) ...[
                Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 20, color: c.textSecondary),
                    const SizedBox(width: SpaceTokens.s8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Free Trial',
                              style: TextStyles.bodyMd(context)
                                  .copyWith(fontWeight: FontWeight.w600)),
                          Text('$trialDays days remaining',
                              style: TextStyles.bodySm(context)
                                  .copyWith(color: c.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SpaceTokens.s12),
                AppButton(
                  label: 'Upgrade to Pro',
                  isFullWidth: true,
                  onPressed: () => _showUpgradeSheet(),
                ),
              ] else ...[
                Text(
                  'Your trial has ended. Upgrade to unlock all features.',
                  style: TextStyles.bodyMd(context).copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: SpaceTokens.s12),
                AppButton(
                  label: 'Unlock Solo OS Pro',
                  isFullWidth: true,
                  onPressed: () => _showUpgradeSheet(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showUpgradeSheet() {
    final c = QColors.of(context);
    final pro = ProService();
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: RadiusTokens.lg),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(SpaceTokens.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: RadiusTokens.pillAll,
              ),
            ),
            const SizedBox(height: SpaceTokens.s24),
            Text('Solo OS Pro',
                style: TextStyles.displayMd(context)),
            const SizedBox(height: SpaceTokens.s8),
            Text(
              'Unlimited AI, unlimited ideas, unlimited growth.',
              style: TextStyles.bodyMd(context).copyWith(color: c.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SpaceTokens.s24),
            _PricingTile(
              title: 'Monthly',
              price: '\$9.99/mo',
              isPopular: false,
              c: c,
              onTap: () async {
                Navigator.pop(ctx);
                if (pro.revenueCatReady) {
                  _snack('Processing purchase.');
                  final ok = await pro.purchase(ProService.monthlyProductId);
                  if (ok && mounted) {
                    _snack('Welcome to Solo OS Pro.');
                    setState(() {});
                  } else if (mounted) {
                    _snack('Purchase not completed.');
                  }
                } else {
                  _snack('In-app purchases are being set up. Your trial continues.');
                }
              },
            ),
            const SizedBox(height: SpaceTokens.s8),
            _PricingTile(
              title: 'Yearly',
              price: '\$79.99/yr',
              subtitle: 'Save 33%',
              isPopular: true,
              c: c,
              onTap: () async {
                Navigator.pop(ctx);
                if (pro.revenueCatReady) {
                  _snack('Processing purchase.');
                  final ok = await pro.purchase(ProService.yearlyProductId);
                  if (ok && mounted) {
                    _snack('Welcome to Solo OS Pro.');
                    setState(() {});
                  } else if (mounted) {
                    _snack('Purchase not completed.');
                  }
                } else {
                  _snack('In-app purchases are being set up. Your trial continues.');
                }
              },
            ),
            const SizedBox(height: SpaceTokens.s16),
            AppButton(
              label: 'Restore Purchases',
              variant: AppButtonVariant.ghost,
              isFullWidth: true,
              onPressed: () async {
                Navigator.pop(ctx);
                _snack('Restoring purchases.');
                final ok = await pro.restorePurchases();
                if (mounted) {
                  _snack(ok ? 'Pro restored.' : 'No previous purchases found.');
                  setState(() {});
                }
              },
            ),
            const SizedBox(height: SpaceTokens.s8),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showAiDisclosure() {
    final loc = context.read<LocaleService>();
    final c = QColors.of(context);
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(loc.t('ai_disclosure_title')),
        content: Text(loc.t('ai_disclosure_body'),
            style: TextStyles.bodySm(context).copyWith(height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.t('ai_disclosure_decline'),
                style: TextStyle(color: c.textSecondary)),
          ),
          AppButton(
            label: loc.t('ai_disclosure_accept'),
            size: AppButtonSize.sm,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

// ── Pricing tile (local to settings) ───────────────────────────────────────

class _PricingTile extends StatelessWidget {
  final String title, price;
  final String? subtitle;
  final bool isPopular;
  final QColorSet c;
  final VoidCallback onTap;

  const _PricingTile({
    required this.title,
    required this.price,
    this.subtitle,
    required this.isPopular,
    required this.c,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: MotionTokens.duration,
        curve: MotionTokens.curve,
        padding: const EdgeInsets.symmetric(
            horizontal: SpaceTokens.s16, vertical: SpaceTokens.s16),
        decoration: BoxDecoration(
          color: isPopular ? c.accent.withValues(alpha: 0.08) : c.surfaceMuted,
          borderRadius: RadiusTokens.smAll,
          border: Border.all(
            color: isPopular ? c.accent : c.border,
            width: isPopular ? 1.5 : 1,
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
                      Text(title,
                          style: TextStyles.bodyMd(context)
                              .copyWith(fontWeight: FontWeight.w600)),
                      if (isPopular) ...[
                        const SizedBox(width: SpaceTokens.s8),
                        AppPill(label: 'BEST', variant: AppPillVariant.lime),
                      ],
                    ],
                  ),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: TextStyles.bodySm(context)
                            .copyWith(color: c.success)),
                ],
              ),
            ),
            Text(price,
                style: TextStyles.bodyMd(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: isPopular ? c.accent : c.textPrimary)),
          ],
        ),
      ),
    );
  }
}
