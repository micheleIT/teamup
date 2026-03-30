import 'dart:math';

import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../utils/team_generator.dart';
import '../widgets/court_background.dart';
import '../widgets/fortune_wheel.dart';
import 'teams_screen.dart';

// ── Data ──────────────────────────────────────────────────────────────────────

typedef _Assignment = ({Player player, int teamNumber, Color teamColor});

enum _Phase { ready, spinning, revealing }

// ── Screen ────────────────────────────────────────────────────────────────────

class WheelAssignmentScreen extends StatefulWidget {
  final AppState state;
  const WheelAssignmentScreen({super.key, required this.state});

  @override
  State<WheelAssignmentScreen> createState() => _WheelAssignmentScreenState();
}

class _WheelAssignmentScreenState extends State<WheelAssignmentScreen> {
  final _wheelKey = GlobalKey<FortuneWheelState>();

  late final List<Team> _teams;
  late final List<_Assignment> _assignments;
  late List<Player> _remaining;

  int _step = 0;
  _Phase _phase = _Phase.ready;

  // Team colors (same set as TeamsScreen)
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

  // Segment colors for the wheel — vibrant, high-contrast
  static const _wheelSegmentColors = [
    Color(0xFFE53935),
    Color(0xFF8E24AA),
    Color(0xFF1E88E5),
    Color(0xFF00ACC1),
    Color(0xFF43A047),
    Color(0xFFFF8F00),
    Color(0xFF5D4037),
    Color(0xFF546E7A),
    Color(0xFFD81B60),
    Color(0xFF3949AB),
  ];

  @override
  void initState() {
    super.initState();

    // 1. Generate teams
    _teams = generateTeams(widget.state.players, widget.state.teamCount);
    _remaining = List.from(widget.state.players);

    // 2. Build assignment list: interleave teams round-by-round
    //    e.g. [Team1P1, Team2P1, Team3P1, Team1P2, Team2P2, ...]
    _assignments = [];
    final maxLen = _teams.map((t) => t.players.length).reduce(max);
    for (var round = 0; round < maxLen; round++) {
      for (var t = 0; t < _teams.length; t++) {
        if (round < _teams[t].players.length) {
          _assignments.add((
            player: _teams[t].players[round],
            teamNumber: t + 1,
            teamColor: _teamColors[t % _teamColors.length],
          ));
        }
      }
    }
  }

  void _spin() {
    if (_phase != _Phase.ready || _step >= _assignments.length) return;

    final target = _assignments[_step];
    final targetIdx = _remaining.indexOf(target.player);
    if (targetIdx == -1) return;

    // Only one player left — skip the spin and assign immediately.
    if (_remaining.length == 1) {
      setState(() => _phase = _Phase.revealing);
      Future.delayed(const Duration(milliseconds: 1600), _advance);
      return;
    }

    setState(() => _phase = _Phase.spinning);

    _wheelKey.currentState!.spin(
      targetIdx,
      onComplete: () {
        if (!mounted) return;
        setState(() => _phase = _Phase.revealing);
        Future.delayed(const Duration(milliseconds: 1600), _advance);
      },
    );
  }

  void _advance() {
    if (!mounted) return;
    final assignment = _assignments[_step];
    setState(() {
      _remaining.remove(assignment.player);
      _step++;
      _phase = _Phase.ready;
    });

    if (_step < _assignments.length) {
      _wheelKey.currentState?.reset();
    } else {
      // All players assigned — navigate to final results
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              TeamsScreen(state: widget.state, precomputedTeams: _teams),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _step < _assignments.length ? _assignments[_step] : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.state.selectedSport.icon}  Wheel of Fortune'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          CourtBackground(sport: widget.state.selectedSport),
          Column(
            children: [
              // ── Progress bar & label ───────────────────────────────────────
              _ProgressHeader(
                step: _step,
                total: _assignments.length,
                current: current,
                phase: _phase,
              ),

              // ── Wheel ─────────────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Positioned.fill(
                            child: FortuneWheel(
                              key: _wheelKey,
                              labels: _remaining.map((p) => p.name).toList(),
                              segmentColors: _wheelSegmentColors,
                            ),
                          ),
                          // Fixed pointer at top
                          const _Pointer(),
                          // Reveal overlay
                          if (_phase == _Phase.revealing && current != null)
                            _RevealOverlay(assignment: current),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Spin button ────────────────────────────────────────────────
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (current != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Next up → '),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: current.teamColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Team ${current.teamNumber}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      FilledButton.icon(
                        onPressed: _phase == _Phase.ready ? _spin : null,
                        icon: const Icon(Icons.casino_outlined),
                        label: Text(switch (_phase) {
                          _Phase.spinning => 'Spinning…',
                          _Phase.revealing => 'Assigned!',
                          _Phase.ready => 'Spin!',
                        }),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ProgressHeader extends StatelessWidget {
  final int step;
  final int total;
  final _Assignment? current;
  final _Phase phase;

  const _ProgressHeader({
    required this.step,
    required this.total,
    required this.current,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: total > 0 ? step / total : 0,
          minHeight: 4,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Text(
                'Player $step / $total',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                switch (phase) {
                  _Phase.spinning => 'Spinning…',
                  _Phase.revealing => 'Assigned!',
                  _Phase.ready =>
                    step < total ? 'Tap Spin to continue' : 'All done!',
                },
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

class _Pointer extends StatelessWidget {
  const _Pointer();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: CustomPaint(painter: _PointerPainter()),
    );
  }
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFD32F2F));
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class _RevealOverlay extends StatelessWidget {
  final _Assignment assignment;
  const _RevealOverlay({required this.assignment});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              assignment.player.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(blurRadius: 8, color: Colors.black87)],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '→',
              style: TextStyle(color: Colors.white70, fontSize: 22),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: assignment.teamColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(blurRadius: 8, color: Colors.black38),
                ],
              ),
              child: Text(
                'Team ${assignment.teamNumber}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
