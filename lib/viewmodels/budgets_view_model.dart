
import 'package:flutter/foundation.dart';

import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import '../repositories/budget_repository.dart';
import '../repositories/transaction_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BudgetsViewModel extends ChangeNotifier {
  final BudgetRepository _budgetRepository = BudgetRepository();
  final TransactionRepository _txRepository = TransactionRepository();

  List<BudgetModel> _budgets = [];
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _error;

  List<BudgetModel> get budgets => _budgets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void load(String userId) {
    _isLoading = true;
    notifyListeners();
    _budgetRepository.getUserBudgets(userId).listen((b) async {
      _budgets = b;
      _isLoading = false;
      notifyListeners();
      // Re-evaluate thresholds whenever budgets change
      await _evaluateBudgetThresholds();
    }, onError: (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    });
    _txRepository.getUserTransactions(userId).listen((txs) async {
      _transactions = txs;
      notifyListeners();
      // Re-evaluate when spending changes
      await _evaluateBudgetThresholds();
    });
  }

  double spentThisMonthForCategory(TransactionCategory category) {
    final now = DateTime.now();
    return _transactions
        .where((t) => t.type == TransactionType.expense)
        .where((t) => t.category == category)
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Future<void> _evaluateBudgetThresholds() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    final String userName = (user?.displayName?.trim().isNotEmpty == true)
        ? user!.displayName!.trim()
        : (user?.email ?? 'You');
    for (final budget in _budgets) {
      final spent = spentThisMonthForCategory(budget.category);
      if (budget.amount <= 0) continue;

      final remaining = (budget.amount - spent).clamp(0, double.infinity);
      final remainingPct = remaining / budget.amount; // 0..1

      // Keys to avoid duplicate alerts within the month and budget
      final monthKey = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
      final key50 = 'budget_${budget.category.name}_${monthKey}_50';
      final key10 = 'budget_${budget.category.name}_${monthKey}_10';

      if (remainingPct <= 0.10 && !(prefs.getBool(key10) ?? false)) {
        await NotificationService.instance.showBudgetAlert(
          title: 'Only 10% left in ${budget.category.name}',
          body: '$userName, you have ₹${remaining.toStringAsFixed(0)} remaining this month.',
        );
        await prefs.setBool(key10, true);
      } else if (remainingPct <= 0.50 && !(prefs.getBool(key50) ?? false)) {
        await NotificationService.instance.showBudgetAlert(
          title: '50% budget used for ${budget.category.name}',
          body: '$userName, you\'ve spent ₹${spent.toStringAsFixed(0)} of ₹${budget.amount.toStringAsFixed(0)}.',
        );
        await prefs.setBool(key50, true);
      }
    }
  }

  Future<void> setGoal({
    required String userId,
    required TransactionCategory category,
    required double amount,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final existing = _budgets.where((b) => b.category == category).toList();
      if (existing.isEmpty) {
        await _budgetRepository.upsertBudget(
          userId: userId,
          budget: BudgetModel(
            id: '',
            userId: userId,
            category: category,
            amount: amount,
            period: 'monthly',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      } else {
        await _budgetRepository.updateAmount(existing.first.id, amount);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> resetGoal({
    required String userId,
    required TransactionCategory category,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final existing = _budgets.where((b) => b.category == category).toList();
      if (existing.isNotEmpty) {
        await _budgetRepository.deleteBudget(existing.first.id);
        _budgets.removeWhere((b) => b.id == existing.first.id);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
}

