import 'package:uuid/uuid.dart';

enum ExpenseCategory { food, transport, shopping, entertainment, health, education, travel, other }

extension ExpenseCategoryLabel on ExpenseCategory {
  String get label {
    switch (this) {
      case ExpenseCategory.food: return 'Food';
      case ExpenseCategory.transport: return 'Transport';
      case ExpenseCategory.shopping: return 'Shopping';
      case ExpenseCategory.entertainment: return 'Entertainment';
      case ExpenseCategory.health: return 'Health';
      case ExpenseCategory.education: return 'Education';
      case ExpenseCategory.travel: return 'Travel';
      case ExpenseCategory.other: return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case ExpenseCategory.food: return '🍔';
      case ExpenseCategory.transport: return '🚗';
      case ExpenseCategory.shopping: return '🛍️';
      case ExpenseCategory.entertainment: return '🎬';
      case ExpenseCategory.health: return '💊';
      case ExpenseCategory.education: return '📚';
      case ExpenseCategory.travel: return '✈️';
      case ExpenseCategory.other: return '💸';
    }
  }
}

class Expense {
  final String id;
  final String title;
  final double amount;
  final String currency;
  final ExpenseCategory category;
  final String scope; // personal, business, family
  final DateTime date;
  final String? notes;
  final DateTime createdAt;

  Expense({
    String? id,
    required this.title,
    required this.amount,
    this.currency = 'USD',
    this.category = ExpenseCategory.other,
    this.scope = 'personal',
    DateTime? date,
    this.notes,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'currency': currency,
        'category': category.name,
        'scope': scope,
        'date': date.toIso8601String(),
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
        id: j['id'],
        title: j['title'],
        amount: (j['amount'] as num).toDouble(),
        currency: j['currency'] ?? 'USD',
        category: ExpenseCategory.values.firstWhere(
          (e) => e.name == j['category'],
          orElse: () => ExpenseCategory.other,
        ),
        scope: j['scope'] ?? 'personal',
        date: DateTime.parse(j['date']),
        notes: j['notes'],
        createdAt: DateTime.parse(j['createdAt']),
      );

  factory Expense.fromRow(Map<String, dynamic> r) => Expense(
        id: r['id'],
        title: r['title'] ?? '',
        amount: (r['amount'] as num?)?.toDouble() ?? 0,
        currency: r['currency'] ?? 'USD',
        category: ExpenseCategory.values.firstWhere(
          (e) => e.name == r['category'],
          orElse: () => ExpenseCategory.other,
        ),
        scope: r['scope'] ?? 'personal',
        date: DateTime.tryParse(r['date'] ?? '') ?? DateTime.now(),
        notes: r['notes'],
        createdAt: DateTime.tryParse(r['created_at'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toRow() => {
        'id': id,
        'title': title,
        'amount': amount,
        'currency': currency,
        'category': category.name,
        'scope': scope,
        'date': date.toIso8601String(),
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };
}
