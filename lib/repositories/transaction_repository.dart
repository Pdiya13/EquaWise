import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/transaction_model.dart';

class TransactionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  Future<String> createTransaction(TransactionModel tx) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final txWithIds = tx.copyWith(id: id, createdAt: now);
    await _firestore.collection('transactions').doc(id).set(txWithIds.toMap());
    return id;
  }

  Stream<List<TransactionModel>> getUserTransactions(String userId) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => TransactionModel.fromSnapshot(d)).toList();
          list.sort((a, b) => b.date.compareTo(a.date));
          return list;
        });
  }
}
