import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'features/home_widgets/home_widget_provider.dart';
import 'services/external_file_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pre-warm SharedPreferences so providers get it instantly
  await SharedPreferences.getInstance();

  ExternalFileHandler.init();

  runApp(const ProviderScope(child: PureMDApp()));

  // Defer home widget init to after first frame
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _initHomeWidget();
  });
}

Future<void> _initHomeWidget() async {
  try {
    final service = HomeWidgetService();
    await service.initialize();
    await service.updateQuickNoteWidget();
  } catch (_) {}
}
