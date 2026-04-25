import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';

import 'editor_provider.dart';
import 'widgets/markdown_toolbar.dart';
import 'widgets/preview_pane.dart';
import 'widgets/editor_scaffold.dart';
import 'widgets/block_editor.dart';

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
  final _blockEditorKey = GlobalKey<BlockEditorState>();
  final _fallbackController = TextEditingController();
  late AnimationController _previewAnimController;
  bool _isPreviewVisible = false;

  @override
  void initState() {
    super.initState();
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
    _fallbackController.dispose();
    _previewAnimController.dispose();
    super.dispose();
  }

  Future<bool> _save() async {
    final notifier = ref.read(editorProvider.notifier);
    final state = ref.read(editorProvider);
    if (state.filePath.isNotEmpty) {
      return notifier.saveFile();
    }
    try {
      final now = DateTime.now();
      final timestamp = '${now.year}${_pad(now.month)}${_pad(now.day)}_${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}';
      final bytes = utf8.encode(state.content);
      final path = await FilePicker.platform.saveFile(
        fileName: '笔记_$timestamp.md',
        type: FileType.custom,
        allowedExtensions: ['md', 'markdown'],
        bytes: bytes,
      );
      if (path == null) return false;
      return notifier.saveNewFile(path);
    } catch (_) {
      return false;
    }
  }

  void _togglePreview() {
    HapticFeedback.lightImpact();
    setState(() => _isPreviewVisible = !_isPreviewVisible);
    if (_isPreviewVisible) {
      _previewAnimController.forward();
    } else {
      _previewAnimController.reverse();
    }
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final isModified = ref.watch(editorProvider.select((s) => s.isModified));
    final filePath = ref.watch(editorProvider.select((s) => s.filePath));
    final colorScheme = Theme.of(context).colorScheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final focusedController = _blockEditorKey.currentState?.focusedController;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            if (isModified) {
              _showSaveDialog(context);
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
              : (filePath.isNotEmpty ? '编辑' : '编辑器'),
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
            opacity: isModified ? 1.0 : 0.4,
            duration: const Duration(milliseconds: 200),
            child: IconButton(
              onPressed: isModified
                  ? () async {
                      HapticFeedback.mediumImpact();
                      final saved = await _save();
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
        editor: BlockEditor(key: _blockEditorKey),
        preview: const PreviewPane(),
        toolbar: MarkdownToolbar(
          controller: focusedController ?? _fallbackController,
          onFormat: () {},
        ),
        showPreview: _isPreviewVisible,
        isLandscape: isLandscape,
      ),
    );
  }

  void _showSaveDialog(BuildContext context) {
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
              final saved = await _save();
              if (ctx.mounted) Navigator.pop(ctx);
              if (saved && context.mounted) context.go('/');
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
