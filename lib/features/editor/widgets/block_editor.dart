import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/md_block.dart';
import '../editor_provider.dart';

class BlockEditor extends ConsumerStatefulWidget {
  const BlockEditor({super.key});

  @override
  ConsumerState<BlockEditor> createState() => BlockEditorState();
}

class BlockEditorState extends ConsumerState<BlockEditor> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  int _focusedIndex = -1;
  List<MDBlock> _lastBlocks = const [];

  // Debounce pending content changes — batch keystrokes before syncing to provider
  final Map<String, String> _pendingUpdates = {};
  Timer? _flushTimer;
  Timer? _forceFlushTimer;

  TextEditingController? get focusedController {
    if (_focusedIndex < 0) return null;
    final blocks = ref.read(editorProvider).blocks;
    if (_focusedIndex >= blocks.length) return null;
    return _controllers[blocks[_focusedIndex].id];
  }

  @override
  void dispose() {
    _flushTimer?.cancel();
    _forceFlushTimer?.cancel();
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(MDBlock block) {
    final ctrl = _controllers.putIfAbsent(block.id, () => TextEditingController(text: block.content));
    if (ctrl.text != block.content) {
      ctrl.text = block.content;
    }
    return ctrl;
  }

  FocusNode _focusNodeFor(MDBlock block) {
    return _focusNodes.putIfAbsent(block.id, () {
      final node = FocusNode();
      node.addListener(() {
        if (node.hasFocus) {
          final blocks = ref.read(editorProvider).blocks;
          final idx = blocks.indexWhere((b) => b.id == block.id);
          if (idx >= 0 && idx != _focusedIndex) {
            setState(() => _focusedIndex = idx);
          }
        }
      });
      return node;
    });
  }

  void _onTextChanged(int index, String text) {
    // Batch keystrokes — only sync to provider after 300ms of inactivity
    final blockId = ref.read(editorProvider).blocks[index].id;
    _pendingUpdates[blockId] = text;

    _flushTimer?.cancel();
    _flushTimer = Timer(const Duration(milliseconds: 300), _flushUpdates);

    // Safety net: force flush at least every 2s during continuous typing
    _forceFlushTimer ??= Timer(const Duration(seconds: 2), _flushUpdates);
  }

  /// Flush pending content changes to the provider now.
  void _flushUpdates() {
    _flushTimer?.cancel();
    _forceFlushTimer?.cancel();
    _forceFlushTimer = null;
    if (_pendingUpdates.isEmpty) return;
    final notifier = ref.read(editorProvider.notifier);
    for (final entry in _pendingUpdates.entries) {
      notifier.updateBlockContentById(entry.key, entry.value);
    }
    _pendingUpdates.clear();
  }

  /// Public flush — called by EditorScreen before save/preview/back navigation.
  void flushUpdates() {
    _flushUpdates();
  }

  void _onDelete(int index) {
    final blocks = ref.read(editorProvider).blocks;
    if (index >= blocks.length) return;
    if (blocks.length <= 1) return;

    ref.read(editorProvider.notifier).deleteBlock(index);
    final targetIndex = index > 0 ? index - 1 : 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final updatedBlocks = ref.read(editorProvider).blocks;
      if (targetIndex < updatedBlocks.length) {
        final targetNode = _focusNodes[updatedBlocks[targetIndex].id];
        if (targetNode != null) {
          targetNode.requestFocus();
          final ctrl = _controllers[updatedBlocks[targetIndex].id];
          if (ctrl != null) {
            ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
          }
        }
      }
    });
  }

  void _onAddBlock(int index) {
    ref.read(editorProvider.notifier).insertBlock(index + 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final blocks = ref.read(editorProvider).blocks;
      if (index + 1 < blocks.length) {
        final node = _focusNodes[blocks[index + 1].id];
        if (node != null) {
          node.requestFocus();
          final ctrl = _controllers[blocks[index + 1].id];
          if (ctrl != null) {
            ctrl.selection = TextSelection.collapsed(offset: 0);
          }
        }
      }
    });
  }

  void _onArrowUp(int index) {
    if (index <= 0) return;
    final blocks = ref.read(editorProvider).blocks;
    if (index - 1 < blocks.length) {
      _focusNodes[blocks[index - 1].id]?.requestFocus();
    }
  }

  void _onArrowDown(int index) {
    final blocks = ref.read(editorProvider).blocks;
    if (index + 1 < blocks.length) {
      _focusNodes[blocks[index + 1].id]?.requestFocus();
    }
  }

  void _showTypeSelector(BuildContext context, int index) {
    HapticFeedback.lightImpact();
    final blocks = ref.read(editorProvider).blocks;
    if (index >= blocks.length) return;
    final currentType = blocks[index].type;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _BlockTypeSelector(
        currentType: currentType,
        onSelect: (type) {
          Navigator.pop(ctx);
          ref.read(editorProvider.notifier).changeBlockType(index, type);
        },
      ),
    ).then((_) {
      // Ensure controllers stay in sync after sheet closes
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final blocks = ref.watch(editorProvider.select((s) => s.blocks));

    // Only clean up orphaned controllers/nodes on structural changes (insert/delete)
    if (blocks.length != _lastBlocks.length) {
      final activeIds = blocks.map((b) => b.id).toSet();
      _controllers.keys.where((id) => !activeIds.contains(id)).toList().forEach((id) {
        _controllers.remove(id)?.dispose();
        _focusNodes.remove(id)?.dispose();
      });
      _lastBlocks = blocks;
    }

    return GestureDetector(
      onTap: () {
        // Tap on empty area → focus the last block
        if (blocks.isNotEmpty) {
          _focusNodes[blocks.last.id]?.requestFocus();
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: blocks.length,
        itemBuilder: (context, index) {
          final block = blocks[index];
          final isFocused = index == _focusedIndex;
          final controller = _controllerFor(block);
          final focusNode = _focusNodeFor(block);

          return _BlockWidget(
            block: block,
            index: index,
            controller: controller,
            focusNode: focusNode,
            isFocused: isFocused,
            onChanged: (text) => _onTextChanged(index, text),
            onDelete: () => _onDelete(index),
            onAddBlock: () => _onAddBlock(index),
            onArrowUp: () => _onArrowUp(index),
            onArrowDown: () => _onArrowDown(index),
            onTypeTap: () => _showTypeSelector(context, index),
            onToggleCheckbox: block.type == MDBlockType.todo
                ? () => ref.read(editorProvider.notifier).toggleTodoChecked(index)
                : null,
          );
        },
      ),
    );
  }
}

class _BlockWidget extends StatelessWidget {
  final MDBlock block;
  final int index;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final ValueChanged<String> onChanged;
  final VoidCallback onDelete;
  final VoidCallback onAddBlock;
  final VoidCallback onArrowUp;
  final VoidCallback onArrowDown;
  final VoidCallback onTypeTap;
  final VoidCallback? onToggleCheckbox;

  const _BlockWidget({
    required this.block,
    required this.index,
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.onChanged,
    required this.onDelete,
    required this.onAddBlock,
    required this.onArrowUp,
    required this.onArrowDown,
    required this.onTypeTap,
    this.onToggleCheckbox,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (block.type == MDBlockType.divider) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 1),
        decoration: BoxDecoration(
          color: isFocused ? colorScheme.primaryContainer.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: _buildDivider(colorScheme),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        color: isFocused ? colorScheme.primaryContainer.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDragHandle(colorScheme),
          Expanded(child: _buildContent(context, colorScheme)),
          if (isFocused) _buildBlockActions(colorScheme),
        ],
      ),
    );
  }

  Widget _buildDragHandle(ColorScheme colorScheme) {
    return GestureDetector(
      onTap: onTypeTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 28,
        height: 36,
        alignment: Alignment.center,
        margin: const EdgeInsets.only(top: 6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isFocused ? colorScheme.primaryContainer.withValues(alpha: 0.5) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            _blockIcon,
            size: 14,
            color: isFocused ? colorScheme.primary : colorScheme.outline,
          ),
        ),
      ),
    );
  }

  Widget _buildBlockActions(ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _actionButton(
          icon: Icons.add_circle_outline,
          color: colorScheme.primary,
          onTap: onAddBlock,
        ),
        const SizedBox(width: 4),
        _actionButton(
          icon: Icons.delete_outline,
          color: colorScheme.error,
          onTap: onDelete,
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        margin: const EdgeInsets.only(top: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  IconData get _blockIcon {
    switch (block.type) {
      case MDBlockType.paragraph:
        return Icons.text_fields;
      case MDBlockType.heading1:
        return Icons.looks_one;
      case MDBlockType.heading2:
        return Icons.looks_two;
      case MDBlockType.heading3:
        return Icons.looks_3;
      case MDBlockType.code:
        return Icons.code;
      case MDBlockType.quote:
        return Icons.format_quote;
      case MDBlockType.bulletList:
        return Icons.format_list_bulleted;
      case MDBlockType.numberedList:
        return Icons.format_list_numbered;
      case MDBlockType.todo:
        return Icons.check_box_outlined;
      case MDBlockType.divider:
        return Icons.horizontal_rule;
      case MDBlockType.table:
        return Icons.table_chart_outlined;
      case MDBlockType.image:
        return Icons.image_outlined;
    }
  }

  Widget _buildDivider(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _buildDragHandle(colorScheme),
          Expanded(
            child: Container(
              height: 1,
              color: colorScheme.outlineVariant,
            ),
          ),
          if (isFocused) _buildBlockActions(colorScheme),
        ],
      ),
    );
  }

  TextStyle _textStyle(BuildContext context, ColorScheme colorScheme) {
    final bodyStyle = Theme.of(context).textTheme.bodyLarge ??
        const TextStyle(fontSize: 16);

    switch (block.type) {
      case MDBlockType.heading1:
        return bodyStyle.copyWith(fontSize: 26, fontWeight: FontWeight.bold, height: 1.4);
      case MDBlockType.heading2:
        return bodyStyle.copyWith(fontSize: 22, fontWeight: FontWeight.w600, height: 1.4);
      case MDBlockType.heading3:
        return bodyStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4);
      case MDBlockType.quote:
        return bodyStyle.copyWith(
          fontSize: 16,
          fontStyle: FontStyle.italic,
          color: colorScheme.onSurfaceVariant,
          height: 1.6,
        );
      case MDBlockType.code:
        return bodyStyle.copyWith(
          fontFamily: 'monospace',
          fontSize: 14,
          height: 1.5,
        );
      case MDBlockType.todo:
        return bodyStyle.copyWith(fontSize: 16, height: 1.6);
      default:
        return bodyStyle.copyWith(fontSize: 16, height: 1.6);
    }
  }

  String? _hintText() {
    switch (block.type) {
      case MDBlockType.paragraph:
        return '输入 "/" 切换块类型...';
      case MDBlockType.heading1:
        return '一级标题';
      case MDBlockType.heading2:
        return '二级标题';
      case MDBlockType.heading3:
        return '三级标题';
      case MDBlockType.code:
        return '输入代码...';
      case MDBlockType.quote:
        return '引用文本...';
      case MDBlockType.bulletList:
        return '列表项...';
      case MDBlockType.numberedList:
        return '列表项...';
      case MDBlockType.todo:
        return '待办事项...';
      case MDBlockType.table:
        return '编辑表格';
      case MDBlockType.image:
        return '图片描述 (可选)';
      default:
        return null;
    }
  }

  Widget _buildContent(BuildContext context, ColorScheme colorScheme) {
    if (block.type == MDBlockType.todo) {
      return _buildTodoRow(context, colorScheme);
    }

    if (block.type == MDBlockType.code) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (block.language != null)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 6),
                child: Text(
                  block.language!,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            _buildTextField(context, colorScheme),
          ],
        ),
      );
    }

    if (block.type == MDBlockType.quote) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: colorScheme.tertiary, width: 3),
          ),
        ),
        child: _buildTextField(context, colorScheme),
      );
    }

    if (block.type == MDBlockType.table) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: _buildTextField(context, colorScheme),
      );
    }

    return _buildTextField(context, colorScheme);
  }

  Widget _buildTodoRow(BuildContext context, ColorScheme colorScheme) {
    return Row(
      children: [
        GestureDetector(
          onTap: onToggleCheckbox,
          child: Container(
            margin: const EdgeInsets.only(top: 10, right: 8),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: block.isChecked ? colorScheme.primary : Colors.transparent,
              border: Border.all(
                color: block.isChecked ? colorScheme.primary : colorScheme.outline,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: block.isChecked
                ? Icon(Icons.check, size: 16, color: colorScheme.onPrimary)
                : null,
          ),
        ),
        Expanded(
          child: _buildTextField(context, colorScheme),
        ),
      ],
    );
  }

  Widget _buildTextField(BuildContext context, ColorScheme colorScheme) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      maxLines: null,
      keyboardAppearance: Theme.of(context).brightness == Brightness.dark
          ? Brightness.dark
          : Brightness.light,
      style: _textStyle(context, colorScheme),
      decoration: InputDecoration(
        border: InputBorder.none,
        isCollapsed: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        hintText: _hintText(),
        hintStyle: TextStyle(
          color: colorScheme.outline.withValues(alpha: 0.4),
          fontSize: 16,
          fontWeight: FontWeight.w300,
        ),
      ),
      onChanged: onChanged,
    );
  }
}

