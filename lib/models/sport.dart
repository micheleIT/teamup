enum Sport {
  soccer(
    label: 'Soccer ⚽',
    icon: '⚽',
    defaultTeamSize: 11,
    minTeamSize: 5,
    maxTeamSize: 11,
    minPlayers: 4,
  ),
  volleyball(
    label: 'Volleyball 🏐',
    icon: '🏐',
    defaultTeamSize: 6,
    minTeamSize: 3,
    maxTeamSize: 6,
    minPlayers: 4,
  ),
  basketball(
    label: 'Basketball 🏀',
    icon: '🏀',
    defaultTeamSize: 5,
    minTeamSize: 3,
    maxTeamSize: 5,
    minPlayers: 4,
  ),
  custom(
    label: 'Custom',
    icon: '🏷️',
    defaultTeamSize: 5,
    minTeamSize: 2,
    maxTeamSize: 20,
    minPlayers: 2,
  );

  const Sport({
    required this.label,
    required this.icon,
    required this.defaultTeamSize,
    required this.minTeamSize,
    required this.maxTeamSize,
    required this.minPlayers,
  });

  final String label;
  final String icon;
  final int defaultTeamSize;
  final int minTeamSize;
  final int maxTeamSize;
  final int minPlayers;
}
