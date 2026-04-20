import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_state.dart';
import '../models/sport.dart';
import '../services/update_service.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import 'teams_screen.dart';
import 'wheel_assignment_screen.dart';

class HomeScreen extends StatefulWidget {
  final AppState state;
  final UpdateService? updateService;

  const HomeScreen({super.key, required this.state, this.updateService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    final info = await PackageInfo.fromPlatform();
    final service = widget.updateService ?? UpdateService();
    final result = await service.checkForUpdate(
      info.version,
      includeDevVersions:
          widget.state.notifyDevUpdates || service.isDevVersion(info.version),
    );

    if (!mounted) return;
    if (!result.isUpdateAvailable) return;

    final version = result.latestVersion ?? '';
    final releaseUrl =
        result.releaseUrl ??
        'https://github.com/micheleIT/teamup/releases/latest';
    final message = result.isDev
        ? 'Dev version $version is available'
        : 'Version $version is available';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 10),
        action: SnackBarAction(
          label: 'View release',
          onPressed: () async {
            final uri = Uri.parse(releaseUrl);
            if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Unable to open release page. Please check your browser settings or try again later.',
                    ),
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
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
                        StatsScreen(statsService: widget.state.statsService),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Settings',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(state: widget.state),
                  ),
                ),
              ),
              if (widget.state.players.isNotEmpty)
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
                    if (ok == true) widget.state.clearPlayers();
                  },
                ),
            ],
          ),
          body: Column(
            children: [
              // ── Sport selector ──────────────────────────────────────────
              _SportSelector(state: widget.state),
              const Divider(height: 1),

              // ── Team count row ──────────────────────────────────────────
              _TeamCountRow(state: widget.state),
              const Divider(height: 1),

              // ── Player list ─────────────────────────────────────────────
              Expanded(
                child: widget.state.players.isEmpty
                    ? const Center(
                        child: Text(
                          'No players yet.\nTap + to add someone.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: widget.state.players.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, indent: 56),
                        itemBuilder: (context, i) {
                          final player = widget.state.players[i];
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
                                      widget.state.removePlayer(player.id),
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
                    onPressed: widget.state.canGenerate
                        ? () => _generate(context)
                        : null,
                    icon: const Icon(Icons.shuffle),
                    label: Text(
                      widget.state.canGenerate
                          ? 'Generate ${widget.state.teamCount} Teams'
                          : 'Need at least ${widget.state.teamCount} players',
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
        builder: (_) => widget.state.wheelEnabled
            ? WheelAssignmentScreen(state: widget.state)
            : TeamsScreen(state: widget.state),
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
                widget.state.addPlayer(controller.text);
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
                widget.state.addPlayer(controller.text);
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
                widget.state.renamePlayer(id, controller.text);
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
                widget.state.renamePlayer(id, controller.text);
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
