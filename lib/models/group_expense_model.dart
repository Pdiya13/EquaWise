import 'package:cloud_firestore/cloud_firestore.dart';

enum SplitType {
  even,
  amount,
  share,
  percentage,
}

enum ExpenseStatus {
  pending,
  approved,
  rejected,
  settled,
}

class GroupExpenseModel {
  final String id;
  final String groupId;
  final String title;
  final String description;
  final double totalAmount;
  final String paidBy; // User ID who paid
  final String paidByName; // Display name of who paid
  final SplitType splitType;
  final List<ExpenseSplit> splits;
  final ExpenseStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? receiptUrl;
  final String? category;

  GroupExpenseModel({
    required this.id,
    required this.groupId,
    required this.title,
    this.description = '',
    required this.totalAmount,
    required this.paidBy,
    required this.paidByName,
    required this.splitType,
    required this.splits,
    this.status = ExpenseStatus.pending,
    required this.createdAt,
    required this.updatedAt,
    this.receiptUrl,
    this.category,
  });

  // Convert GroupExpenseModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'title': title,
      'description': description,
      'totalAmount': totalAmount,
      'paidBy': paidBy,
      'paidByName': paidByName,
      'splitType': splitType.name,
      'splits': splits.map((split) => split.toMap()).toList(),
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'receiptUrl': receiptUrl,
      'category': category,
    };
  }

  // Create GroupExpenseModel from Firestore document
  factory GroupExpenseModel.fromMap(Map<String, dynamic> map) {
    return GroupExpenseModel(
      id: map['id'] ?? '',
      groupId: map['groupId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      paidBy: map['paidBy'] ?? '',
      paidByName: map['paidByName'] ?? '',
      splitType: SplitType.values.firstWhere(
        (e) => e.name == map['splitType'],
        orElse: () => SplitType.even,
      ),
      splits: (map['splits'] as List<dynamic>?)
          ?.map((split) => ExpenseSplit.fromMap(split))
          .toList() ?? [],
      status: ExpenseStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ExpenseStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      receiptUrl: map['receiptUrl'],
      category: map['category'],
    );
  }

  // Create GroupExpenseModel from Firestore document snapshot
  factory GroupExpenseModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return GroupExpenseModel.fromMap(data);
  }

  // Copy with method for updates
  GroupExpenseModel copyWith({
    String? id,
    String? groupId,
    String? title,
    String? description,
    double? totalAmount,
    String? paidBy,
    String? paidByName,
    SplitType? splitType,
    List<ExpenseSplit>? splits,
    ExpenseStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? receiptUrl,
    String? category,
  }) {
    return GroupExpenseModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      description: description ?? this.description,
      totalAmount: totalAmount ?? this.totalAmount,
      paidBy: paidBy ?? this.paidBy,
      paidByName: paidByName ?? this.paidByName,
      splitType: splitType ?? this.splitType,
      splits: splits ?? this.splits,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      category: category ?? this.category,
    );
  }

  @override
  String toString() {
    return 'GroupExpenseModel(id: $id, title: $title, totalAmount: $totalAmount, splitType: $splitType)';
  }
}

class ExpenseSplit {
  final String userId;
  final String userName;
  final double amount;
  final double? share; // For share-based splits
  final double? percentage; // For percentage-based splits
  final ExpenseStatus status;
  final DateTime? paidAt;

  ExpenseSplit({
    required this.userId,
    required this.userName,
    required this.amount,
    this.share,
    this.percentage,
    this.status = ExpenseStatus.pending,
    this.paidAt,
  });

  // Convert ExpenseSplit to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'amount': amount,
      'share': share,
      'percentage': percentage,
      'status': status.name,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
    };
  }

  // Create ExpenseSplit from Map
  factory ExpenseSplit.fromMap(Map<String, dynamic> map) {
    return ExpenseSplit(
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      share: map['share']?.toDouble(),
      percentage: map['percentage']?.toDouble(),
      status: ExpenseStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ExpenseStatus.pending,
      ),
      paidAt: map['paidAt'] != null 
          ? (map['paidAt'] as Timestamp).toDate() 
          : null,
    );
  }

  // Copy with method for updates
  ExpenseSplit copyWith({
    String? userId,
    String? userName,
    double? amount,
    double? share,
    double? percentage,
    ExpenseStatus? status,
    DateTime? paidAt,
  }) {
    return ExpenseSplit(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      amount: amount ?? this.amount,
      share: share ?? this.share,
      percentage: percentage ?? this.percentage,
      status: status ?? this.status,
      paidAt: paidAt ?? this.paidAt,
    );
  }

  @override
  String toString() {
    return 'ExpenseSplit(userId: $userId, userName: $userName, amount: $amount, status: $status)';
  }
}
