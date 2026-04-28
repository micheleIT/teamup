import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teamup/models/game_record.dart';
import 'package:teamup/models/sport.dart';
import 'package:teamup/services/stats_service.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

GameRecord _record({
  required DateTime playedAt,
  Sport sport = Sport.soccer,
  int? winnerTeamNumber,
  String p1Id = 'p1',
  String p1Name = 'Alice',
  String p2Id = 'p2',
  String p2Name = 'Bob',
}) {
  return GameRecord(
    id: '${playedAt.microsecondsSinceEpoch}_$sport',
    sport: sport,
    playedAt: playedAt,
    teams: [
      GameTeam(
        number: 1,
        players: [GamePlayer(id: p1Id, name: p1Name)],
      ),
      GameTeam(
        number: 2,
        players: [GamePlayer(id: p2Id, name: p2Name)],
      ),
    ],
    winnerTeamNumber: winnerTeamNumber,
  );
}

DateTime get _startOfToday {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('StatsService.computeStats — since filter', () {
    late StatsService service;

    setUp(() {
      service = StatsService();
    });

    test('returns stats for ALL records when since is null', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final today = DateTime.now();
      await service.addRecord(
        _record(playedAt: yesterday, winnerTeamNumber: 1),
      );
      await service.addRecord(_record(playedAt: today, winnerTeamNumber: 1));

      final stats = service.computeStats();
      final alice = stats.firstWhere((s) => s.playerName == 'Alice');
      expect(alice.gamesPlayed, 2);
    });

    test(
      'returns only today\'s records when since is start of today',
      () async {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final today = DateTime.now();
        await service.addRecord(
          _record(playedAt: yesterday, winnerTeamNumber: 1),
        );
        await service.addRecord(_record(playedAt: today, winnerTeamNumber: 1));

        final stats = service.computeStats(since: _startOfToday);
        final alice = stats.firstWhere((s) => s.playerName == 'Alice');
        expect(alice.gamesPlayed, 1);
      },
    );

    test('returns empty list when no games were played today', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await service.addRecord(
        _record(playedAt: yesterday, winnerTeamNumber: 1),
      );

      final stats = service.computeStats(since: _startOfToday);
      expect(stats, isEmpty);
    });

    test('includes record whose playedAt is exactly start-of-today', () async {
      await service.addRecord(
        _record(playedAt: _startOfToday, winnerTeamNumber: 1),
      );

      final stats = service.computeStats(since: _startOfToday);
      expect(stats, isNotEmpty);
      final alice = stats.firstWhere((s) => s.playerName == 'Alice');
      expect(alice.gamesPlayed, 1);
    });

    test('since and sport filters compose correctly', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final today = DateTime.now();

      await service.addRecord(
        _record(playedAt: yesterday, sport: Sport.soccer, winnerTeamNumber: 1),
      );
      await service.addRecord(
        _record(playedAt: today, sport: Sport.soccer, winnerTeamNumber: 1),
      );
      await service.addRecord(
        _record(playedAt: today, sport: Sport.basketball, winnerTeamNumber: 1),
      );

      // Only today's soccer games
      final stats = service.computeStats(
        sport: Sport.soccer,
        since: _startOfToday,
      );
      final alice = stats.firstWhere((s) => s.playerName == 'Alice');
      expect(alice.gamesPlayed, 1);
    });

    test('win/loss counts are correct for filtered records', () async {
      final today = DateTime.now();
      // Alice wins game 1, Bob wins game 2
      await service.addRecord(
        _record(playedAt: today, winnerTeamNumber: 1),
      ); // Alice (team 1) wins
      await service.addRecord(
        _record(playedAt: today, winnerTeamNumber: 2),
      ); // Bob (team 2) wins

      final stats = service.computeStats(since: _startOfToday);
      final alice = stats.firstWhere((s) => s.playerName == 'Alice');
      final bob = stats.firstWhere((s) => s.playerName == 'Bob');

      expect(alice.wins, 1);
      expect(alice.losses, 1);
      expect(bob.wins, 1);
      expect(bob.losses, 1);
    });

    test('draw is counted correctly in today filter', () async {
      final today = DateTime.now();
      // null winnerTeamNumber = draw
      await service.addRecord(_record(playedAt: today));

      final stats = service.computeStats(since: _startOfToday);
      final alice = stats.firstWhere((s) => s.playerName == 'Alice');
      expect(alice.draws, 1);
      expect(alice.wins, 0);
      expect(alice.losses, 0);
    });

    test(
      'same player name with different IDs in historical records is merged',
      () async {
        // Simulate two old records where "Alice" was stored under a different
        // ID (e.g. before the uniqueness fix was in place).
        final today = DateTime.now();
        await service.addRecord(
          _record(playedAt: today, winnerTeamNumber: 1, p1Id: 'old-id-1'),
        );
        await service.addRecord(
          _record(playedAt: today, winnerTeamNumber: 1, p1Id: 'old-id-2'),
        );

        final stats = service.computeStats();

        // Must be exactly ONE entry for Alice, not two.
        final aliceEntries = stats
            .where((s) => s.playerName == 'Alice')
            .toList();
        expect(aliceEntries, hasLength(1));

        // Both games must be counted.
        expect(aliceEntries.first.gamesPlayed, 2);
        expect(aliceEntries.first.wins, 2);
      },
    );
  });

  // ── Import / Export ──────────────────────────────────────────────────────────

  group('StatsService export / import', () {
    late StatsService service;

    setUp(() {
      service = StatsService();
    });

    test('exportToJson without date filter exports all records', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final today = DateTime.now();
      await service.addRecord(
        _record(playedAt: yesterday, winnerTeamNumber: 1),
      );
      await service.addRecord(_record(playedAt: today, winnerTeamNumber: 2));

      final json = service.exportToJson();
      final decoded = jsonDecode(json) as List;
      expect(decoded, hasLength(2));
    });

    test('exportToJson with date filter returns only matching records', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final today = DateTime.now();
      await service.addRecord(
        _record(playedAt: yesterday, winnerTeamNumber: 1),
      );
      await service.addRecord(_record(playedAt: today, winnerTeamNumber: 2));

      final json = service.exportToJson(since: _startOfToday);
      final decoded = jsonDecode(json) as List;
      expect(decoded, hasLength(1));
    });

    test('exportToJson returns empty JSON array when no records match filter', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await service.addRecord(
        _record(playedAt: yesterday, winnerTeamNumber: 1),
      );

      final json = service.exportToJson(since: _startOfToday);
      expect(json, '[]');
    });

    test('importFromJson with merge=false replaces all records', () async {
      final today = DateTime.now();
      await service.addRecord(
        _record(playedAt: today, winnerTeamNumber: 1),
      );
      expect(service.records, hasLength(1));

      // Build a JSON string with two new records
      final other = StatsService();
      final d1 = DateTime(2025, 1, 1);
      final d2 = DateTime(2025, 1, 2);
      await other.addRecord(
        _record(playedAt: d1, winnerTeamNumber: 1, p1Id: 'new1', p1Name: 'Eve'),
      );
      await other.addRecord(
        _record(playedAt: d2, winnerTeamNumber: 2, p1Id: 'new2', p1Name: 'Eve'),
      );
      final json = other.exportToJson();

      await service.importFromJson(json, merge: false);

      // Old record gone; two new records present
      expect(service.records, hasLength(2));
      expect(service.records.every((r) => r.teams.first.players.first.name == 'Eve'), isTrue);
    });

    test('importFromJson with merge=true appends new records', () async {
      final today = DateTime.now();
      await service.addRecord(
        _record(playedAt: today, winnerTeamNumber: 1),
      );
      expect(service.records, hasLength(1));
      final existingId = service.records.first.id;

      // Export from another service with one overlapping + one new record
      final other = StatsService();
      // Same record (same id should be skipped)
      await other.addRecord(service.records.first);
      // Brand-new record
      await other.addRecord(
        _record(
          playedAt: DateTime(2025, 6, 1),
          winnerTeamNumber: 2,
          p1Id: 'newp',
          p1Name: 'Charlie',
        ),
      );
      final json = other.exportToJson();

      await service.importFromJson(json, merge: true);

      // Should have original + 1 new = 2 records (duplicate skipped)
      expect(service.records, hasLength(2));
      expect(service.records.any((r) => r.id == existingId), isTrue);
      expect(
        service.records.any(
          (r) => r.teams.first.players.first.name == 'Charlie',
        ),
        isTrue,
      );
    });

    test('importFromJson with merge=true on empty service adds all records', () async {
      final other = StatsService();
      final d = DateTime(2025, 3, 10);
      await other.addRecord(_record(playedAt: d, winnerTeamNumber: 1));
      final json = other.exportToJson();

      await service.importFromJson(json, merge: true);

      expect(service.records, hasLength(1));
    });

    test('importFromJson persists data across reload', () async {
      final other = StatsService();
      await other.addRecord(
        _record(playedAt: DateTime(2025, 4, 1), winnerTeamNumber: 1),
      );
      final json = other.exportToJson();

      await service.importFromJson(json, merge: false);

      // Reload from prefs
      final reloaded = StatsService();
      await reloaded.load();
      expect(reloaded.records, hasLength(1));
    });

    test('importFromJson throws FormatException for invalid JSON', () async {
      expect(
        () => service.importFromJson('not json', merge: true),
        throwsA(isA<FormatException>()),
      );
    });

    test('importFromJson throws FormatException when JSON is not a list', () async {
      expect(
        () => service.importFromJson('{"key": "value"}', merge: true),
        throwsA(isA<FormatException>()),
      );
    });

    test('roundtrip: export then import restores identical records', () async {
      final t1 = DateTime(2025, 5, 20, 10, 0);
      final t2 = DateTime(2025, 5, 21, 14, 30);
      await service.addRecord(
        _record(playedAt: t1, sport: Sport.soccer, winnerTeamNumber: 1),
      );
      await service.addRecord(
        _record(
          playedAt: t2,
          sport: Sport.basketball,
          winnerTeamNumber: null, // draw
        ),
      );

      final json = service.exportToJson();

      final target = StatsService();
      await target.importFromJson(json, merge: false);

      expect(target.records, hasLength(2));

      final soccerRecord = target.records.firstWhere(
        (r) => r.sport == Sport.soccer,
      );
      expect(soccerRecord.winnerTeamNumber, 1);

      final basketballRecord = target.records.firstWhere(
        (r) => r.sport == Sport.basketball,
      );
      expect(basketballRecord.isDraw, isTrue);
    });
  });
}
