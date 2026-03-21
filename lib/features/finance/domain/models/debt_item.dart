import 'package:uuid/uuid.dart';

enum DebtCategory { friend, family, studentLoan, bankLoan, creditCard, other }
enum DebtStatus { active, paid, overdue }
enum DebtPriority { low, medium, high }

extension DebtCategoryLabel on DebtCategory {
  String get label {
    switch (this) {
      case DebtCategory.friend: return 'Friend';
      case DebtCategory.family: return 'Family';
      case DebtCategory.studentLoan: return 'Student Loan';
      case DebtCategory.bankLoan: return 'Bank Loan';
      case DebtCategory.creditCard: return 'Credit Card';
      case DebtCategory.other: return 'Other';
    }
  }
  String get emoji {
    switch (this) {
      case DebtCategory.friend: return '🤝';
      case DebtCategory.family: return '👨‍👩‍👧';
      case DebtCategory.studentLoan: return '🎓';
      case DebtCategory.bankLoan: return '🏦';
      case DebtCategory.creditCard: return '💳';
      case DebtCategory.other: return '📋';
    }
  }
}

class DebtItem {
  final String id;
  final String title;
  final String creditorName;
  final DebtCategory category;
  final double originalAmount;
  double remainingAmount;
  final String currency;
  final DateTime? dueDate;
  double? monthlyPaymentGoal;
  final String? notes;
  final DebtPriority priority;
  DebtStatus status;
  final DateTime createdAt;
  DateTime updatedAt;

  DebtItem({
    String? id,
    required this.title,
    required this.creditorName,
    required this.category,
    required this.originalAmount,
    double? remainingAmount,
    this.currency = 'USD',
    this.dueDate,
    this.monthlyPaymentGoal,
    this.notes,
    this.priority = DebtPriority.medium,
    this.status = DebtStatus.active,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        remainingAmount = remainingAmount ?? originalAmount,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get paidAmount => originalAmount - remainingAmount;
  double get progressPercent =>
      originalAmount > 0 ? (paidAmount / originalAmount).clamp(0.0, 1.0) : 0.0;

  bool get isOverdue =>
      dueDate != null && dueDate!.isBefore(DateTime.now()) && status == DebtStatus.active;

  bool get isDueThisWeek {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final weekEnd = now.add(Duration(days: 7 - now.weekday));
    return dueDate!.isAfter(now) && dueDate!.isBefore(weekEnd);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'creditorName': creditorName,
        'category': category.name,
        'originalAmount': originalAmount,
        'remainingAmount': remainingAmount,
        'currency': currency,
        'dueDate': dueDate?.toIso8601String(),
        'monthlyPaymentGoal': monthlyPaymentGoal,
        'notes': notes,
        'priority': priority.name,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory DebtItem.fromJson(Map<String, dynamic> j) => DebtItem(
        id: j['id'],
        title: j['title'],
        creditorName: j['creditorName'] ?? '',
        category: DebtCategory.values.firstWhere(
          (e) => e.name == j['category'],
          orElse: () => DebtCategory.other,
        ),
        originalAmount: (j['originalAmount'] as num).toDouble(),
        remainingAmount: (j['remainingAmount'] as num).toDouble(),
        currency: j['currency'] ?? 'USD',
        dueDate: j['dueDate'] != null ? DateTime.tryParse(j['dueDate']) : null,
        monthlyPaymentGoal: j['monthlyPaymentGoal'] != null
            ? (j['monthlyPaymentGoal'] as num).toDouble()
            : null,
        notes: j['notes'],
        priority: DebtPriority.values.firstWhere(
          (e) => e.name == j['priority'],
          orElse: () => DebtPriority.medium,
        ),
        status: DebtStatus.values.firstWhere(
          (e) => e.name == j['status'],
          orElse: () => DebtStatus.active,
        ),
        createdAt: DateTime.parse(j['createdAt']),
        updatedAt: DateTime.parse(j['updatedAt']),
      );
}
