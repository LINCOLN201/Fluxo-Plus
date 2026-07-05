import 'package:flutter/material.dart';

abstract final class CategoryIcons {
  static const choices = <(String, IconData, String)>[
    ('restaurant', Icons.restaurant_rounded, 'Alimentação'),
    ('credit_card', Icons.credit_card_rounded, 'Cartão'),
    ('wifi', Icons.wifi_rounded, 'Internet'),
    ('home', Icons.home_rounded, 'Moradia'),
    ('directions_car', Icons.directions_car_rounded, 'Transporte'),
    ('medical_services', Icons.medical_services_rounded, 'Saúde'),
    ('celebration', Icons.celebration_rounded, 'Lazer'),
    ('school', Icons.school_rounded, 'Educação'),
    ('shopping_bag', Icons.shopping_bag_rounded, 'Compras'),
    ('payments', Icons.payments_rounded, 'Salário'),
    ('work', Icons.work_rounded, 'Trabalho'),
    ('add_circle', Icons.add_circle_rounded, 'Outros ganhos'),
    ('more_horiz', Icons.more_horiz_rounded, 'Outros'),
    ('category', Icons.category_rounded, 'Categoria'),
  ];

  static IconData resolve(String name) {
    for (final item in choices) {
      if (item.$1 == name) return item.$2;
    }
    return Icons.category_rounded;
  }
}
