import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Todo {
  final String? id;
  final String title;
  final String description;
  final DateTime dueDate;
  bool isCompleted;
  final String priority;
  final String? categoryId;
  final String categoryName;

  Todo({
    this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    this.isCompleted = false,
    this.priority = 'Medium',
    this.categoryId,
    this.categoryName = 'Default',
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'isCompleted': isCompleted,
      'priority': priority,
      'categoryId': categoryId,
      'categoryName': categoryName,
    };
  }

  factory Todo.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Todo(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      isCompleted: data['isCompleted'] ?? false,
      priority: data['priority'] ?? 'Medium',
      categoryId: data['categoryId'],
      categoryName: data['categoryName'] ?? 'Default',
    );
  }

  Todo copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    String? priority,
    String? categoryId,
    String? categoryName,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
    );
  }

  @override
  String toString() {
    return 'Todo(id: $id, title: $title, dueDate: $dueDate, priority: $priority)';
  }
}
