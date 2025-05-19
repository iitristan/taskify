import 'package:flutter/material.dart';

class Category {
  final String? id;
  final String name;
  final Color color;
  final IconData icon;

  Category({
    this.id,
    required this.name,
    required this.color,
    required this.icon,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'color': color.value,
      'icon': icon.codePoint,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map, String docId) {
    return Category(
      id: docId,
      name: map['name'] ?? '',
      color: Color(map['color'] ?? 0xFF000000),
      icon: IconData(map['icon'] ?? 0, fontFamily: 'MaterialIcons'),
    );
  }

  Category copyWith({
    String? id,
    String? name,
    Color? color,
    IconData? icon,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }
}
