import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _email;

  bool get isLoggedIn => _isLoggedIn;
  String? get email => _email;

  void login(String email) {
    _isLoggedIn = true;
    _email = email;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _email = null;
    notifyListeners();
  }
}
