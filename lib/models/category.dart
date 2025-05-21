import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String? id;
  final String userId;
  final String name;
  final IconData icon;
  final Color color;

  const Category({
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
      icon: _getIconFromCodePoint(data['icon'] ?? Icons.folder.codePoint),
      color: Color(data['color'] ?? Colors.blue.value),
    );
  }

  static IconData _getIconFromCodePoint(int codePoint) {
    // Common Material Icons
    switch (codePoint) {
      case 0xe2c7: // folder
        return Icons.folder;
      case 0xe88a: // work
        return Icons.work;
      case 0xe87c: // home
        return Icons.home;
      case 0xe8d6: // school
        return Icons.school;
      case 0xe8f9: // shopping_cart
        return Icons.shopping_cart;
      case 0xe8b8: // local_hospital
        return Icons.local_hospital;
      case 0xe8f6: // sports
        return Icons.sports;
      case 0xe8b6: // local_grocery_store
        return Icons.local_grocery_store;
      case 0xe8a1: // favorite
        return Icons.favorite;
      case 0xe8b8: // star
        return Icons.star;
      default:
        return Icons.folder;
    }
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
