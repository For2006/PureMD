import 'package:go_router/go_router.dart';

import '../../features/reader/reader_screen.dart';
import '../../features/editor/editor_screen.dart';
import '../../features/file_browser/file_browser_screen.dart';
import '../../features/settings/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'reader',
      builder: (context, state) => const ReaderScreen(),
    ),
    GoRoute(
      path: '/editor',
      name: 'editor',
      builder: (context, state) {
        final filePath = state.uri.queryParameters['path'];
        final quickMode = state.uri.queryParameters['mode'] == 'quick';
        return EditorScreen(
          filePath: filePath,
          quickMode: quickMode,
        );
      },
    ),
    GoRoute(
      path: '/files',
      name: 'files',
      builder: (context, state) => const FileBrowserScreen(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
