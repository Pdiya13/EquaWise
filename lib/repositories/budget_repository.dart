import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/budget_model.dart';

class BudgetRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  Stream<List<BudgetModel>> getUserBudgets(String userId) {
    return _firestore
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) => s.docs.map((d) => BudgetModel.fromSnapshot(d)).toList());
  }

  Future<String> upsertBudget({
    required String userId,
    required BudgetModel budget,
  }) async {
    String id = budget.id.isEmpty ? _uuid.v4() : budget.id;
    final now = DateTime.now();
    final withIds = budget.copyWith(
      id: id, 
      userId: userId, 
      updatedAt: now, 
      createdAt: budget.createdAt.millisecondsSinceEpoch == 0 ? now : budget.createdAt
    );
    await _firestore.collection('budgets').doc(id).set(withIds.toMap());
    return id;
  }

  Future<void> updateAmount(String budgetId, double amount) async {
    await _firestore.collection('budgets').doc(budgetId).update({
      'amount': amount,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteBudget(String budgetId) async {
    await _firestore.collection('budgets').doc(budgetId).delete();
  }
}

