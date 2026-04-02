import '../models/sport.dart';

/// Stats for one sport specifically.
class SportStats {
  final int gamesPlayed;
  final int wins;
  final int draws;
  final int losses;

  const SportStats({
    required this.gamesPlayed,
    required this.wins,
    required this.draws,
    required this.losses,
  });

  double get winRate => gamesPlayed == 0 ? 0.0 : wins / gamesPlayed;
}

/// Aggregated stats for a single player across all (or filtered) games.
class PlayerStats {
  final String playerId;

  /// Most-recently seen display name for this player.
  final String playerName;

  final int gamesPlayed;
  final int wins;
  final int draws;
  final int losses;

  /// Breakdown per sport — only contains sports the player has played.
  final Map<Sport, SportStats> bySport;

  const PlayerStats({
    required this.playerId,
    required this.playerName,
    required this.gamesPlayed,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.bySport,
  });

  double get winRate => gamesPlayed == 0 ? 0.0 : wins / gamesPlayed;
  double get drawRate => gamesPlayed == 0 ? 0.0 : draws / gamesPlayed;
  double get lossRate => gamesPlayed == 0 ? 0.0 : losses / gamesPlayed;
}
