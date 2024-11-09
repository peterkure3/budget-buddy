// lib/state/budget_state.dart

import 'package:flutter/foundation.dart';
import '../models/budget.dart';
import '../state/settings_state.dart';


class BudgetState extends ChangeNotifier {
  final SettingsState _settingsState;
  Budget? _budget;
  bool _isLoading = false;
  String? _error;

  BudgetState(this._settingsState);

  Budget? get budget => _budget;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get income => _budget?.income ?? 0.0;
  String get currency => _settingsState.currencySymbol;

  Future<void> loadBudget() async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Load budget from storage or API
      _budget = Budget(
        income: 0,
        balance: 0,
        lastUpdated: DateTime.now(),
        categories: [
          BudgetCategory(id: '1', name: 'Food', amount: 0),
          BudgetCategory(id: '2', name: 'Transportation', amount: 0),
          BudgetCategory(id: '3', name: 'Entertainment', amount: 0),
          BudgetCategory(id: '4', name: 'Utilities', amount: 0),
          BudgetCategory(id: '5', name: 'Other', amount: 0),
        ],
      );
      _error = null;
    } catch (e) {
      _error = 'Failed to load budget: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateBudget(Budget updatedBudget) async {
    _isLoading = true;
    notifyListeners();

    try {
      _budget = updatedBudget;
      // TODO: Save updated budget to storage or API
      _error = null;
    } catch (e) {
      _error = 'Failed to update budget: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  void updateCategory(String categoryId, double amount) {
    if (_budget != null) {
      final updatedCategories = _budget!.categories.map((category) {
        if (category.id == categoryId) {
          return category.copyWith(amount: amount);
        }
        return category;
      }).toList();

      final newBalance = _budget!.income - updatedCategories.fold(0.0, (sum, category) => sum + category.amount);

      _budget = _budget!.copyWith(
        categories: updatedCategories,
        balance: newBalance,
        lastUpdated: DateTime.now(),
      );

      notifyListeners();
    }
  }

  Future<void> saveBudget(double income, List<BudgetCategory> categories) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newBalance = income - categories.fold(0.0, (sum, category) => sum + category.amount);
      _budget = Budget(
        income: income,
        balance: newBalance,
        lastUpdated: DateTime.now(),
        categories: categories,
      );
      // TODO: Save budget to storage or API
      _error = null;
    } catch (e) {
      _error = 'Failed to save budget: $e';
    }

    _isLoading = false;
    notifyListeners();
  }
}
