import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/pro_service.dart';
import '../../services/locale_service.dart';

/// Full-screen paywall shown when a free-tier limit is hit.
///
/// Pass [feature] to describe which limit was reached (e.g. 'ai_calls', 'contacts').
class PaywallScreen extends StatelessWidget {
  final String feature;

  const PaywallScreen({super.key, required this.feature});

  @override
  Widget build(BuildContext context) {
    final pro = ProService();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const Spacer(flex: 2),

              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                ls.t('paywall_title'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Subtitle — dynamic based on feature
              Text(
                _subtitle(),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Feature list
              _FeatureRow(icon: Icons.auto_awesome, text: ls.t('paywall_feat_ai')),
              _FeatureRow(icon: Icons.lightbulb_outline, text: ls.t('paywall_feat_ideas')),
              _FeatureRow(icon: Icons.people_outline, text: ls.t('paywall_feat_contacts')),
              _FeatureRow(icon: Icons.history_rounded, text: ls.t('paywall_feat_history')),
              _FeatureRow(icon: Icons.all_inclusive_rounded, text: ls.t('paywall_feat_unlimited')),

              const Spacer(flex: 3),

              // Yearly — best value
              _PurchaseButton(
                label: ls.t('paywall_yearly'),
                price: '\$79.99/yr',
                badge: ls.t('paywall_save'),
                isPrimary: true,
                onTap: () => _purchase(context, ProService.yearlyProductId, pro),
              ),
              const SizedBox(height: 10),

              // Monthly
              _PurchaseButton(
                label: ls.t('paywall_monthly'),
                price: '\$9.99/mo',
                isPrimary: false,
                onTap: () => _purchase(context, ProService.monthlyProductId, pro),
              ),
              const SizedBox(height: 16),

              // Restore
              TextButton(
                onPressed: () async {
                  final ok = await pro.restorePurchases();
                  if (context.mounted) {
                    if (ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(ls.t('paywall_restored'))),
                      );
                      Navigator.pop(context, true);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(ls.t('paywall_no_purchases'))),
                      );
                    }
                  }
                },
                child: Text(
                  ls.t('paywall_restore'),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle() {
    switch (feature) {
      case 'ai_calls':
        return ls.t('paywall_sub_ai');
      case 'contacts':
        return ls.t('paywall_sub_contacts');
      case 'ideas':
        return ls.t('paywall_sub_ideas');
      case 'standup':
        return ls.t('paywall_sub_standup');
      default:
        return ls.t('paywall_sub_default');
    }
  }

  Future<void> _purchase(BuildContext context, String productId, ProService pro) async {
    if (!pro.revenueCatReady) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ls.t('paywall_not_ready'))),
        );
      }
      return;
    }
    final ok = await pro.purchase(productId);
    if (context.mounted) {
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ls.t('paywall_welcome'))),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ls.t('paywall_cancelled'))),
        );
      }
    }
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
          ),
          const Icon(Icons.check_rounded, color: AppColors.accentGreen, size: 18),
        ],
      ),
    );
  }
}

class _PurchaseButton extends StatelessWidget {
  final String label, price;
  final String? badge;
  final bool isPrimary;
  final VoidCallback onTap;

  const _PurchaseButton({
    required this.label,
    required this.price,
    this.badge,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: isPrimary
                ? const LinearGradient(colors: [AppColors.gradientStart, AppColors.gradientEnd])
                : null,
            color: isPrimary ? null : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: isPrimary ? null : Border.all(color: AppColors.textMuted.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: isPrimary ? Colors.white : AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accentGreen,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                price,
                style: TextStyle(
                  color: isPrimary ? Colors.white : AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
