import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminRacesScreen extends StatelessWidget {
  const AdminRacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final races = FirebaseFirestore.instance
        .collection('races')
        .orderBy('date', descending: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Upravljanje trkama')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _RaceEditDialog.show(context);
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: races.snapshots(),
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
            return const Center(child: Text('Nema trka'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final d in docs)
                Card(
                  elevation: 0,
                  child: ListTile(
                    leading: const Icon(Icons.sports_motorsports),
                    title: Text((d.data()['name'] as String?) ?? d.id),
                    subtitle: Text(_subtitle(d.data())),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'edit') {
                          await _RaceEditDialog.show(
                            context,
                            docId: d.id,
                            initial: d.data(),
                          );
                        }
                        if (v == 'results') {
                          await _RaceResultsDialog.show(
                            context,
                            raceId: d.id,
                            initial: d.data(),
                          );
                        }
                        if (v == 'delete') {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Brisanje'),
                              content: const Text('Obrisati trku?'),
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
                            final seasonYear = (d.data()['seasonYear'] as num?)?.toInt();
                            await FirebaseFirestore.instance
                                .collection('races')
                                .doc(d.id)
                                .delete();

                            if (seasonYear != null) {
                              await FirebaseFirestore.instance
                                  .collection('seasons')
                                  .doc('$seasonYear')
                                  .collection('races')
                                  .doc(d.id)
                                  .delete();
                            }
                          }
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Izmeni')),
                        PopupMenuItem(value: 'results', child: Text('Rezultati')),
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

  static String _subtitle(Map<String, dynamic> data) {
    final seasonYear = data['seasonYear'];
    final date = (data['date'] as String?) ?? '-';
    final city = (data['city'] as String?) ?? '';
    final country = (data['country'] as String?) ?? '';
    final loc = [city, country].where((e) => e.trim().isNotEmpty).join(', ');
    final sy = seasonYear == null ? '' : 'Sezona: $seasonYear';
    return [sy, 'Datum: $date', if (loc.isNotEmpty) loc]
        .where((e) => e.trim().isNotEmpty)
        .join(' • ');
  }
}

class _RaceEditDialog extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? initial;
  const _RaceEditDialog({this.docId, this.initial});

  static Future<void> show(
    BuildContext context, {
    String? docId,
    Map<String, dynamic>? initial,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => _RaceEditDialog(docId: docId, initial: initial),
    );
  }

  @override
  State<_RaceEditDialog> createState() => _RaceEditDialogState();
}

class _RaceEditDialogState extends State<_RaceEditDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _circuit;
  late final TextEditingController _city;
  late final TextEditingController _country;
  late final TextEditingController _date;
  late final TextEditingController _seasonYear;

  bool _hasSprint = false;

  @override
  void initState() {
    super.initState();
    final i = widget.initial ?? const <String, dynamic>{};
    _name = TextEditingController(text: (i['name'] as String?) ?? '');
    _circuit =
        TextEditingController(text: (i['circuitName'] as String?) ?? '');
    _city = TextEditingController(text: (i['city'] as String?) ?? '');
    _country = TextEditingController(text: (i['country'] as String?) ?? '');
    _date = TextEditingController(text: (i['date'] as String?) ?? '');
    _seasonYear = TextEditingController(
      text: (i['seasonYear'] as num?)?.toInt().toString() ?? '',
    );
    _hasSprint = (i['hasSprint'] as bool?) ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _circuit.dispose();
    _city.dispose();
    _country.dispose();
    _date.dispose();
    _seasonYear.dispose();
    super.dispose();
  }

  String? _req(String? v) {
    if ((v ?? '').trim().isEmpty) return 'Obavezno polje';
    return null;
  }

  String? _dateVal(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Obavezno polje';
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return 'Format: YYYY-MM-DD';
    }
    return null;
  }

  String? _yearVal(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Obavezno polje';
    final y = int.tryParse(value);
    if (y == null || y < 1950 || y > 2100) return 'Neispravna godina';
    return null;
  }

  Future<void> _save() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    final newSeasonYear = int.parse(_seasonYear.text.trim());
    final prevSeasonYear = (widget.initial?['seasonYear'] as num?)?.toInt();

    final data = <String, dynamic>{
      'name': _name.text.trim(),
      'circuitName': _circuit.text.trim(),
      'city': _city.text.trim(),
      'country': _country.text.trim(),
      'date': _date.text.trim(),
      'seasonYear': newSeasonYear,
      'hasSprint': _hasSprint,
      'results': (widget.initial?['results'] as List?) ?? const [],
      'sprintResults': (widget.initial?['sprintResults'] as List?) ?? const [],
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final col = FirebaseFirestore.instance.collection('races');
    if (widget.docId == null) {
      final doc = col.doc();
      await doc.set(
        {
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await _SeasonMirror.upsertSeasonAndRace(
        seasonYear: newSeasonYear,
        raceId: doc.id,
        raceData: data,
      );
    } else {
      await col.doc(widget.docId).set(data, SetOptions(merge: true));

      if (prevSeasonYear != null && prevSeasonYear != newSeasonYear) {
        await FirebaseFirestore.instance
            .collection('seasons')
            .doc('$prevSeasonYear')
            .collection('races')
            .doc(widget.docId)
            .delete();
      }

      await _SeasonMirror.upsertSeasonAndRace(
        seasonYear: newSeasonYear,
        raceId: widget.docId!,
        raceData: data,
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.docId != null;

    return AlertDialog(
      title: Text(isEdit ? 'Izmeni trku' : 'Nova trka'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Naziv',
                    border: OutlineInputBorder(),
                  ),
                  validator: _req,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _circuit,
                  decoration: const InputDecoration(
                    labelText: 'Staza',
                    border: OutlineInputBorder(),
                  ),
                  validator: _req,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _city,
                        decoration: const InputDecoration(
                          labelText: 'Grad',
                          border: OutlineInputBorder(),
                        ),
                        validator: _req,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _country,
                        decoration: const InputDecoration(
                          labelText: 'Država',
                          border: OutlineInputBorder(),
                        ),
                        validator: _req,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _date,
                        decoration: const InputDecoration(
                          labelText: 'Datum (YYYY-MM-DD)',
                          border: OutlineInputBorder(),
                        ),
                        validator: _dateVal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _seasonYear,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Sezona (godina)',
                          border: OutlineInputBorder(),
                        ),
                        validator: _yearVal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sprint vikend'),
                  value: _hasSprint,
                  onChanged: (v) => setState(() => _hasSprint = v),
                ),
              ],
            ),
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

class _SeasonMirror {
  static Future<void> upsertSeasonAndRace({
    required int seasonYear,
    required String raceId,
    required Map<String, dynamic> raceData,
  }) async {
    final db = FirebaseFirestore.instance;
    final seasonRef = db.collection('seasons').doc('$seasonYear');
    await seasonRef.set(
      {
        'year': seasonYear,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await seasonRef.collection('races').doc(raceId).set(
      {
        'name': raceData['name'],
        'circuitName': raceData['circuitName'],
        'city': raceData['city'],
        'country': raceData['country'],
        'date': raceData['date'],
        'hasSprint': raceData['hasSprint'],
        'results': raceData['results'] ?? const [],
        'sprintResults': raceData['sprintResults'] ?? const [],
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}

class _RaceResultsDialog extends StatefulWidget {
  final String raceId;
  final Map<String, dynamic> initial;
  const _RaceResultsDialog({required this.raceId, required this.initial});

  static Future<void> show(
    BuildContext context, {
    required String raceId,
    required Map<String, dynamic> initial,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => _RaceResultsDialog(raceId: raceId, initial: initial),
    );
  }

  @override
  State<_RaceResultsDialog> createState() => _RaceResultsDialogState();
}

class _RaceResultsDialogState extends State<_RaceResultsDialog> {
  final List<Map<String, dynamic>> _rows = [];
  bool _saving = false;

  late final int? _seasonYear;
  late final String _raceDateStr;
  Map<String, String> _rosterDriverTeam = const {};
  Map<String, String> _rosterDriverName = const {};

  @override
  void initState() {
    super.initState();
    _seasonYear = (widget.initial['seasonYear'] as num?)?.toInt();
    _raceDateStr = (widget.initial['date'] as String?) ?? '';
    const racePoints = [25, 18, 15, 12, 10, 8, 6, 4, 2, 1];

    final existing = (widget.initial['results'] as List?) ?? const [];
    final Map<int, Map<String, dynamic>> byPos = {};
    for (final e in existing) {
      final m = Map<String, dynamic>.from(e as Map);
      final pos = (m['position'] as num?)?.toInt();
      if (pos != null && pos >= 1 && pos <= 20) {
        byPos[pos] = m;
      }
    }

    _rows.clear();
    for (int pos = 1; pos <= 20; pos++) {
      final m = byPos[pos] ?? const <String, dynamic>{};
      final points = (pos >= 1 && pos <= racePoints.length)
          ? racePoints[pos - 1]
          : 0;
      _rows.add({
        'driverId': (m['driverId'] as String?) ?? '',
        'driverName': (m['driverName'] as String?) ?? '',
        'position': pos,
        'points': points,
      });
    }

    _loadRoster();
  }

  Future<void> _loadRoster() async {
    final y = _seasonYear;
    if (y == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('seasons')
        .doc('$y')
        .collection('drivers')
        .get();

    final Map<String, String> driverTeam = {};
    final Map<String, String> driverName = {};
    for (final d in snap.docs) {
      final data = d.data();
      final teamId = (data['teamId'] as String?) ?? '';
      if (teamId.trim().isEmpty) continue;
      driverTeam[d.id] = teamId;
      driverName[d.id] = (data['name'] as String?) ?? d.id;
    }

    if (!mounted) return;
    setState(() {
      _rosterDriverTeam = driverTeam;
      _rosterDriverName = driverName;
    });
  }

  bool _validRow(Map<String, dynamic> r) {
    final driverId = (r['driverId'] as String?)?.trim() ?? '';
    if (driverId.isEmpty) return false;
    if ((_rosterDriverTeam[driverId] ?? '').trim().isEmpty) return false;
    return true;
  }

  Future<void> _save() async {
    if (!_canSaveByDate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Rezultati mogu da se unesu tek na dan trke ($_raceDateStr) ili kasnije.',
          ),
        ),
      );
      return;
    }

    final seasonYear = _seasonYear;
    if (seasonYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trka nema definisanu sezonu (seasonYear).')),
      );
      return;
    }

    if (_rosterDriverTeam.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nema rostera za ovu sezonu. Prvo unesi vozače u sezoni (Admin -> Sezonski roster).',
          ),
        ),
      );
      return;
    }

    if (_rosterDriverTeam.length < 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Roster za sezonu mora imati najmanje 20 vozača da bi uneo rezultate 1-20.',
          ),
        ),
      );
      return;
    }

    final clean = <Map<String, dynamic>>[];
    final Set<String> usedDrivers = {};
    for (final r in _rows) {
      if (!_validRow(r)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Popuni sva polja za rezultate (vozač iz rostera, pozicija, poeni).',
            ),
          ),
        );
        return;
      }

      final driverId = (r['driverId'] as String).trim();
      if (usedDrivers.contains(driverId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vozač ne može biti izabran više puta.')),
        );
        return;
      }
      usedDrivers.add(driverId);

      final teamId = _rosterDriverTeam[driverId] ?? '';
      final driverName = (_rosterDriverName[driverId] ?? '').trim();
      clean.add({
        'driverId': driverId,
        'driverName': driverName,
        'teamId': teamId,
        'position': r['position'] as int,
        'points': r['points'] as int,
      });
    }

    clean.sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));

    setState(() => _saving = true);
    try {
      final db = FirebaseFirestore.instance;

      final seasonRef = db.collection('seasons').doc('$seasonYear');

      final teamIds = clean.map((e) => e['teamId'] as String).toSet().toList();
      Map<String, String> teamNames = {};
      if (teamIds.isNotEmpty) {
        final teamSnap = await db
            .collection('teams')
            .where(FieldPath.documentId, whereIn: teamIds)
            .get();
        teamNames = {
          for (final d in teamSnap.docs)
            d.id: (d.data()['name'] as String?) ?? d.id,
        };
      }

      final batch = db.batch();
      for (final r in clean) {
        final driverId = r['driverId'] as String;
        final teamId = r['teamId'] as String;
        final driverName = (r['driverName'] as String?) ?? driverId;

        batch.set(
          seasonRef.collection('drivers').doc(driverId),
          {
            'name': driverName.isEmpty ? driverId : driverName,
            'teamId': teamId,
            'points': 0,
            'updatedAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        batch.set(
          seasonRef.collection('teams').doc(teamId),
          {
            'name': teamNames[teamId] ?? teamId,
            'points': 0,
            'updatedAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      await db.collection('races').doc(widget.raceId).set(
        {
          'results': clean,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await db
          .collection('seasons')
          .doc('$seasonYear')
          .collection('races')
          .doc(widget.raceId)
          .set(
        {
          'results': clean,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rosterIds = _rosterDriverTeam.keys.toList()..sort();
    final canSaveByDate = _canSaveByDate();

    return AlertDialog(
      title: const Text('Rezultati trke'),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (!canSaveByDate)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Rezultati se mogu uneti tek na dan trke ($_raceDateStr) ili kasnije.',
                  ),
                ),
              if (_seasonYear == null)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text('Trka nema seasonYear.'),
                )
              else if (_rosterDriverTeam.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Roster za sezonu je prazan. Dodaj vozače u sezoni u Admin -> Sezonski roster.',
                  ),
                ),
              for (int i = 0; i < _rows.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 7,
                        child: DropdownButtonFormField<String>(
                          initialValue:
                              ((_rows[i]['driverId'] as String?) ?? '').isEmpty
                                  ? null
                                  : (_rows[i]['driverId'] as String),
                          items: [
                            for (final id in rosterIds)
                              DropdownMenuItem(
                                value: id,
                                child: Text(_rosterDriverName[id] ?? id),
                              ),
                          ],
                          onChanged: _rosterDriverTeam.isEmpty
                              ? null
                              : (v) => setState(() {
                                    _rows[i]['driverId'] = v ?? '';
                                  }),
                          decoration: const InputDecoration(
                            labelText: 'Vozač',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Pozicija',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            ((_rows[i]['position'] as int?) ?? 0).toString(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Poeni',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            ((_rows[i]['points'] as int?) ?? 0).toString(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Otkaži'),
        ),
        FilledButton(
          onPressed: (_saving || !canSaveByDate) ? null : _save,
          child: Text(_saving ? 'Čuvam...' : 'Sačuvaj'),
        ),
      ],
    );
  }

  bool _canSaveByDate() {
    final v = _raceDateStr.trim();
    if (v.isEmpty) return true;
    final dt = DateTime.tryParse(v);
    if (dt == null) return true;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final raceDay = DateTime(dt.year, dt.month, dt.day);
    return !today.isBefore(raceDay);
  }
}
