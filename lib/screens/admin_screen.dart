import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/orders_provider.dart';
import 'admin_order_detail_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrdersProvider>(
      builder: (context, orders, _) {
        final revenue = orders.orders.fold<double>(
          0,
          (sum, o) => sum + o.totalPrice,
        );

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Admin panel',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit_calendar_outlined),
                    title: const Text('Upravljanje trkama'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Trke')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.confirmation_number_outlined),
                    title: const Text('Upravljanje kartama'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Karte')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Porudžbine',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text('Ukupno: ${orders.orders.length}'),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Prihod',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(revenue.toStringAsFixed(2)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Lista porudžbina',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (orders.orders.isEmpty)
              const Text('Nema porudžbina')
            else
              for (final o in orders.orders)
                Card(
                  elevation: 0,
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: Text('Porudžbina • ${_formatDateTime(o.createdAt)}'),
                    subtitle: Text(
                      'Stavke: ${o.items.length} • Ukupno: ${o.totalPrice.toStringAsFixed(2)}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminOrderDetailScreen(order: o),
                        ),
                      );
                    },
                  ),
                ),
          ],
        );
      },
    );
  }

  static String _formatDateTime(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }
}
