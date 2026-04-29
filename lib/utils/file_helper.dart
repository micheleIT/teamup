import 'dart:convert';

import 'package:file_picker/file_picker.dart';

import 'file_helper_stub.dart'
    if (dart.library.html) 'file_helper_web.dart'
    as platform;

/// Cross-platform file save/load helpers for import/export.
class FileHelper {
  FileHelper._();

  /// Triggers a file download with the given [content] and suggested
  /// [fileName]. On web this creates a browser download.
  static Future<bool> saveToFile(String content, String fileName) {
    return platform.saveToFile(content, fileName);
  }

  /// Opens a file picker for the user to select a JSON file to import.
  /// Returns the file content as a string, or `null` if cancelled.
  static Future<String?> loadFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;
    if (file.bytes != null) {
      return utf8.decode(file.bytes!);
    }
    return null;
  }
}
