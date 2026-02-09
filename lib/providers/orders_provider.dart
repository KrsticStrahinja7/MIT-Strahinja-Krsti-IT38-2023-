import 'package:flutter/foundation.dart';

class OrderItem {
  final String title;
  final double price;
  final int quantity;

  OrderItem({
    required this.title,
    required this.price,
    required this.quantity,
  });
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
}

class OrdersProvider extends ChangeNotifier {
  final List<Order> _orders = [];

  List<Order> get orders => List.unmodifiable(_orders);

  void addOrder({
    required List<OrderItem> items,
    required double totalPrice,
  }) {
    _orders.insert(
      0,
      Order(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
        items: items,
        totalPrice: totalPrice,
      ),
    );
    notifyListeners();
  }

  void clear() {
    _orders.clear();
    notifyListeners();
  }
}
