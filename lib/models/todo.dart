class Todo {
  final int? id;
  final String title;
  final String description;
  final DateTime dueDate;
  bool isCompleted;
  final String priority;
  final int? categoryId;
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
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
      'priority': priority,
      'categoryId': categoryId,
      'categoryName': categoryName,
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dueDate: DateTime.parse(map['dueDate']),
      isCompleted: map['isCompleted'] == 1,
      priority: map['priority'] ?? 'Medium',
      categoryId: map['categoryId'],
      categoryName: map['categoryName'] ?? 'Default',
    );
  }

  Todo copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    String? priority,
    int? categoryId,
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
}
