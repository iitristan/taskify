import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/todo.dart';
import 'dart:async';

class TodoProvider with ChangeNotifier {
  List<Todo> _todos = [];
  Database? _database;
  bool _isInitialized = false;

  List<Todo> get todos => _todos;

  Future<void> initDatabase() async {
    if (_isInitialized) return;

    try {
      _database = await openDatabase(
        join(await getDatabasesPath(), 'todo_database.db'),
        onCreate: (db, version) {
          return db.execute(
            'CREATE TABLE todos(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, description TEXT, dueDate TEXT, isCompleted INTEGER, priority TEXT)',
          );
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute(
              'ALTER TABLE todos ADD COLUMN priority TEXT DEFAULT "Medium"',
            );
          }
        },
        version: 2,
      );
      await loadTodos();
      _isInitialized = true;
    } catch (e) {
      print('Database initialization error: $e');
      // For web platform or when database fails, use in-memory data
      _todos = [
        Todo(
          id: 1,
          title: 'Complete app redesign',
          description: 'Finish the UI improvements for the Taskify app',
          dueDate: DateTime.now().add(const Duration(days: 2)),
          priority: 'High',
        ),
        Todo(
          id: 2,
          title: 'Buy groceries',
          description: 'Get milk, eggs, and bread',
          dueDate: DateTime.now(),
          priority: 'Medium',
        ),
        Todo(
          id: 3,
          title: 'Call mom',
          description: 'Weekly check-in call',
          dueDate: DateTime.now().add(const Duration(days: 1)),
          priority: 'Low',
        ),
      ];
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> loadTodos() async {
    if (_database == null) return;

    try {
      final List<Map<String, dynamic>> maps = await _database!.query('todos');
      _todos = List.generate(maps.length, (i) => Todo.fromMap(maps[i]));
      notifyListeners();
    } catch (e) {
      print('Error loading todos: $e');
    }
  }

  Future<void> addTodo(Todo todo) async {
    try {
      if (_database != null) {
        final id = await _database!.insert(
          'todos',
          todo.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        _todos.add(
          Todo(
            id: id,
            title: todo.title,
            description: todo.description,
            dueDate: todo.dueDate,
            isCompleted: todo.isCompleted,
            priority: todo.priority,
          ),
        );
      } else {
        // For web platform, use in-memory data
        final id = _todos.isEmpty ? 1 : _todos.last.id! + 1;
        _todos.add(
          Todo(
            id: id,
            title: todo.title,
            description: todo.description,
            dueDate: todo.dueDate,
            isCompleted: todo.isCompleted,
            priority: todo.priority,
          ),
        );
      }
      notifyListeners();
    } catch (e) {
      print('Error adding todo: $e');
    }
  }

  Future<void> updateTodo(Todo todo) async {
    try {
      if (_database != null) {
        await _database!.update(
          'todos',
          todo.toMap(),
          where: 'id = ?',
          whereArgs: [todo.id],
        );
      }

      final index = _todos.indexWhere((t) => t.id == todo.id);
      if (index != -1) {
        _todos[index] = todo;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating todo: $e');
    }
  }

  Future<void> deleteTodo(int id) async {
    try {
      if (_database != null) {
        await _database!.delete('todos', where: 'id = ?', whereArgs: [id]);
      }

      _todos.removeWhere((todo) => todo.id == id);
      notifyListeners();
    } catch (e) {
      print('Error deleting todo: $e');
    }
  }

  List<Todo> getTodosForDate(DateTime date) {
    return _todos.where((todo) {
      return todo.dueDate.year == date.year &&
          todo.dueDate.month == date.month &&
          todo.dueDate.day == date.day;
    }).toList();
  }

  List<Todo> getTodosByPriority(String priority) {
    return _todos.where((todo) => todo.priority == priority).toList();
  }
}
