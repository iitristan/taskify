import 'package:flutter/material.dart';

class TaskCategory {
  final int? id;
  final String name;
  final Color color;
  final IconData icon;

  TaskCategory({
    this.id,
    required this.name,
    required this.color,
    required this.icon,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color.value,
      'icon': icon.codePoint,
    };
  }

  factory TaskCategory.fromMap(Map<String, dynamic> map) {
    return TaskCategory(
      id: map['id'],
      name: map['name'],
      color: Color(map['color']),
      icon: IconData(map['icon'], fontFamily: 'MaterialIcons'),
    );
  }
}
