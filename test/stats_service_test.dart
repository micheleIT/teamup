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
  });
}
