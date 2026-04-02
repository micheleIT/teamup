import 'dart:convert';
import '../models/sport.dart';

// ── Snapshot of a player at game time ─────────────────────────────────────────

class GamePlayer {
  final String id;
  final String name;

  const GamePlayer({required this.id, required this.name});

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory GamePlayer.fromJson(Map<String, dynamic> j) =>
      GamePlayer(id: j['id'] as String, name: j['name'] as String);
}

// ── One team in a recorded game ───────────────────────────────────────────────

class GameTeam {
  final int number;
  final List<GamePlayer> players;

  const GameTeam({required this.number, required this.players});

  Map<String, dynamic> toJson() => {
    'number': number,
    'players': players.map((p) => p.toJson()).toList(),
  };

  factory GameTeam.fromJson(Map<String, dynamic> j) => GameTeam(
    number: j['number'] as int,
    players: (j['players'] as List)
        .map((p) => GamePlayer.fromJson(p as Map<String, dynamic>))
        .toList(),
  );
}

// ── A completed game ──────────────────────────────────────────────────────────

class GameRecord {
  final String id;
  final Sport sport;
  final DateTime playedAt;
  final List<GameTeam> teams;

  /// null = draw
  final int? winnerTeamNumber;

  const GameRecord({
    required this.id,
    required this.sport,
    required this.playedAt,
    required this.teams,
    this.winnerTeamNumber,
  });

  bool get isDraw => winnerTeamNumber == null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'sport': sport.name,
    'playedAt': playedAt.toIso8601String(),
    'teams': teams.map((t) => t.toJson()).toList(),
    'winnerTeamNumber': winnerTeamNumber,
  };

  factory GameRecord.fromJson(Map<String, dynamic> j) => GameRecord(
    id: j['id'] as String,
    sport: Sport.values.firstWhere(
      (s) => s.name == j['sport'],
      orElse: () => Sport.custom,
    ),
    playedAt: DateTime.parse(j['playedAt'] as String),
    teams: (j['teams'] as List)
        .map((t) => GameTeam.fromJson(t as Map<String, dynamic>))
        .toList(),
    winnerTeamNumber: j['winnerTeamNumber'] as int?,
  );

  String toJsonString() => jsonEncode(toJson());
  factory GameRecord.fromJsonString(String s) =>
      GameRecord.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
