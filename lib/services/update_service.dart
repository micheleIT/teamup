import 'dart:convert';

import 'package:http/http.dart' as http;

/// Result of an update availability check.
class UpdateCheckResult {
  final bool isUpdateAvailable;
  final String? latestVersion;
  final String? releaseUrl;

  const UpdateCheckResult({
    required this.isUpdateAvailable,
    this.latestVersion,
    this.releaseUrl,
  });
}

/// Checks GitHub releases for a newer version of the app.
class UpdateService {
  static const _releasesApiUrl =
      'https://api.github.com/repos/micheleIT/teamup/releases/latest';

  final http.Client _client;

  UpdateService({http.Client? client}) : _client = client ?? http.Client();

  /// Checks whether a newer release exists on GitHub.
  ///
  /// Returns an [UpdateCheckResult] with [isUpdateAvailable] set to `true`
  /// if [currentVersion] is lower than the latest published release tag.
  /// On any network or parsing error returns a result with
  /// [isUpdateAvailable] set to `false`.
  Future<UpdateCheckResult> checkForUpdate(String currentVersion) async {
    try {
      final response = await _client
          .get(
            Uri.parse(_releasesApiUrl),
            headers: {'Accept': 'application/vnd.github+json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return const UpdateCheckResult(isUpdateAvailable: false);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = data['tag_name'] as String? ?? '';
      final latestVersion =
          tagName.startsWith('v') ? tagName.substring(1) : tagName;
      final releaseUrl = data['html_url'] as String?;

      final isNewer = _isNewerVersion(latestVersion, currentVersion);
      return UpdateCheckResult(
        isUpdateAvailable: isNewer,
        latestVersion: latestVersion,
        releaseUrl: releaseUrl,
      );
    } catch (_) {
      return const UpdateCheckResult(isUpdateAvailable: false);
    }
  }

  /// Returns `true` when [latest] is strictly greater than [current].
  ///
  /// Both strings are expected to be in `MAJOR.MINOR.PATCH` format.
  /// Non-numeric segments are treated as 0.
  bool isNewerVersion(String latest, String current) =>
      _isNewerVersion(latest, current);

  bool _isNewerVersion(String latest, String current) {
    final l = _parseParts(latest);
    final c = _parseParts(current);
    for (var i = 0; i < 3; i++) {
      if (l[i] > c[i]) return true;
      if (l[i] < c[i]) return false;
    }
    return false;
  }

  List<int> _parseParts(String version) {
    final parts = version.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    while (parts.length < 3) {
      parts.add(0);
    }
    return parts;
  }
}
