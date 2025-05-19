import 'package:flutter/foundation.dart' as foundation;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/category.dart';

class CategoryProvider with foundation.ChangeNotifier {
  List<Category> _categories = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isInitialized = false;

  List<Category> get categories => _categories;
  bool get isInitialized => _isInitialized;

  Future<void> initDatabase() async {
    if (_isInitialized) return;

    try {
      foundation.debugPrint('Initializing category database...');
      await loadCategories();
      _isInitialized = true;
      foundation.debugPrint('Category database initialized successfully');
    } catch (e) {
      foundation.debugPrint('Category database initialization error: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> loadCategories() async {
    try {
      foundation.debugPrint('Loading categories from Firestore...');
      final QuerySnapshot snapshot = await _firestore.collection('categories').get();
      _categories = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Category.fromMap(data, doc.id);
      }).toList();
      foundation.debugPrint('Loaded ${_categories.length} categories');
      notifyListeners();
    } catch (e) {
      foundation.debugPrint('Error loading categories: $e');
    }
  }

  Future<void> addCategory(Category category) async {
    try {
      final docRef = await _firestore.collection('categories').add(category.toMap());
      final newCategory = category.copyWith(id: docRef.id);
      _categories.add(newCategory);
      notifyListeners();
    } catch (e) {
      foundation.debugPrint('Error adding category: $e');
    }
  }

  Future<void> updateCategory(Category category) async {
    try {
      await _firestore.collection('categories').doc(category.id).update(category.toMap());
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = category;
        notifyListeners();
      }
    } catch (e) {
      foundation.debugPrint('Error updating category: $e');
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _firestore.collection('categories').doc(id).delete();
      _categories.removeWhere((category) => category.id == id);
      notifyListeners();
    } catch (e) {
      foundation.debugPrint('Error deleting category: $e');
    }
  }
}
