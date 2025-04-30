import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Todo {
  final String id;
  String title;
  String? description;
  bool isCompleted;
  DateTime createdAt;
  DateTime? updatedAt;

  Todo({
    required this.title,
    this.description,
    String? id,
    bool? isCompleted,
    DateTime? createdAt,
    this.updatedAt,
  })  : id = id ?? const Uuid().v4(),
        isCompleted = isCompleted ?? false,
        createdAt = createdAt ?? DateTime.now();

  // Create from JSON (for Firestore)
  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      isCompleted: json['isCompleted'] ?? false,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: json['updatedAt'] != null 
          ? (json['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  // Convert to JSON (for Firestore)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Create a copy with updated fields
  Todo copyWith({
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? updatedAt,
  }) {
    return Todo(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
} 