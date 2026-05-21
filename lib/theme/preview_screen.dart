// lib/theme/preview_screen.dart
//
// Design-system QA screen — debug only.
// Renders every atom in light + dark mode side by side.
//
// Route: Navigator.pushNamed(context, '/ds-preview')
// Or: the debug fab in DashboardScreen (added in main.dart entry point).
//
// This file is NOT imported by production paths.
// Wrap with: if (kDebugMode) Navigator.push(...)

import 'package:flutter/material.dart';
import 'tokens.dart';
import 'text_styles.dart';
import 'app_colors.dart';
import 'atoms/app_button.dart';
import 'atoms/app_card.dart';
import 'atoms/app_row.dart';
import 'atoms/app_pill.dart';
import 'atoms/mono_text.dart';
import 'atoms/section_label.dart';
import 'atoms/app_input.dart';

class DesignSystemPreviewScreen extends StatefulWidget {
  const DesignSystemPreviewScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute(
      builder: (_) => const DesignSystemPreviewScreen(),
    );
  }

  @override
  State<DesignSystemPreviewScreen> createState() =>
      _DesignSystemPreviewScreenState();
}

class _DesignSystemPreviewScreenState
    extends State<DesignSystemPreviewScreen> {
  bool _showDark = false;

  @override
  Widget build(BuildContext context) {
    // This screen always renders in the current app theme.
    // Use the toggle to see dark variant inline.
    final c = QColors.of(context);

    return Scaffold(
      backgroundColor: c.appBg,
      appBar: AppBar(
        title: const Text('Design System'),
        actions: <Widget>[
          Row(
            children: [
              Text(
                'Dark preview',
                style: TextStyles.bodyMd(context)
                    .copyWith(color: c.textSecondary),
              ),
              const SizedBox(width: SpaceTokens.s8),
              Switch(
                value: _showDark,
                onChanged: (v) => setState(() => _showDark = v),
              ),
              const SizedBox(width: SpaceTokens.s16),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(SpaceTokens.s16),
        child: _showDark
            // Side-by-side: wrap in two themed builders
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _AtomGrid(isDark: false)),
                  const SizedBox(width: SpaceTokens.s12),
                  Expanded(child: _AtomGrid(isDark: true)),
                ],
              )
            : _AtomGrid(isDark: QColors.isDark(context)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The actual grid of atoms, rendered inside a forced-brightness Theme.
// ---------------------------------------------------------------------------

class _AtomGrid extends StatelessWidget {
  const _AtomGrid({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // Force the brightness for the preview pane.
    return Theme(
      data: isDark
          ? Theme.of(context).copyWith(brightness: Brightness.dark)
          : Theme.of(context).copyWith(brightness: Brightness.light),
      child: Builder(builder: (ctx) {
        final c = QColors.of(ctx);
        return Container(
          color: c.appBg,
          padding: const EdgeInsets.all(SpaceTokens.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- Header ----
              Text(
                isDark ? 'Dark' : 'Light',
                style: TextStyles.displayMd(ctx),
              ),
              const SizedBox(height: SpaceTokens.s24),

              // ---- COLORS ----
              SectionLabel('Colors'),
              _ColorSwatch(label: 'appBg', color: c.appBg),
              _ColorSwatch(label: 'surface', color: c.surface),
              _ColorSwatch(label: 'surfaceMuted', color: c.surfaceMuted),
              _ColorSwatch(label: 'border', color: c.border),
              _ColorSwatch(label: 'textPrimary', color: c.textPrimary),
              _ColorSwatch(label: 'textSecondary', color: c.textSecondary),
              _ColorSwatch(label: 'accent / lime', color: c.accent),
              _ColorSwatch(label: 'success', color: c.success),
              _ColorSwatch(label: 'danger', color: c.danger),
              _ColorSwatch(label: 'warn', color: c.warn),
              const SizedBox(height: SpaceTokens.s24),

              // ---- TYPOGRAPHY ----
              SectionLabel('Typography'),
              Text('display.lg — 28/34 -0.5', style: TextStyles.displayLg(ctx)),
              const SizedBox(height: SpaceTokens.s4),
              Text('display.md — 22/28 -0.3', style: TextStyles.displayMd(ctx)),
              const SizedBox(height: SpaceTokens.s4),
              Text('body.lg — 16/22', style: TextStyles.bodyLg(ctx)),
              const SizedBox(height: SpaceTokens.s4),
              Text('body.md — 14/20 (default)', style: TextStyles.bodyMd(ctx)),
              const SizedBox(height: SpaceTokens.s4),
              Text('body.sm — 13/18', style: TextStyles.bodySm(ctx)),
              const SizedBox(height: SpaceTokens.s4),
              Text(
                'LABEL — 11/14 +0.6 UPPERCASE',
                style: TextStyles.label(ctx).copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: SpaceTokens.s4),
              Text('mono — 13/18 tabular', style: TextStyles.mono(ctx)),
              const SizedBox(height: SpaceTokens.s24),

              // ---- MONO TEXT ----
              SectionLabel('MonoText'),
              MonoText('\$4,200'),
              MonoText('09:30', color: c.textSecondary),
              MonoText('23/31', size: 16),
              const SizedBox(height: SpaceTokens.s24),

              // ---- SECTION LABEL ----
              SectionLabel('SectionLabel atom'),
              SectionLabel('Today'),
              SectionLabel('Pipeline'),
              SectionLabel('This week'),
              const SizedBox(height: SpaceTokens.s24),

              // ---- PILLS ----
              SectionLabel('AppPill'),
              Wrap(
                spacing: SpaceTokens.s8,
                runSpacing: SpaceTokens.s8,
                children: const [
                  AppPill(label: 'Lime', variant: AppPillVariant.lime),
                  AppPill(label: 'Neutral', variant: AppPillVariant.neutral),
                  AppPill(label: 'Success', variant: AppPillVariant.success, leadingDot: true),
                  AppPill(label: 'Danger', variant: AppPillVariant.danger, leadingDot: true),
                  AppPill(label: 'Warn', variant: AppPillVariant.warn, leadingDot: true),
                ],
              ),
              const SizedBox(height: SpaceTokens.s24),

              // ---- BUTTONS ----
              SectionLabel('AppButton — primary'),
              AppButton(
                label: 'Primary md',
                onPressed: () {},
              ),
              const SizedBox(height: SpaceTokens.s8),
              Row(
                children: [
                  AppButton(
                    label: 'sm',
                    size: AppButtonSize.sm,
                    onPressed: () {},
                  ),
                  const SizedBox(width: SpaceTokens.s8),
                  AppButton(
                    label: 'md',
                    size: AppButtonSize.md,
                    onPressed: () {},
                  ),
                  const SizedBox(width: SpaceTokens.s8),
                  AppButton(
                    label: 'lg',
                    size: AppButtonSize.lg,
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: SpaceTokens.s8),
              AppButton(
                label: 'Full width',
                onPressed: () {},
                isFullWidth: true,
              ),
              const SizedBox(height: SpaceTokens.s8),
              AppButton(
                label: 'Disabled',
                onPressed: null,
              ),
              const SizedBox(height: SpaceTokens.s16),
              SectionLabel('AppButton — secondary'),
              AppButton(
                label: 'Secondary',
                variant: AppButtonVariant.secondary,
                onPressed: () {},
              ),
              const SizedBox(height: SpaceTokens.s16),
              SectionLabel('AppButton — ghost'),
              AppButton(
                label: 'Ghost',
                variant: AppButtonVariant.ghost,
                onPressed: () {},
              ),
              const SizedBox(height: SpaceTokens.s24),

              // ---- CARD ----
              SectionLabel('AppCard'),
              AppCard(
                padding: const EdgeInsets.all(SpaceTokens.s16),
                child: Text('Border-only card. No shadow.', style: TextStyles.bodyMd(ctx)),
              ),
              const SizedBox(height: SpaceTokens.s8),
              AppCard(
                padding: const EdgeInsets.all(SpaceTokens.s16),
                onTap: () {},
                child: Text('Tappable card', style: TextStyles.bodyMd(ctx)),
              ),
              const SizedBox(height: SpaceTokens.s24),

              // ---- ROW ----
              SectionLabel('AppRow'),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: c.border, width: 1),
                  borderRadius: RadiusTokens.mdAll,
                ),
                child: Column(
                  children: [
                    AppRow(
                      title: 'Send invoice to Acme',
                      subtitle: 'Today · High',
                      leading: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          border: Border.all(color: c.border, width: 1),
                          borderRadius: RadiusTokens.smAll,
                        ),
                      ),
                      trailing: const AppPill(label: 'Due', variant: AppPillVariant.danger),
                      onTap: () {},
                    ),
                    AppRow(
                      title: 'Review contracts',
                      subtitle: 'Tomorrow',
                      leading: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: c.accent.withValues(alpha: 0.15),
                          border: Border.all(color: c.accent, width: 1),
                          borderRadius: RadiusTokens.smAll,
                        ),
                      ),
                      trailing: MonoText('09:00', color: c.textSecondary),
                      onTap: () {},
                    ),
                    AppRow(
                      title: 'No divider row',
                      showDivider: false,
                      onTap: () {},
                      isSelected: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: SpaceTokens.s24),

              // ---- INPUT ----
              SectionLabel('AppInput'),
              const AppInput(hintText: 'Search tasks...'),
              const SizedBox(height: SpaceTokens.s8),
              const AppInput(
                label: 'Amount',
                hintText: '0.00',
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: SpaceTokens.s8),
              const AppInput(
                hintText: 'Error state',
                errorText: 'Required field',
              ),
              const SizedBox(height: SpaceTokens.s48),
            ],
          ),
        );
      }),
    );
  }
}

// Small color swatch for the palette section.
class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: RadiusTokens.smAll,
              border: Border.all(color: c.border, width: 1),
            ),
          ),
          const SizedBox(width: SpaceTokens.s8),
          Text(
            label,
            style: TextStyles.bodySm(context).copyWith(color: c.textSecondary),
          ),
          const Spacer(),
          MonoText(
            '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
            color: c.textDisabled,
            size: 11,
          ),
        ],
      ),
    );
  }
}
