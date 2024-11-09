// lib/models/budget_category.dart

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
