import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/models/family_person.dart';

class FamilyPersonCard extends StatelessWidget {
  final FamilyPerson person;
  final VoidCallback onTap;
  final VoidCallback onContactedToday;
  final bool showAttentionBadge;

  const FamilyPersonCard({
    super.key,
    required this.person,
    required this.onTap,
    required this.onContactedToday,
    this.showAttentionBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = person.isContactOverdue;
    final isBirthday = person.isBirthdayToday;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: isBirthday
              ? Border.all(color: AppColors.accent.withOpacity(0.5))
              : isOverdue
                  ? Border.all(color: AppColors.accentRed.withOpacity(0.25))
                  : null,
        ),
        child: Row(
          children: [
            _Avatar(person: person),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          person.displayName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (isBirthday)
                        const Text('🎂', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '${person.relationshipType.emoji} ${person.relationshipType.label}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11),
                      ),
                      if (person.daysSinceContact != null) ...[
                        const Text(' · ',
                            style: TextStyle(color: AppColors.textMuted)),
                        Text(
                          _contactLabel(person),
                          style: TextStyle(
                            color: isOverdue
                                ? AppColors.accentRed
                                : AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _ContactButton(onTap: onContactedToday),
          ],
        ),
      ),
    );
  }

  String _contactLabel(FamilyPerson p) {
    final days = p.daysSinceContact!;
    if (days == 0) return 'Today';
    if (days == 1) return '1d ago';
    return '${days}d ago';
  }
}

class _Avatar extends StatelessWidget {
  final FamilyPerson person;
  const _Avatar({required this.person});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: person.isBirthdayToday
              ? AppColors.accent
              : AppColors.textMuted.withOpacity(0.3),
        ),
      ),
      child: Center(
        child: Text(
          person.relationshipType.emoji,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ContactButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.accentGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
        ),
        child: const Text(
          '✓ Talked',
          style: TextStyle(
              color: AppColors.accentGreen,
              fontSize: 11,
              fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
