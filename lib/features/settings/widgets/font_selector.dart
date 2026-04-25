import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../settings_provider.dart';

class FontSelector extends ConsumerWidget {
  const FontSelector({super.key});

  static const _fontOptions = [
    ('', '默认'),
    ('Noto Sans SC', 'Noto Sans SC'),
    ('Noto Serif SC', 'Noto Serif SC'),
    ('LXGW WenKai', '霞鹜文楷'),
    ('Inter', 'Inter'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final currentFont = settings?.fontFamily ?? '';
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _fontOptions.map((option) {
        final (fontFamily, displayName) = option;
        final isSelected = fontFamily == currentFont;

        return ChoiceChip(
          label: Text(
            displayName,
            style: fontFamily.isNotEmpty
                ? GoogleFonts.getFont(fontFamily)
                : null,
          ),
          selected: isSelected,
          onSelected: (_) {
            ref.read(settingsProvider.notifier).setFontFamily(fontFamily);
          },
          backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          selectedColor: colorScheme.primaryContainer,
          side: BorderSide(
            color: isSelected ? colorScheme.primary : Colors.transparent,
          ),
        );
      }).toList(),
    );
  }
}
