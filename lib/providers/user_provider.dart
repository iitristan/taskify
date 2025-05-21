import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_provider.dart';

class UserProvider with ChangeNotifier {
  String _name = 'User';
  final AuthProvider? _authProvider;

  String get name => _name;

  UserProvider({AuthProvider? authProvider}) : _authProvider = authProvider {
    _loadUserData();

    // Listen to auth changes if authProvider is provided
    _authProvider?.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    if (_authProvider?.isAuthenticated == true && _authProvider?.user != null) {
      // Update name from auth user
      updateUserData(name: _authProvider!.user!.name);
    }
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_onAuthChanged);
    super.dispose();
  }

  Future<void> _loadUserData() async {
    // Try to get name from auth first
    if (_authProvider?.isAuthenticated == true && _authProvider?.user != null) {
      _name = _authProvider!.user!.name;
      notifyListeners();
      return;
    }

    // Fall back to shared preferences if not authenticated
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString('user_name') ?? 'User';
    notifyListeners();
  }

  Future<void> updateUserData({String? name}) async {
    final prefs = await SharedPreferences.getInstance();

    if (name != null) {
      _name = name;
      await prefs.setString('user_name', name);

      // Also update the name in Firebase if the user is authenticated
      if (_authProvider?.isAuthenticated == true &&
          _authProvider?.user != null) {
        await _authProvider!.updateUserProfile(name);
      }
    }

    notifyListeners();
  }
}
