import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String name;
  final String description;
  final String createdBy;
  final List<String> memberIds;
  final Map<String, String> memberNames; // uid -> displayName mapping
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? imageUrl;
  final Map<String, dynamic> settings;

  GroupModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.createdBy,
    required this.memberIds,
    required this.memberNames,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
    this.settings = const {},
  });

  // Convert GroupModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdBy': createdBy,
      'memberIds': memberIds,
      'memberNames': memberNames,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'imageUrl': imageUrl,
      'settings': settings,
    };
  }

  // Create GroupModel from Firestore document
  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      createdBy: map['createdBy'] ?? '',
      memberIds: List<String>.from(map['memberIds'] ?? []),
      memberNames: Map<String, String>.from(map['memberNames'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      imageUrl: map['imageUrl'],
      settings: Map<String, dynamic>.from(map['settings'] ?? {}),
    );
  }

  // Create GroupModel from Firestore document snapshot
  factory GroupModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return GroupModel.fromMap(data);
  }

  // Copy with method for updates
  GroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? createdBy,
    List<String>? memberIds,
    Map<String, String>? memberNames,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? imageUrl,
    Map<String, dynamic>? settings,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      memberIds: memberIds ?? this.memberIds,
      memberNames: memberNames ?? this.memberNames,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imageUrl: imageUrl ?? this.imageUrl,
      settings: settings ?? this.settings,
    );
  }

  @override
  String toString() {
    return 'GroupModel(id: $id, name: $name, memberIds: $memberIds, createdAt: $createdAt)';
  }
}

extension GroupModelFetch on GroupModel {
  static Future<GroupModel?> fetchById(String groupId) async {
    final doc = await FirebaseFirestore.instance.collection('groups').doc(groupId).get();
    if (!doc.exists) return null;
    return GroupModel.fromSnapshot(doc);
  }
}