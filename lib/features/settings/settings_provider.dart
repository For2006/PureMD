import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme/app_themes.dart';
import '../../models/app_settings.dart';
import '../../services/storage_service.dart';

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AsyncValue<AppSettings>>((ref) {
  return SettingsNotifier(ref);
});

class SettingsNotifier extends StateNotifier<AsyncValue<AppSettings>> {
  final Ref _ref;
  Timer? _debounceTimer;

  SettingsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final storageService = _ref.read(storageServiceProvider);
      final settings = await storageService.getSettings();
      state = AsyncValue.data(settings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setTheme(AppThemeVariant variant) async {
    final current = state.valueOrNull ?? const AppSettings();
    final updated = current.copyWith(themeVariant: variant);
    state = AsyncValue.data(updated);
    _scheduleSave();
  }

  Future<void> setFontFamily(String fontFamily) async {
    final current = state.valueOrNull ?? const AppSettings();
    final updated = current.copyWith(fontFamily: fontFamily);
    state = AsyncValue.data(updated);
    _scheduleSave();
  }

  Future<void> setFontSize(double fontSize) async {
    final current = state.valueOrNull ?? const AppSettings();
    final updated = current.copyWith(fontSize: fontSize);
    state = AsyncValue.data(updated);
    _scheduleSave();
  }

  Future<void> toggleSystemDarkMode(bool value) async {
    final current = state.valueOrNull ?? const AppSettings();
    final updated = current.copyWith(useSystemDarkMode: value);
    state = AsyncValue.data(updated);
    _scheduleSave();
  }

  void _scheduleSave() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final settings = state.valueOrNull;
      if (settings == null) return;
      try {
        final storageService = _ref.read(storageServiceProvider);
        await storageService.saveSettings(settings);
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
