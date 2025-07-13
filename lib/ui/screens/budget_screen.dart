import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/budget_state.dart';
import 'budget_setup_screen.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final budgetState = Provider.of<BudgetState>(context);

    if (budgetState.budget == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Budget')),
        body: Center(
          child: ElevatedButton(
            child: Text('Create Budget'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => BudgetSetupScreen()),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Budget'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => BudgetSetupScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('Income'),
            trailing: Text(
              '${budgetState.currency}${budgetState.income.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Divider(),
          ...budgetState.budget!.categories.map((category) => ListTile(
                title: Text(category.name),
                trailing: Text(
                  '${budgetState.currency}${category.allocation.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              )),
          Divider(),
          ListTile(
            title: Text('Remaining Balance'),
            trailing: Text(
              '${budgetState.currency}${budgetState.budget!.balance.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
    );
  }
}
