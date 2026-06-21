import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  static final AuthProvider _instance = AuthProvider._internal();
  factory AuthProvider() => _instance;
  AuthProvider._internal();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  void authenticate(Map<String, dynamic> userData) {
    _currentUser = UserModel.fromJson(userData);
    _saveToPrefs();
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _removeFromPrefs();
    notifyListeners();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      try {
        final map = jsonDecode(userJson) as Map<String, dynamic>;
        _currentUser = UserModel.fromJson(map);
        notifyListeners();
      } catch (e) {
        print("Failed to load user from preferences: $e");
      }
    }
  }

  Future<void> _saveToPrefs() async {
    if (_currentUser == null) return;
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_currentUser!.toJson());
    await prefs.setString('user', json);
  }

  Future<void> _removeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
  }
}