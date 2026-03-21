import 'package:uuid/uuid.dart';

enum ObligationCategory {
  rent,
  utilities,
  subscription,
  insurance,
  salary,
  taxes,
  loan,
  other
}

enum ObligationFrequency { weekly, biweekly, monthly, quarterly, annual }

extension ObligationCategoryLabel on ObligationCategory {
  String get label {
    switch (this) {
      case ObligationCategory.rent: return 'Rent';
      case ObligationCategory.utilities: return 'Utilities';
      case ObligationCategory.subscription: return 'Subscription';
      case ObligationCategory.insurance: return 'Insurance';
      case ObligationCategory.salary: return 'Salary';
      case ObligationCategory.taxes: return 'Taxes';
      case ObligationCategory.loan: return 'Loan';
      case ObligationCategory.other: return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case ObligationCategory.rent: return '🏠';
      case ObligationCategory.utilities: return '⚡';
      case ObligationCategory.subscription: return '📱';
      case ObligationCategory.insurance: return '🛡️';
      case ObligationCategory.salary: return '👥';
      case ObligationCategory.taxes: return '🏛️';
      case ObligationCategory.loan: return '🏦';
      case ObligationCategory.other: return '📋';
    }
  }
}

extension ObligationFrequencyLabel on ObligationFrequency {
  String get label {
    switch (this) {
      case ObligationFrequency.weekly: return 'Weekly';
      case ObligationFrequency.biweekly: return 'Bi-weekly';
      case ObligationFrequency.monthly: return 'Monthly';
      case ObligationFrequency.quarterly: return 'Quarterly';
      case ObligationFrequency.annual: return 'Annual';
    }
  }

  /// Approximate number of months per billing cycle
  double get monthMultiplier {
    switch (this) {
      case ObligationFrequency.weekly: return 1 / 4.33;
      case ObligationFrequency.biweekly: return 1 / 2.17;
      case ObligationFrequency.monthly: return 1;
      case ObligationFrequency.quarterly: return 3;
      case ObligationFrequency.annual: return 12;
    }
  }

  /// Monthly equivalent cost
  double monthlyAmount(double amount) => amount / monthMultiplier;
}

class ObligationItem {
  final String id;
  final String title;
  final ObligationCategory category;
  final double amount;
  final String currency;
  final ObligationFrequency frequency;
  final int? dueDayOfMonth; // 1–31, null if not monthly
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  DateTime updatedAt;

  ObligationItem({
    String? id,
    required this.title,
    required this.category,
    required this.amount,
    this.currency = 'USD',
    this.frequency = ObligationFrequency.monthly,
    this.dueDayOfMonth,
    this.notes,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Monthly cost equivalent
  double get monthlyCost => frequency.monthlyAmount(amount);

  bool get isSubscription => category == ObligationCategory.subscription;

  /// Due date this month, if applicable
  DateTime? get nextDueDate {
    if (dueDayOfMonth == null) return null;
    final now = DateTime.now();
    final candidate = DateTime(now.year, now.month, dueDayOfMonth!);
    return candidate.isBefore(now)
        ? DateTime(now.year, now.month + 1, dueDayOfMonth!)
        : candidate;
  }

  bool get isDueThisWeek {
    final due = nextDueDate;
    if (due == null) return false;
    final now = DateTime.now();
    return due.difference(now).inDays <= 7;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category.name,
        'amount': amount,
        'currency': currency,
        'frequency': frequency.name,
        'dueDayOfMonth': dueDayOfMonth,
        'notes': notes,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ObligationItem.fromJson(Map<String, dynamic> j) => ObligationItem(
        id: j['id'],
        title: j['title'],
        category: ObligationCategory.values.firstWhere(
          (e) => e.name == j['category'],
          orElse: () => ObligationCategory.other,
        ),
        amount: (j['amount'] as num).toDouble(),
        currency: j['currency'] ?? 'USD',
        frequency: ObligationFrequency.values.firstWhere(
          (e) => e.name == j['frequency'],
          orElse: () => ObligationFrequency.monthly,
        ),
        dueDayOfMonth: j['dueDayOfMonth'],
        notes: j['notes'],
        isActive: j['isActive'] ?? true,
        createdAt: DateTime.parse(j['createdAt']),
        updatedAt: DateTime.parse(j['updatedAt']),
      );
}
