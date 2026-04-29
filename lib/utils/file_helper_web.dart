import 'dart:convert';
import 'dart:typed_data';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web implementation — triggers a browser file download.
Future<bool> saveToFile(String content, String fileName) async {
  try {
    final bytes = utf8.encode(content);
    final blob = html.Blob([Uint8List.fromList(bytes)], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
    return true;
  } catch (_) {
    return false;
  }
}
