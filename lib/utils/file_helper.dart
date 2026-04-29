import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Cross-platform file save/load helpers for import/export.
///
/// Uses `file_picker` which works on Android, web, and desktop.
class FileHelper {
  FileHelper._();

  /// Opens a save-file dialog with the given [content] and suggested
  /// [fileName]. On web this triggers a browser download; on Android
  /// it opens the system file-save dialog.
  ///
  /// Returns `true` if the file was saved successfully.
  static Future<bool> saveToFile(String content, String fileName) async {
    try {
      final bytes = Uint8List.fromList(utf8.encode(content));
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save statistics',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );
      return result != null;
    } catch (_) {
      return false;
    }
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
