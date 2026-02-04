import 'package:flutter/material.dart';

class KalendarScreen extends StatelessWidget {
  const KalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kalendar')),
      body: const Center(
        child: Text('Ovde ide sadržaj kalendara'),
      ),
    );
  }
}
