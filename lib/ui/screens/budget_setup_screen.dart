import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/budget_state.dart';
import '../../models/budget.dart';

class BudgetSetupScreen extends StatefulWidget {
  const BudgetSetupScreen({super.key});

  @override
  _BudgetSetupScreenState createState() => _BudgetSetupScreenState();
}

class _BudgetSetupScreenState extends State<BudgetSetupScreen> {
  late TextEditingController _incomeController;
  List<BudgetCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    final budgetState = Provider.of<BudgetState>(context, listen: false);
    _incomeController =
        TextEditingController(text: budgetState.income.toString());
    _categories =
        List<BudgetCategory>.from(budgetState.budget?.categories ?? []);
  }

  @override
  Widget build(BuildContext context) {
    final budgetState = Provider.of<BudgetState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Setup Budget'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          TextField(
            controller: _incomeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Income',
              prefixText: budgetState.currency,
            ),
          ),
          SizedBox(height: 16),
          Text('Categories', style: Theme.of(context).textTheme.titleLarge),
          ..._categories.map(_buildCategoryTile),
          ListTile(
            leading: Icon(Icons.add),
            title: Text('Add Category'),
            onTap: _addCategory,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.save),
        onPressed: () => _saveBudget(budgetState),
      ),
    );
  }

  Widget _buildCategoryTile(BudgetCategory category) {
    final budgetState = Provider.of<BudgetState>(context, listen: false);
    return ListTile(
      title: Text(category.name),
      subtitle:
          Text('${budgetState.currency}${category.allocation.toStringAsFixed(2)}'),
      trailing: IconButton(
        icon: Icon(Icons.delete),
        onPressed: () => _removeCategory(category),
      ),
      onTap: () => _editCategory(category),
    );
  }

  void _addCategory() async {
    final result = await _showCategoryDialog();
    if (result != null) {
      setState(() {
        _categories.add(result);
      });
    }
  }

  void _editCategory(BudgetCategory category) async {
    final result = await _showCategoryDialog(category);
    if (result != null) {
      setState(() {
        final index = _categories.indexWhere((c) => c.id == category.id);
        _categories[index] = result;
      });
    }
  }

  void _removeCategory(BudgetCategory category) {
    setState(() {
      _categories.removeWhere((c) => c.id == category.id);
    });
  }

  Future<BudgetCategory?> _showCategoryDialog(
      [BudgetCategory? category]) async {
    final nameController = TextEditingController(text: category?.name ?? '');
    final amountController =
        TextEditingController(text: category?.allocation.toString() ?? '');
    final budgetState = Provider.of<BudgetState>(context, listen: false);

    return showDialog<BudgetCategory>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? 'Add Category' : 'Edit Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Category Name'),
            ),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: budgetState.currency,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('Save'),
            onPressed: () {
              final name = nameController.text;
              final amount = double.tryParse(amountController.text) ?? 0;
              Navigator.of(context).pop(
                BudgetCategory(
                  id: category?.id ?? DateTime.now().toString(),
                  name: name,
                  allocation: amount,
                  spent: 0,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _saveBudget(BudgetState budgetState) {
    final income = double.tryParse(_incomeController.text) ?? 0;
    budgetState.saveBudget(income, _categories);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }
}
