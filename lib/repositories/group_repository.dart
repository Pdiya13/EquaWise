import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/group_model.dart';
import '../models/group_expense_model.dart';
import '../models/user_model.dart';

class GroupRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Create a new group
  Future<String> createGroup({
    required String name,
    required String description,
    required String createdBy,
    required List<String> memberIds,
    required Map<String, String> memberNames,
  }) async {
    final groupId = _uuid.v4();
    final now = DateTime.now();

    final group = GroupModel(
      id: groupId,
      name: name,
      description: description,
      createdBy: createdBy,
      memberIds: memberIds,
      memberNames: memberNames,
      createdAt: now,
      updatedAt: now,
    );

    // Add group to groups collection
    await _firestore.collection('groups').doc(groupId).set(group.toMap());

    // Update user documents to include the new group
    for (String memberId in memberIds) {
      await _firestore.collection('users').doc(memberId).update({
        'groupIds': FieldValue.arrayUnion([groupId]),
      });
    }

    return groupId;
  }

  // Get all groups for a user
  Stream<List<GroupModel>> getUserGroups(String userId) {
    return _firestore
        .collection('groups')
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final groups = snapshot.docs
              .map((doc) => GroupModel.fromSnapshot(doc))
              .toList();
          groups.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return groups;
        });
  }

  // Get a specific group
  Future<GroupModel?> getGroup(String groupId) async {
    final doc = await _firestore.collection('groups').doc(groupId).get();
    if (doc.exists) {
      return GroupModel.fromSnapshot(doc);
    }
    return null;
  }

  // Get all users from database
  Stream<List<UserModel>> getAllUsers() {
    return _firestore
        .collection('users')
        .orderBy('displayName')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromSnapshot(doc))
            .toList());
  }

  // Update group
  Future<void> updateGroup(GroupModel group) async {
    await _firestore.collection('groups').doc(group.id).update({
      ...group.toMap(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Delete group
  Future<void> deleteGroup(String groupId) async {
    // Remove group from all users' groupIds
    final group = await getGroup(groupId);
    if (group != null) {
      for (String memberId in group.memberIds) {
        await _firestore.collection('users').doc(memberId).update({
          'groupIds': FieldValue.arrayRemove([groupId]),
        });
      }
    }

    // Delete group document
    await _firestore.collection('groups').doc(groupId).delete();

    // Delete all expenses for this group
    final expenses = await _firestore
        .collection('group_expenses')
        .where('groupId', isEqualTo: groupId)
        .get();
    
    for (var doc in expenses.docs) {
      await doc.reference.delete();
    }
  }

  // Create a group expense
  Future<String> createGroupExpense(GroupExpenseModel expense) async {
    final expenseId = _uuid.v4();
    final now = DateTime.now();

    final expenseWithId = expense.copyWith(
      id: expenseId,
      createdAt: now,
      updatedAt: now,
    );

    await _firestore
        .collection('group_expenses')
        .doc(expenseId)
        .set(expenseWithId.toMap());

    return expenseId;
  }

  // Get all expenses for a group
  Stream<List<GroupExpenseModel>> getGroupExpenses(String groupId) {
    return _firestore
        .collection('group_expenses')
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((snapshot) {
          final expenses = snapshot.docs
              .map((doc) => GroupExpenseModel.fromSnapshot(doc))
              .toList();
          expenses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return expenses;
        });
  }

  // Update expense status
  Future<void> updateExpenseStatus(String expenseId, ExpenseStatus status) async {
    await _firestore.collection('group_expenses').doc(expenseId).update({
      'status': status.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Update split status for a specific user
  Future<void> updateSplitStatus(
    String expenseId,
    String userId,
    ExpenseStatus status,
  ) async {
    final expenseDoc = await _firestore
        .collection('group_expenses')
        .doc(expenseId)
        .get();

    if (expenseDoc.exists) {
      final expense = GroupExpenseModel.fromSnapshot(expenseDoc);
      final updatedSplits = expense.splits.map((split) {
        if (split.userId == userId) {
          return split.copyWith(
            status: status,
            paidAt: status == ExpenseStatus.settled ? DateTime.now() : null,
          );
        }
        return split;
      }).toList();

      await _firestore.collection('group_expenses').doc(expenseId).update({
        'splits': updatedSplits.map((split) => split.toMap()).toList(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    }
  }

  // Get user's pending expenses
  Stream<List<GroupExpenseModel>> getUserPendingExpenses(String userId) {
    return _firestore
        .collection('group_expenses')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => GroupExpenseModel.fromSnapshot(doc))
              .where((expense) => expense.splits.any(
                  (split) => split.userId == userId && split.status == ExpenseStatus.pending))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }
}
