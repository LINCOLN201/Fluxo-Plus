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
    this.isPaid = true,
    this.installmentGroup,
    this.installmentNumber = 1,
    this.installmentCount = 1,
  });

  final int? id;
  final TransactionType type;
  final double amount;
  final int categoryId;
  final int accountId;
  final DateTime date;
  final String description;
  final DateTime createdAt;
  final bool isPaid;
  final String? installmentGroup;
  final int installmentNumber;
  final int installmentCount;

  String get name => description;
  double get installmentTotal => amount * installmentCount;

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
        isPaid: ((map['is_paid'] as int?) ?? 1) == 1,
        installmentGroup: map['installment_group'] as String?,
        installmentNumber: (map['installment_number'] as int?) ?? 1,
        installmentCount: (map['installment_count'] as int?) ?? 1,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'type': type.name,
        'amount': amount,
        'category_id': categoryId,
        'account_id': accountId,
        'date': date.toIso8601String(),
        'description': description,
        'is_paid': isPaid ? 1 : 0,
        'installment_group': installmentGroup,
        'installment_number': installmentNumber,
        'installment_count': installmentCount,
        'created_at': createdAt.toIso8601String(),
      };
}
