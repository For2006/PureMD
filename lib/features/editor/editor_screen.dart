import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'editor_provider.dart';
import 'widgets/markdown_toolbar.dart';
import 'widgets/preview_pane.dart';
import 'widgets/editor_scaffold.dart';

class EditorScreen extends ConsumerStatefulWidget {
  final String? filePath;
  final bool quickMode;

  const EditorScreen({
    super.key,
    this.filePath,
    this.quickMode = false,
  });

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _textController;
  late AnimationController _previewAnimController;
  bool _isPreviewVisible = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _previewAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.quickMode) {
        ref.read(editorProvider.notifier).createNewFile();
      } else if (widget.filePath != null) {
        ref.read(editorProvider.notifier).loadFile(widget.filePath!);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _previewAnimController.dispose();
    super.dispose();
  }

  void _togglePreview() {
    HapticFeedback.lightImpact();
    setState(() => _isPreviewVisible = !_isPreviewVisible);
    if (_isPreviewVisible) {
      _previewAnimController.forward();
    } else {
      _previewAnimController.reverse();
    }
    ref.read(editorProvider.notifier).togglePreview();
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorProvider);
    final notifier = ref.read(editorProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    if (_textController.text != editorState.content) {
      _textController.text = editorState.content;
      _textController.selection = TextSelection.collapsed(
        offset: editorState.content.length,
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            if (editorState.isModified) {
              _showSaveDialog(context, notifier);
            } else {
              context.go('/');
            }
          },
          icon: const Icon(Icons.arrow_back),
          iconSize: 22,
        ),
        title: Text(
          widget.quickMode
              ? '新笔记'
              : (editorState.filePath.isNotEmpty ? '编辑' : '编辑器'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        actions: [
          if (!isLandscape)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: IconButton(
                key: ValueKey(_isPreviewVisible),
                onPressed: _togglePreview,
                icon: Icon(
                  _isPreviewVisible
                      ? Icons.edit_outlined
                      : Icons.visibility_outlined,
                ),
                tooltip: _isPreviewVisible ? '编辑' : '预览',
                iconSize: 22,
              ),
            ),
          AnimatedOpacity(
            opacity: editorState.isModified ? 1.0 : 0.4,
            duration: const Duration(milliseconds: 200),
            child: IconButton(
              onPressed: editorState.isModified
                  ? () async {
                      HapticFeedback.mediumImpact();
                      final saved = await notifier.saveFile();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(
                                  saved ? Icons.check_circle_outline : Icons.error_outline,
                                  color: colorScheme.onInverseSurface,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Text(saved ? '已保存' : '保存失败'),
                              ],
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    }
                  : null,
              icon: const Icon(Icons.check),
              tooltip: '保存',
              iconSize: 22,
            ),
          ),
        ],
      ),
      body: EditorScaffold(
        editor: _buildEditor(context, colorScheme, notifier),
        preview: PreviewPane(content: editorState.content),
        toolbar: MarkdownToolbar(
          controller: _textController,
          onFormat: () {
            notifier.updateContent(_textController.text);
          },
        ),
        showPreview: _isPreviewVisible,
        isLandscape: isLandscape,
      ),
    );
  }

  Widget _buildEditor(BuildContext context, ColorScheme colorScheme, EditorNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _textController,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        keyboardAppearance: Theme.of(context).brightness == Brightness.dark
            ? Brightness.dark
            : Brightness.light,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontFamily: 'monospace',
              height: 1.7,
              letterSpacing: 0.3,
            ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: '开始写作...',
          hintStyle: TextStyle(
            color: colorScheme.outline.withValues(alpha: 0.6),
            fontWeight: FontWeight.w300,
          ),
          contentPadding: const EdgeInsets.only(top: 8, bottom: 8),
        ),
        onChanged: (text) {
          notifier.updateContent(text);
        },
      ),
    );
  }

  void _showSaveDialog(BuildContext context, EditorNotifier notifier) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('未保存的更改'),
        content: const Text('是否保存当前更改？'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/');
            },
            child: Text(
              '放弃',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          TextButton(
            onPressed: () async {
              await notifier.saveFile();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) context.go('/');
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
