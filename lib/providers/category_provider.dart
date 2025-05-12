import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/category.dart';

class CategoryProvider with ChangeNotifier {
  List<TaskCategory> _categories = [];
  Database? _database;
  bool _isInitialized = false;

  List<TaskCategory> get categories => _categories;

  Future<void> initDatabase() async {
    if (_isInitialized) return;

    try {
      _database = await openDatabase(
        join(await getDatabasesPath(), 'category_database.db'),
        onCreate: (db, version) {
          return db.execute(
            'CREATE TABLE categories(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, color INTEGER, icon INTEGER)',
          );
        },
        version: 1,
      );
      await loadCategories();
      _isInitialized = true;
    } catch (e) {
      print('Category database initialization error: $e');
      // For web platform or when database fails, use in-memory data
      _categories = [
        TaskCategory(id: 1, name: 'Work', color: Colors.blue, icon: Icons.work),
        TaskCategory(
          id: 2,
          name: 'Personal',
          color: Colors.green,
          icon: Icons.person,
        ),
        TaskCategory(
          id: 3,
          name: 'Shopping',
          color: Colors.orange,
          icon: Icons.shopping_cart,
        ),
        TaskCategory(
          id: 4,
          name: 'Health',
          color: Colors.red,
          icon: Icons.favorite,
        ),
        TaskCategory(
          id: 5,
          name: 'Education',
          color: Colors.purple,
          icon: Icons.school,
        ),
      ];
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> loadCategories() async {
    if (_database == null) return;

    try {
      final List<Map<String, dynamic>> maps = await _database!.query(
        'categories',
      );
      if (maps.isEmpty) {
        // Add default categories if none exist
        await addCategory(
          TaskCategory(name: 'Work', color: Colors.blue, icon: Icons.work),
        );
        await addCategory(
          TaskCategory(
            name: 'Personal',
            color: Colors.green,
            icon: Icons.person,
          ),
        );
        await addCategory(
          TaskCategory(
            name: 'Shopping',
            color: Colors.orange,
            icon: Icons.shopping_cart,
          ),
        );
        await addCategory(
          TaskCategory(name: 'Health', color: Colors.red, icon: Icons.favorite),
        );
        await addCategory(
          TaskCategory(
            name: 'Education',
            color: Colors.purple,
            icon: Icons.school,
          ),
        );
        return;
      }

      _categories = List.generate(
        maps.length,
        (i) => TaskCategory.fromMap(maps[i]),
      );
      notifyListeners();
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> addCategory(TaskCategory category) async {
    try {
      if (_database != null) {
        final id = await _database!.insert(
          'categories',
          category.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        _categories.add(
          TaskCategory(
            id: id,
            name: category.name,
            color: category.color,
            icon: category.icon,
          ),
        );
      } else {
        // For web platform, use in-memory data
        final id = _categories.isEmpty ? 1 : _categories.last.id! + 1;
        _categories.add(
          TaskCategory(
            id: id,
            name: category.name,
            color: category.color,
            icon: category.icon,
          ),
        );
      }
      notifyListeners();
    } catch (e) {
      print('Error adding category: $e');
    }
  }

  Future<void> updateCategory(TaskCategory category) async {
    try {
      if (_database != null) {
        await _database!.update(
          'categories',
          category.toMap(),
          where: 'id = ?',
          whereArgs: [category.id],
        );
      }

      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = category;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating category: $e');
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      if (_database != null) {
        await _database!.delete('categories', where: 'id = ?', whereArgs: [id]);
      }

      _categories.removeWhere((category) => category.id == id);
      notifyListeners();
    } catch (e) {
      print('Error deleting category: $e');
    }
  }

  TaskCategory? getCategoryById(int? id) {
    if (id == null) return null;
    try {
      return _categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }
}
