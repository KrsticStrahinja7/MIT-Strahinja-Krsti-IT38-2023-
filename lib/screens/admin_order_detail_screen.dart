import 'package:flutter/material.dart';

import '../providers/orders_provider.dart';

class AdminOrderDetailScreen extends StatelessWidget {
  final Order order;
  const AdminOrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalji porudžbine')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Porudžbina',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text('Datum: ${_formatDateTime(order.createdAt)}'),
          const SizedBox(height: 4),
          Text('Ukupno: ${order.totalPrice.toStringAsFixed(2)}'),
          const SizedBox(height: 16),
          Text(
            'Stavke',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (final it in order.items)
            Card(
              elevation: 0,
              child: ListTile(
                leading: const Icon(Icons.confirmation_number_outlined),
                title: Text(it.title),
                subtitle: Text('Količina: ${it.quantity}'),
                trailing: Text(it.price.toStringAsFixed(2)),
              ),
            ),
        ],
      ),
    );
  }

  static String _formatDateTime(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }
}
