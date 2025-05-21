import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Todo {
  final String? id;
  final String userId;
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
  final String status;

  Todo({
    this.id,
    required this.userId,
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
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'isCompleted': isCompleted,
      'priority': priority,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'isRecurring': isRecurring,
      'recurrenceType': recurrenceType,
      'recurrenceEndDate':
          recurrenceEndDate != null
              ? Timestamp.fromDate(recurrenceEndDate!)
              : null,
      'status': status,
    };
  }

  factory Todo.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Todo(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      isCompleted: data['isCompleted'] ?? false,
      priority: data['priority'] ?? 'Medium',
      categoryId: data['categoryId'],
      categoryName: data['categoryName'] ?? 'Default',
      isRecurring: data['isRecurring'] ?? false,
      recurrenceType: data['recurrenceType'],
      recurrenceEndDate:
          data['recurrenceEndDate'] != null
              ? (data['recurrenceEndDate'] as Timestamp).toDate()
              : null,
      status: data['status'] ?? 'pending',
    );
  }

  Todo copyWith({
    String? id,
    String? userId,
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
    String? status,
  }) {
    return Todo(
      id: id ?? this.id,
      userId: userId ?? this.userId,
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
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'Todo(id: $id, userId: $userId, title: $title, dueDate: $dueDate, priority: $priority, status: $status)';
  }
}
