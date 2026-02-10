import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class WishlistProvider extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  final Set<String> _raceIds = {};

  String? _uid;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  Set<String> get raceIds => Set.unmodifiable(_raceIds);

  bool contains(String raceId) => _raceIds.contains(raceId);

  DocumentReference<Map<String, dynamic>>? _docRef() {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('private').doc('wishlist');
  }

  void setUser(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _sub?.cancel();
    _sub = null;
    _raceIds.clear();
    notifyListeners();

    final ref = _docRef();
    if (ref == null) return;

    _sub = ref.snapshots().listen((doc) {
      final data = doc.data();
      final ids = ((data?['raceIds'] as List?) ?? const [])
          .map((e) => e.toString())
          .toSet();
      _raceIds
        ..clear()
        ..addAll(ids);
      notifyListeners();
    });
  }

  Future<void> add(String raceId) async {
    final ref = _docRef();
    if (ref == null) return;
    await ref.set({
      'raceIds': FieldValue.arrayUnion([raceId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> remove(String raceId) async {
    final ref = _docRef();
    if (ref == null) return;
    await ref.set({
      'raceIds': FieldValue.arrayRemove([raceId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void clear() {
    _raceIds.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
