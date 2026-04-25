import 'dart:io';

class FileService {
  FileService._();

  static Future<String> readFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw FileSystemException('File not found', path);
    }
    return await file.readAsString();
  }

  static Future<void> writeFile(String path, String content) async {
    final file = File(path);
    await file.writeAsString(content);
  }

  static Future<bool> fileExists(String path) async {
    return File(path).exists();
  }

  static Future<DateTime> lastModified(String path) async {
    final file = File(path);
    return await file.lastModified();
  }

  static String getFileName(String path) {
    return path.split(Platform.pathSeparator).last;
  }

  static String getFileNameWithoutExtension(String path) {
    final name = getFileName(path);
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex == -1) return name;
    return name.substring(0, dotIndex);
  }
}
