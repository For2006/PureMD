import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../editor_provider.dart';
import '../../settings/settings_provider.dart';
import '../../reader/widgets/markdown_renderer.dart';

class PreviewPane extends ConsumerStatefulWidget {
  const PreviewPane({super.key});

  @override
  ConsumerState<PreviewPane> createState() => _PreviewPaneState();
}

class _PreviewPaneState extends ConsumerState<PreviewPane> {
  String _displayedContent = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _displayedContent = ref.read(editorProvider.select((s) => s.content));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rawContent = ref.watch(editorProvider.select((s) => s.content));
    if (rawContent != _displayedContent) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 200), () {
        if (mounted) setState(() => _displayedContent = rawContent);
      });
    }

    final content = _displayedContent;
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
