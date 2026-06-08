import 'package:flutter/foundation.dart';

import '../models/group_model.dart';
import '../models/group_expense_model.dart';
import '../models/user_model.dart';
import '../repositories/group_repository.dart';
import '../repositories/transaction_repository.dart';
import '../models/transaction_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class GroupsViewModel extends ChangeNotifier {
  final GroupRepository _groupRepository = GroupRepository();
  final TransactionRepository _txRepository = TransactionRepository();

  List<GroupModel> _groups = [];
  List<UserModel> _allUsers = [];
  List<GroupExpenseModel> _groupExpenses = [];
  List<GroupExpenseModel> _pendingExpenses = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<GroupModel> get groups => _groups;
  List<UserModel> get allUsers => _allUsers;
  List<GroupExpenseModel> get groupExpenses => _groupExpenses;
  List<GroupExpenseModel> get pendingExpenses => _pendingExpenses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load user groups
  void loadUserGroups(String userId) {
    _groupRepository.getUserGroups(userId).listen(
      (groups) {
        _groups = groups;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  // Load all users
  void loadAllUsers() {
    _groupRepository.getAllUsers().listen(
      (users) {
        _allUsers = users;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  // Load group expenses
  void loadGroupExpenses(String groupId) {
    _groupRepository.getGroupExpenses(groupId).listen(
      (expenses) {
        _groupExpenses = expenses;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  // Load user's pending expenses
  void loadPendingExpenses(String userId) {
    _groupRepository.getUserPendingExpenses(userId).listen(
      (expenses) async {
        await _notifyNewPendingSplits(userId, expenses);
        _pendingExpenses = expenses;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  // Count only items the user needs to pay (across all groups)
  int pendingSplitsCountForUser(String userId) {
    int count = 0;
    for (final expense in _pendingExpenses) {
      for (final split in expense.splits) {
        if (split.userId == userId &&
            split.status == ExpenseStatus.pending &&
            expense.paidBy != userId) {
          count++;
        }
      }
    }
    return count;
  }

  // Send local notifications for newly detected pending splits
  Future<void> _notifyNewPendingSplits(String userId, List<GroupExpenseModel> incoming) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final monthKey = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';

      // Build a set of already-notified expenseIds
      final notifiedKeyPrefix = 'pending_notified_${userId}_';

      // Determine which expenseIds are already notified
      final Set<String> alreadyNotified = {};
      for (final e in _pendingExpenses) {
        final key = '${notifiedKeyPrefix}${e.id}_$monthKey';
        if (prefs.getBool(key) ?? false) {
          alreadyNotified.add(e.id);
        } 
      }

      for (final expense in incoming) {
        // Only notify if this expense has a pending split for the user and the user is not the payer
        final hasPendingForUser = expense.splits.any((s) => s.userId == userId && s.status == ExpenseStatus.pending);
        if (!hasPendingForUser || expense.paidBy == userId) continue;

        final key = '${notifiedKeyPrefix}${expense.id}_$monthKey';
        if (alreadyNotified.contains(expense.id) || (prefs.getBool(key) ?? false)) continue;

        final split = expense.splits.firstWhere((s) => s.userId == userId);
        await NotificationService.instance.showBudgetAlert(
          title: 'New split request from ${expense.paidByName}',
          body: 'Pay ₹${split.amount.toStringAsFixed(0)} for ${expense.title}',
        );
        await prefs.setBool(key, true);
      }
    } catch (_) {
      // Best-effort notifications; ignore failures
    }
  }

  // Create a new group
  Future<String?> createGroup({
    required String name,
    required String description,
    required String createdBy,
    required List<String> memberIds,
    required Map<String, String> memberNames,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final groupId = await _groupRepository.createGroup(
        name: name,
        description: description,
        createdBy: createdBy,
        memberIds: memberIds,
        memberNames: memberNames,
      );

      _isLoading = false;
      notifyListeners();
      return groupId;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Create a group expense
  Future<String?> createGroupExpense({
    required String groupId,
    required String title,
    required String description,
    required double totalAmount,
    required String paidBy,
    required String paidByName,
    required SplitType splitType,
    required List<ExpenseSplit> splits,
    String? category,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final expense = GroupExpenseModel(
        id: '', // Will be set by repository
        groupId: groupId,
        title: title,
        description: description,
        totalAmount: totalAmount,
        paidBy: paidBy,
        paidByName: paidByName,
        splitType: splitType,
        splits: splits,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        category: category,
      );

      final expenseId = await _groupRepository.createGroupExpense(expense);

      _isLoading = false;
      notifyListeners();
      return expenseId;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Update expense status
  Future<void> updateExpenseStatus(String expenseId, ExpenseStatus status) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _groupRepository.updateExpenseStatus(expenseId, status);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Update split status
  Future<void> updateSplitStatus(
    String expenseId,
    String userId,
    ExpenseStatus status,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Update split status in expense
      await _groupRepository.updateSplitStatus(expenseId, userId, status);

      // If settled, create transactions for both participants
      if (status == ExpenseStatus.settled) {
        // Find the expense in current cache
        final expense = _groupExpenses.firstWhere((e) => e.id == expenseId, orElse: () =>
            _pendingExpenses.firstWhere((e) => e.id == expenseId));

        final split = expense.splits.firstWhere((s) => s.userId == userId);
        final payerId = expense.paidBy;
        final participantId = userId;
        final amount = split.amount;

        final now = DateTime.now();

        // Debit transaction for participant (money out)
        await _txRepository.createTransaction(TransactionModel(
          id: '',
          userId: participantId,
          title: 'Paid to ${expense.paidByName}',
          description: 'Settlement for ${expense.title}',
          amount: amount,
          type: TransactionType.expense,
          category: TransactionCategory.groupExpense,
          date: now,
          createdAt: now,
          groupId: expense.groupId,
          groupExpenseId: expense.id,
          relatedUserId: payerId,
        ));

        // Credit transaction for payer (money in)
        await _txRepository.createTransaction(TransactionModel(
          id: '',
          userId: payerId,
          title: 'Received from ${split.userName}',
          description: 'Settlement for ${expense.title}',
          amount: amount,
          type: TransactionType.income,
          category: TransactionCategory.groupExpense,
          date: now,
          createdAt: now,
          groupId: expense.groupId,
          groupExpenseId: expense.id,
          relatedUserId: participantId,
        ));
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Calculate splits based on type
  List<ExpenseSplit> calculateSplits({
    required List<String> memberIds,
    required Map<String, String> memberNames,
    required double totalAmount,
    required SplitType splitType,
    Map<String, double>? customAmounts,
    Map<String, double>? shares,
    Map<String, double>? percentages,
  }) {
    List<ExpenseSplit> splits = [];

    switch (splitType) {
      case SplitType.even:
        final amountPerPerson = totalAmount / memberIds.length;
        for (String memberId in memberIds) {
          splits.add(ExpenseSplit(
            userId: memberId,
            userName: memberNames[memberId] ?? '',
            amount: amountPerPerson,
          ));
        }
        break;

      case SplitType.amount:
        if (customAmounts != null) {
          for (String memberId in memberIds) {
            final amount = customAmounts[memberId] ?? 0.0;
            splits.add(ExpenseSplit(
              userId: memberId,
              userName: memberNames[memberId] ?? '',
              amount: amount,
            ));
          }
        }
        break;

      case SplitType.share:
        if (shares != null) {
          final totalShares = shares.values.fold(0.0, (double sum, double share) => sum + share);
          for (String memberId in memberIds) {
            final share = shares[memberId] ?? 0.0;
            final double amount = totalShares == 0.0 ? 0.0 : (share / totalShares) * totalAmount;
            splits.add(ExpenseSplit(
              userId: memberId,
              userName: memberNames[memberId] ?? '',
              amount: amount,
              share: share,
            ));
          }
        }
        break;

      case SplitType.percentage:
        if (percentages != null) {
          for (String memberId in memberIds) {
            final percentage = percentages[memberId] ?? 0.0;
            final amount = (percentage / 100) * totalAmount;
            splits.add(ExpenseSplit(
              userId: memberId,
              userName: memberNames[memberId] ?? '',
              amount: amount,
              percentage: percentage,
            ));
          }
        }
        break;
    }

    return splits;
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear data
  void clearData() {
    _groups.clear();
    _allUsers.clear();
    _groupExpenses.clear();
    _pendingExpenses.clear();
    _error = null;
    notifyListeners();
  }
}
