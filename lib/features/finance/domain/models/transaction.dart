enum TransactionType { income, expense }

class Transaction {
  final String id;
  String title;
  double amount;
  TransactionType type;
  String category;
  DateTime date;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    this.category = 'Other',
    DateTime? date,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'type': type.name,
        'category': category,
        'date': date.toIso8601String(),
      };

  factory Transaction.fromJson(Map<String, dynamic> j) => Transaction(
        id: j['id'],
        title: j['title'],
        amount: (j['amount'] as num).toDouble(),
        type: j['type'] == 'income' ? TransactionType.income : TransactionType.expense,
        category: j['category'] ?? 'Other',
        date: DateTime.tryParse(j['date'] ?? '') ?? DateTime.now(),
      );
}
