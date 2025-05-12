import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/category.dart';

class CategoryProvider with ChangeNotifier {
  static const String _tableName = 'categories';
  static const String _dbName = 'category_database.db';

  List<TaskCategory> _categories = [];
  Database? _database;
  bool _isInitialized = false;

  List<TaskCategory> get categories => _categories;

  Future<void> initDatabase() async {
    if (_isInitialized) return;

    try {
      _database = await openDatabase(
        join(await getDatabasesPath(), _dbName),
        onCreate: (db, version) {
          return db.execute(
            'CREATE TABLE $_tableName(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, color INTEGER, icon INTEGER)',
          );
        },
        version: 1,
      );
      await loadCategories();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Category database initialization error: $e');
      _setupDefaultCategories();
    }
  }

  void _setupDefaultCategories() {
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

  Future<void> loadCategories() async {
    if (_database == null) return;

    try {
      final List<Map<String, dynamic>> maps = await _database!.query(
        _tableName,
      );

      if (maps.isEmpty) {
        await _addDefaultCategories();
        return;
      }

      _categories = List.generate(
        maps.length,
        (i) => TaskCategory.fromMap(maps[i]),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  Future<void> _addDefaultCategories() async {
    // Add default categories if none exist
    final defaultCategories = [
      TaskCategory(name: 'Work', color: Colors.blue, icon: Icons.work),
      TaskCategory(name: 'Personal', color: Colors.green, icon: Icons.person),
      TaskCategory(
        name: 'Shopping',
        color: Colors.orange,
        icon: Icons.shopping_cart,
      ),
      TaskCategory(name: 'Health', color: Colors.red, icon: Icons.favorite),
      TaskCategory(name: 'Education', color: Colors.purple, icon: Icons.school),
    ];

    for (var category in defaultCategories) {
      await addCategory(category);
    }
  }

  Future<void> addCategory(TaskCategory category) async {
    try {
      if (_database != null) {
        final id = await _database!.insert(
          _tableName,
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
      debugPrint('Error adding category: $e');
    }
  }

  Future<bool> updateCategory(TaskCategory category) async {
    if (category.id == null) {
      debugPrint('Cannot update category without id');
      return false;
    }

    try {
      if (_database != null) {
        await _database!.update(
          _tableName,
          category.toMap(),
          where: 'id = ?',
          whereArgs: [category.id],
        );
      }

      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = category;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating category: $e');
      return false;
    }
  }

  Future<bool> deleteCategory(int id) async {
    try {
      if (_database != null) {
        final rowsDeleted = await _database!.delete(
          _tableName,
          where: 'id = ?',
          whereArgs: [id],
        );

        if (rowsDeleted == 0) {
          return false;
        }
      }

      final initialLength = _categories.length;
      _categories.removeWhere((category) => category.id == id);

      if (_categories.length != initialLength) {
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting category: $e');
      return false;
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
