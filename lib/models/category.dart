import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String? id;
  final String userId;
  final String name;
  final IconData icon;
  final Color color;

  Category({
    this.id,
    required this.userId,
    required this.name,
    required this.icon,
    required this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'icon': icon.codePoint,
      'color': color.value,
    };
  }

  factory Category.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Category(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      icon: IconData(
        data['icon'] ?? Icons.folder.codePoint,
        fontFamily: 'MaterialIcons',
      ),
      color: Color(data['color'] ?? Colors.blue.value),
    );
  }

  Category copyWith({
    String? id,
    String? userId,
    String? name,
    IconData? icon,
    Color? color,
  }) {
    return Category(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }

  @override
  String toString() {
    return 'Category(id: $id, userId: $userId, name: $name)';
  }
}
