import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  income,
  expense,
  groupSettlement,
}

enum TransactionCategory {
  food,
  transport,
  entertainment,
  shopping,
  bills,
  healthcare,
  education,
  travel,
  other,
  groupExpense,
  // Personal expense categories
  health,
  donation,
  party,
  repairing,
  movie,
  household,
  sports,
}

class TransactionModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final DateTime date;
  final DateTime createdAt;
  final String? groupId;
  final String? groupExpenseId;
  final String? relatedUserId; // For group settlements
  final String? receiptUrl;
  final Map<String, dynamic> metadata;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    required this.createdAt,
    this.groupId,
    this.groupExpenseId,
    this.relatedUserId,
    this.receiptUrl,
    this.metadata = const {},
  });

  // Convert TransactionModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'amount': amount,
      'type': type.name,
      'category': category.name,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
      'groupId': groupId,
      'groupExpenseId': groupExpenseId,
      'relatedUserId': relatedUserId,
      'receiptUrl': receiptUrl,
      'metadata': metadata,
    };
  }

  // Create TransactionModel from Firestore document
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      category: TransactionCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => TransactionCategory.other,
      ),
      date: (map['date'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      groupId: map['groupId'],
      groupExpenseId: map['groupExpenseId'],
      relatedUserId: map['relatedUserId'],
      receiptUrl: map['receiptUrl'],
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  // Create TransactionModel from Firestore document snapshot
  factory TransactionModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return TransactionModel.fromMap(data);
  }

  // Copy with method for updates
  TransactionModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    double? amount,
    TransactionType? type,
    TransactionCategory? category,
    DateTime? date,
    DateTime? createdAt,
    String? groupId,
    String? groupExpenseId,
    String? relatedUserId,
    String? receiptUrl,
    Map<String, dynamic>? metadata,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      groupId: groupId ?? this.groupId,
      groupExpenseId: groupExpenseId ?? this.groupExpenseId,
      relatedUserId: relatedUserId ?? this.relatedUserId,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'TransactionModel(id: $id, title: $title, amount: $amount, type: $type, date: $date)';
  }
}
