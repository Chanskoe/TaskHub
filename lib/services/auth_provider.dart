import 'package:flutter/material.dart';
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
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}