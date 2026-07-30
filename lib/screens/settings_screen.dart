import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_state.dart';
import '../services/update_service.dart';

const _kReleasesUrl =
    'https://github.com/micheleIT/teamup/releases/latest';

class SettingsScreen extends StatefulWidget {
  final AppState state;
  final UpdateService? updateService;

  const SettingsScreen({super.key, required this.state, this.updateService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _checkingForUpdate = false;

  Future<void> _checkForUpdate() async {
    if (_checkingForUpdate) return;
    setState(() => _checkingForUpdate = true);

    final info = await PackageInfo.fromPlatform();
    final service = widget.updateService ?? UpdateService();
    final result = await service.checkForUpdate(
      info.version,
      includeDevVersions:
          widget.state.notifyDevUpdates ||
          service.isDevVersion(info.version),
    );

    if (!mounted) return;
    setState(() => _checkingForUpdate = false);

    if (result.checkFailed) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Update Check Failed'),
          content: const Text(
            'Could not check for updates. Please check your internet connection and try again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    if (result.isUpdateAvailable) {
      final version = result.latestVersion ?? '';
      final url =
          result.releaseUrl ?? _kReleasesUrl;
      widget.state.setPendingUpdate(version, url, isDev: result.isDev);

      if (!mounted) return;
      final label = result.isDev
          ? 'Dev version $version is available'
          : 'Version $version is available';
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Update Available'),
          content: Text(label),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Dismiss'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                final uri = Uri.parse(url);
                if (!await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                )) {
                  if (context.mounted) {
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
              child: const Text('View Release'),
            ),
          ],
        ),
      );
    } else {
      widget.state.clearPendingUpdate();

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Up to Date'),
          content: Text(
            'You are running the latest version (${info.version}).',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListenableBuilder(
        listenable: widget.state,
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
                value: widget.state.wheelEnabled,
                onChanged: widget.state.setWheelEnabled,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.emoji_events_outlined),
                title: const Text('Automatically ask for registering results'),
                subtitle: const Text(
                  'Ask to record the match result before shuffling new teams',
                ),
                value: widget.state.autoAskForResults,
                onChanged: widget.state.setAutoAskForResults,
              ),
              const Divider(),
              const _SectionHeader('Updates'),
              SwitchListTile(
                secondary: const Icon(Icons.science_outlined),
                title: const Text('Dev release notifications'),
                subtitle: const Text(
                  'Also notify about dev versions (e.g. 1.2.0.dev)',
                ),
                value: widget.state.notifyDevUpdates,
                onChanged: widget.state.setNotifyDevUpdates,
              ),
              ListTile(
                leading: _checkingForUpdate
                    ? Semantics(
                        label: 'Checking for updates',
                        child: const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.system_update_outlined),
                title: const Text('Check for Updates'),
                trailing: _checkingForUpdate
                    ? null
                    : const Icon(Icons.chevron_right),
                onTap: _checkingForUpdate ? null : _checkForUpdate,
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
