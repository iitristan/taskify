import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';
import 'auth_provider.dart';

class CategoryProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthProvider _authProvider;
  List<Category> _categories = [];
  bool _isInitialized = false;

  CategoryProvider(this._authProvider) {
    if (_authProvider.isAuthenticated) {
      initDatabase();
    }

    // Listen to auth changes
    _authProvider.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    if (_authProvider.isAuthenticated) {
      initDatabase();
    } else {
      _categories = [];
      _isInitialized = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthChanged);
    super.dispose();
  }

  List<Category> get categories => _categories;
  bool get isInitialized => _isInitialized;

  Future<void> initDatabase() async {
    if (_isInitialized || !_authProvider.isAuthenticated) return;

    try {
      await loadCategories();
      _isInitialized = true;
    } catch (e) {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> loadCategories() async {
    if (!_authProvider.isAuthenticated) return;

    try {
      final QuerySnapshot snapshot =
          await _firestore
              .collection('categories')
              .where('userId', isEqualTo: _authProvider.user!.id)
              .get();

      _categories =
          snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
      notifyListeners();
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> addCategory(Category category) async {
    if (!_authProvider.isAuthenticated) return;

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
    if (!_authProvider.isAuthenticated) return;

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
    if (!_authProvider.isAuthenticated) return;

    try {
      await _firestore.collection('categories').doc(id).delete();
      _categories.removeWhere((category) => category.id == id);
      notifyListeners();
    } catch (e) {
      // Handle error silently
    }
  }
}
