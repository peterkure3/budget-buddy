// lib/models/budget.dart

class Budget {
  final double income;
  final double balance; // income - total spent
  final DateTime lastUpdated;
  final List<BudgetCategory> categories;

  Budget({
    required this.income,
    required this.balance,
    required this.lastUpdated,
    required this.categories,
  });

  double get totalSpent => categories.fold(0.0, (sum, c) => sum + c.spent);

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

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      income: (json['income'] as num).toDouble(),
      balance: (json['balance'] as num).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      categories: (json['categories'] as List)
          .map((e) => BudgetCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'income': income,
      'balance': balance,
      'lastUpdated': lastUpdated.toIso8601String(),
      'categories': categories.map((e) => e.toJson()).toList(),
    };
  }
}

class BudgetCategory {
  final String id;
  final String name;
  final double allocation; // planned
  final double spent;      // actual

  BudgetCategory({
    required this.id,
    required this.name,
    required this.allocation,
    required this.spent,
  });

  double get remaining => allocation - spent;

  BudgetCategory copyWith({
    String? id,
    String? name,
    double? allocation,
    double? spent,
  }) {
    return BudgetCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      allocation: allocation ?? this.allocation,
      spent: spent ?? this.spent,
    );
  }

  factory BudgetCategory.fromJson(Map<String, dynamic> json) {
    return BudgetCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      allocation: (json['allocation'] as num?)?.toDouble() ?? 0.0,
      spent: (json['spent'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'allocation': allocation,
      'spent': spent,
    };
  }
}
