import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../core/constants/app_constants.dart';
import 'storage_service.dart';

class PresetDocumentService {
  final StorageService _storageService;

  PresetDocumentService(this._storageService);

  Future<String> ensurePresetDocument() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final presetPath =
        '${docsDir.path}${Platform.pathSeparator}${AppConstants.presetFileName}';
    final file = File(presetPath);

    if (!await file.exists()) {
      final content = await rootBundle.loadString(
        'assets/documents/${AppConstants.presetFileName}',
      );
      await file.writeAsString(content);
    }

    await _storageService.setHasLaunched();
    return presetPath;
  }
}
