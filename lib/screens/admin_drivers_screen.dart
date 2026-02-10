import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminDriversScreen extends StatelessWidget {
  const AdminDriversScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final drivers = FirebaseFirestore.instance
        .collection('drivers')
        .orderBy('name', descending: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Upravljanje vozačima')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _DriverEditDialog.show(context);
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: drivers.snapshots(),
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
            return const Center(child: Text('Nema vozača'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final d in docs)
                Card(
                  elevation: 0,
                  child: ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text((d.data()['name'] as String?) ?? d.id),
                    subtitle: Text(d.id),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'edit') {
                          await _DriverEditDialog.show(
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
                              content: const Text('Obrisati vozača?'),
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
                                .collection('drivers')
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

class _DriverEditDialog extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? initial;
  const _DriverEditDialog({this.docId, this.initial});

  static Future<void> show(
    BuildContext context, {
    String? docId,
    Map<String, dynamic>? initial,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => _DriverEditDialog(docId: docId, initial: initial),
    );
  }

  @override
  State<_DriverEditDialog> createState() => _DriverEditDialogState();
}

class _DriverEditDialogState extends State<_DriverEditDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _id;
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    final i = widget.initial ?? const <String, dynamic>{};
    _id = TextEditingController(text: widget.docId ?? '');
    _name = TextEditingController(text: (i['name'] as String?) ?? '');
  }

  @override
  void dispose() {
    _id.dispose();
    _name.dispose();
    super.dispose();
  }

  String? _req(String? v) {
    if ((v ?? '').trim().isEmpty) return 'Obavezno polje';
    return null;
  }

  Future<void> _save() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    final id = _id.text.trim();
    final data = <String, dynamic>{
      'name': _name.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final col = FirebaseFirestore.instance.collection('drivers');
    if (widget.docId == null) {
      await col.doc(id).set(
        {
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } else {
      await col.doc(widget.docId).set(data, SetOptions(merge: true));
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.docId != null;

    return AlertDialog(
      title: Text(isEdit ? 'Izmeni vozača' : 'Novi vozač'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _id,
                enabled: !isEdit,
                decoration: const InputDecoration(
                  labelText: 'ID (npr. max_verstappen)',
                  border: OutlineInputBorder(),
                ),
                validator: _req,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Ime i prezime',
                  border: OutlineInputBorder(),
                ),
                validator: _req,
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
