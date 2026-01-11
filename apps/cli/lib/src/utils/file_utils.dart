import 'dart:convert';
import 'dart:io';

/// File utilities for the CLI.
class FileUtils {
  static String getHomeDir() {
    final home = Platform.environment['HOME'];
    if (home == null) {
      throw Exception('HOME environment variable not found');
    }
    return home;
  }

  static String resolvePath(String path) {
    if (path.startsWith('~/')) {
      return '${getHomeDir()}${path.substring(1)}';
    }
    return path;
  }

  static Future<String> readFileAsString(String path) async {
    final file = File(path);
    if (!file.existsSync()) {
      throw FileSystemException('File not found', path);
    }
    return file.readAsString();
  }

  static Future<void> writeFileAsString(String path, String content) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  static Future<bool> fileExists(String path) async {
    return File(path).existsSync();
  }

  static Future<bool> directoryExists(String path) async {
    return Directory(path).existsSync();
  }

  static Future<void> setFilePermissions(String path, int mode) async {
    if (Platform.isLinux || Platform.isMacOS) {
      await Process.run('chmod', [mode.toString(), path]);
    }
  }

  static Future<void> setDirectoryPermissions(String path, int mode) async {
    if (Platform.isLinux || Platform.isMacOS) {
      await Process.run('chmod', [mode.toString(), path]);
    }
  }

  static Map<String, dynamic> parseJsonFile(String content) {
    try {
      final decoded = jsonDecode(content) as Map<String, dynamic>;
      return decoded;
    } catch (e) {
      throw FormatException('Invalid JSON: $e');
    }
  }

  static String encodeJsonFile(Map<String, dynamic> data) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }
}
