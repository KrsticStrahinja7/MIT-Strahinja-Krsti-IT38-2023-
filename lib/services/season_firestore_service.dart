import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/season.dart';

class SeasonFirestoreService {
  final FirebaseFirestore _db;

  SeasonFirestoreService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  Future<List<int>> listSeasonYears() async {
    final snap = await _db.collection('seasons').orderBy('year', descending: true).get();
    return snap.docs.map((d) => (d.data()['year'] as num?)?.toInt() ?? 0).where((y) => y > 0).toList();
  }

  Future<Season> loadSeason(int year) async {
    final seasonRef = _db.collection('seasons').doc('$year');

    final seasonDoc = await seasonRef.get();
    if (!seasonDoc.exists) {
      throw Exception('Sezona $year ne postoji u bazi');
    }

    final driversF = seasonRef.collection('drivers').get();
    final teamsF = seasonRef.collection('teams').get();
    final racesF = seasonRef.collection('races').orderBy('date').get();

    final driversSnap = await driversF;
    final teamsSnap = await teamsF;
    final racesSnap = await racesF;

    final drivers = driversSnap.docs.map((d) {
      final data = d.data();
      return Driver(
        id: d.id,
        name: (data['name'] as String?) ?? d.id,
        teamId: (data['teamId'] as String?) ?? '',
        points: (data['points'] as num?)?.toInt() ?? 0,
      );
    }).toList();

    final teams = teamsSnap.docs.map((d) {
      final data = d.data();
      return Team(
        id: d.id,
        name: (data['name'] as String?) ?? d.id,
        points: (data['points'] as num?)?.toInt() ?? 0,
      );
    }).toList();

    final races = racesSnap.docs.map((d) {
      final data = d.data();
      final results = ((data['results'] as List?) ?? const [])
          .map((e) => RaceResult.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final sprintResults = ((data['sprintResults'] as List?) ?? const [])
          .map((e) => RaceResult.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      return Race(
        id: d.id,
        seasonYear: year,
        name: (data['name'] as String?) ?? d.id,
        circuitName: (data['circuitName'] as String?) ?? '',
        city: (data['city'] as String?) ?? '',
        country: (data['country'] as String?) ?? '',
        date: (data['date'] as String?) ?? '',
        hasSprint: (data['hasSprint'] as bool?) ?? false,
        results: results,
        sprintResults: sprintResults,
      );
    }).toList();

    return Season(year: year, drivers: drivers, teams: teams, races: races);
  }
}
