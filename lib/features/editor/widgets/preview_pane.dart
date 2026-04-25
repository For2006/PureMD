import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/settings_provider.dart';
import '../../reader/widgets/markdown_renderer.dart';

class PreviewPane extends ConsumerWidget {
  final String content;

  const PreviewPane({super.key, required this.content});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;

    if (content.isEmpty) {
      return Center(
        child: Text(
          '预览区域',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: MarkdownRenderer(
        data: content,
        fontSize: settings?.fontSize,
      ),
    );
  }
}
