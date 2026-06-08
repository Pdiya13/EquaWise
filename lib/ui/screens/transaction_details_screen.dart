import 'package:flutter/material.dart';

import '../../models/transaction_model.dart';
import '../../services/firestore_service.dart';
import '../../models/group_model.dart';
import '../../models/user_model.dart';

class TransactionDetailsScreen extends StatefulWidget {
  final TransactionModel transaction;

  const TransactionDetailsScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailsScreen> createState() => _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  String? _payerName;
  String? _counterpartyName;
  String? _groupName;

  @override
  void initState() {
    super.initState();
    _loadNames();
  }

  Future<void> _loadNames() async {
    try {
      final tx = widget.transaction;
      // Load payer (owner of this transaction)
      final payer = await FirestoreService.getUser(tx.userId);
      // Load counterparty (for group settlements) if present
      UserModel? counterparty;
      if (tx.relatedUserId != null && tx.relatedUserId!.isNotEmpty) {
        counterparty = await FirestoreService.getUser(tx.relatedUserId!);
      }
      // Load group name if present
      GroupModel? group;
      if (tx.groupId != null && tx.groupId!.isNotEmpty) {
        group = await GroupModelFetch.fetchById(tx.groupId!);
      }
      if (mounted) {
        setState(() {
          _payerName = payer?.displayName ?? payer?.email ?? tx.userId;
          _counterpartyName = counterparty?.displayName ?? counterparty?.email ?? tx.relatedUserId;
          _groupName = group?.name;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction;
    final isIncome = tx.type == TransactionType.income;
    final color = isIncome ? Colors.green : Colors.red;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: color.withOpacity(0.1),
                      child: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tx.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      (isIncome ? '+₹' : '-₹') + tx.amount.toStringAsFixed(2),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            _InfoTile(label: 'Category', value: tx.category.name),
            _InfoTile(label: 'Type', value: isIncome ? 'Income' : (tx.type == TransactionType.groupSettlement ? 'Group Settlement' : 'Expense')),
            _InfoTile(label: 'Date', value: _formatDate(tx.date)),
            _InfoTile(label: 'Time', value: _formatTime(tx.date)),
            if (_groupName != null && _groupName!.isNotEmpty)
              _InfoTile(label: 'Group', value: _groupName!),
            if (_payerName != null)
              _InfoTile(label: isIncome ? 'Received From' : 'Paid To', value: isIncome ? (_counterpartyName ?? '-') : (_counterpartyName ?? '-')),
            if (_payerName != null)
              _InfoTile(label: 'Your Account', value: _payerName!),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        subtitle: Text(value),
      ),
    );
  }
}


