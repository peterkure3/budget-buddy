// lib/state/budget_state.dart

import 'package:flutter/foundation.dart';
import '../models/budget.dart';
import '../state/settings_state.dart';
import '../services/budget_service.dart';

class BudgetState extends ChangeNotifier {
  final SettingsState _settingsState;
  final BudgetService _budgetService = BudgetService();
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
      final loadedBudget = await _budgetService.loadBudget();
      if (loadedBudget != null) {
        _budget = loadedBudget;
        _error = null;
      } else {
        // If no budget is found, initialize with defaults
        _budget = Budget(
          income: 0,
          balance: 0,
          lastUpdated: DateTime.now(),
          categories: [
            BudgetCategory(id: '1', name: 'Food', allocation: 0, spent: 0),
            BudgetCategory(id: '2', name: 'Transportation', allocation: 0, spent: 0),
            BudgetCategory(id: '3', name: 'Entertainment', allocation: 0, spent: 0),
            BudgetCategory(id: '4', name: 'Utilities', allocation: 0, spent: 0),
            BudgetCategory(id: '5', name: 'Other', allocation: 0, spent: 0),
          ],
        );
        _error = null;
      }
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
      final success = await _budgetService.saveBudget(updatedBudget);
      if (!success) {
        _error = 'Failed to update budget: Could not save to storage.';
      } else {
        _error = null;
      }
    } catch (e) {
      _error = 'Failed to update budget: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Update allocation for a category
  void updateCategoryAllocation(String categoryId, double allocation) {
    if (_budget != null) {
      final updatedCategories = _budget!.categories.map((category) {
        if (category.id == categoryId) {
          return category.copyWith(allocation: allocation);
        }
        return category;
      }).toList();
      _budget = _budget!.copyWith(
        categories: updatedCategories,
        lastUpdated: DateTime.now(),
      );
      notifyListeners();
    }
  }

  // Update spent for a category
  void updateCategorySpent(String categoryId, double spent) {
    if (_budget != null) {
      final updatedCategories = _budget!.categories.map((category) {
        if (category.id == categoryId) {
          return category.copyWith(spent: spent);
        }
        return category;
      }).toList();
      _budget = _budget!.copyWith(
        categories: updatedCategories,
        lastUpdated: DateTime.now(),
      );
      notifyListeners();
    }
  }

  // Recalculate balance based on total spent
  void recalculateBalance() {
    if (_budget != null) {
      final totalSpent = _budget!.categories.fold(0.0, (sum, c) => sum + c.spent);
      final newBalance = _budget!.income - totalSpent;
      _budget = _budget!.copyWith(
        balance: newBalance,
        lastUpdated: DateTime.now(),
      );
      // Auto-trigger budget alert if enabled and below threshold
      final alertsEnabled = _settingsState.budgetAlerts;
      final threshold = _settingsState.budgetAlertThreshold ?? 20.0;
      if (alertsEnabled && _budget!.income > 0) {
        final percent = (newBalance / _budget!.income) * 100;
        if (percent < threshold) {
          _settingsState.notificationService.setBudgetAlert(
            enabled: true,
            threshold: threshold,
            title: 'Budget Alert',
            body: _settingsState.budgetAlertMessage ?? 'Your balance is getting low!',
          );
        }
      }
      notifyListeners();
    }
  }

  Future<void> saveBudget(double income, List<BudgetCategory> categories) async {
    _isLoading = true;
    notifyListeners();

    try {
      final totalSpent = categories.fold(0.0, (sum, c) => sum + c.spent);
      final newBudget = Budget(
        income: income,
        balance: income - totalSpent,
        lastUpdated: DateTime.now(),
        categories: categories,
      );
      final success = await _budgetService.saveBudget(newBudget);
      if (success) {
        _budget = newBudget;
        _error = null;
      } else {
        _error = 'Failed to save budget: Could not save to storage.';
      }
    } catch (e) {
      _error = 'Failed to save budget: $e';
    }

    _isLoading = false;
    notifyListeners();
  }
}
