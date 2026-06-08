import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/transactions_view_model.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../models/transaction_model.dart';

class TodayExpensesScreen extends StatelessWidget {
  const TodayExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Expenses"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Consumer2<AuthViewModel, TransactionsViewModel>(
          builder: (context, authVm, txVm, _) {
            if (authVm.isLoading || txVm.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final List<TransactionModel> todayExpenses = _getTodayExpenses(txVm.transactions);

            if (todayExpenses.isEmpty) {
              return const Center(child: Text('No expenses today'));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final tx = todayExpenses[index];
                return ListTile(
                  leading: Icon(_getCategoryIcon(tx.category)),
                  title: Text(tx.title),
                  subtitle: Text('${tx.date.hour.toString().padLeft(2, '0')}:${tx.date.minute.toString().padLeft(2, '0')}'),
                  trailing: Text('₹${tx.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                );
              },
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemCount: todayExpenses.length,
            );
          },
        ),
      ),
    );
  }

  List<TransactionModel> _getTodayExpenses(List<TransactionModel> transactions) {
    final now = DateTime.now();
    return transactions.where((t) =>
      t.type == TransactionType.expense &&
      t.date.year == now.year &&
      t.date.month == now.month &&
      t.date.day == now.day
    ).toList();
  }

  IconData _getCategoryIcon(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.food:
        return Icons.restaurant;
      case TransactionCategory.health:
        return Icons.health_and_safety;
      case TransactionCategory.donation:
        return Icons.volunteer_activism;
      case TransactionCategory.party:
        return Icons.celebration;
      case TransactionCategory.repairing:
        return Icons.build;
      case TransactionCategory.movie:
        return Icons.movie;
      case TransactionCategory.household:
        return Icons.home;
      case TransactionCategory.transport:
        return Icons.directions_car;
      case TransactionCategory.travel:
        return Icons.flight;
      case TransactionCategory.sports:
        return Icons.sports;
      case TransactionCategory.groupExpense:
        return Icons.group;
      default:
        return Icons.category;
    }
  }
}


