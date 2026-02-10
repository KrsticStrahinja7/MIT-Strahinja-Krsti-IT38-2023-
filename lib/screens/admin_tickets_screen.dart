import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminTicketsScreen extends StatelessWidget {
  const AdminTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tickets = FirebaseFirestore.instance
        .collection('ticket_options')
        .orderBy('sector', descending: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Upravljanje kartama')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _TicketEditDialog.show(context);
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: tickets.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Greška: ${snap.error}'),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('Nema definisanih karata'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final d in docs)
                Card(
                  elevation: 0,
                  child: ListTile(
                    leading: const Icon(Icons.confirmation_number_outlined),
                    title: Text('Sektor ${(d.data()['sector'] as String?) ?? d.id}'),
                    subtitle: Text(
                      'Cena/dan: ${((d.data()['pricePerDay'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'edit') {
                          await _TicketEditDialog.show(
                            context,
                            docId: d.id,
                            initial: d.data(),
                          );
                        }
                        if (v == 'delete') {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Brisanje'),
                              content: const Text('Obrisati opciju karte?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Otkaži'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Obriši'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) {
                            await FirebaseFirestore.instance
                                .collection('ticket_options')
                                .doc(d.id)
                                .delete();
                          }
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Izmeni')),
                        PopupMenuItem(value: 'delete', child: Text('Obriši')),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TicketEditDialog extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? initial;
  const _TicketEditDialog({this.docId, this.initial});

  static Future<void> show(
    BuildContext context, {
    String? docId,
    Map<String, dynamic>? initial,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => _TicketEditDialog(docId: docId, initial: initial),
    );
  }

  @override
  State<_TicketEditDialog> createState() => _TicketEditDialogState();
}

class _TicketEditDialogState extends State<_TicketEditDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _sector;
  late final TextEditingController _price;

  @override
  void initState() {
    super.initState();
    final i = widget.initial ?? const <String, dynamic>{};
    _sector = TextEditingController(text: (i['sector'] as String?) ?? '');
    _price = TextEditingController(
      text: ((i['pricePerDay'] as num?)?.toDouble())?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _sector.dispose();
    _price.dispose();
    super.dispose();
  }

  String? _sectorVal(String? v) {
    final value = (v ?? '').trim().toUpperCase();
    if (value.isEmpty) return 'Obavezno polje';
    if (!RegExp(r'^[A-Z0-9]{1,3}$').hasMatch(value)) return 'Neispravan sektor';
    return null;
  }

  String? _priceVal(String? v) {
    final value = (v ?? '').trim().replaceAll(',', '.');
    if (value.isEmpty) return 'Obavezno polje';
    final p = double.tryParse(value);
    if (p == null || p <= 0) return 'Neispravna cena';
    return null;
  }

  Future<void> _save() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    final sector = _sector.text.trim().toUpperCase();
    final price = double.parse(_price.text.trim().replaceAll(',', '.'));

    final col = FirebaseFirestore.instance.collection('ticket_options');
    final ref = widget.docId == null ? col.doc() : col.doc(widget.docId);

    await ref.set({
      'sector': sector,
      'pricePerDay': price,
      'updatedAt': FieldValue.serverTimestamp(),
      if (widget.docId == null) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.docId != null;

    return AlertDialog(
      title: Text(isEdit ? 'Izmeni kartu' : 'Nova karta'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _sector,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Sektor (npr. A)',
                  border: OutlineInputBorder(),
                ),
                validator: _sectorVal,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cena po danu',
                  border: OutlineInputBorder(),
                ),
                validator: _priceVal,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Otkaži'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Sačuvaj'),
        ),
      ],
    );
  }
}
