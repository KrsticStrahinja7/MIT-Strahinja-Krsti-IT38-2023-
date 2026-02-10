import 'package:flutter/foundation.dart';
import '../models/season.dart';
import '../services/season_firestore_service.dart';

class SeasonsProvider extends ChangeNotifier {
  final _service = SeasonFirestoreService();

  List<Season> _seasons = [];
  Season? _active;
  bool _loading = false;
  String? _error;

  List<Season> get seasons => _seasons;
  Season? get active => _active;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final years = await _service.listSeasonYears();
      final loaded = <Season>[];
      for (final y in years) {
        loaded.add(await _service.loadSeason(y));
      }
      _seasons = loaded.map(_withComputedStandings).toList();
      if (_seasons.isNotEmpty) {
        _seasons.sort((a, b) => b.year.compareTo(a.year));
        _active = _seasons.first;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setActive(Season s) {
    _active = s;
    notifyListeners();
  }

  Season _withComputedStandings(Season s) {
    // F1 points rules
    const racePoints = [25, 18, 15, 12, 10, 8, 6, 4, 2, 1];
    const sprintPoints = [8, 7, 6, 5, 4, 3, 2, 1];

    final Map<String, int> driverPoints = {for (final d in s.drivers) d.id: 0};

    final Map<String, String> driverTeam = {
      for (final d in s.drivers) d.id: d.teamId,
    };

    for (final race in s.races) {
      for (final r in race.results) {
        final idx = r.position - 1;
        final pts = (idx >= 0 && idx < racePoints.length) ? racePoints[idx] : 0;
        driverPoints[r.driverId] = (driverPoints[r.driverId] ?? 0) + pts;
      }
      for (final r in race.sprintResults) {
        final idx = r.position - 1;
        final pts = (idx >= 0 && idx < sprintPoints.length)
            ? sprintPoints[idx]
            : 0;
        driverPoints[r.driverId] = (driverPoints[r.driverId] ?? 0) + pts;
      }
    }

    final updatedDrivers = [
      for (final d in s.drivers)
        Driver(
          id: d.id,
          name: d.name,
          teamId: d.teamId,
          points: driverPoints[d.id] ?? 0,
        ),
    ];

    final Map<String, int> teamPoints = {for (final t in s.teams) t.id: 0};
    driverPoints.forEach((driverId, pts) {
      final teamId = driverTeam[driverId];
      if (teamId != null) {
        teamPoints[teamId] = (teamPoints[teamId] ?? 0) + pts;
      }
    });
    final updatedTeams = [
      for (final t in s.teams)
        Team(id: t.id, name: t.name, points: teamPoints[t.id] ?? 0),
    ];

    return Season(
      year: s.year,
      drivers: updatedDrivers,
      teams: updatedTeams,
      races: s.races,
    );
  }
}
