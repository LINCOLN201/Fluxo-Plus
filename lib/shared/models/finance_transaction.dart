import 'category.dart';

class FinanceTransaction {
  const FinanceTransaction({
    this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.accountId,
    required this.date,
    required this.description,
    required this.createdAt,
  });

  final int? id;
  final TransactionType type;
  final double amount;
  final int categoryId;
  final int accountId;
  final DateTime date;
  final String description;
  final DateTime createdAt;

  factory FinanceTransaction.fromMap(Map<String, Object?> map) =>
      FinanceTransaction(
        id: map['id'] as int,
        type: TransactionType.values.byName(map['type'] as String),
        amount: (map['amount'] as num).toDouble(),
        categoryId: map['category_id'] as int,
        accountId: map['account_id'] as int,
        date: DateTime.parse(map['date'] as String),
        description: map['description'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'type': type.name,
        'amount': amount,
        'category_id': categoryId,
        'account_id': accountId,
        'date': date.toIso8601String(),
        'description': description,
        'created_at': createdAt.toIso8601String(),
      };
}
