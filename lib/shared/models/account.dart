import '../../core/utils/money.dart';

class Account {
  const Account({
    this.id,
    required this.name,
    required this.initialBalance,
    required this.createdAt,
  });

  final int? id;
  final String name;
  final double initialBalance;
  final DateTime createdAt;

  factory Account.fromMap(Map<String, Object?> map) => Account(
        id: map['id'] as int,
        name: map['name'] as String,
        initialBalance: Money.fromCents(map['initial_balance_cents']),
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'initial_balance_cents': Money.toCents(initialBalance),
        'created_at': createdAt.toIso8601String(),
      };
}
