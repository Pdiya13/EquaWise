import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/budgets_view_model.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../models/transaction_model.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final List<TransactionCategory> _categories = const [
    TransactionCategory.food,
    TransactionCategory.health,
    TransactionCategory.donation,
    TransactionCategory.party,
    TransactionCategory.repairing,
    TransactionCategory.movie,
    TransactionCategory.household,
    TransactionCategory.transport,
    TransactionCategory.travel,
    TransactionCategory.sports,
    TransactionCategory.other,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthViewModel>();
      final vm = context.read<BudgetsViewModel>();
      if (auth.currentUser != null) vm.load(auth.currentUser!.uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      body: Consumer2<BudgetsViewModel, AuthViewModel>(
        builder: (context, vm, auth, _) {
          if (vm.isLoading) return const Center(child: CircularProgressIndicator());
          final userId = auth.currentUser?.uid;
          if (userId == null) return const Center(child: Text('Please log in'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final goal = vm.budgets.where((b) => b.category == cat).map((b) => b.amount).fold(0.0, (a, b) => b);
              final spent = vm.spentThisMonthForCategory(cat);
              final progress = goal > 0 ? (spent / goal).clamp(0.0, 1.0) : 0.0;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_categoryName(cat), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          Text('₹${goal.toStringAsFixed(0)}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: progress, minHeight: 8),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Spent: ₹${spent.toStringAsFixed(0)}'),
                          Text('Left: ₹${(goal - spent).clamp(0, double.infinity).toStringAsFixed(0)}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _setGoal(context, vm, userId, cat, goal),
                            icon: const Icon(Icons.edit),
                            label: const Text('Set Goal'),
                          ),
                          OutlinedButton.icon(
                            onPressed: goal <= 0 ? null : () => _confirmReset(context, vm, userId, cat),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reset Goal'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _setGoal(BuildContext context, BudgetsViewModel vm, String userId, TransactionCategory cat, double current) async {
    final controller = TextEditingController(text: current > 0 ? current.toStringAsFixed(0) : '0');
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set goal for ${_categoryName(cat)}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: '₹ '),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(double.tryParse(controller.text.trim()) ?? 0.0), child: const Text('Save')),
        ],
      ),
    );
    if (amount != null) {
      await vm.setGoal(userId: userId, category: cat, amount: amount);
    }
  }

  Future<void> _confirmReset(BuildContext context, BudgetsViewModel vm, String userId, TransactionCategory cat) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset goal?'),
        content: Text('This will remove the goal for ${_categoryName(cat)}.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Reset')),
        ],
      ),
    );
    if (ok == true) {
      await vm.resetGoal(userId: userId, category: cat);
    }
  }

  String _categoryName(TransactionCategory cat) {
    switch (cat) {
      case TransactionCategory.food:
        return 'Food';
      case TransactionCategory.health:
        return 'Health';
      case TransactionCategory.donation:
        return 'Donation';
      case TransactionCategory.party:
        return 'Party';
      case TransactionCategory.repairing:
        return 'Repairing';
      case TransactionCategory.movie:
        return 'Movie';
      case TransactionCategory.household:
        return 'Household';
      case TransactionCategory.transport:
        return 'Transport';
      case TransactionCategory.travel:
        return 'Travel';
      case TransactionCategory.sports:
        return 'Sports';
      case TransactionCategory.entertainment:
        return 'Entertainment';
      case TransactionCategory.shopping:
        return 'Shopping';
      case TransactionCategory.bills:
        return 'Bills';
      case TransactionCategory.healthcare:
        return 'Healthcare';
      case TransactionCategory.education:
        return 'Education';
      case TransactionCategory.groupExpense:
        return 'Group';
      case TransactionCategory.other:
        return 'Other';
    }
  }
}

