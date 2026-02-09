import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/season.dart';
import '../providers/auth_provider.dart';
import '../providers/orders_provider.dart';
import '../providers/seasons_provider.dart';
import '../providers/wishlist_provider.dart';
import 'race_detail_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer4<AuthProvider, OrdersProvider, SeasonsProvider,
        WishlistProvider>(
      builder: (context, auth, orders, seasons, wishlist, _) {
        if (!auth.isLoggedIn) {
          return const Center(child: Text('Uloguj se da vidiš profil'));
        }

        final season = seasons.active;
        final upcoming = season == null ? <Race>[] : _upcomingRaces(season.races);
        final wishlistRaces = season == null
            ? <Race>[]
            : season.races
                .where((r) => wishlist.contains(r.id))
                .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Podaci korisnika',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _InfoRow(label: 'Ime', value: auth.firstName ?? '-'),
            const SizedBox(height: 8),
            _InfoRow(label: 'Prezime', value: auth.lastName ?? '-'),
            const SizedBox(height: 8),
            _InfoRow(label: 'Email', value: auth.email ?? '-'),
            const SizedBox(height: 8),
            _InfoRow(label: 'Telefon', value: auth.phone ?? '-'),
            const SizedBox(height: 16),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              leading: const Icon(Icons.confirmation_number_outlined),
              title: const Text('Kupljene karte'),
              children: [
                if (orders.orders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Nema kupljenih karata'),
                    ),
                  )
                else
                  for (final o in orders.orders) ...[
                    const SizedBox(height: 4),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Porudžbina • ${_formatDateTime(o.createdAt)}'),
                      subtitle: Text(
                        'Ukupno: ${o.totalPrice.toStringAsFixed(2)}',
                      ),
                    ),
                    for (final it in o.items)
                      Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 6),
                        child: Text(
                          '${it.title} • x${it.quantity} • ${it.price.toStringAsFixed(2)}',
                        ),
                      ),
                    const Divider(height: 16),
                  ],
              ],
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              leading: const Icon(Icons.favorite_border),
              title: const Text('Wishlist'),
              children: [
                if (season == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Nema aktivne sezone'),
                    ),
                  )
                else ...[
                  const SizedBox(height: 4),
                  if (wishlistRaces.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8, bottom: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Wishlist je prazna'),
                      ),
                    )
                  else
                    for (final r in wishlistRaces)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(r.name),
                        subtitle: Text('${r.city}, ${r.country} • ${r.date}'),
                        leading: const Icon(Icons.favorite),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => wishlist.remove(r.id),
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RaceDetailScreen(race: r),
                            ),
                          );
                        },
                      ),
                  const SizedBox(height: 8),
                  Text(
                    'Dodaj dostupne trke',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  if (upcoming.isEmpty)
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Nema dostupnih trka'),
                    )
                  else
                    for (final r in upcoming)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(r.name),
                        subtitle: Text('${r.city}, ${r.country} • ${r.date}'),
                        trailing: IconButton(
                          icon: Icon(
                            wishlist.contains(r.id)
                                ? Icons.favorite
                                : Icons.favorite_border,
                          ),
                          onPressed: () {
                            if (wishlist.contains(r.id)) {
                              wishlist.remove(r.id);
                            } else {
                              wishlist.add(r.id);
                            }
                          },
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RaceDetailScreen(race: r),
                            ),
                          );
                        },
                      ),
                ],
              ],
            ),
          ],
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

  static String _formatDateTime(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
