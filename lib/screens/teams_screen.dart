import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models/team.dart';
import '../utils/team_generator.dart';
import '../widgets/court_background.dart';
import 'record_result_sheet.dart';
import 'wheel_assignment_screen.dart';

class TeamsScreen extends StatefulWidget {
  final AppState state;

  /// If provided, these teams are displayed directly without re-shuffling.
  /// The reshuffle button is still available to generate fresh teams.
  final List<Team>? precomputedTeams;

  const TeamsScreen({super.key, required this.state, this.precomputedTeams});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  late List<Team> _teams;
  bool _resultRecorded = false;

  @override
  void initState() {
    super.initState();
    if (widget.precomputedTeams != null) {
      _teams = widget.precomputedTeams!;
    } else {
      _roll();
    }
  }

  void _roll() {
    setState(() {
      _teams = generateTeams(widget.state.players, widget.state.teamCount);
      _resultRecorded = false;
    });
  }

  Future<void> _recordResult(BuildContext context, {String? skipButtonLabel}) async {
    if (_resultRecorded) return;
    final record = await showRecordResultSheet(
      context: context,
      sport: widget.state.selectedSport,
      teams: _teams,
      allPlayers: widget.state.players,
      skipButtonLabel: skipButtonLabel,
    );
    if (record == null) return;
    await widget.state.statsService.addRecord(record);
    setState(() => _resultRecorded = true);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Result recorded!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _reshuffle(BuildContext context) async {
    if (widget.state.autoAskForResults && !_resultRecorded) {
      await _recordResult(context, skipButtonLabel: 'Reshuffle without saving');
    }
    if (!context.mounted) return;
    if (widget.state.wheelEnabled) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WheelAssignmentScreen(state: widget.state),
        ),
      );
    } else {
      _roll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _teamColors(context, _teams.length);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.state.selectedSport.icon}  Teams'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _resultRecorded
                  ? Icons.emoji_events
                  : Icons.emoji_events_outlined,
            ),
            tooltip: _resultRecorded ? 'Result already recorded' : 'Record result',
            onPressed: _resultRecorded ? null : () => _recordResult(context),
          ),
          IconButton(
            icon: const Icon(Icons.shuffle),
            tooltip: 'Shuffle again',
            onPressed: () => _reshuffle(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          CourtBackground(sport: widget.state.selectedSport),
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _teams.length,
            itemBuilder: (context, i) {
              final team = _teams[i];
              final color = colors[i % colors.length];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                color: color.withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: color, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Team header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(11),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            team.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${team.players.length} player${team.players.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Players
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          for (final player in team.players)
                            ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: color.withValues(alpha: 0.25),
                                child: Text(
                                  player.name[0].toUpperCase(),
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(player.name),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _reshuffle(context),
        icon: const Icon(Icons.shuffle),
        label: const Text('Reshuffle'),
      ),
    );
  }

  static List<Color> _teamColors(BuildContext context, int count) {
    // A palette of visually distinct, accessible-ish colors for teams
    const palette = [
      Color(0xFF1565C0), // blue
      Color(0xFFC62828), // red
      Color(0xFF2E7D32), // green
      Color(0xFFEF6C00), // orange
      Color(0xFF6A1B9A), // purple
      Color(0xFF00838F), // teal
      Color(0xFF558B2F), // lime/olive
      Color(0xFF4527A0), // deep purple
    ];
    if (count <= palette.length) return palette.sublist(0, count);
    // Cycle if somehow more teams than colors
    return [for (var i = 0; i < count; i++) palette[i % palette.length]];
  }
}
