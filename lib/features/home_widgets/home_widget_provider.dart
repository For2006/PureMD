import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../core/constants/app_constants.dart';

final homeWidgetProvider = Provider<HomeWidgetService>((ref) {
  return HomeWidgetService();
});

class HomeWidgetService {
  Future<void> updateKeyInfoCard({
    required String title,
    required String snippet,
  }) async {
    try {
      await HomeWidget.saveWidgetData('key_info_title', title);
      await HomeWidget.saveWidgetData('key_info_snippet', snippet);
      await HomeWidget.updateWidget(
        name: 'HomeWidgetProvider',
        androidName: 'HomeWidgetProvider',
      );
    } catch (_) {}
  }

  Future<void> updateQuickNoteWidget({String? hint}) async {
    try {
      await HomeWidget.saveWidgetData(
        'quick_note_hint',
        hint ?? '点击开始新笔记',
      );
      await HomeWidget.updateWidget(
        name: 'QuickNoteWidgetProvider',
        androidName: 'QuickNoteWidgetProvider',
      );
    } catch (_) {}
  }

  Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId(AppConstants.appName);
    } catch (_) {}
  }
}
