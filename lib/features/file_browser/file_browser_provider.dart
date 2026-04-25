import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/recent_file_entry.dart';
import '../../services/storage_service.dart';

final fileBrowserProvider =
    StateNotifierProvider<FileBrowserNotifier, AsyncValue<List<RecentFileEntry>>>((ref) {
  return FileBrowserNotifier(ref);
});

class FileBrowserNotifier extends StateNotifier<AsyncValue<List<RecentFileEntry>>> {
  final Ref _ref;

  FileBrowserNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadRecentFiles();
  }

  Future<void> _loadRecentFiles() async {
    try {
      final storageService = _ref.read(storageServiceProvider);
      final files = await storageService.getRecentFiles();
      state = AsyncValue.data(files);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addToRecent({
    required String path,
    required String displayName,
    required String contentPreview,
  }) async {
    try {
      final storageService = _ref.read(storageServiceProvider);
      final files = List<RecentFileEntry>.from(state.value ?? []);

      files.removeWhere((f) => f.path == path);
      files.insert(0, RecentFileEntry(
        path: path,
        displayName: displayName,
        lastOpenedAt: DateTime.now(),
        contentPreview: contentPreview,
      ));

      if (files.length > 20) files.removeRange(20, files.length);

      state = AsyncValue.data(files);
      await storageService.saveRecentFiles(files);
    } catch (_) {}
  }

  Future<void> removeFromRecent(String path) async {
    try {
      final storageService = _ref.read(storageServiceProvider);
      final files = List<RecentFileEntry>.from(state.value ?? []);
      files.removeWhere((f) => f.path == path);
      state = AsyncValue.data(files);
      await storageService.saveRecentFiles(files);
    } catch (_) {}
  }

  Future<void> clearRecent() async {
    state = const AsyncValue.data([]);
    try {
      final storageService = _ref.read(storageServiceProvider);
      await storageService.saveRecentFiles([]);
    } catch (_) {}
  }

  Future<void> refresh() async {
    await _loadRecentFiles();
  }
}
