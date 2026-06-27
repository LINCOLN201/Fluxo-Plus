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
        initialBalance: (map['initial_balance'] as num).toDouble(),
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'initial_balance': initialBalance,
        'created_at': createdAt.toIso8601String(),
      };
}
