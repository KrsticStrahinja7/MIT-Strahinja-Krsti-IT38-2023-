import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/season.dart';
import '../providers/seasons_provider.dart';

class RaceDetailScreen extends StatelessWidget {
  final Race race;
  const RaceDetailScreen({super.key, required this.race});

  @override
  Widget build(BuildContext context) {
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
