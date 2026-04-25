import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pure_md/config/theme/app_themes.dart';
import 'package:pure_md/config/theme/color_schemes.dart';
import 'package:pure_md/core/utils/markdown_utils.dart';
import 'package:pure_md/models/app_settings.dart';
import 'package:pure_md/models/markdown_file.dart';
import 'package:pure_md/models/recent_file_entry.dart';
import 'package:pure_md/app.dart';

void main() {
  // Prevent google_fonts from making network requests in tests
  GoogleFonts.config.allowRuntimeFetching = false;
  group('AppSettings', () {
    test('default values', () {
      const settings = AppSettings();
      expect(settings.themeVariant, AppThemeVariant.light);
      expect(settings.fontFamily, '');
      expect(settings.fontSize, 16.0);
      expect(settings.useSystemDarkMode, true);
    });

    test('JSON serialization roundtrip', () {
      const original = AppSettings(
        themeVariant: AppThemeVariant.oled,
        fontFamily: 'Noto Sans SC',
        fontSize: 18.0,
        useSystemDarkMode: false,
      );
      final json = original.toJson();
      final restored = AppSettings.fromJson(json);
      expect(restored.themeVariant, original.themeVariant);
      expect(restored.fontFamily, original.fontFamily);
      expect(restored.fontSize, original.fontSize);
      expect(restored.useSystemDarkMode, original.useSystemDarkMode);
    });

    test('copyWith preserves unset fields', () {
      const settings = AppSettings(fontSize: 20.0);
      final copied = settings.copyWith(fontFamily: 'Inter');
      expect(copied.fontSize, 20.0);
      expect(copied.fontFamily, 'Inter');
      expect(copied.themeVariant, AppThemeVariant.light);
    });
  });

  group('MarkdownFile', () {
    test('contentPreview truncates long content', () {
      final file = MarkdownFile(
        path: '/test.md',
        name: 'test.md',
        content: 'a' * 200,
        lastModified: DateTime(2026),
      );
      expect(file.contentPreview.endsWith('...'), true);
      expect(file.contentPreview.length, 103);
    });

    test('contentPreview does not truncate short content', () {
      final file = MarkdownFile(
        path: '/test.md',
        name: 'test.md',
        content: 'Hello',
        lastModified: DateTime(2026),
      );
      expect(file.contentPreview, 'Hello');
    });
  });

  group('RecentFileEntry', () {
    test('JSON serialization roundtrip', () {
      final now = DateTime(2026, 4, 25, 10, 30);
      final entry = RecentFileEntry(
        path: '/doc.md',
        displayName: 'doc.md',
        lastOpenedAt: now,
        contentPreview: 'preview text',
      );
      final json = entry.toJson();
      final restored = RecentFileEntry.fromJson(json);
      expect(restored.path, entry.path);
      expect(restored.displayName, entry.displayName);
      expect(restored.lastOpenedAt, entry.lastOpenedAt);
      expect(restored.contentPreview, entry.contentPreview);
    });
  });

  group('MarkdownUtils', () {
    test('insertBold wraps selection', () {
      final controller = TextEditingController(text: 'hello world');
      controller.selection = TextSelection(baseOffset: 0, extentOffset: 5);
      MarkdownUtils.insertBold(controller);
      expect(controller.text, '**hello** world');
    });

    test('insertBold with collapsed selection inserts markers at cursor', () {
      final controller = TextEditingController(text: 'hello');
      controller.selection = const TextSelection.collapsed(offset: 5);
      MarkdownUtils.insertBold(controller);
      expect(controller.text, 'hello****');
    });

    test('insertItalic wraps selection', () {
      final controller = TextEditingController(text: 'hello');
      controller.selection = TextSelection(baseOffset: 0, extentOffset: 5);
      MarkdownUtils.insertItalic(controller);
      expect(controller.text, '*hello*');
    });

    test('insertStrikethrough wraps selection', () {
      final controller = TextEditingController(text: 'hello');
      controller.selection = TextSelection(baseOffset: 0, extentOffset: 5);
      MarkdownUtils.insertStrikethrough(controller);
      expect(controller.text, '~~hello~~');
    });
  });

  group('ColorSchemes', () {
    test('all color schemes have all required properties', () {
      for (final scheme in [
        ColorSchemes.light,
        ColorSchemes.dark,
        ColorSchemes.oled,
        ColorSchemes.warmBrown,
        ColorSchemes.coldGray,
      ]) {
        expect(scheme.secondaryContainer, isNotNull);
        expect(scheme.onSecondaryContainer, isNotNull);
        expect(scheme.tertiaryContainer, isNotNull);
        expect(scheme.onTertiaryContainer, isNotNull);
        expect(scheme.errorContainer, isNotNull);
        expect(scheme.onErrorContainer, isNotNull);
      }
    });
  });

  group('AppThemeVariant', () {
    test('isDark returns correct values', () {
      expect(AppThemeVariant.light.isDark, false);
      expect(AppThemeVariant.dark.isDark, true);
      expect(AppThemeVariant.oled.isDark, true);
      expect(AppThemeVariant.warmBrown.isDark, true);
      expect(AppThemeVariant.coldGray.isDark, true);
    });

    test('each variant has a displayName', () {
      for (final variant in AppThemeVariant.values) {
        expect(variant.displayName.isNotEmpty, true);
      }
    });
  });

  group('Widget build', () {
    testWidgets('PureMDApp renders without error', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: PureMDApp()));
      await tester.pump();
      // Should not throw — basic smoke test
    });
  });
}
