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
  final bool isRecurring;
  final String? recurrenceType; // daily, weekly, monthly
  final DateTime? recurrenceEndDate;

  Todo({
    this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    this.isCompleted = false,
    this.priority = 'Medium',
    this.categoryId,
    this.categoryName = 'Default',
    this.isRecurring = false,
    this.recurrenceType,
    this.recurrenceEndDate,
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
      'isRecurring': isRecurring,
      'recurrenceType': recurrenceType,
      'recurrenceEndDate': recurrenceEndDate != null ? Timestamp.fromDate(recurrenceEndDate!) : null,
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
      isRecurring: data['isRecurring'] ?? false,
      recurrenceType: data['recurrenceType'],
      recurrenceEndDate: data['recurrenceEndDate'] != null ? (data['recurrenceEndDate'] as Timestamp).toDate() : null,
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
    bool? isRecurring,
    String? recurrenceType,
    DateTime? recurrenceEndDate,
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
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
    );
  }

  @override
  String toString() {
    return 'Todo(id: $id, title: $title, dueDate: $dueDate, priority: $priority)';
  }
}
