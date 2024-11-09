import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/budget_state.dart';
import '../../state/transaction_state.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../state/settings_state.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currencySymbol = context.watch<SettingsState>().currencySymbol;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer<BudgetState>(
                builder: (context, budgetState, _) {
                  if (budgetState.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final budget = budgetState.budget;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Account Balance',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$currencySymbol${budget?.balance.toStringAsFixed(2) ?? '0.00'}',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Monthly Income: $currencySymbol${budget?.income.toStringAsFixed(2) ?? '0.00'}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (budget != null) Text(
                            'Last Updated: ${DateFormat('MMM dd, yyyy').format(budget.lastUpdated)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Recent Transactions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Consumer<TransactionState>(
                builder: (context, transactionState, _) {
                  if (transactionState.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final transactions = transactionState.transactions;
                  if (transactions.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No recent transactions'),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactions.length.clamp(0, 5),
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      return ListTile(
                        title: Text(transaction.description),
                        subtitle: Text(
                          DateFormat('MMM dd, yyyy').format(transaction.date),
                        ),
                        trailing: Text(
                          '-\$${transaction.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
} 