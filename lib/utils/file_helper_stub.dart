/// Stub implementation for non-web platforms.
/// On Android, file download is not directly supported via this path;
/// the export dialog's copy-to-clipboard remains the primary option.
Future<bool> saveToFile(String content, String fileName) async {
  // No native file-save on Android without additional dependencies.
  return false;
}
