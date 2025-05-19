import 'package:cloud_firestore/cloud_firestore.dart';

class Reminder {
  final String? id;
  final String todoId;
  final DateTime reminderTime;
  final bool isRepeating;
  final String repeatType; // daily, weekly, monthly

  Reminder({
    this.id,
    required this.todoId,
    required this.reminderTime,
    this.isRepeating = false,
    this.repeatType = 'none',
  });

  Map<String, dynamic> toMap() {
    return {
      'todoId': todoId,
      'reminderTime': Timestamp.fromDate(reminderTime),
      'isRepeating': isRepeating,
      'repeatType': repeatType,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map, String docId) {
    return Reminder(
      id: docId,
      todoId: map['todoId'] ?? '',
      reminderTime: (map['reminderTime'] as Timestamp).toDate(),
      isRepeating: map['isRepeating'] ?? false,
      repeatType: map['repeatType'] ?? 'none',
    );
  }

  Reminder copyWith({
    String? id,
    String? todoId,
    DateTime? reminderTime,
    bool? isRepeating,
    String? repeatType,
  }) {
    return Reminder(
      id: id ?? this.id,
      todoId: todoId ?? this.todoId,
      reminderTime: reminderTime ?? this.reminderTime,
      isRepeating: isRepeating ?? this.isRepeating,
      repeatType: repeatType ?? this.repeatType,
    );
  }
}
