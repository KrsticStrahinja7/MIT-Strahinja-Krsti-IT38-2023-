import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminCommentsScreen extends StatefulWidget {
  const AdminCommentsScreen({super.key});

  @override
  State<AdminCommentsScreen> createState() => _AdminCommentsScreenState();
}

class _AdminCommentsScreenState extends State<AdminCommentsScreen> {
  String _statusFilter = 'pending';

  Query<Map<String, dynamic>> _query() {
    final base = FirebaseFirestore.instance.collection('race_comments');
    if (_statusFilter == 'all') {
      return base.orderBy('createdAt', descending: true);
    }
    return base
        .where('status', isEqualTo: _statusFilter)
        .orderBy('createdAt', descending: true);
  }

  Future<void> _setStatus({
    required String docId,
    required String status,
  }) {
    return FirebaseFirestore.instance.collection('race_comments').doc(docId).set(
      {
        'status': status,
        'reviewedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upravljanje komentarima'),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _statusFilter,
              onChanged: (v) {
                if (v == null) return;
                setState(() => _statusFilter = v);
              },
              items: const [
                DropdownMenuItem(value: 'pending', child: Text('Na čekanju')),
                DropdownMenuItem(value: 'approved', child: Text('Odobreni')),
                DropdownMenuItem(value: 'rejected', child: Text('Odbijeni')),
                DropdownMenuItem(value: 'all', child: Text('Svi')),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _query().snapshots(),
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
            return const Center(child: Text('Nema komentara'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final d in docs) ...[
                Card(
                  elevation: 0,
                  child: ListTile(
                    leading: Icon(
                      (d.data()['status'] as String?) == 'approved'
                          ? Icons.check_circle_outline
                          : (d.data()['status'] as String?) == 'rejected'
                              ? Icons.cancel_outlined
                              : Icons.hourglass_top,
                    ),
                    title: Text(
                      '${(d.data()['userName'] as String?) ?? '-'} - Sektor ${(d.data()['sector'] as String?) ?? '-'}',
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text((d.data()['text'] as String?) ?? ''),
                        const SizedBox(height: 6),
                        Text(
                          'Trka: ${(d.data()['raceName'] as String?) ?? (d.data()['raceId'] as String?) ?? d.id}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Sezona: ${(d.data()['seasonYear'] as num?)?.toInt() ?? '-'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: (d.data()['status'] as String?) == 'pending'
                        ? Wrap(
                            spacing: 8,
                            children: [
                              IconButton(
                                tooltip: 'Odobri',
                                onPressed: () =>
                                    _setStatus(docId: d.id, status: 'approved'),
                                icon: const Icon(Icons.check),
                              ),
                              IconButton(
                                tooltip: 'Odbij',
                                onPressed: () =>
                                    _setStatus(docId: d.id, status: 'rejected'),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          );
        },
      ),
    );
  }
}
