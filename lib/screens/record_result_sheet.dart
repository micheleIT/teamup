import 'package:flutter/material.dart';
import '../models/game_record.dart';
import '../models/player.dart';
import '../models/sport.dart';
import '../models/team.dart';

/// Shows a bottom sheet to record the result of a completed game.
/// Returns the saved [GameRecord], or null if the user dismissed.
Future<GameRecord?> showRecordResultSheet({
  required BuildContext context,
  required Sport sport,
  required List<Team> teams,
  required List<Player> allPlayers,
}) {
  return showModalBottomSheet<GameRecord>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) =>
        _RecordResultSheet(sport: sport, teams: teams, allPlayers: allPlayers),
  );
}

// ── Sheet widget ──────────────────────────────────────────────────────────────

class _RecordResultSheet extends StatefulWidget {
  final Sport sport;
  final List<Team> teams;
  final List<Player> allPlayers;

  const _RecordResultSheet({
    required this.sport,
    required this.teams,
    required this.allPlayers,
  });

  @override
  State<_RecordResultSheet> createState() => _RecordResultSheetState();
}

class _RecordResultSheetState extends State<_RecordResultSheet> {
  /// null = draw, else the winning team's number
  int? _selectedWinner;
  bool _isDraw = false;

  static const _teamColors = [
    Color(0xFF1565C0),
    Color(0xFFC62828),
    Color(0xFF2E7D32),
    Color(0xFFEF6C00),
    Color(0xFF6A1B9A),
    Color(0xFF00838F),
    Color(0xFF558B2F),
    Color(0xFF4527A0),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom,
        left: 16,
        right: 16,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text(
            'Who won? ${widget.sport.icon}',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Team buttons
          ...widget.teams.asMap().entries.map((e) {
            final i = e.key;
            final team = e.value;
            final color = _teamColors[i % _teamColors.length];
            final selected = !_isDraw && _selectedWinner == team.number;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: selected
                      ? color.withValues(alpha: 0.15)
                      : null,
                  side: BorderSide(
                    color: selected ? color : Colors.grey[400]!,
                    width: selected ? 2 : 1,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => setState(() {
                  _isDraw = false;
                  _selectedWinner = team.number;
                }),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (selected)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(Icons.emoji_events, size: 20),
                      ),
                    Text(
                      'Team ${team.number}  ·  '
                      '${team.players.map((p) => p.name).join(', ')}',
                      style: TextStyle(
                        color: selected ? color : null,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }),

          // Draw option
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: _isDraw
                    ? Colors.grey.withValues(alpha: 0.15)
                    : null,
                side: BorderSide(
                  color: _isDraw ? Colors.grey[700]! : Colors.grey[400]!,
                  width: _isDraw ? 2 : 1,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => setState(() {
                _isDraw = true;
                _selectedWinner = null;
              }),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isDraw)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.handshake_outlined, size: 20),
                    ),
                  Text(
                    'Draw / No winner',
                    style: TextStyle(
                      color: _isDraw ? Colors.grey[800] : null,
                      fontWeight: _isDraw ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Confirm
          FilledButton.icon(
            onPressed: (_selectedWinner != null || _isDraw) ? _confirm : null,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save Result'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _confirm() {
    final gamePlayers = {for (final p in widget.allPlayers) p.id: p};

    final gameTeams = widget.teams.map((t) {
      return GameTeam(
        number: t.number,
        players: t.players.map((p) {
          final current = gamePlayers[p.id];
          return GamePlayer(id: p.id, name: current?.name ?? p.name);
        }).toList(),
      );
    }).toList();

    final record = GameRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      sport: widget.sport,
      playedAt: DateTime.now(),
      teams: gameTeams,
      winnerTeamNumber: _isDraw ? null : _selectedWinner,
    );

    Navigator.pop(context, record);
  }
}
