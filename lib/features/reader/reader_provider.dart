import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/storage_service.dart';
import '../../services/preset_document_service.dart';
import '../../services/file_service.dart';
import '../../models/markdown_file.dart';
import '../file_browser/file_browser_provider.dart';

final currentFileProvider = StateNotifierProvider<ReaderNotifier, AsyncValue<MarkdownFile?>>((ref) {
  return ReaderNotifier(ref);
});

final isFocusModeProvider = StateProvider<bool>((ref) => false);
final scrollPositionProvider = StateProvider<double>((ref) => 0.0);

class ReaderNotifier extends StateNotifier<AsyncValue<MarkdownFile?>> {
  final Ref _ref;

  ReaderNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final storageService = _ref.read(storageServiceProvider);
      final hasLaunched = await storageService.hasLaunched();

      if (!hasLaunched) {
        final presetService = PresetDocumentService(storageService);
        final presetPath = await presetService.ensurePresetDocument();
        await loadFile(presetPath);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadFile(String path) async {
    try {
      final content = await FileService.readFile(path);
      final lastModified = await FileService.lastModified(path);
      final name = FileService.getFileName(path);
      final file = MarkdownFile(
        path: path,
        name: name,
        content: content,
        lastModified: lastModified,
      );
      state = AsyncValue.data(file);
      // Fire-and-forget: update recent files list without blocking
      _ref.read(fileBrowserProvider.notifier).addToRecent(
            path: path,
            displayName: name,
            contentPreview: content.length > 100 ? content.substring(0, 100) : content,
          );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> reload() async {
    final currentFile = state.value;
    if (currentFile != null) {
      await loadFile(currentFile.path);
    }
  }
}
