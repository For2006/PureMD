import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../models/app_settings.dart';
import '../models/recent_file_entry.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

class StorageService {
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<bool> hasLaunched() async {
    final prefs = await _preferences;
    return prefs.getBool(AppConstants.hasLaunchedKey) ?? false;
  }

  Future<void> setHasLaunched() async {
    final prefs = await _preferences;
    await prefs.setBool(AppConstants.hasLaunchedKey, true);
  }

  Future<AppSettings> getSettings() async {
    final prefs = await _preferences;
    final jsonStr = prefs.getString(AppConstants.settingsKey);
    if (jsonStr == null) return const AppSettings();
    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return AppSettings.fromJson(json);
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await _preferences;
    await prefs.setString(
      AppConstants.settingsKey,
      jsonEncode(settings.toJson()),
    );
  }

  Future<List<RecentFileEntry>> getRecentFiles() async {
    final prefs = await _preferences;
    final jsonStr = prefs.getString(AppConstants.recentFilesKey);
    if (jsonStr == null) return [];
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((e) => RecentFileEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveRecentFiles(List<RecentFileEntry> files) async {
    final prefs = await _preferences;
    await prefs.setString(
      AppConstants.recentFilesKey,
      jsonEncode(files.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> clearAll() async {
    final prefs = await _preferences;
    await prefs.clear();
  }
}
