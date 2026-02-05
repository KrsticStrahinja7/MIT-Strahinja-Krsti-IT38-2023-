class Driver {
  final String id;
  final String name;
  final String teamId;
  final int points;

  Driver({required this.id, required this.name, required this.teamId, required this.points});

  factory Driver.fromJson(Map<String, dynamic> json) => Driver(
        id: json['id'] as String,
        name: json['name'] as String,
        teamId: json['teamId'] as String,
        points: json['points'] as int,
      );
}

class Team {
  final String id;
  final String name;
  final int points;

  Team({required this.id, required this.name, required this.points});

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        id: json['id'] as String,
        name: json['name'] as String,
        points: json['points'] as int,
      );
}

class Race {
  final String id;
  final int seasonYear;
  final String name;
  final String circuitName;
  final String city;
  final String country;
  final String date; // ISO string for simplicity
  final bool hasSprint;

  Race({
    required this.id,
    required this.seasonYear,
    required this.name,
    required this.circuitName,
    required this.city,
    required this.country,
    required this.date,
    required this.hasSprint,
  });

  factory Race.fromJson(Map<String, dynamic> json) => Race(
        id: json['id'] as String,
        seasonYear: json['seasonYear'] as int,
        name: json['name'] as String,
        circuitName: json['circuitName'] as String,
        city: json['city'] as String,
        country: json['country'] as String,
        date: json['date'] as String,
        hasSprint: json['hasSprint'] as bool? ?? false,
      );
}

class Season {
  final int year;
  final List<Driver> drivers;
  final List<Team> teams;
  final List<Race> races;

  Season({required this.year, required this.drivers, required this.teams, required this.races});

  factory Season.fromJson(Map<String, dynamic> json) => Season(
        year: json['year'] as int,
        drivers: (json['drivers'] as List).map((e) => Driver.fromJson(e as Map<String, dynamic>)).toList(),
        teams: (json['teams'] as List).map((e) => Team.fromJson(e as Map<String, dynamic>)).toList(),
        races: (json['races'] as List).map((e) => Race.fromJson(e as Map<String, dynamic>)).toList(),
      );
}
