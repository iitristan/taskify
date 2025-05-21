import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart' as app_models;

class AuthProvider with ChangeNotifier {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  app_models.User? _user;
  bool _isInitialized = false;

  app_models.User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _auth.authStateChanges().listen((firebase_auth.User? firebaseUser) async {
      if (firebaseUser != null) {
        // Get user data from Firestore
        final userData =
            await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (userData.exists) {
          _user = app_models.User.fromFirestore(userData);
        }
      } else {
        _user = null;
      }
      _isInitialized = true;
      notifyListeners();
    });
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final userData =
            await _firestore
                .collection('users')
                .doc(userCredential.user!.uid)
                .get();
        if (userData.exists) {
          _user = app_models.User.fromFirestore(userData);
          notifyListeners();
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signUpWithEmailAndPassword(
    String name,
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Create user document in Firestore
        final newUser = app_models.User(
          id: userCredential.user!.uid,
          name: name,
          email: email,
        );

        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(newUser.toMap());
        _user = newUser;
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUserProfile(String name) async {
    try {
      if (_user != null) {
        await _firestore.collection('users').doc(_user!.id).update({
          'name': name,
        });
        _user = _user!.copyWith(name: name);
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }
}
