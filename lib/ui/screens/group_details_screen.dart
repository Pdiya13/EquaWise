import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../viewmodels/groups_view_model.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../models/group_model.dart';
import '../../models/group_expense_model.dart';
import '../../repositories/group_repository.dart';

class GroupDetailsScreen extends StatefulWidget {
  final String groupId;

  const GroupDetailsScreen({super.key, required this.groupId});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  GroupModel? _group;
  final GroupRepository _repo = GroupRepository();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<GroupsViewModel>();
      final authVm = context.read<AuthViewModel>();
      
      vm.loadGroupExpenses(widget.groupId);
      if (authVm.currentUser != null) {
        vm.loadPendingExpenses(authVm.currentUser!.uid);
      }
      _group = await _repo.getGroup(widget.groupId);
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_group?.name ?? 'Group'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      body: Consumer2<GroupsViewModel, AuthViewModel>(
        builder: (context, vm, authVm, _) {
          if (vm.isLoading && vm.groupExpenses.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentUserId = authVm.currentUser?.uid ?? '';
          final pendingCount = _getPendingCountForUser(vm.groupExpenses, currentUserId);

          return Column(
            children: [
              if (_group != null)
                _GroupHeader(group: _group!),
              
              // Pending splits summary
              if (pendingCount > 0)
                _PendingSplitsCard(
                  pendingCount: pendingCount,
                  onTap: () => context.push('/pending-splits/${widget.groupId}'),
                ),
              
              // Expenses list
              Expanded(
                child: vm.groupExpenses.isEmpty
                    ? const Center(child: Text('No expenses yet'))
                    : ListView.builder(
                        itemCount: vm.groupExpenses.length,
                        itemBuilder: (context, index) {
                          final expense = vm.groupExpenses[index];
                          return _ExpenseTile(expense: expense);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/split-expense/${widget.groupId}'),
        icon: const Icon(Icons.call_split),
        label: const Text('Split an expense'),
      ),
    );
  }

  int _getPendingCountForUser(List<GroupExpenseModel> expenses, String userId) {
    int count = 0;
    for (final expense in expenses) {
      // Count only cases where YOU need to pay (exclude items where others owe you)
      for (final split in expense.splits) {
        if (split.userId == userId && split.status == ExpenseStatus.pending && expense.paidBy != userId) {
          count++;
        }
      }
    }
    return count;
  }
}

class _PendingSplitsCard extends StatelessWidget {
  final int pendingCount;
  final VoidCallback onTap;

  const _PendingSplitsCard({
    required this.pendingCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange.shade50,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.pending_actions,
                color: Colors.orange.shade700,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pending Splits',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    Text(
                      '$pendingCount pending payment${pendingCount == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.orange.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.orange.shade700,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final GroupModel group;

  const _GroupHeader({required this.group});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            if (group.description.isNotEmpty)
              Text(
                group.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: group.memberIds
                  .map((id) => Chip(
                        label: Text(group.memberNames[id] ?? id),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final GroupExpenseModel expense;

  const _ExpenseTile({required this.expense});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.receipt_long),
      title: Text(expense.title),
      subtitle: Text('${expense.paidByName} • ${expense.splitType.name}'),
      trailing: Text('₹${expense.totalAmount.toStringAsFixed(2)}'),
    );
  }
}