class _BlockTypeSelector extends StatelessWidget {
  final MDBlockType currentType;
  final ValueChanged<MDBlockType> onSelect;

  const _BlockTypeSelector({
    required this.currentType,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '切换块类型',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _buildOptions(context, colorScheme),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOptions(BuildContext context, ColorScheme colorScheme) {
    final options = [
      (MDBlockType.paragraph, Icons.text_fields, '正文'),
      (MDBlockType.heading1, Icons.looks_one, '标题 1'),
      (MDBlockType.heading2, Icons.looks_two, '标题 2'),
      (MDBlockType.heading3, Icons.looks_3, '标题 3'),
      (MDBlockType.quote, Icons.format_quote, '引用'),
      (MDBlockType.bulletList, Icons.format_list_bulleted, '无序列表'),
      (MDBlockType.numberedList, Icons.format_list_numbered, '有序列表'),
      (MDBlockType.todo, Icons.check_box_outlined, '待办'),
      (MDBlockType.code, Icons.code, '代码'),
      (MDBlockType.table, Icons.table_chart_outlined, '表格'),
      (MDBlockType.image, Icons.image_outlined, '图片'),
      (MDBlockType.divider, Icons.horizontal_rule, '分隔线'),
    ];

    return options.map((option) {
      final (type, icon, label) = option;
      final isSelected = type == currentType;
      return ListTile(
        leading: Icon(icon, color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant),
        title: Text(label),
        trailing: isSelected
            ? Icon(Icons.check, color: colorScheme.primary, size: 18)
            : null,
        dense: true,
        onTap: () => onSelect(type),
      );
    }).toList();
  }
}
