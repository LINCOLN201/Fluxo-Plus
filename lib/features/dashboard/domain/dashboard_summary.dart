import '../../../shared/models/category.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.balance,
    required this.monthIncome,
    required this.monthExpense,
    required this.recentTransactions,
    required this.monthlyFlow,
    required this.categorySpending,
    required this.pendingAlerts,
  });

  final double balance;
  final double monthIncome;
  final double monthExpense;
  final List<TransactionListItem> recentTransactions;
  final List<MonthlyFlow> monthlyFlow;
  final List<CategorySpending> categorySpending;
  final int pendingAlerts;

  double get savings => monthIncome - monthExpense;
}

class MonthlyFlow {
  const MonthlyFlow({
    required this.month,
    required this.income,
    required this.expense,
  });

  final DateTime month;
  final double income;
  final double expense;
}

class CategorySpending {
  const CategorySpending({
    required this.name,
    required this.amount,
    required this.color,
  });

  final String name;
  final double amount;
  final int color;
}

class TransactionListItem {
  const TransactionListItem({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.categoryName,
    required this.date,
    required this.isPaid,
    required this.categoryIcon,
    required this.installmentNumber,
    required this.installmentCount,
  });

  final int id;
  final TransactionType type;
  final double amount;
  final String description;
  final String categoryName;
  final DateTime date;
  final bool isPaid;
  final String categoryIcon;
  final int installmentNumber;
  final int installmentCount;
}
