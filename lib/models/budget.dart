// lib/models/budget.dart

class Budget {
  final double income;
  final double balance;
  final DateTime lastUpdated;
  final List<BudgetCategory> categories;

  Budget({
    required this.income,
    required this.balance,
    required this.lastUpdated,
    required this.categories,
  });

  Budget copyWith({
    double? income,
    double? balance,
    DateTime? lastUpdated,
    List<BudgetCategory>? categories,
  }) {
    return Budget(
      income: income ?? this.income,
      balance: balance ?? this.balance,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      categories: categories ?? this.categories,
    );
  }
}

class BudgetCategory {
  final String id;
  final String name;
  final double amount;

  BudgetCategory({
    required this.id,
    required this.name,
    required this.amount,
  });

  BudgetCategory copyWith({
    String? id,
    String? name,
    double? amount,
  }) {
    return BudgetCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
    );
  }
}
