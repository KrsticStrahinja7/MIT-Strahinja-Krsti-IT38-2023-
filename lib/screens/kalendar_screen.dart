import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/seasons_provider.dart';
import 'season_detail_screen.dart';

class KalendarScreen extends StatelessWidget {
  const KalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kalendar sezona')),
      body: Consumer<SeasonsProvider>(
        builder: (context, prov, _) {
          if (prov.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (prov.error != null) {
            return Center(child: Text('Greška: ${prov.error}'));
          }
          final seasons = prov.seasons;
          if (seasons.isEmpty) {
            return const Center(child: Text('Nema dostupnih sezona'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: seasons.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final s = seasons[index];
              return ListTile(
                title: Text('Sezona ${s.year}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  prov.setActive(s);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SeasonDetailScreen()),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
