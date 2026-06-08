import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/group_model.dart';
import '../../models/group_expense_model.dart';
import '../../viewmodels/groups_view_model.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../repositories/group_repository.dart';

class SplitExpenseScreen extends StatefulWidget {
  final String groupId;

  const SplitExpenseScreen({super.key, required this.groupId});

  @override
  State<SplitExpenseScreen> createState() => _SplitExpenseScreenState();
}

class _SplitExpenseScreenState extends State<SplitExpenseScreen>
    with SingleTickerProviderStateMixin {
  final _amountController = TextEditingController();
  final _titleController = TextEditingController(text: 'Expense');
  final Map<String, TextEditingController> _amountControllers = {};
  final Map<String, TextEditingController> _shareControllers = {};
  final Map<String, TextEditingController> _percentageControllers = {};

  final GroupRepository _repo = GroupRepository();
  GroupModel? _group;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _group = await _repo.getGroup(widget.groupId);
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    for (final c in _amountControllers.values) c.dispose();
    for (final c in _shareControllers.values) c.dispose();
    for (final c in _percentageControllers.values) c.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Expense'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Evenly'),
            Tab(text: 'Amount'),
            Tab(text: 'Shares'),
            Tab(text: 'Percent'),
          ],
        ),
      ),
      body: _group == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Total amount',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildEvenlyTab(),
                      _buildAmountTab(),
                      _buildSharesTab(),
                      _buildPercentTab(),
                    ],
                  ),
                ),
                SafeArea(
                  minimum: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _sendRequest,
                      child: const Text('Send request'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMemberList(
    Map<String, Widget> trailingBuilder,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final uid = _group!.memberIds[index];
        final name = _group!.memberNames[uid] ?? uid;
        return ListTile(
          leading: CircleAvatar(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?')),
          title: Text(name),
          trailing: SizedBox(width: 160, child: trailingBuilder[uid]),
        );
      },
      separatorBuilder: (_, __) => const Divider(height: 0),
      itemCount: _group!.memberIds.length,
    );
  }

  Widget _buildEvenlyTab() {
    return _buildMemberList({for (final id in _group!.memberIds) id: const Text('Even split')});
  }

  Widget _buildAmountTab() {
    for (final id in _group!.memberIds) {
      _amountControllers.putIfAbsent(id, () => TextEditingController());
    }
    return _buildMemberList({
      for (final id in _group!.memberIds)
        id: TextField(
          controller: _amountControllers[id],
          textAlign: TextAlign.right,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: 'Amount'),
        )
    });
  }

  Widget _buildSharesTab() {
    for (final id in _group!.memberIds) {
      _shareControllers.putIfAbsent(id, () => TextEditingController());
    }
    return _buildMemberList({
      for (final id in _group!.memberIds)
        id: TextField(
          controller: _shareControllers[id],
          textAlign: TextAlign.right,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Shares'),
        )
    });
  }

  Widget _buildPercentTab() {
    for (final id in _group!.memberIds) {
      _percentageControllers.putIfAbsent(id, () => TextEditingController());
    }
    return _buildMemberList({
      for (final id in _group!.memberIds)
        id: TextField(
          controller: _percentageControllers[id],
          textAlign: TextAlign.right,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(suffixText: '%'),
        )
    });
  }

  Future<void> _sendRequest() async {
    final vm = context.read<GroupsViewModel>();
    final auth = context.read<AuthViewModel>();

    final totalAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    final splitType = _tabController.index == 0
        ? SplitType.even
        : _tabController.index == 1
            ? SplitType.amount
            : _tabController.index == 2
                ? SplitType.share
                : SplitType.percentage;

    Map<String, double>? customAmounts;
    Map<String, double>? shares;
    Map<String, double>? percentages;

    if (splitType == SplitType.amount) {
      customAmounts = {
        for (final id in _group!.memberIds)
          id: double.tryParse(_amountControllers[id]?.text.trim() ?? '') ?? 0.0
      };
    } else if (splitType == SplitType.share) {
      shares = {
        for (final id in _group!.memberIds)
          id: double.tryParse(_shareControllers[id]?.text.trim() ?? '') ?? 0.0
      };
    } else if (splitType == SplitType.percentage) {
      percentages = {
        for (final id in _group!.memberIds)
          id: double.tryParse(_percentageControllers[id]?.text.trim() ?? '') ?? 0.0
      };
    }

    final splits = vm.calculateSplits(
      memberIds: _group!.memberIds,
      memberNames: _group!.memberNames,
      totalAmount: totalAmount,
      splitType: splitType,
      customAmounts: customAmounts,
      shares: shares,
      percentages: percentages,
    );

    final expenseId = await vm.createGroupExpense(
      groupId: widget.groupId,
      title: _titleController.text.trim(),
      description: '',
      totalAmount: totalAmount,
      paidBy: auth.currentUser?.uid ?? '',
      paidByName: auth.currentUser?.displayName ?? auth.currentUser?.email ?? 'Unknown',
      splitType: splitType,
      splits: splits,
    );

    if (expenseId != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request sent')),
      );
      Navigator.of(context).pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${vm.error ?? 'Unknown error'}')),
      );
    }
  }
}
