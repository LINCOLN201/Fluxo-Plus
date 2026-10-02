enum TransactionType { income, expense }

class Category {
  const Category({
    this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    this.isDefault = false,
    this.isSubscription = false,
  });

  final int? id;
  final String name;
  final TransactionType type;
  final String icon;
  final int color;
  final bool isDefault;
  final bool isSubscription;

  factory Category.fromMap(Map<String, Object?> map) => Category(
        id: map['id'] as int,
        name: map['name'] as String,
        type: TransactionType.values.byName(map['type'] as String),
        icon: map['icon'] as String,
        color: map['color'] as int,
        isDefault: (map['is_default'] as int? ?? 0) == 1,
        isSubscription: (map['is_subscription'] as int? ?? 0) == 1,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'type': type.name,
        'icon': icon,
        'color': color,
        'is_default': isDefault ? 1 : 0,
        'is_subscription': isSubscription ? 1 : 0,
      };
}
