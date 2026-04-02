import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_record.dart';
import '../models/player_stats.dart';
import '../models/sport.dart';

class StatsService extends ChangeNotifier {
  static const _prefsKey = 'teamup_game_records';

  final List<GameRecord> _records = [];

  List<GameRecord> get records => List.unmodifiable(
    _records..sort((a, b) => b.playedAt.compareTo(a.playedAt)),
  );

  /// Load persisted records. Call once from main() or app init.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    _records
      ..clear()
      ..addAll(raw.map(GameRecord.fromJsonString));
    notifyListeners();
  }

  /// Persist and add a new game record.
  Future<void> addRecord(GameRecord record) async {
    _records.add(record);
    await _persist();
    notifyListeners();
  }

  /// Delete a game record by id.
  Future<void> deleteRecord(String id) async {
    _records.removeWhere((r) => r.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      _records.map((r) => r.toJsonString()).toList(),
    );
  }

  // ── Stats computation ───────────────────────────────────────────────────────

  /// Returns per-player stats aggregated over [records] (all by default).
  /// Optionally filter to a specific [sport].
  List<PlayerStats> computeStats({Sport? sport}) {
    final filtered = sport == null
        ? _records
        : _records.where((r) => r.sport == sport).toList();

    // Map playerId → mutable accumulators
    final Map<String, _Accumulator> acc = {};

    for (final record in filtered) {
      for (final team in record.teams) {
        final isWinner = record.winnerTeamNumber == team.number;
        final isDraw = record.isDraw;

        for (final gp in team.players) {
          final a = acc.putIfAbsent(
            gp.id,
            () => _Accumulator(id: gp.id, name: gp.name),
          );
          a.name = gp.name; // keep most recent
          a.total++;
          if (isDraw) {
            a.draws++;
          } else if (isWinner) {
            a.wins++;
          } else {
            a.losses++;
          }

          // Per-sport bucket
          final sb = a.bySport.putIfAbsent(
            record.sport,
            () => _SportAccumulator(),
          );
          sb.total++;
          if (isDraw) {
            sb.draws++;
          } else if (isWinner) {
            sb.wins++;
          } else {
            sb.losses++;
          }
        }
      }
    }

    return acc.values
        .map(
          (a) => PlayerStats(
            playerId: a.id,
            playerName: a.name,
            gamesPlayed: a.total,
            wins: a.wins,
            draws: a.draws,
            losses: a.losses,
            bySport: a.bySport.map(
              (s, sb) => MapEntry(
                s,
                SportStats(
                  gamesPlayed: sb.total,
                  wins: sb.wins,
                  draws: sb.draws,
                  losses: sb.losses,
                ),
              ),
            ),
          ),
        )
        .toList()
      ..sort((a, b) {
        final cmp = b.wins.compareTo(a.wins);
        return cmp != 0 ? cmp : b.gamesPlayed.compareTo(a.gamesPlayed);
      });
  }
}

// ── Private accumulators ──────────────────────────────────────────────────────

class _Accumulator {
  final String id;
  String name;
  int total = 0;
  int wins = 0;
  int draws = 0;
  int losses = 0;
  final Map<Sport, _SportAccumulator> bySport = {};

  _Accumulator({required this.id, required this.name});
}

class _SportAccumulator {
  int total = 0;
  int wins = 0;
  int draws = 0;
  int losses = 0;
}
