import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';

class CategoryProvider with ChangeNotifier {
  List<Category> _categories = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isInitialized = false;

  List<Category> get categories => _categories;
  bool get isInitialized => _isInitialized;

  Future<void> initDatabase() async {
    if (_isInitialized) return;

    try {
      await loadCategories();
      _isInitialized = true;
    } catch (e) {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> loadCategories() async {
    try {
      final QuerySnapshot snapshot =
          await _firestore.collection('categories').get();
      _categories =
          snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Category.fromMap(data, doc.id);
          }).toList();

      notifyListeners();
    } catch (e) {
      notifyListeners();
    }
  }

  Future<void> addCategory(Category category) async {
    try {
      final docRef = await _firestore
          .collection('categories')
          .add(category.toMap());
      final newCategory = category.copyWith(id: docRef.id);
      _categories.add(newCategory);
      notifyListeners();
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> updateCategory(Category category) async {
    try {
      await _firestore
          .collection('categories')
          .doc(category.id)
          .update(category.toMap());
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = category;
        notifyListeners();
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _firestore.collection('categories').doc(id).delete();
      _categories.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      // Handle error silently
    }
  }
}
