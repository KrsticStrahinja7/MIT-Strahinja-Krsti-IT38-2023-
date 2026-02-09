import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isAdmin = false;
  String? _email;
  String? _fullName;
  String? _firstName;
  String? _lastName;
  String? _phone;

  bool get isLoggedIn => _isLoggedIn;
  bool get isAdmin => _isAdmin;
  String? get email => _email;
  String? get fullName => _fullName;
  String? get firstName => _firstName;
  String? get lastName => _lastName;
  String? get phone => _phone;

  void login({required String email, required String password}) {
    _isLoggedIn = true;
    _email = email;
    _isAdmin = email.trim().toLowerCase() == 'admin@f1pass.com' &&
        password.trim() == 'admin123';
    notifyListeners();
  }

  void register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
  }) {
    _isLoggedIn = true;
    _isAdmin = false;
    _firstName = firstName;
    _lastName = lastName;
    _fullName = '${firstName.trim()} ${lastName.trim()}'.trim();
    _email = email;
    _phone = phone;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _isAdmin = false;
    _email = null;
    _fullName = null;
    _firstName = null;
    _lastName = null;
    _phone = null;
    notifyListeners();
  }
}
