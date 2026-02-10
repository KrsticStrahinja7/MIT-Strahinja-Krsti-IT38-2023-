import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String title;
  final double price;
  final int quantity;

  OrderItem({
    required this.title,
    required this.price,
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'price': price,
        'quantity': quantity,
      };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        title: json['title'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      );
}

class Order {
  final String id;
  final DateTime createdAt;
  final List<OrderItem> items;
  final double totalPrice;

  Order({
    required this.id,
    required this.createdAt,
    required this.items,
    required this.totalPrice,
  });

  factory Order.fromDoc(String id, Map<String, dynamic> data) {
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final items = ((data['items'] as List?) ?? const [])
        .map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final total = (data['totalPrice'] as num?)?.toDouble() ?? 0;
    return Order(id: id, createdAt: createdAt, items: items, totalPrice: total);
  }
}

class OrdersProvider extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  final List<Order> _orders = [];

  String? _uid;
  bool _isAdmin = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  List<Order> get orders => List.unmodifiable(_orders);

  void setUser({required String? uid, required bool isAdmin}) {
    final changed = uid != _uid || isAdmin != _isAdmin;
    if (!changed) return;
    _uid = uid;
    _isAdmin = isAdmin;
    _sub?.cancel();
    _sub = null;
    _orders.clear();
    notifyListeners();

    if (_uid == null) return;

    final Query<Map<String, dynamic>> q = _isAdmin
        ? _db.collectionGroup('orders').orderBy('createdAt', descending: true)
        : _db
            .collection('users')
            .doc(_uid)
            .collection('orders')
            .orderBy('createdAt', descending: true);

    _sub = q.snapshots().listen((snap) {
      _orders
        ..clear()
        ..addAll(
          snap.docs.map((d) => Order.fromDoc(d.id, d.data())),
        );
      notifyListeners();
    });
  }

  Future<void> addOrder({
    required List<OrderItem> items,
    required double totalPrice,
  }) {
    if (_uid == null) {
      throw StateError('User is not logged in');
    }
    final ref = _db.collection('users').doc(_uid).collection('orders').doc();
    return ref.set({
      'createdAt': FieldValue.serverTimestamp(),
      'totalPrice': totalPrice,
      'items': items.map((e) => e.toJson()).toList(),
    });
  }

  void clear() {
    _orders.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
