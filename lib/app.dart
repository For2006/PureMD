import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/router/app_router.dart';
import 'config/theme/app_theme.dart';
import 'features/reader/reader_provider.dart';
import 'features/settings/settings_provider.dart';
import 'models/app_settings.dart';
import 'services/external_file_handler.dart';

class PureMDApp extends ConsumerStatefulWidget {
  const PureMDApp({super.key});

  @override
  ConsumerState<PureMDApp> createState() => _PureMDAppState();
}

class _PureMDAppState extends ConsumerState<PureMDApp> {
  @override
  void initState() {
    super.initState();
    SystemChannels.navigation.setMethodCallHandler((call) async {});
    _setupExternalFileHandler();
  }

  void _setupExternalFileHandler() {
    // Check for file from initial launch intent
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final pending = ExternalFileHandler.consumePending();
      if (pending != null) {
        await _loadExternalFile(pending);
      }
    });
    // Listen for files opened while app is running
    ExternalFileHandler.onFileOpened.listen((file) async {
      if (!mounted) return;
      await _loadExternalFile(file);
    });
  }

  Future<void> _loadExternalFile(Map<String, String> file) async {
    final f = await ExternalFileHandler.saveToTemp(file);
    ref.read(currentFileProvider.notifier).loadFile(f.path);
    appRouter.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final settings = settingsAsync.valueOrNull ?? const AppSettings();

    final theme = AppTheme.buildTheme(
      settings.themeVariant,
      fontFamily: settings.fontFamily.isNotEmpty ? settings.fontFamily : null,
      fontSize: settings.fontSize,
    );

    return MaterialApp.router(
      title: 'PureMD',
      debugShowCheckedModeBanner: false,
      theme: theme,
      routerConfig: appRouter,
      builder: (context, child) {
        return AnimatedTheme(
          data: theme,
          duration: const Duration(milliseconds: 300),
          child: child!,
        );
      },
    );
  }
}
