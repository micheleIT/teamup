import 'dart:math';
import '../models/player.dart';
import '../models/team.dart';

/// Randomly distributes [players] into [teamCount] as-equal-as-possible teams.
///
/// Throws [ArgumentError] if [teamCount] < 2 or there are fewer players than teams.
List<Team> generateTeams(List<Player> players, int teamCount) {
  if (teamCount < 2) throw ArgumentError('teamCount must be at least 2');
  if (players.length < teamCount) {
    throw ArgumentError(
        'Not enough players (${players.length}) for $teamCount teams');
  }

  final shuffled = List<Player>.from(players)..shuffle(Random());

  // Pre-create empty mutable lists for each team
  final buckets = List.generate(teamCount, (_) => <Player>[]);

  for (var i = 0; i < shuffled.length; i++) {
    buckets[i % teamCount].add(shuffled[i]);
  }

  return [
    for (var i = 0; i < teamCount; i++)
      Team(number: i + 1, players: List.unmodifiable(buckets[i])),
  ];
}
