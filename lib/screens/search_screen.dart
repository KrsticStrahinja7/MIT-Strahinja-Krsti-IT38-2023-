import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/season.dart';
import '../providers/seasons_provider.dart';
import 'race_detail_screen.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SeasonsProvider>(
      builder: (context, prov, _) {
        if (prov.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (prov.error != null) {
          return Center(child: Text('Greška: ${prov.error}'));
        }
        final season = prov.active;
        if (season == null) {
          return const Center(child: Text('Nema aktivne sezone'));
        }

        final upcoming = _upcomingRaces(season.races);
        if (upcoming.isEmpty) {
          return const Center(child: Text('Nema dostupnih trka za kupovinu'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: upcoming.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final r = upcoming[index];
            return ListTile(
              title: Text(r.name),
              subtitle: Text('${r.city}, ${r.country} • ${r.date}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => RaceDetailScreen(race: r)),
                );
              },
            );
          },
        );
      },
    );
  }

  List<Race> _upcomingRaces(List<Race> races) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcoming = races.where((r) {
      final d = _parseLocalDate(r.date);
      if (d == null) return false;
      return d.isAfter(today);
    }).toList();
    upcoming.sort((a, b) {
      final da = _parseLocalDate(a.date) ?? DateTime(2100);
      final db = _parseLocalDate(b.date) ?? DateTime(2100);
      return da.compareTo(db);
    });
    return upcoming;
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
}
