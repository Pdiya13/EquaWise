import 'package:flutter/foundation.dart';

import '../models/transaction_model.dart';
import '../repositories/transaction_repository.dart';

class TransactionsViewModel extends ChangeNotifier {
  final TransactionRepository _transactionRepository = TransactionRepository();

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load user transactions
  void loadUserTransactions(String userId) {
    _transactionRepository.getUserTransactions(userId).listen(
      (transactions) {
        _transactions = transactions;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  // Get total income
  double get totalIncome {
    return _transactions
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  // Get total expenses
  double get totalExpenses {
    return _transactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  // Get net balance
  double get netBalance {
    return totalIncome - totalExpenses;
  }

  // Get transactions by category
  List<TransactionModel> getTransactionsByCategory(TransactionCategory category) {
    return _transactions.where((tx) => tx.category == category).toList();
  }

  // Get group settlement transactions
  List<TransactionModel> get groupSettlements {
    return _transactions.where((tx) => tx.category == TransactionCategory.groupExpense).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearData() {
    _transactions.clear();
    _error = null;
    notifyListeners();
  }
}
