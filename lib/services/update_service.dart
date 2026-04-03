import 'dart:convert';

import 'package:http/http.dart' as http;

/// Result of an update availability check.
class UpdateCheckResult {
  final bool isUpdateAvailable;
  final String? latestVersion;
  final String? releaseUrl;

  /// Whether the available version is a dev release.
  final bool isDev;

  const UpdateCheckResult({
    required this.isUpdateAvailable,
    this.latestVersion,
    this.releaseUrl,
    this.isDev = false,
  });
}

/// Checks GitHub releases for a newer version of the app.
class UpdateService {
  static const _releasesApiUrl =
      'https://api.github.com/repos/micheleIT/teamup/releases/latest';
  static const _releasesListApiUrl =
      'https://api.github.com/repos/micheleIT/teamup/releases';

  final http.Client _client;

  UpdateService({http.Client? client}) : _client = client ?? http.Client();

  static const _githubHeaders = {'Accept': 'application/vnd.github+json'};

  /// Checks whether a newer release exists on GitHub.
  ///
  /// When [includeDevVersions] is `true`, also checks for newer dev releases
  /// (tags containing `.dev`). If both a stable and a dev update are found,
  /// the one with the higher version number is returned (stable wins a tie).
  ///
  /// On any network or parsing error returns a result with
  /// [isUpdateAvailable] set to `false`.
  Future<UpdateCheckResult> checkForUpdate(
    String currentVersion, {
    bool includeDevVersions = false,
  }) async {
    try {
      final stableResult = await _checkStableRelease(currentVersion);
      if (!includeDevVersions) return stableResult;

      final devResult = await _checkLatestDevRelease(currentVersion);

      if (!stableResult.isUpdateAvailable && !devResult.isUpdateAvailable) {
        return const UpdateCheckResult(isUpdateAvailable: false);
      }
      if (!devResult.isUpdateAvailable) return stableResult;
      if (!stableResult.isUpdateAvailable) return devResult;

      // Both available – return the higher version; stable wins a tie.
      final stableNumeric = stableResult.latestVersion ?? '';
      final devNumeric = _stripDevSuffix(devResult.latestVersion ?? '');
      return isNewerVersion(devNumeric, stableNumeric) ? devResult : stableResult;
    } catch (_) {
      return const UpdateCheckResult(isUpdateAvailable: false);
    }
  }

  Future<UpdateCheckResult> _checkStableRelease(String currentVersion) async {
    try {
      final response = await _client
          .get(Uri.parse(_releasesApiUrl), headers: _githubHeaders)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return const UpdateCheckResult(isUpdateAvailable: false);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = data['tag_name'] as String? ?? '';
      final latestVersion =
          tagName.startsWith('v') ? tagName.substring(1) : tagName;
      final releaseUrl = data['html_url'] as String?;

      return UpdateCheckResult(
        isUpdateAvailable: isNewerVersion(latestVersion, currentVersion),
        latestVersion: latestVersion,
        releaseUrl: releaseUrl,
      );
    } catch (_) {
      return const UpdateCheckResult(isUpdateAvailable: false);
    }
  }

  Future<UpdateCheckResult> _checkLatestDevRelease(
    String currentVersion,
  ) async {
    try {
      final response = await _client
          .get(Uri.parse(_releasesListApiUrl), headers: _githubHeaders)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return const UpdateCheckResult(isUpdateAvailable: false);
      }

      final releases = jsonDecode(response.body) as List<dynamic>;

      UpdateCheckResult? best;
      for (final item in releases) {
        final release = item as Map<String, dynamic>;
        if (release['draft'] == true) continue;

        final tagName = release['tag_name'] as String? ?? '';
        final version = tagName.startsWith('v') ? tagName.substring(1) : tagName;

        if (!isDevVersion(version)) continue;

        final numericVersion = _stripDevSuffix(version);
        if (!isNewerVersion(numericVersion, currentVersion)) continue;

        if (best == null ||
            isNewerVersion(numericVersion, _stripDevSuffix(best.latestVersion ?? ''))) {
          best = UpdateCheckResult(
            isUpdateAvailable: true,
            latestVersion: version,
            releaseUrl: release['html_url'] as String?,
            isDev: true,
          );
        }
      }

      return best ?? const UpdateCheckResult(isUpdateAvailable: false);
    } catch (_) {
      return const UpdateCheckResult(isUpdateAvailable: false);
    }
  }

  /// Returns `true` when [latest] is strictly greater than [current].
  ///
  /// Both strings are expected to be in `MAJOR.MINOR.PATCH` format.
  /// Non-numeric segments are treated as 0.
  bool isNewerVersion(String latest, String current) {
    final l = _parseParts(latest);
    final c = _parseParts(current);
    for (var i = 0; i < 3; i++) {
      if (l[i] > c[i]) return true;
      if (l[i] < c[i]) return false;
    }
    return false;
  }

  /// Returns `true` if [version] contains a `.dev` suffix.
  bool isDevVersion(String version) => version.contains('.dev');

  /// Strips the `.dev` suffix (and any characters after it) from [version].
  String _stripDevSuffix(String version) {
    final idx = version.indexOf('.dev');
    return idx == -1 ? version : version.substring(0, idx);
  }

  List<int> _parseParts(String version) {
    final stripped = _stripDevSuffix(version);
    final parts =
        stripped.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    while (parts.length < 3) {
      parts.add(0);
    }
    return parts.take(3).toList();
  }
}
