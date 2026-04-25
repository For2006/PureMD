import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'features/home_widgets/home_widget_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  _initHomeWidget();

  runApp(const ProviderScope(child: PureMDApp()));
}

Future<void> _initHomeWidget() async {
  try {
    final service = HomeWidgetService();
    await service.initialize();
    await service.updateQuickNoteWidget();
  } catch (_) {}
}
