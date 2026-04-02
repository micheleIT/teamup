import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models/sport.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import 'teams_screen.dart';
import 'wheel_assignment_screen.dart';

class HomeScreen extends StatelessWidget {
  final AppState state;
  const HomeScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('TeamUp'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.bar_chart_outlined),
                tooltip: 'Statistics',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        StatsScreen(statsService: state.statsService),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Settings',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(state: state),
                  ),
                ),
              ),
              if (state.players.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined),
                  tooltip: 'Clear all players',
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Clear all players?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) state.clearPlayers();
                  },
                ),
            ],
          ),
          body: Column(
            children: [
              // ── Sport selector ──────────────────────────────────────────
              _SportSelector(state: state),
              const Divider(height: 1),

              // ── Team count row ──────────────────────────────────────────
              _TeamCountRow(state: state),
              const Divider(height: 1),

              // ── Player list ─────────────────────────────────────────────
              Expanded(
                child: state.players.isEmpty
                    ? const Center(
                        child: Text(
                          'No players yet.\nTap + to add someone.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: state.players.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, indent: 56),
                        itemBuilder: (context, i) {
                          final player = state.players[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              child: Text(
                                player.name.isNotEmpty
                                    ? player.name[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(player.name),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 20,
                                  ),
                                  tooltip: 'Rename',
                                  onPressed: () => _showRenameDialog(
                                    context,
                                    player.id,
                                    player.name,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  tooltip: 'Remove',
                                  onPressed: () =>
                                      state.removePlayer(player.id),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              // ── Generate button ──────────────────────────────────────────
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton.icon(
                    onPressed: state.canGenerate
                        ? () => _generate(context)
                        : null,
                    icon: const Icon(Icons.shuffle),
                    label: Text(
                      state.canGenerate
                          ? 'Generate ${state.teamCount} Teams'
                          : 'Need at least ${state.teamCount} players',
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddPlayerDialog(context),
            tooltip: 'Add player',
            child: const Icon(Icons.person_add),
          ),
        );
      },
    );
  }

  void _generate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => state.wheelEnabled
            ? WheelAssignmentScreen(state: state)
            : TeamsScreen(state: state),
      ),
    );
  }

  Future<void> _showAddPlayerDialog(BuildContext context) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Player'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'e.g. Alex',
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
            onFieldSubmitted: (_) {
              if (formKey.currentState!.validate()) {
                state.addPlayer(controller.text);
                Navigator.pop(ctx);
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                state.addPlayer(controller.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    String id,
    String currentName,
  ) async {
    final controller = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Player'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Name'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
            onFieldSubmitted: (_) {
              if (formKey.currentState!.validate()) {
                state.renamePlayer(id, controller.text);
                Navigator.pop(ctx);
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                state.renamePlayer(id, controller.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SportSelector extends StatelessWidget {
  final AppState state;
  const _SportSelector({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sport', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: Sport.values.map((sport) {
              final selected = state.selectedSport == sport;
              return ChoiceChip(
                label: Text(sport.label),
                selected: selected,
                onSelected: (_) => state.selectSport(sport),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _TeamCountRow extends StatelessWidget {
  final AppState state;
  const _TeamCountRow({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('Teams', style: Theme.of(context).textTheme.labelLarge),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: state.teamCount > 2
                ? () => state.setTeamCount(state.teamCount - 1)
                : null,
          ),
          SizedBox(
            width: 32,
            child: Text(
              state.teamCount.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed:
                state.players.isNotEmpty &&
                    state.teamCount < state.players.length
                ? () => state.setTeamCount(state.teamCount + 1)
                : null,
          ),
        ],
      ),
    );
  }
}
