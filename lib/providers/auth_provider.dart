import 'package:flutter/material.dart';
import '../models/models.dart';
import '../db/database_helper.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == 'Admin';
  bool get isTechnician => _currentUser?.role == 'Technician';
  bool get isReceptionist => _currentUser?.role == 'Receptionist';

  Future<bool> login(String username, String password) async {
    final user = await DatabaseHelper.instance.login(username, password);
    if (user != null) {
      _currentUser = user;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
