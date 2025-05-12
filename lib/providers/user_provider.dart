import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider with ChangeNotifier {
  String _name = 'User';
  String _email = 'user@example.com';

  String get name => _name;
  String get email => _email;

  UserProvider() {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString('user_name') ?? 'User';
    _email = prefs.getString('user_email') ?? 'user@example.com';
    notifyListeners();
  }

  Future<void> updateUserData({String? name, String? email}) async {
    final prefs = await SharedPreferences.getInstance();

    if (name != null) {
      _name = name;
      await prefs.setString('user_name', name);
    }

    if (email != null) {
      _email = email;
      await prefs.setString('user_email', email);
    }

    notifyListeners();
  }
}
