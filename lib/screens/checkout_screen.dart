import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/orders_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _cardCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cardCtrl.dispose();
    _expCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  String? _validateName(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Obavezno polje';
    if (value.length < 3) return 'Unesi puno ime';
    return null;
  }

  String? _validateCard(String? v) {
    final digits = (v ?? '').replaceAll(RegExp(r'\s+'), '');
    if (digits.isEmpty) return 'Obavezno polje';
    if (!RegExp(r'^\d{16}$').hasMatch(digits)) {
      return 'Broj kartice mora imati 16 cifara';
    }
    return null;
  }

  String? _validateExp(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Obavezno polje';
    final m = RegExp(r'^(\d{2})\/(\d{2})$').firstMatch(value);
    if (m == null) return 'Format: MM/YY';

    final mm = int.parse(m.group(1)!);
    final yy = int.parse(m.group(2)!);
    if (mm < 1 || mm > 12) return 'Neispravan mesec';

    final now = DateTime.now();
    final fullYear = 2000 + yy;
    final exp = DateTime(fullYear, mm + 1, 0);
    if (exp.isBefore(DateTime(now.year, now.month, now.day))) {
      return 'Kartica je istekla';
    }
    return null;
  }

  String? _validateCvv(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Obavezno polje';
    if (!RegExp(r'^\d{3}$').hasMatch(value)) return 'CVV mora imati 3 cifre';
    return null;
  }

  Future<void> _submit() async {
    final cart = context.read<CartProvider>();
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Korpa je prazna')));
      return;
    }

    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Potvrda plaćanja'),
          content: Text(
            'Biće naplaćeno: ${cart.totalPrice.toStringAsFixed(2)}\n\nNastaviti?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Otkaži'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Plati'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final orderItems = [
      for (final it in cart.items)
        OrderItem(title: it.title, price: it.price, quantity: it.quantity),
    ];
    try {
      await context.read<OrdersProvider>().addOrder(
            items: orderItems,
            totalPrice: cart.totalPrice,
          );
      cart.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Plaćanje nije uspelo: $e')),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Uspešno plaćanje')));

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Iznos za plaćanje',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cart.totalPrice.toStringAsFixed(2),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Stavke: ${cart.items.length}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Ime na kartici',
                          border: OutlineInputBorder(),
                        ),
                        validator: _validateName,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _cardCtrl,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Broj kartice',
                          hintText: '1234 5678 9012 3456',
                          border: OutlineInputBorder(),
                        ),
                        validator: _validateCard,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _expCtrl,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Datum isteka',
                                hintText: 'MM/YY',
                                border: OutlineInputBorder(),
                              ),
                              validator: _validateExp,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _cvvCtrl,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'CVV',
                                hintText: '123',
                                border: OutlineInputBorder(),
                              ),
                              validator: _validateCvv,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: cart.items.isEmpty ? null : _submit,
                          child: const Text('Plati'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
