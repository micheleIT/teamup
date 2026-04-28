import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/player_stats.dart';
import '../models/game_record.dart';
import '../models/sport.dart';
import '../services/stats_service.dart';

enum _StatsPeriod { today, allTime }

class StatsScreen extends StatefulWidget {
  final StatsService statsService;
  const StatsScreen({super.key, required this.statsService});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  _StatsPeriod _period = _StatsPeriod.allTime;

  DateTime? get _since {
    if (_period == _StatsPeriod.today) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day);
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    // Overall + one tab for each defined sport
    _tabs = TabController(length: Sport.values.length + 1, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.statsService,
      builder: (context, _) {
        final records = widget.statsService.records;

        final tabs = [
          const Tab(text: 'Overall'),
          ...Sport.values.map((s) => Tab(text: s.icon)),
        ];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Statistics'),
            centerTitle: true,
            bottom: TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: tabs,
            ),
            actions: [
              if (records.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.history),
                  tooltip: 'Game history',
                  onPressed: () => _showHistory(context, records),
                ),
              PopupMenuButton<_ImportExportAction>(
                tooltip: 'Import / Export',
                icon: const Icon(Icons.more_vert),
                onSelected: (action) {
                  switch (action) {
                    case _ImportExportAction.exportToday:
                      _showExportDialog(context, today: true);
                    case _ImportExportAction.exportAll:
                      _showExportDialog(context, today: false);
                    case _ImportExportAction.import:
                      _showImportDialog(context);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: _ImportExportAction.exportToday,
                    child: ListTile(
                      leading: Icon(Icons.upload),
                      title: Text("Export today's games"),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: _ImportExportAction.exportAll,
                    child: ListTile(
                      leading: Icon(Icons.upload_file),
                      title: Text('Export all games'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem(
                    value: _ImportExportAction.import,
                    child: ListTile(
                      leading: Icon(Icons.download),
                      title: Text('Import games'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SegmentedButton<_StatsPeriod>(
                  segments: const [
                    ButtonSegment(
                      value: _StatsPeriod.today,
                      label: Text('Today'),
                      icon: Icon(Icons.today_outlined),
                    ),
                    ButtonSegment(
                      value: _StatsPeriod.allTime,
                      label: Text('All Time'),
                      icon: Icon(Icons.history),
                    ),
                  ],
                  selected: {_period},
                  onSelectionChanged: (s) => setState(() => _period = s.first),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _StatsTab(
                      stats: widget.statsService.computeStats(since: _since),
                      sport: null,
                      period: _period,
                    ),
                    ...Sport.values.map(
                      (s) => _StatsTab(
                        stats: widget.statsService.computeStats(
                          sport: s,
                          since: _since,
                        ),
                        sport: s,
                        period: _period,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showHistory(BuildContext context, List<GameRecord> records) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _HistorySheet(
        records: records,
        onDelete: (id) => widget.statsService.deleteRecord(id),
      ),
    );
  }

  void _showExportDialog(BuildContext context, {required bool today}) {
    DateTime? since;
    if (today) {
      final now = DateTime.now();
      since = DateTime(now.year, now.month, now.day);
    }
    final json = widget.statsService.exportToJson(since: since);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(today ? "Export today's games" : 'Export all games'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Copy the JSON below and save it to a file. You can later '
                'import it on any device.',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Theme.of(
                    ctx,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(10),
                  child: SelectableText(
                    json,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: json));
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
                Navigator.pop(ctx);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    final controller = TextEditingController();
    var mergeMode = true; // true = merge, false = replace
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Import games'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paste the JSON data you exported from another device.',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '[{"id": "...", ...}]',
                  ),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
                const SizedBox(height: 12),
                Text(
                  'Import mode',
                  style: Theme.of(ctx).textTheme.labelMedium,
                ),
                const SizedBox(height: 4),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: true,
                      label: Text('Merge'),
                      icon: Icon(Icons.merge),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text('Replace'),
                      icon: Icon(Icons.swap_horiz),
                    ),
                  ],
                  selected: {mergeMode},
                  onSelectionChanged: (s) =>
                      setDialogState(() => mergeMode = s.first),
                ),
                if (!mergeMode) ...[
                  const SizedBox(height: 8),
                  Text(
                    '⚠ Replace mode will delete all existing game records.',
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ctx).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Import'),
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Please paste JSON data first')),
                  );
                  return;
                }
                try {
                  await widget.statsService.importFromJson(
                    text,
                    merge: mergeMode,
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Statistics imported successfully'),
                      ),
                    );
                  }
                } on FormatException catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Import failed: ${e.message}')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Import/export action enum ─────────────────────────────────────────────────

enum _ImportExportAction { exportToday, exportAll, import }

// ── Stats tab ─────────────────────────────────────────────────────────────────

class _StatsTab extends StatelessWidget {
  final List<PlayerStats> stats;
  final Sport? sport;
  final _StatsPeriod period;

  const _StatsTab({
    required this.stats,
    required this.sport,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sports_score_outlined,
              size: 56,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              period == _StatsPeriod.today
                  ? (sport == null
                        ? 'No games recorded today.'
                        : 'No ${sport!.label} games recorded today.')
                  : (sport == null
                        ? 'No games recorded yet.\nRecord a result from the teams screen.'
                        : 'No ${sport!.label} games recorded yet.'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: stats.length,
      itemBuilder: (context, i) =>
          _PlayerCard(rank: i + 1, stats: stats[i], sport: sport),
    );
  }
}

// ── Player stats card ─────────────────────────────────────────────────────────

class _PlayerCard extends StatelessWidget {
  final int rank;
  final PlayerStats stats;
  final Sport? sport;

  const _PlayerCard({
    required this.rank,
    required this.stats,
    required this.sport,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isTop3 = rank <= 3;
    final medals = ['🥇', '🥈', '🥉'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    isTop3 ? medals[rank - 1] : '#$rank',
                    style: TextStyle(
                      fontSize: isTop3 ? 22 : 14,
                      fontWeight: FontWeight.bold,
                      color: isTop3 ? null : cs.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stats.playerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                _WinRateChip(winRate: stats.winRate),
              ],
            ),
            const SizedBox(height: 10),

            // W/D/L bar
            _WdlBar(
              wins: stats.wins,
              draws: stats.draws,
              losses: stats.losses,
              gamesPlayed: stats.gamesPlayed,
            ),
            const SizedBox(height: 8),

            // Counts row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Stat('GP', stats.gamesPlayed, Colors.grey),
                _Stat('W', stats.wins, Colors.green[700]!),
                _Stat('D', stats.draws, Colors.orange[700]!),
                _Stat('L', stats.losses, Colors.red[700]!),
              ],
            ),

            // Per-sport breakdown (only in Overall tab)
            if (sport == null && stats.bySport.length > 1) ...[
              const Divider(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: stats.bySport.entries.map((e) {
                  final s = e.value;
                  return Chip(
                    label: Text(
                      '${e.key.icon} ${s.wins}W ${s.draws}D ${s.losses}L',
                    ),
                    labelStyle: const TextStyle(fontSize: 11),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Win-rate chip ─────────────────────────────────────────────────────────────

class _WinRateChip extends StatelessWidget {
  final double winRate;
  const _WinRateChip({required this.winRate});

  @override
  Widget build(BuildContext context) {
    final pct = (winRate * 100).toStringAsFixed(0);
    Color color;
    if (winRate >= 0.6) {
      color = Colors.green[700]!;
    } else if (winRate >= 0.4) {
      color = Colors.orange[700]!;
    } else {
      color = Colors.red[700]!;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        '$pct%',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}

// ── W/D/L stacked bar ─────────────────────────────────────────────────────────

class _WdlBar extends StatelessWidget {
  final int wins, draws, losses, gamesPlayed;
  const _WdlBar({
    required this.wins,
    required this.draws,
    required this.losses,
    required this.gamesPlayed,
  });

  @override
  Widget build(BuildContext context) {
    if (gamesPlayed == 0) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 8,
        child: Row(
          children: [
            _bar(wins / gamesPlayed, Colors.green[600]!),
            _bar(draws / gamesPlayed, Colors.orange[400]!),
            _bar(losses / gamesPlayed, Colors.red[400]!),
          ],
        ),
      ),
    );
  }

  Widget _bar(double fraction, Color color) => Flexible(
    flex: max(1, (fraction * 1000).round()),
    child: Container(color: color),
  );
}

// ── Single stat label ─────────────────────────────────────────────────────────

class _Stat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _Stat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ── History bottom sheet ──────────────────────────────────────────────────────

class _HistorySheet extends StatelessWidget {
  final List<GameRecord> records;
  final Future<void> Function(String id) onDelete;

  const _HistorySheet({required this.records, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Game History',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              controller: controller,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: records.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final r = records[i];
                final winner = r.winnerTeamNumber;
                return ListTile(
                  leading: Text(
                    r.sport.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(winner == null ? 'Draw' : 'Team $winner won'),
                  subtitle: Text(
                    '${r.teams.map((t) => t.players.map((p) => p.name).join(', ')).join(' vs ')}'
                    '\n${_formatDate(r.playedAt)}',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: 'Delete',
                    onPressed: () async {
                      await onDelete(r.id);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
