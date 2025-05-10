import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/todo.dart';

class TodoProvider with ChangeNotifier {
  List<Todo> _todos = [];
  Database? _database;

  List<Todo> get todos => _todos;

  Future<void> initDatabase() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'todo_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE todos(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, description TEXT, dueDate TEXT, isCompleted INTEGER)',
        );
      },
      version: 1,
    );
    await loadTodos();
  }

  Future<void> loadTodos() async {
    if (_database == null) await initDatabase();
    final List<Map<String, dynamic>> maps = await _database!.query('todos');
    _todos = List.generate(maps.length, (i) => Todo.fromMap(maps[i]));
    notifyListeners();
  }

  Future<void> addTodo(Todo todo) async {
    if (_database == null) await initDatabase();
    final id = await _database!.insert(
      'todos',
      todo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _todos.add(Todo(
      id: id,
      title: todo.title,
      description: todo.description,
      dueDate: todo.dueDate,
      isCompleted: todo.isCompleted,
    ));
    notifyListeners();
  }

  Future<void> updateTodo(Todo todo) async {
    if (_database == null) await initDatabase();
    await _database!.update(
      'todos',
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
    final index = _todos.indexWhere((t) => t.id == todo.id);
    if (index != -1) {
      _todos[index] = todo;
      notifyListeners();
    }
  }

  Future<void> deleteTodo(int id) async {
    if (_database == null) await initDatabase();
    await _database!.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
    );
    _todos.removeWhere((todo) => todo.id == id);
    notifyListeners();
  }

  List<Todo> getTodosForDate(DateTime date) {
    return _todos.where((todo) {
      return todo.dueDate.year == date.year &&
          todo.dueDate.month == date.month &&
          todo.dueDate.day == date.day;
    }).toList();
  }
} 