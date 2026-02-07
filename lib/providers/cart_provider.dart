import 'package:flutter/foundation.dart';

class CartItem {
  final String id;
  final String title;
  final double price;
  final int quantity;

  CartItem({
    required this.id,
    required this.title,
    required this.price,
    required this.quantity,
  });

  CartItem copyWith({
    String? id,
    String? title,
    double? price,
    int? quantity,
  }) {
    return CartItem(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
    );
  }
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalItems => _items.fold(0, (sum, e) => sum + e.quantity);

  double get totalPrice =>
      _items.fold(0, (sum, e) => sum + (e.price * e.quantity));

  void addItem({
    required String title,
    required double price,
    int quantity = 1,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _items.add(
      CartItem(
        id: id,
        title: title,
        price: price,
        quantity: quantity,
      ),
    );
    notifyListeners();
  }

  void addDemoItem() {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _items.add(
      CartItem(
        id: id,
        title: 'Demo karta',
        price: 99.0,
        quantity: 1,
      ),
    );
    notifyListeners();
  }

  void remove(String id) {
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
