import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class ExternalFileHandler {
  static const _channel = MethodChannel('com.puremd.app/file');

  static Map<String, String>? _pendingFile;
  static final _pendingController = StreamController<Map<String, String>>.broadcast();
  static Stream<Map<String, String>> get onFileOpened => _pendingController.stream;

  static Map<String, String>? consumePending() {
    final pending = _pendingFile;
    _pendingFile = null;
    return pending;
  }

  static void init() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'openFile') {
        final uri = call.arguments as String;
        try {
          final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
            'readContentUri',
            {'uri': uri},
          );
          if (result != null) {
            final file = <String, String>{
              'content': result['content'] as String,
              'name': result['name'] as String? ?? 'unknown.md',
            };
            _pendingFile = file;
            _pendingController.add(file);
          }
        } catch (_) {}
      }
    });
  }

  static Future<File> saveToTemp(Map<String, String> file) async {
    final tempDir = await getTemporaryDirectory();
    final f = File('${tempDir.path}${Platform.pathSeparator}${file['name']}');
    await f.writeAsString(file['content']!);
    return f;
  }

  static void dispose() {
    _pendingController.close();
  }
}
