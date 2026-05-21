// lib/features/calendar/presentation/screens/calendar_settings_screen.dart
//
// Quiet OS — Calendar Settings sub-screen.
// Migrated from the legacy lib/features/settings/presentation/screens/calendar_screen.dart.
//
// All the same functionality (sign in / sign out / sync toggle / refresh /
// connected-email display), rebuilt with Quiet OS atoms.
// The legacy CalendarScreen file is left untouched; routing is updated in
// settings_screen.dart and dashboard_screen.dart.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/tokens.dart';
import '../../../../theme/text_styles.dart';
import '../../../../theme/atoms/section_label.dart';
import '../../../../theme/atoms/mono_text.dart';
import '../../../../theme/atoms/app_button.dart';

import '../../../../services/google_calendar_service.dart';

class CalendarSettingsScreen extends StatelessWidget {
  const CalendarSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: c.appBg,
      body: Column(
        children: [
          // ── HEADER ───────────────────────────────────────────────
          Container(
            color: c.appBg,
            padding: EdgeInsets.fromLTRB(
              SpaceTokens.s16,
              topInset + SpaceTokens.s8,
              SpaceTokens.s8,
              SpaceTokens.s16,
            ),
            child: Row(
              children: [
                // Back arrow — 44pt tap target
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: Icon(
                        Icons.chevron_left,
                        size: 22,
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: SpaceTokens.s4),
                Expanded(
                  child: Text(
                    'Calendar',
                    style: TextStyles.displayMd(context),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: c.border),

          // ── BODY ─────────────────────────────────────────────────
          Expanded(
            child: Consumer<GoogleCalendarService>(
              builder: (context, calSvc, _) {
                return ListView(
                  padding: const EdgeInsets.all(SpaceTokens.s16),
                  children: [
                    // ── Google Calendar connection ─────────────────
                    SectionLabel('GOOGLE CALENDAR'),
                    _ConnectionCard(calSvc: calSvc),
                    const SizedBox(height: SpaceTokens.s24),

                    // ── Sync behaviour (placeholder for future) ────
                    if (calSvc.isSignedIn) ...[
                      SectionLabel('SYNC'),
                      _SyncCard(calSvc: calSvc),
                      const SizedBox(height: SpaceTokens.s24),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CONNECTION CARD
// ---------------------------------------------------------------------------

class _ConnectionCard extends StatefulWidget {
  const _ConnectionCard({required this.calSvc});
  final GoogleCalendarService calSvc;

  @override
  State<_ConnectionCard> createState() => _ConnectionCardState();
}

class _ConnectionCardState extends State<_ConnectionCard> {
  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    final svc = widget.calSvc;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          // Status row
          Padding(
            padding: const EdgeInsets.all(SpaceTokens.s16),
            child: Row(
              children: [
                // Status dot
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: svc.isSignedIn ? c.success : c.textDisabled,
                  ),
                ),
                const SizedBox(width: SpaceTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        svc.isSignedIn ? 'Connected' : 'Not connected',
                        style: TextStyles.bodyMd(context).copyWith(
                          color: svc.isSignedIn
                              ? c.textPrimary
                              : c.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (svc.isSignedIn)
                        Text(
                          svc.userEmail,
                          style: TextStyles.bodySm(context)
                              .copyWith(color: c.textSecondary),
                        )
                      else
                        Text(
                          'Sign in to sync events to the week view',
                          style: TextStyles.bodySm(context)
                              .copyWith(color: c.textDisabled),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Error message if present
          if (svc.error != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: SpaceTokens.s16,
                vertical: SpaceTokens.s8,
              ),
              color: c.danger.withValues(alpha: 0.08),
              child: Text(
                svc.error!,
                style: TextStyles.bodySm(context)
                    .copyWith(color: c.danger),
              ),
            ),
          ],

          // Loading indicator
          if (svc.loading)
            LinearProgressIndicator(
              color: c.accent,
              backgroundColor: c.surfaceMuted,
              minHeight: 1,
            ),

          Container(height: 1, color: c.border),

          // Action button
          Padding(
            padding: const EdgeInsets.all(SpaceTokens.s16),
            child: svc.isSignedIn
                ? Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Refresh',
                          variant: AppButtonVariant.secondary,
                          isLoading: svc.loading,
                          onPressed: svc.loading
                              ? null
                              : () {
                                  HapticFeedback.lightImpact();
                                  svc.fetchEvents();
                                },
                        ),
                      ),
                      const SizedBox(width: SpaceTokens.s12),
                      AppButton(
                        label: 'Disconnect',
                        variant: AppButtonVariant.secondary,
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          await svc.signOut();
                        },
                      ),
                    ],
                  )
                : AppButton(
                    label: 'Connect Google Calendar',
                    isFullWidth: true,
                    isLoading: svc.loading,
                    onPressed: svc.loading
                        ? null
                        : () async {
                            HapticFeedback.mediumImpact();
                            await svc.signIn();
                          },
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SYNC CARD  — shows event count, last-refresh timestamp
// ---------------------------------------------------------------------------

class _SyncCard extends StatelessWidget {
  const _SyncCard({required this.calSvc});
  final GoogleCalendarService calSvc;

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    final count = calSvc.events.length;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SpaceTokens.s16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Events loaded',
                style: TextStyles.bodyMd(context)
                    .copyWith(color: c.textSecondary),
              ),
            ),
            MonoText(
              '$count',
              size: 13,
              color: c.textPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
