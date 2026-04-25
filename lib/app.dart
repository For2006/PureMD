import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/router/app_router.dart';
import 'config/theme/app_theme.dart';
import 'features/settings/settings_provider.dart';
import 'models/app_settings.dart';

class PureMDApp extends ConsumerWidget {
  const PureMDApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    );
  }
}
