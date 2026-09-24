import '../../core/utils/money.dart';

class Goal {
  const Goal({
    this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    this.deadline,
    required this.createdAt,
  });

  final int? id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final DateTime createdAt;

  double get progress =>
      targetAmount <= 0 ? 0 : (currentAmount / targetAmount).clamp(0, 1);

  factory Goal.fromMap(Map<String, Object?> map) => Goal(
        id: map['id'] as int,
        name: map['name'] as String,
        targetAmount: Money.fromCents(map['target_amount_cents']),
        currentAmount: Money.fromCents(map['current_amount_cents']),
        deadline: map['deadline'] == null
            ? null
            : DateTime.parse(map['deadline'] as String),
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'target_amount_cents': Money.toCents(targetAmount),
        'current_amount_cents': Money.toCents(currentAmount),
        'deadline': deadline?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}
