import 'package:uuid/uuid.dart';
import 'obligation_item.dart'; // reuse ObligationFrequency

enum IncomeCategory { freelance, salary, project, youtube, sponsorship, investment, realEstate, other }

extension IncomeCategoryLabel on IncomeCategory {
  String get label {
    switch (this) {
      case IncomeCategory.freelance: return 'Freelance';
      case IncomeCategory.salary: return 'Salary';
      case IncomeCategory.project: return 'Project';
      case IncomeCategory.youtube: return 'YouTube';
      case IncomeCategory.sponsorship: return 'Sponsorship';
      case IncomeCategory.investment: return 'Investment';
      case IncomeCategory.realEstate: return 'Real Estate';
      case IncomeCategory.other: return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case IncomeCategory.freelance: return '💻';
      case IncomeCategory.salary: return '💼';
      case IncomeCategory.project: return '📂';
      case IncomeCategory.youtube: return '▶️';
      case IncomeCategory.sponsorship: return '🤝';
      case IncomeCategory.investment: return '📈';
      case IncomeCategory.realEstate: return '🏠';
      case IncomeCategory.other: return '💰';
    }
  }
}

class IncomeStream {
  final String id;
  final String title;
  final IncomeCategory category;
  final String scope; // personal, business, family
  final double amount;
  final String currency;
  final ObligationFrequency frequency;
  final bool isOneTime;
  final DateTime? date; // for one-time income
  final bool isActive;
  final String? notes;
  final DateTime createdAt;
  DateTime updatedAt;

  IncomeStream({
    String? id,
    required this.title,
    required this.category,
    this.scope = 'personal',
    required this.amount,
    this.currency = 'USD',
    this.frequency = ObligationFrequency.monthly,
    this.isOneTime = false,
    this.date,
    this.isActive = true,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get monthlyIncome => isOneTime ? 0.0 : frequency.monthlyAmount(amount);

  IncomeStream copyWith({
    String? title,
    double? amount,
    IncomeCategory? category,
    ObligationFrequency? frequency,
    DateTime? date,
    bool? isActive,
    String? notes,
  }) {
    return IncomeStream(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      scope: scope,
      amount: amount ?? this.amount,
      currency: currency,
      frequency: frequency ?? this.frequency,
      isOneTime: isOneTime,
      date: date ?? this.date,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category.name,
        'scope': scope,
        'amount': amount,
        'currency': currency,
        'frequency': frequency.name,
        'isOneTime': isOneTime,
        'date': date?.toIso8601String(),
        'isActive': isActive,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory IncomeStream.fromJson(Map<String, dynamic> j) => IncomeStream(
        id: j['id'],
        title: j['title'],
        category: IncomeCategory.values.firstWhere(
          (e) => e.name == j['category'],
          orElse: () => IncomeCategory.other,
        ),
        scope: j['scope'] ?? 'personal',
        amount: (j['amount'] as num).toDouble(),
        currency: j['currency'] ?? 'USD',
        frequency: ObligationFrequency.values.firstWhere(
          (e) => e.name == j['frequency'],
          orElse: () => ObligationFrequency.monthly,
        ),
        isOneTime: j['isOneTime'] ?? false,
        date: j['date'] != null ? DateTime.parse(j['date']) : null,
        isActive: j['isActive'] ?? true,
        notes: j['notes'],
        createdAt: DateTime.parse(j['createdAt']),
        updatedAt: DateTime.parse(j['updatedAt']),
      );

  factory IncomeStream.fromRow(Map<String, dynamic> r) => IncomeStream(
        id: r['id'],
        title: r['title'] ?? '',
        category: IncomeCategory.values.firstWhere(
          (e) => e.name == r['category'],
          orElse: () => IncomeCategory.other,
        ),
        scope: r['scope'] ?? 'personal',
        amount: (r['amount'] as num?)?.toDouble() ?? 0,
        currency: r['currency'] ?? 'USD',
        frequency: ObligationFrequency.values.firstWhere(
          (e) => e.name == r['frequency'],
          orElse: () => ObligationFrequency.monthly,
        ),
        isOneTime: r['is_one_time'] ?? false,
        date: r['date'] != null ? DateTime.tryParse(r['date']) : null,
        isActive: r['is_active'] ?? true,
        notes: r['notes'],
        createdAt: DateTime.tryParse(r['created_at'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(r['updated_at'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toRow() => {
        'id': id,
        'title': title,
        'category': category.name,
        'scope': scope,
        'amount': amount,
        'currency': currency,
        'frequency': frequency.name,
        'is_one_time': isOneTime,
        'date': date?.toIso8601String(),
        'is_active': isActive,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
