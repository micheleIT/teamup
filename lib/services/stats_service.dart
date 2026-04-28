import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_record.dart';
import '../models/player_stats.dart';
import '../models/sport.dart';

class StatsService extends ChangeNotifier {
  static const _prefsKey = 'teamup_game_records';

  final List<GameRecord> _records = [];

  List<GameRecord> get records => List.unmodifiable(
    List<GameRecord>.of(_records)
      ..sort((a, b) => b.playedAt.compareTo(a.playedAt)),
  );

  /// Load persisted records. Call once from main() or app init.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    final loadedRecords = <GameRecord>[];
    var removedInvalidEntries = false;

    for (final entry in raw) {
      try {
        loadedRecords.add(GameRecord.fromJsonString(entry));
      } catch (_) {
        removedInvalidEntries = true;
      }
    }

    _records
      ..clear()
      ..addAll(loadedRecords);

    if (removedInvalidEntries) {
      await _persist();
    }
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

  // ── Import / Export ─────────────────────────────────────────────────────────

  /// Returns a JSON string containing game records.
  /// When [since] is provided only records played on or after that date are
  /// included (e.g. pass the start of today to export only today's games).
  String exportToJson({DateTime? since}) {
    final toExport = since == null
        ? List<GameRecord>.of(_records)
        : _records.where((r) => !r.playedAt.isBefore(since)).toList();
    return jsonEncode(toExport.map((r) => r.toJson()).toList());
  }

  /// Import game records from a JSON string produced by [exportToJson].
  ///
  /// * [merge] == `true`  — new records are appended; records whose [id]
  ///   already exists locally are silently skipped.
  /// * [merge] == `false` — all existing records are replaced by the
  ///   imported ones.
  ///
  /// Throws a [FormatException] when [json] is not valid JSON or does not
  /// contain a top-level list of record objects.
  Future<void> importFromJson(String json, {required bool merge}) async {
    final decoded = jsonDecode(json);
    if (decoded is! List) {
      throw const FormatException(
        'Invalid statistics file: expected a JSON array of game records.',
      );
    }
    final imported = decoded
        .map((e) => GameRecord.fromJson(e as Map<String, dynamic>))
        .toList();

    if (merge) {
      final existingIds = _records.map((r) => r.id).toSet();
      for (final record in imported) {
        if (!existingIds.contains(record.id)) {
          _records.add(record);
        }
      }
    } else {
      _records
        ..clear()
        ..addAll(imported);
    }
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
  /// Optionally filter to a specific [sport] and/or only include records
  /// whose [GameRecord.playedAt] is on or after [since].
  List<PlayerStats> computeStats({Sport? sport, DateTime? since}) {
    final filtered = _records.where((r) {
      if (sport != null && r.sport != sport) return false;
      if (since != null && r.playedAt.isBefore(since)) return false;
      return true;
    }).toList();

    // Map normalised-name → mutable accumulators.
    // Keying by name (case-insensitive) ensures that historical records where
    // the same player was stored under different IDs are merged into one row.
    final Map<String, _Accumulator> acc = {};

    for (final record in filtered) {
      for (final team in record.teams) {
        final isWinner = record.winnerTeamNumber == team.number;
        final isDraw = record.isDraw;

        for (final gp in team.players) {
          final key = gp.name.toLowerCase();
          final a = acc.putIfAbsent(
            key,
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
