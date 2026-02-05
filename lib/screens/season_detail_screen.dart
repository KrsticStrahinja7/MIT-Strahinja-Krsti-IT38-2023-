import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/seasons_provider.dart';
import '../models/season.dart';

class SeasonDetailScreen extends StatelessWidget {
  const SeasonDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sezona')),
      body: Consumer<SeasonsProvider>(
        builder: (context, prov, _) {
          if (prov.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (prov.error != null) {
            return Center(child: Text('Greška: ${prov.error}'));
          }
          final Season? s = prov.active;
          if (s == null) {
            return const Center(child: Text('Nema podataka o sezoni'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sezona ${s.year}', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Text('Poredak vozača', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _buildDriversTable(s),
                const SizedBox(height: 24),
                Text('Poredak timova', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _buildTeamsTable(s),
                const SizedBox(height: 24),
                Text('Trke', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _buildRacesList(context, s),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDriversTable(Season s) {
    final rows = s.drivers
      ..sort((a, b) => b.points.compareTo(a.points));
    return DataTable(
      columns: const [
        DataColumn(label: Text('#')),
        DataColumn(label: Text('Vozač')),
        DataColumn(label: Text('Tim')),
        DataColumn(label: Text('Poeni')),
      ],
      rows: [
        for (int i = 0; i < rows.length; i++)
          DataRow(cells: [
            DataCell(Text('${i + 1}')),
            DataCell(Text(rows[i].name)),
            DataCell(Text(rows[i].teamId.toUpperCase())),
            DataCell(Text(rows[i].points.toString())),
          ])
      ],
    );
  }

  Widget _buildTeamsTable(Season s) {
    final rows = s.teams
      ..sort((a, b) => b.points.compareTo(a.points));
    return DataTable(
      columns: const [
        DataColumn(label: Text('#')),
        DataColumn(label: Text('Tim')),
        DataColumn(label: Text('Poeni')),
      ],
      rows: [
        for (int i = 0; i < rows.length; i++)
          DataRow(cells: [
            DataCell(Text('${i + 1}')),
            DataCell(Text(rows[i].name)),
            DataCell(Text(rows[i].points.toString())),
          ])
      ],
    );
  }

  Widget _buildRacesList(BuildContext context, Season s) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: s.races.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final r = s.races[index];
        return ListTile(
          title: Text(r.name),
          subtitle: Text('${r.circuitName} • ${r.city}, ${r.country}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: navigate to RaceDetail in next step
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Race: ${r.name}')),
            );
          },
        );
      },
    );
  }
}
