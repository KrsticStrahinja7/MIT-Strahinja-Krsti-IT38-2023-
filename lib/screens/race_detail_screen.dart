import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/season.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/seasons_provider.dart';
import 'login_screen.dart';

class RaceDetailScreen extends StatefulWidget {
  final Race race;
  const RaceDetailScreen({super.key, required this.race});

  @override
  State<RaceDetailScreen> createState() => _RaceDetailScreenState();
}

class _RaceDetailScreenState extends State<RaceDetailScreen> {
  String? _sector;
  int? _days;

  static const Map<String, double> _sectorPrices = {
    'A': 150.0,
    'B': 110.0,
    'C': 80.0,
  };

  double? get _totalPrice {
    final sector = _sector;
    final days = _days;
    if (sector == null || days == null) return null;
    final base = _sectorPrices[sector];
    if (base == null) return null;
    return base * days;
  }

  bool get _isPastRace {
    final d = _parseLocalDate(widget.race.date);
    if (d == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return !d.isAfter(today);
  }

  DateTime? _parseLocalDate(String value) {
    final parts = value.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  @override
  Widget build(BuildContext context) {
    final race = widget.race;

    return Scaffold(
      appBar: AppBar(title: Text(race.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<SeasonsProvider>(
          builder: (context, prov, _) {
            final season = prov.active;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Staza: ${race.circuitName}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('Lokacija: ${race.city}, ${race.country}'),
                  const SizedBox(height: 8),
                  Text('Datum: ${race.date}'),
                  const SizedBox(height: 8),
                  if (race.hasSprint) const Chip(label: Text('Sprint vikend')),
                  const SizedBox(height: 16),
                  Text('Karta', style: Theme.of(context).textTheme.titleMedium),
                  if (_isPastRace) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Ova trka je već prošla. Kupovina karata nije dostupna.',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.error.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _sector,
                    decoration: const InputDecoration(
                      labelText: 'Sektor',
                      border: OutlineInputBorder(),
                    ),
                    items: _sectorPrices.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(
                              'Sektor ${e.key} ( ${e.value.toStringAsFixed(2)} / dan )',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _isPastRace
                        ? null
                        : (v) => setState(() => _sector = v),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Broj dana',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final d in const [1, 2, 3])
                        ChoiceChip(
                          label: Text('$d'),
                          selected: _days == d,
                          onSelected: _isPastRace
                              ? null
                              : (_) => setState(() => _days = d),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Ukupno: ${(_totalPrice ?? 0).toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed:
                          (_isPastRace || _sector == null || _days == null)
                          ? null
                          : () {
                              final auth = context.read<AuthProvider>();
                              if (!auth.isLoggedIn) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                );
                                return;
                              }
                              final total = _totalPrice ?? 0;
                              context.read<CartProvider>().addItem(
                                title:
                                    'Karta: ${race.name} • Sektor $_sector • ${_days}d',
                                price: total,
                                quantity: 1,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Dodato u korpu')),
                              );
                            },
                      icon: const Icon(Icons.shopping_cart_outlined),
                      label: const Text('Dodaj u korpu'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Rezultati trke',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _resultsTable(context, season, race.results, isSprint: false),
                  if (race.hasSprint) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Rezultati sprinta',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _resultsTable(
                      context,
                      season,
                      race.sprintResults,
                      isSprint: true,
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Komentari',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('Nema komentara (placeholder)'),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _resultsTable(
    BuildContext context,
    Season? season,
    List<RaceResult> results, {
    required bool isSprint,
  }) {
    if (results.isEmpty) {
      return const Text('Nema podataka');
    }
    final driversById = {
      for (final d in (season?.drivers ?? <Driver>[])) d.id: d.name,
    };
    final sorted = [...results]
      ..sort((a, b) => a.position.compareTo(b.position));
    final List<int> racePoints = const [25, 18, 15, 12, 10, 8, 6, 4, 2, 1];
    final List<int> sprintPoints = const [8, 7, 6, 5, 4, 3, 2, 1];
    return DataTable(
      columns: const [
        DataColumn(label: Text('#')),
        DataColumn(label: Text('Vozač')),
        DataColumn(label: Text('Poeni')),
      ],
      rows: [
        for (final r in sorted)
          DataRow(
            cells: [
              DataCell(Text(r.position.toString())),
              DataCell(
                Text(driversById[r.driverId] ?? r.driverId.toUpperCase()),
              ),
              DataCell(
                Text(() {
                  final idx = r.position - 1;
                  if (isSprint) {
                    return idx >= 0 && idx < sprintPoints.length
                        ? sprintPoints[idx].toString()
                        : '0';
                  }
                  return idx >= 0 && idx < racePoints.length
                      ? racePoints[idx].toString()
                      : '0';
                }()),
              ),
            ],
          ),
      ],
    );
  }
}
