import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../state/transaction_state.dart';
import '../../models/transaction.dart';
import 'package:intl/intl.dart';
import '../../state/settings_state.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencySymbol = context.watch<SettingsState>().currencySymbol;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.statistics),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<TransactionState>(
        builder: (context, state, child) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactions = state.transactions;
          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No transactions yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add some to see statistics!',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          // Calculate statistics
          double totalSpent = transactions.fold(
              0, (sum, transaction) => sum + transaction.amount.abs());
          
          final firstDate = transactions.map((t) => t.date).reduce((a, b) => a.isBefore(b) ? a : b);
          final lastDate = transactions.map((t) => t.date).reduce((a, b) => a.isAfter(b) ? a : b);
          final daysDifference = lastDate.difference(firstDate).inDays + 1;
          final dailyAverage = totalSpent / daysDifference;

          final maxTransaction = transactions.reduce(
              (a, b) => a.amount.abs() > b.amount.abs() ? a : b);
          final minTransaction = transactions.reduce(
              (a, b) => a.amount.abs() < b.amount.abs() ? a : b);

          final Map<DateTime, double> dailyTotals = {};
          for (var transaction in transactions) {
            final date = DateTime(
              transaction.date.year,
              transaction.date.month,
              transaction.date.day,
            );
            dailyTotals[date] = (dailyTotals[date] ?? 0) + transaction.amount.abs();
          }

          final sortedDates = dailyTotals.keys.toList()
            ..sort((a, b) => b.compareTo(a));
          final last7Days = sortedDates.take(7).toList()
            ..sort((a, b) => a.compareTo(b));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuickStats(context, dailyAverage, totalSpent, currencySymbol),
                const SizedBox(height: 24),
                _buildSpendingHighlights(context, maxTransaction, minTransaction, currencySymbol),
                const SizedBox(height: 24),
                _buildWeeklySpendingChart(context, last7Days, dailyTotals, currencySymbol),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, double dailyAverage, double totalSpent, String currencySymbol) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Daily Average',
            value: dailyAverage,
            icon: Icons.calendar_today,
            color: Colors.blue,
            currencySymbol: currencySymbol,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: 'Total Spent',
            value: totalSpent,
            icon: Icons.account_balance_wallet,
            color: Colors.green,
            currencySymbol: currencySymbol,
          ),
        ),
      ],
    );
  }

  Widget _buildSpendingHighlights(BuildContext context, Transaction maxTransaction, Transaction minTransaction, String currencySymbol) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Spending Highlights',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _HighlightRow(
              title: 'Biggest Expense',
              transaction: maxTransaction,
              icon: Icons.arrow_upward,
              color: Colors.red,
              currencySymbol: currencySymbol,
            ),
            const Divider(height: 24),
            _HighlightRow(
              title: 'Smallest Expense',
              transaction: minTransaction,
              icon: Icons.arrow_downward,
              color: Colors.green,
              currencySymbol: currencySymbol,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySpendingChart(BuildContext context, List<DateTime> last7Days, Map<DateTime, double> dailyTotals, String currencySymbol) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last 7 Days Spending',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: dailyTotals.values.reduce((a, b) => a > b ? a : b) * 1.2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '$currencySymbol${rod.toY.toStringAsFixed(2)}',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value >= 0 && value < last7Days.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                DateFormat('E').format(last7Days[value.toInt()]),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(
                    last7Days.length,
                    (index) => BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: dailyTotals[last7Days[index]] ?? 0,
                          color: Theme.of(context).colorScheme.primary,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;
  final Color color;
  final String currencySymbol;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              '$currencySymbol${value.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightRow extends StatelessWidget {
  final String title;
  final Transaction transaction;
  final IconData icon;
  final Color color;
  final String currencySymbol;

  const _HighlightRow({
    required this.title,
    required this.transaction,
    required this.icon,
    required this.color,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(
                transaction.description,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Text(
          '$currencySymbol${transaction.amount.abs().toStringAsFixed(2)}',
          style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16),
        ),
      ],
    );
  }
}
