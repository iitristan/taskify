class Reminder {
  final int? id;
  final int todoId;
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
      'id': id,
      'todoId': todoId,
      'reminderTime': reminderTime.toIso8601String(),
      'isRepeating': isRepeating ? 1 : 0,
      'repeatType': repeatType,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'],
      todoId: map['todoId'],
      reminderTime: DateTime.parse(map['reminderTime']),
      isRepeating: map['isRepeating'] == 1,
      repeatType: map['repeatType'],
    );
  }
}
