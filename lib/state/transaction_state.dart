import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../services/transaction_service.dart';
import 'budget_state.dart';
import 'settings_state.dart';

class TransactionState extends ChangeNotifier {
  final BudgetState _budgetState;
  final SettingsState _settingsState;

  final TransactionService _service = TransactionService();

  TransactionState(this._budgetState, this._settingsState);

  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTransactions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _transactions = await _service.loadTransactions();
    } catch (e) {
      _error = 'Failed to load transactions';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    _transactions.add(transaction);
    await _service.saveTransactions(_transactions);

    // Update category spent and budget balance
    if (_budgetState.budget != null && transaction.categoryId != null) {
      final categories = _budgetState.budget!.categories;
      final idx = categories.indexWhere((c) => c.id == transaction.categoryId);
      if (idx != -1) {
        final cat = categories[idx];
        final newSpent = cat.spent + transaction.amount.abs();
        _budgetState.updateCategorySpent(cat.id, newSpent);
        _budgetState.recalculateBalance();
      }
    }
    notifyListeners();
  }

  Future<void> removeTransaction(String id) async {
    final transaction = _transactions.firstWhere(
      (t) => t.id == id,
      orElse: () => null as Transaction,
    );
    _transactions.removeWhere((t) => t.id == id);
    await _service.saveTransactions(_transactions);

    // Update category spent and budget balance
    if (_budgetState.budget != null && transaction.categoryId != null) {
      final categories = _budgetState.budget!.categories;
      final idx = categories.indexWhere((c) => c.id == transaction.categoryId);
      if (idx != -1) {
        final cat = categories[idx];
        final newSpent = (cat.spent - transaction.amount.abs()).clamp(0, double.infinity) as double;
        _budgetState.updateCategorySpent(cat.id, newSpent);
        _budgetState.recalculateBalance();
      }
    }
    notifyListeners();
  }
}
