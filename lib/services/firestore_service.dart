import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  static const String _usersCollection = 'users';
  // static const String _transactionsCollection = 'transactions';
  // static const String _groupsCollection = 'groups';
  // static const String _budgetsCollection = 'budgets';

  // User operations
  static Future<void> createUser(UserModel user) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .set(user.toMap());
      print('User created successfully: ${user.uid}');
    } catch (e) {
      print('Error creating user: $e');
      throw Exception('Failed to create user: $e');
    }
  }

  static Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();

      if (doc.exists) {
        return UserModel.fromSnapshot(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      throw Exception('Failed to get user: $e');
    }
  }

  static Future<void> updateUser(UserModel user) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .update(user.toMap());
      print('User updated successfully: ${user.uid}');
    } catch (e) {
      print('Error updating user: $e');
      throw Exception('Failed to update user: $e');
    }
  }

  static Future<void> updateUserLastLogin(String uid) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'lastLoginAt': Timestamp.fromDate(DateTime.now()),
      });
      print('User last login updated: $uid');
    } catch (e) {
      print('Error updating last login: $e');
      throw Exception('Failed to update last login: $e');
    }
  }

  static Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).delete();
      print('User deleted successfully: $uid');
    } catch (e) {
      print('Error deleting user: $e');
      throw Exception('Failed to delete user: $e');
    }
  }

  // Stream to listen to user changes
  static Stream<UserModel?> getUserStream(String uid) {
    return _firestore.collection(_usersCollection).doc(uid).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists) {
        return UserModel.fromSnapshot(snapshot);
      }
      return null;
    });
  }

  // Get all users (for admin purposes)
  static Stream<List<UserModel>> getAllUsers() {
    return _firestore.collection(_usersCollection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromSnapshot(doc)).toList();
    });
  }

  // Check if user exists
  static Future<bool> userExists(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      return doc.exists;
    } catch (e) {
      print('Error checking user existence: $e');
      return false;
    }
  }

  // Update user balance
  static Future<void> updateUserBalance(String uid, double newBalance) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'totalBalance': newBalance,
      });
      print('User balance updated: $uid -> $newBalance');
    } catch (e) {
      print('Error updating user balance: $e');
      throw Exception('Failed to update user balance: $e');
    }
  }

  // Add group to user
  static Future<void> addGroupToUser(String uid, String groupId) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'groupIds': FieldValue.arrayUnion([groupId]),
      });
      print('Group added to user: $uid -> $groupId');
    } catch (e) {
      print('Error adding group to user: $e');
      throw Exception('Failed to add group to user: $e');
    }
  }

  // Remove group from user
  static Future<void> removeGroupFromUser(String uid, String groupId) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'groupIds': FieldValue.arrayRemove([groupId]),
      });
      print('Group removed from user: $uid -> $groupId');
    } catch (e) {
      print('Error removing group from user: $e');
      throw Exception('Failed to remove group from user: $e');
    }
  }
}
