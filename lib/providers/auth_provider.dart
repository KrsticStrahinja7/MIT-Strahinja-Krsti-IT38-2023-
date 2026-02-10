import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthProvider extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  User? _user;
  bool _isAdmin = false;
  String? _email;
  String? _fullName;
  String? _firstName;
  String? _lastName;
  String? _phone;
  bool _raceDayNotifications = false;

  late final StreamSubscription<User?> _sub;

  AuthProvider() {
    _user = _auth.currentUser;
    _sub = _auth.authStateChanges().listen((u) async {
      _user = u;
      _email = u?.email;
      _isAdmin = (_email ?? '').trim().toLowerCase() == 'admin@f1pass.com';
      if (u == null) {
        _fullName = null;
        _firstName = null;
        _lastName = null;
        _phone = null;
        notifyListeners();
        return;
      }

      await _loadProfile(u.uid);
      notifyListeners();
    });
  }

  bool get isLoggedIn => _isLoggedIn;
  bool get isAdmin => _isAdmin;
  String? get email => _email;
  String? get fullName => _fullName;
  String? get firstName => _firstName;
  String? get lastName => _lastName;
  String? get phone => _phone;
  bool get raceDayNotifications => _raceDayNotifications;

  bool get _isLoggedIn => _user != null;

  String? get uid => _user?.uid;

  Future<void> login({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) {
    return _registerImpl(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      password: password,
    );
  }

  Future<void> _registerImpl({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;

    await _db.collection('users').doc(uid).set({
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'isAdmin': email.trim().toLowerCase() == 'admin@f1pass.com',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _loadProfile(String uid) async {
    try {
      final ref = _db.collection('users').doc(uid);
      final doc = await ref.get();
      if (!doc.exists) {
        final email = (_email ?? '').trim();
        await ref.set({
          'email': email,
          'isAdmin': email.toLowerCase() == 'admin@f1pass.com',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      final data = (await ref.get()).data();
      if (data == null) return;
      _firstName = (data['firstName'] as String?)?.trim();
      _lastName = (data['lastName'] as String?)?.trim();
      if ((_firstName ?? '').isNotEmpty || (_lastName ?? '').isNotEmpty) {
        _fullName = '${_firstName ?? ''} ${_lastName ?? ''}'.trim();
      }
      _phone = (data['phone'] as String?)?.trim();
      _raceDayNotifications = (data['raceDayNotifications'] as bool?) ?? false;
      final isAdminFromDb = data['isAdmin'] as bool?;
      if (isAdminFromDb != null) {
        _isAdmin = isAdminFromDb;
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> setRaceDayNotifications(bool enabled) async {
    final uid = _user?.uid;
    if (uid == null) return;

    _raceDayNotifications = enabled;
    notifyListeners();

    try {
      await _db.collection('users').doc(uid).set(
        {
          'raceDayNotifications': enabled,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // ignore
    }

    try {
      // Ask permission on iOS; Android is auto granted pre-13.
      await FirebaseMessaging.instance.requestPermission();
      if (enabled) {
        await FirebaseMessaging.instance.subscribeToTopic('race-day');
      } else {
        await FirebaseMessaging.instance.unsubscribeFromTopic('race-day');
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
