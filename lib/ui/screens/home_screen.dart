import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/transaction_state.dart';
import '../../state/budget_state.dart';
import '../../models/transaction.dart';
import '../../models/budget.dart';
import '../../state/settings_state.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';



class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isExpense = true;
  BudgetCategory? _selectedCategory;

final List<BudgetCategory> _categories = [
  BudgetCategory(id: '1', name: 'Food', amount: 0),
  BudgetCategory(id: '2', name: 'Transportation', amount: 0),
  BudgetCategory(id: '3', name: 'Entertainment', amount: 0),
  BudgetCategory(id: '4', name: 'Utilities', amount: 0),
  BudgetCategory(id: '5', name: 'Other', amount: 0),
];


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionState>().loadTransactions();
      context.read<BudgetState>().loadBudget();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

 Future<void> _showTransactionTypeDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Transaction Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.remove_circle_outline, color: Colors.red),
              title: const Text('Expense'),
              onTap: () {
                setState(() => _isExpense = true);
                Navigator.pop(context);
                _addTransaction();
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: Colors.green),
              title: const Text('Income'),
              onTap: () {
                setState(() => _isExpense = false);
                Navigator.pop(context);
                _addTransaction();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addTransaction() async {
    final currencySymbol = context.read<SettingsState>().currencySymbol;
    
    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(_isExpense ? 'Add Expense' : 'Add Income'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: currencySymbol,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => _selectDate(context),
                      child: Text(
                        DateFormat('MMM dd, yyyy').format(_selectedDate),
                      ),
                    ),
                  ],
                ),
                if (_isExpense) ...[
                  const SizedBox(height: 16),
                  Consumer<BudgetState>(
                    builder: (context, budgetState, child) {
                      return DropdownButtonFormField<BudgetCategory>(
                        value: _selectedCategory,
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category.name),
                          );
                        }).toList(),
                        onChanged: (BudgetCategory? newValue) {
                          setState(() {
                            _selectedCategory = newValue;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_descriptionController.text.isNotEmpty &&
                    _amountController.text.isNotEmpty &&
                    (_isExpense ? _selectedCategory != null : true)) {
                  final amount = double.parse(_amountController.text);
                  final transaction = Transaction(
                    id: DateTime.now().toString(),
                    description: _descriptionController.text,
                    amount: _isExpense ? -amount : amount,
                    date: _selectedDate,
                    categoryId: _isExpense ? _selectedCategory!.id : null,
                  );
                  
                  context.read<TransactionState>().addTransaction(transaction);
                  
                  // Update budget balance and category
                  final budgetState = context.read<BudgetState>();
                  if (budgetState.budget != null) {
                    final newBalance = budgetState.budget!.balance + (_isExpense ? -amount : amount);
                    budgetState.updateBudget(budgetState.budget!.copyWith(
                      balance: newBalance,
                      lastUpdated: DateTime.now(),
                    ));

                    if (_isExpense && _selectedCategory != null) {
                      budgetState.updateCategory(_selectedCategory!.id, _selectedCategory!.amount + amount);
                    }

                  }

                  _descriptionController.clear();
                  _amountController.clear();
                  setState(() {
                    _selectedDate = DateTime.now();
                    _selectedCategory = null;
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildTransactionList(List<Transaction> transactions, String currencySymbol) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add one',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    // Group transactions by date
    final groupedTransactions = <DateTime, List<Transaction>>{};
    for (var transaction in transactions) {
      final date = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      if (!groupedTransactions.containsKey(date)) {
        groupedTransactions[date] = [];
      }
      groupedTransactions[date]!.add(transaction);
    }

    final sortedDates = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final dayTransactions = groupedTransactions[date]!;
        final dayTotal = dayTransactions.fold<double>(
          0,
          (sum, transaction) => sum + transaction.amount,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(date),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Total: $currencySymbol${dayTotal.abs().toStringAsFixed(2)}',
                    style: TextStyle(
                      color: dayTotal >= 0 ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ...dayTransactions.map((transaction) => Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Dismissible(
                key: Key(transaction.id),
                onDismissed: (direction) {
                  context.read<TransactionState>().removeTransaction(transaction.id);
                },
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: transaction.amount < 0 
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    child: Icon(
                      transaction.amount < 0 
                          ? Icons.add_circle_outline
                          : Icons.remove_circle_outline,
                      color: transaction.amount < 0 ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(
                    transaction.description,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(DateFormat('HH:mm').format(transaction.date)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${transaction.amount < 0 ? '+' : '-'}$currencySymbol${transaction.amount.abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: transaction.amount < 0 ? Colors.green : Colors.red,
                        ),
                      ),
                      Text(
                        transaction.amount < 0 ? 'Income' : 'Expense',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )).toList(),
            if (index < sortedDates.length - 1) const Divider(),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == DateTime(now.year, now.month, now.day)) {
      return 'Today';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM d, y').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = context.watch<SettingsState>().currencySymbol;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.transactions),
            Consumer<TransactionState>(
              builder: (context, state, _) => Text(
                '${state.transactions.length} transactions',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<TransactionState>(
        builder: (context, state, child) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state.error != null) {
            return Center(child: Text(state.error!));
          }

          return _buildTransactionList(state.transactions, currencySymbol);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showTransactionTypeDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}
