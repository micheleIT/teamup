import 'package:flutter/material.dart';
import '../app_state.dart';

class SettingsScreen extends StatelessWidget {
  final AppState state;
  const SettingsScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          return ListView(
            children: [
              const _SectionHeader('Team Generation'),
              SwitchListTile(
                secondary: const Icon(Icons.casino_outlined),
                title: const Text('Wheel of Fortune'),
                subtitle: const Text(
                  'Animate team assignment with a spinning wheel',
                ),
                value: state.wheelEnabled,
                onChanged: state.setWheelEnabled,
              ),
              const Divider(),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
