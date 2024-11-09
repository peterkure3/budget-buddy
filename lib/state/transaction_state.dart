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
    
    if (_budgetState.budget != null) {
      final updatedBudget = Budget(
        income: _budgetState.budget!.income,
        balance: _budgetState.budget!.balance - transaction.amount,
        lastUpdated: DateTime.now(),
        categories: _budgetState.budget!.categories,
      );
      await _budgetState.updateBudget(updatedBudget);
    }
    
    notifyListeners();
  }

  Future<void> removeTransaction(String id) async {
    _transactions.removeWhere((t) => t.id == id);
    await _service.saveTransactions(_transactions);
    notifyListeners();
  }
}
