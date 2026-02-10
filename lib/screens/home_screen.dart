import 'package:flutter/material.dart';
import 'kalendar_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.primary.withValues(alpha: 0.35),
                  const Color(0xFF0A0A0A),
                ],
              ),
              border: Border.all(
                color: cs.primary.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -6,
                  top: -10,
                  child: Icon(
                    Icons.sports_motorsports,
                    size: 92,
                    color: cs.primary.withValues(alpha: 0.20),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'F1Pass',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tvoj pass za sezonu: kalendar, rezultati i karte na jednom mestu.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const KalendarScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.calendar_month),
                        label: const Text('Kalendar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Card(
            elevation: 0,
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/images/f1.jpg',
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Istorijat Formule 1',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Formula 1 je vrhunac automobilskog sporta — spoj brzine, tehnologije i strategije. Od 1950. godine do danas, F1 je postala globalni spektakl koji stalno pomera granice: aerodinamika, sigurnost, hibridni sistemi i analiza podataka menjali su način na koji se trke voze i pobeđuju.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            icon: Icons.flag,
            title: '1950–1970: Počeci i heroji',
            text:
                'Nastaje svetsko prvenstvo i rađa se legenda. U prvim decenijama dominiraju vozački talent i hrabrost. Razvoj bezbednosti kreće postepeno, a staze i bolidi oblikuju identitet sporta.',
          ),
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.air,
            title: '1970–2000: Aerodinamika i timska dominacija',
            text:
                'Aerodinamička rešenja, ground effect i evolucija šasije postaju presudni. Timovi grade dugoročne projekte, a strategija i pouzdanost ulaze u centar pažnje.',
          ),
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.hub,
            title: '2000–danas: Data, hibridi i strategija',
            text:
                'Moderna Formula 1 je visoko inženjerski sport. Hibridni motori, energetski sistemi, telemetrija i analiza podataka postaju standard, dok pravila teže uzbudljivijim trkama i održivosti.',
          ),
          const SizedBox(height: 16),
          Text(
            'Brzi vodič kroz ere',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _TimelineTile(
            year: '1950',
            title: 'Prva sezona',
            subtitle: 'Start zvaničnog F1 šampionata.',
          ),
          _TimelineTile(
            year: '1970+',
            title: 'Aero revolucija',
            subtitle: 'Bolidi postaju sve brži zahvaljujući aerodinamici.',
          ),
          _TimelineTile(
            year: '2014+',
            title: 'Hibridna era',
            subtitle: 'Pogonske jedinice + strategija energije i podataka.',
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: cs.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final String year;
  final String title;
  final String subtitle;

  const _TimelineTile({
    required this.year,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: cs.primary.withValues(alpha: 0.35)),
              color: cs.primary.withValues(alpha: 0.10),
            ),
            child: Center(
              child: Text(
                year,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
