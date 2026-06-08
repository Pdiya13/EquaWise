import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/groups_view_model.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../models/group_expense_model.dart';
import '../../services/payment_service.dart';
import '../../utils/constants.dart';

class PendingSplitsScreen extends StatefulWidget {
  final String groupId;

  const PendingSplitsScreen({super.key, required this.groupId});

  @override
  State<PendingSplitsScreen> createState() => _PendingSplitsScreenState();
}

class _PendingSplitsScreenState extends State<PendingSplitsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = context.read<AuthViewModel>();
      final groupsViewModel = context.read<GroupsViewModel>();
      
      // Ensure we have the latest expenses for this group
      groupsViewModel.loadGroupExpenses(widget.groupId);
      // Also keep user-wide pending in sync (not relied upon for UI anymore)
      if (authViewModel.currentUser != null) {
        groupsViewModel.loadPendingExpenses(authViewModel.currentUser!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Splits'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      body: Consumer2<GroupsViewModel, AuthViewModel>(
        builder: (context, groupsViewModel, authViewModel, child) {
          if (groupsViewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Build from this group's expenses so both cases are included:
          //  - positive amount  -> you owe someone
          //  - negative amount  -> others owe you
          final currentUserId = authViewModel.currentUser?.uid ?? '';
          final userSplits =
              _getUserSplits(groupsViewModel.groupExpenses, currentUserId);

          if (userSplits.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64),
                  SizedBox(height: 16),
                  Text('No pending splits'),
                  Text('All caught up!'),
                ],
              ),
            );
          }

          return Column(
            children: [
              _buildSummaryCard(context, userSplits),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: userSplits.length,
                  itemBuilder: (context, index) {
                    final split = userSplits[index];
                    return _SplitCard(
                      split: split,
                      onSettle: () => _payAndSettle(groupsViewModel, split, authViewModel),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, List<UserSplit> userSplits) {
    final totalOwed = userSplits
        .where((split) => split.amount > 0)
        .fold(0.0, (sum, split) => sum + split.amount);
    
    final totalOwedToMe = userSplits
        .where((split) => split.amount < 0)
        .fold(0.0, (sum, split) => sum + split.amount.abs());

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryItem(
                  title: 'You Owe',
                  amount: totalOwed,
                  color: Colors.red,
                  icon: Icons.arrow_upward,
                ),
                _SummaryItem(
                  title: 'Owed to You',
                  amount: totalOwedToMe,
                  color: Colors.green,
                  icon: Icons.arrow_downward,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<UserSplit> _getUserSplits(List<GroupExpenseModel> expenses, String currentUserId) {
    List<UserSplit> splits = [];
    
    for (final expense in expenses) {
      // Case 1: You owe someone else (their expense includes your pending split)
      for (final split in expense.splits) {
        if (split.userId == currentUserId &&
            split.status == ExpenseStatus.pending &&
            expense.paidBy != currentUserId) {
          splits.add(UserSplit(
            expenseId: expense.id,
            expenseTitle: expense.title,
            counterpartyName: expense.paidByName,
            amount: split.amount, // positive -> you owe
            splitType: expense.splitType,
            createdAt: expense.createdAt,
            userId: split.userId,
          ));
        }
      }

      // Case 2: Others owe you (you are the payer and their split is pending)
      if (expense.paidBy == currentUserId) {
        for (final split in expense.splits) {
          if (split.userId != currentUserId &&
              split.status == ExpenseStatus.pending) {
            splits.add(UserSplit(
              expenseId: expense.id,
              expenseTitle: expense.title,
              counterpartyName: split.userName,
              amount: -split.amount, // negative -> owed to you
              splitType: expense.splitType,
              createdAt: expense.createdAt,
              userId: split.userId,
            ));
          }
        }
      }
    }
    
    // Sort by creation date (newest first)
    splits.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return splits;
  }

  Future<void> _payAndSettle(GroupsViewModel groupsViewModel, UserSplit split, AuthViewModel authVm) async {
    // Only trigger payment for positive amounts (you owe). For "owed to you"
    // entries (negative amounts) we don't open Razorpay.
    if (split.amount <= 0) {
      return;
    }
    // Initialize Razorpay once with callbacks
    PaymentService.instance.initialize(
      onSuccess: (paymentId) async {
        await groupsViewModel.updateSplitStatus(
          split.expenseId,
          split.userId,
          ExpenseStatus.settled,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment successful and settled!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      onError: (code, message) async {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment failed ($code): $message'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );

    // Open payment sheet
    PaymentService.instance.pay(
      key: AppSecrets.razorpayKey,
      amountInRupees: split.amount.abs(),
      name: split.counterpartyName,
      description: split.expenseTitle,
      prefillEmail: authVm.currentUser?.email,
      upiOnly: true,
    );
  }
}

class UserSplit {
  final String expenseId;
  final String expenseTitle;
  final String counterpartyName; // the other person in this split relative to current user
  final double amount;
  final SplitType splitType;
  final DateTime createdAt;
  final String userId;

  UserSplit({
    required this.expenseId,
    required this.expenseTitle,
    required this.counterpartyName,
    required this.amount,
    required this.splitType,
    required this.createdAt,
    required this.userId,
  });
}

class _SummaryItem extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryItem({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _SplitCard extends StatelessWidget {
  final UserSplit split;
  final VoidCallback onSettle;

  const _SplitCard({
    required this.split,
    required this.onSettle,
  });

  @override
  Widget build(BuildContext context) {
    final isOwed = split.amount > 0; // you owe if positive; owed to you if negative
    final color = isOwed ? Colors.red : Colors.green;
    final icon = isOwed ? Icons.arrow_upward : Icons.arrow_downward;
    final actionText = isOwed ? 'Pay Now' : 'Waiting';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    split.expenseTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '₹${split.amount.abs().toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isOwed 
                  ? 'You owe ${split.counterpartyName}'
                  : '${split.counterpartyName} owes you',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Split: ${split.splitType.name} • ${_formatDate(split.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: isOwed
                  ? ElevatedButton.icon(
                      onPressed: onSettle,
                      icon: const Icon(Icons.check),
                      label: Text(actionText),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                      ),
                    )
                  : OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.hourglass_bottom),
                      label: Text(actionText),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
