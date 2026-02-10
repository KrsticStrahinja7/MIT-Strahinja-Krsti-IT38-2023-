import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminSeasonRosterScreen extends StatefulWidget {
  const AdminSeasonRosterScreen({super.key});

  @override
  State<AdminSeasonRosterScreen> createState() =>
      _AdminSeasonRosterScreenState();
}

class _AdminSeasonRosterScreenState extends State<AdminSeasonRosterScreen> {
  final _yearCtrl = TextEditingController(text: DateTime.now().year.toString());

  @override
  void dispose() {
    _yearCtrl.dispose();
    super.dispose();
  }

  int? get _year => int.tryParse(_yearCtrl.text.trim());

  @override
  Widget build(BuildContext context) {
    final y = _year;

    return Scaffold(
      appBar: AppBar(title: const Text('Sezonski roster')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _yearCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Sezona (godina)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: y == null
                      ? null
                      : () async {
                          await _RosterAddDialog.show(context, seasonYear: y);
                        },
                  child: const Text('Dodaj vozača u sezonu'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (y == null)
              const Expanded(child: Center(child: Text('Unesi godinu sezone')))
            else
              Expanded(child: _SeasonRosterList(seasonYear: y)),
          ],
        ),
      ),
    );
  }
}

class _SeasonRosterList extends StatelessWidget {
  final int seasonYear;
  const _SeasonRosterList({required this.seasonYear});

  @override
  Widget build(BuildContext context) {
    final roster = FirebaseFirestore.instance
        .collection('seasons')
        .doc('$seasonYear')
        .collection('drivers')
        .orderBy('name');

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: roster.snapshots(),
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
          return const Center(child: Text('Nema vozača za ovu sezonu'));
        }

        return ListView(
          children: [
            for (final d in docs)
              Card(
                elevation: 0,
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text((d.data()['name'] as String?) ?? d.id),
                  subtitle: Text(
                    'driverId: ${d.id} • teamId: ${(d.data()['teamId'] as String?) ?? ''}',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'edit') {
                        await _RosterAddDialog.show(
                          context,
                          seasonYear: seasonYear,
                          driverId: d.id,
                          initial: d.data(),
                        );
                      }
                      if (v == 'delete') {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Brisanje'),
                            content: const Text('Ukloniti vozača iz sezone?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Otkaži'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Ukloni'),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) {
                          await FirebaseFirestore.instance
                              .collection('seasons')
                              .doc('$seasonYear')
                              .collection('drivers')
                              .doc(d.id)
                              .delete();
                        }
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Izmeni')),
                      PopupMenuItem(value: 'delete', child: Text('Ukloni')),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RosterAddDialog extends StatefulWidget {
  final int seasonYear;
  final String? driverId;
  final Map<String, dynamic>? initial;
  const _RosterAddDialog({
    required this.seasonYear,
    this.driverId,
    this.initial,
  });

  static Future<void> show(
    BuildContext context, {
    required int seasonYear,
    String? driverId,
    Map<String, dynamic>? initial,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => _RosterAddDialog(
        seasonYear: seasonYear,
        driverId: driverId,
        initial: initial,
      ),
    );
  }

  @override
  State<_RosterAddDialog> createState() => _RosterAddDialogState();
}

class _RosterAddDialogState extends State<_RosterAddDialog> {
  String? _selectedDriverId;
  String? _selectedTeamId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedDriverId = widget.driverId;
    _selectedTeamId = (widget.initial?['teamId'] as String?);
  }

  Future<void> _save(String driverName, String teamName) async {
    final driverId = (_selectedDriverId ?? '').trim();
    final teamId = (_selectedTeamId ?? '').trim();
    if (driverId.isEmpty || teamId.isEmpty) return;

    setState(() => _saving = true);
    try {
      final db = FirebaseFirestore.instance;
      final seasonRef = db.collection('seasons').doc('${widget.seasonYear}');

      await seasonRef.set({
        'year': widget.seasonYear,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await seasonRef.collection('drivers').doc(driverId).set({
        'name': driverName,
        'teamId': teamId,
        'points': 0,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await seasonRef.collection('teams').doc(teamId).set({
        'name': teamName,
        'points': 0,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.driverId != null;

    final driversStream = FirebaseFirestore.instance
        .collection('drivers')
        .orderBy('name')
        .snapshots();
    final teamsStream = FirebaseFirestore.instance
        .collection('teams')
        .orderBy('name')
        .snapshots();

    return AlertDialog(
      title: Text(isEdit ? 'Izmeni vozača u sezoni' : 'Dodaj vozača u sezonu'),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: driversStream,
              builder: (context, snap) {
                final docs = snap.data?.docs ?? const [];
                return DropdownButtonFormField<String>(
                  initialValue: _selectedDriverId,
                  items: [
                    for (final d in docs)
                      DropdownMenuItem(
                        value: d.id,
                        child: Text((d.data()['name'] as String?) ?? d.id),
                      ),
                  ],
                  onChanged: isEdit
                      ? null
                      : (v) => setState(() => _selectedDriverId = v),
                  decoration: const InputDecoration(
                    labelText: 'Vozač',
                    border: OutlineInputBorder(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: teamsStream,
              builder: (context, snap) {
                final docs = snap.data?.docs ?? const [];
                return DropdownButtonFormField<String>(
                  initialValue: _selectedTeamId,
                  items: [
                    for (final d in docs)
                      DropdownMenuItem(
                        value: d.id,
                        child: Text((d.data()['name'] as String?) ?? d.id),
                      ),
                  ],
                  onChanged: (v) => setState(() => _selectedTeamId = v),
                  decoration: const InputDecoration(
                    labelText: 'Tim',
                    border: OutlineInputBorder(),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'Pravilo: svaki vozač u sezoni ima tačno jedan tim.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Otkaži'),
        ),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: driversStream,
          builder: (context, dSnap) {
            QueryDocumentSnapshot<Map<String, dynamic>>? driverDoc;
            for (final d in dSnap.data?.docs ?? const []) {
              if (d.id == _selectedDriverId) {
                driverDoc = d;
                break;
              }
            }
            final driverName =
                (driverDoc?.data()['name'] as String?) ??
                (_selectedDriverId ?? '');

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: teamsStream,
              builder: (context, tSnap) {
                QueryDocumentSnapshot<Map<String, dynamic>>? teamDoc;
                for (final d in tSnap.data?.docs ?? const []) {
                  if (d.id == _selectedTeamId) {
                    teamDoc = d;
                    break;
                  }
                }
                final teamName =
                    (teamDoc?.data()['name'] as String?) ??
                    (_selectedTeamId ?? '');

                final canSave =
                    !_saving &&
                    (_selectedDriverId ?? '').isNotEmpty &&
                    (_selectedTeamId ?? '').isNotEmpty;
                return FilledButton(
                  onPressed: canSave ? () => _save(driverName, teamName) : null,
                  child: Text(_saving ? 'Čuvam...' : 'Sačuvaj'),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
