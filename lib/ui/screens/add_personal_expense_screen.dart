import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// import '../../viewmodels/transactions_view_model.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../models/transaction_model.dart';
import '../../repositories/transaction_repository.dart';

class AddPersonalExpenseScreen extends StatefulWidget {
  const AddPersonalExpenseScreen({super.key});

  @override
  State<AddPersonalExpenseScreen> createState() => _AddPersonalExpenseScreenState();
}

class _AddPersonalExpenseScreenState extends State<AddPersonalExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  TransactionCategory _selectedCategory = TransactionCategory.food;
  final TransactionRepository _transactionRepository = TransactionRepository();

  final List<TransactionCategory> _personalCategories = [
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
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Personal Expense'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Expense title field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Expense Title',
                  hintText: 'Enter expense title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an expense title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Amount field
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: 'Enter amount',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category dropdown
              DropdownButtonFormField<TransactionCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _personalCategories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Icon(_getCategoryIcon(category)),
                        const SizedBox(width: 8),
                        Text(_getCategoryName(category)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Enter description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Add expense button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addExpense,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Expense'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authViewModel = context.read<AuthViewModel>();
    // final transactionsViewModel = context.read<TransactionsViewModel>();

    if (authViewModel.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to add an expense'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.parse(_amountController.text.trim());
    final now = DateTime.now();

    final transaction = TransactionModel(
      id: '', // Will be set by repository
      userId: authViewModel.currentUser!.uid,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      amount: amount,
      type: TransactionType.expense,
      category: _selectedCategory,
      date: now,
      createdAt: now,
    );

    try {
      await _transactionRepository.createTransaction(transaction);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add expense: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
      case TransactionCategory.other:
        return Icons.category;
      default:
        return Icons.category;
    }
  }

  String _getCategoryName(TransactionCategory category) {
    switch (category) {
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
      case TransactionCategory.other:
        return 'Other';
      default:
        return 'Other';
    }
  }
}
