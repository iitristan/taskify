import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/todo.dart';

class TodoProvider with ChangeNotifier {
  List<Todo> _todos = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isInitialized = false;

  List<Todo> get todos => _todos;
  bool get isInitialized => _isInitialized;

  Future<void> initDatabase() async {
    if (_isInitialized) return;

    try {
      await loadTodos();
      _isInitialized = true;
    } catch (e) {
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
      // Handle error silently
    }
  }

  Future<void> addTodo(Todo todo) async {
    try {
      final docRef = await _firestore.collection('todos').add(todo.toMap());
      final newTodo = todo.copyWith(id: docRef.id);
      _todos.add(newTodo);
      notifyListeners();
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> updateTodo(Todo todo) async {
    try {
      await _firestore.collection('todos').doc(todo.id).update(todo.toMap());

      final index = _todos.indexWhere((t) => t.id == todo.id);
      if (index != -1) {
        _todos[index] = todo;
        notifyListeners();
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> deleteTodo(String id) async {
    try {
      await _firestore.collection('todos').doc(id).delete();
      _todos.removeWhere((todo) => todo.id == id);
      notifyListeners();
    } catch (e) {
      // Handle error silently
    }
  }

  List<Todo> getTodosForDate(DateTime date) {
    try {
      return _todos.where((todo) {
        // Check if the task is due on this date
        bool isDueOnDate =
            todo.dueDate.year == date.year &&
            todo.dueDate.month == date.month &&
            todo.dueDate.day == date.day;

        // If it's a recurring task, check if it falls on this date
        if (todo.isRecurring &&
            todo.recurrenceType != null &&
            todo.recurrenceEndDate != null) {
          // Check if the date is within the recurrence period
          if (date.isBefore(todo.recurrenceEndDate!)) {
            switch (todo.recurrenceType) {
              case 'daily':
                return true;
              case 'weekly':
                return todo.dueDate.weekday == date.weekday;
              case 'monthly':
                return todo.dueDate.day == date.day;
              default:
                return false;
            }
          }
        }

        return isDueOnDate;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  List<Todo> getTodosByPriority(String priority) {
    try {
      return _todos.where((todo) => todo.priority == priority).toList();
    } catch (e) {
      return [];
    }
  }

  List<Todo> getTodosByCategory(String categoryId) {
    try {
      return _todos.where((todo) => todo.categoryId == categoryId).toList();
    } catch (e) {
      return [];
    }
  }
}
