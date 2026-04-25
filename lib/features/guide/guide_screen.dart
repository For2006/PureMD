import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../reader/widgets/markdown_renderer.dart';

class MarkdownGuideScreen extends ConsumerStatefulWidget {
  const MarkdownGuideScreen({super.key});

  @override
  ConsumerState<MarkdownGuideScreen> createState() => _MarkdownGuideScreenState();
}

class _MarkdownGuideScreenState extends ConsumerState<MarkdownGuideScreen> {
  String _content = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGuide();
  }

  Future<void> _loadGuide() async {
    try {
      final content = await rootBundle.loadString('assets/documents/markdown-guide.md');
      if (mounted) {
        setState(() {
          _content = content;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go('/settings'),
          icon: const Icon(Icons.arrow_back),
          iconSize: 22,
        ),
        title: Text(
          'Markdown 语法',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _content.isEmpty
              ? Center(
                  child: Text(
                    '无法加载语法指南',
                    style: TextStyle(color: colorScheme.outline),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: MarkdownRenderer(
                    data: _content,
                  ),
                ),
    );
  }
}
