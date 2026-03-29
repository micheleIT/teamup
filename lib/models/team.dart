import 'player.dart';

class Team {
  final int number;
  final List<Player> players;

  const Team({required this.number, required this.players});

  String get name => 'Team $number';
}
