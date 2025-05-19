import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/todo.dart';
import 'dart:async';

class TodoProvider with ChangeNotifier {
  List<Todo> _todos = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isInitialized = false;

  List<Todo> get todos => _todos;

  Future<void> initDatabase() async {
    if (_isInitialized) return;

    try {
      await loadTodos();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Database initialization error: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> loadTodos() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection('todos').get();
      _todos = snapshot.docs.map((doc) => Todo.fromFirestore(doc)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading todos: $e');
    }
  }

  Future<void> addTodo(Todo todo) async {
    try {
      debugPrint('Adding todo with date: ${todo.dueDate}');
      final docRef = await _firestore.collection('todos').add(todo.toMap());
      final newTodo = todo.copyWith(id: docRef.id);
      _todos.add(newTodo);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding todo: $e');
    }
  }

  Future<void> updateTodo(Todo todo) async {
    try {
      debugPrint('Updating todo with date: ${todo.dueDate}');
      await _firestore.collection('todos').doc(todo.id).update(todo.toMap());

      final index = _todos.indexWhere((t) => t.id == todo.id);
      if (index != -1) {
        _todos[index] = todo;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating todo: $e');
    }
  }

  Future<void> deleteTodo(String id) async {
    try {
      await _firestore.collection('todos').doc(id).delete();
      _todos.removeWhere((todo) => todo.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting todo: $e');
    }
  }

  List<Todo> getTodosForDate(DateTime date) {
    try {
      return _todos.where((todo) {
        return todo.dueDate.year == date.year &&
            todo.dueDate.month == date.month &&
            todo.dueDate.day == date.day;
      }).toList();
    } catch (e) {
      debugPrint('Error filtering todos by date: $e');
      return [];
    }
  }

  List<Todo> getTodosByPriority(String priority) {
    try {
      return _todos.where((todo) => todo.priority == priority).toList();
    } catch (e) {
      debugPrint('Error filtering todos by priority: $e');
      return [];
    }
  }

  List<Todo> getTodosByCategory(String categoryId) {
    try {
      return _todos.where((todo) => todo.categoryId == categoryId).toList();
    } catch (e) {
      debugPrint('Error filtering todos by category: $e');
      return [];
    }
  }
}
