import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings_provider.dart';

class FontSizeSlider extends ConsumerWidget {
  const FontSizeSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final fontSize = settings?.fontSize ?? 16.0;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '字体大小',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            Text(
              '${fontSize.round()}sp',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: fontSize,
          min: 12,
          max: 24,
          divisions: 12,
          activeColor: colorScheme.primary,
          inactiveColor: colorScheme.primaryContainer,
          onChanged: (value) {
            ref.read(settingsProvider.notifier).setFontSize(value);
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '预览文字效果 Preview Text 预覽文字效果',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: fontSize,
                ),
          ),
        ),
      ],
    );
  }
}
