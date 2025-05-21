import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider with ChangeNotifier {
  String _name = 'User';

  String get name => _name;

  UserProvider() {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString('user_name') ?? 'User';
    notifyListeners();
  }

  Future<void> updateUserData({String? name}) async {
    final prefs = await SharedPreferences.getInstance();

    if (name != null) {
      _name = name;
      await prefs.setString('user_name', name);
    }

    notifyListeners();
  }
}
