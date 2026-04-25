import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/markdown_utils.dart';

class MarkdownToolbar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onFormat;

  const MarkdownToolbar({
    super.key,
    required this.controller,
    this.onFormat,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ToolButton(
              icon: Icons.format_bold,
              label: '粗体',
              onTap: () => _insert(_Action.bold),
              colorScheme: colorScheme,
            ),
            _ToolButton(
              icon: Icons.format_italic,
              label: '斜体',
              onTap: () => _insert(_Action.italic),
              colorScheme: colorScheme,
            ),
            _ToolButton(
              icon: Icons.strikethrough_s,
              label: '删除线',
              onTap: () => _insert(_Action.strikethrough),
              colorScheme: colorScheme,
            ),
            _VerticalDivider(colorScheme: colorScheme),
            _ToolButton(
              icon: Icons.title,
              label: '标题',
              onTap: () => _insert(_Action.heading),
              colorScheme: colorScheme,
            ),
            _ToolButton(
              icon: Icons.link,
              label: '链接',
              onTap: () => _insert(_Action.link),
              colorScheme: colorScheme,
            ),
            _ToolButton(
              icon: Icons.image_outlined,
              label: '图片',
              onTap: () => _insert(_Action.image),
              colorScheme: colorScheme,
            ),
            _VerticalDivider(colorScheme: colorScheme),
            _ToolButton(
              icon: Icons.code,
              label: '代码',
              onTap: () => _insert(_Action.code),
              colorScheme: colorScheme,
            ),
            _ToolButton(
              icon: Icons.integration_instructions,
              label: '代码块',
              onTap: () => _insert(_Action.codeBlock),
              colorScheme: colorScheme,
            ),
            _VerticalDivider(colorScheme: colorScheme),
            _ToolButton(
              icon: Icons.format_list_bulleted,
              label: '列表',
              onTap: () => _insert(_Action.unorderedList),
              colorScheme: colorScheme,
            ),
            _ToolButton(
              icon: Icons.format_list_numbered,
              label: '编号',
              onTap: () => _insert(_Action.orderedList),
              colorScheme: colorScheme,
            ),
            _ToolButton(
              icon: Icons.check_box_outlined,
              label: '待办',
              onTap: () => _insert(_Action.todo),
              colorScheme: colorScheme,
            ),
            _VerticalDivider(colorScheme: colorScheme),
            _ToolButton(
              icon: Icons.format_quote,
              label: '引用',
              onTap: () => _insert(_Action.quote),
              colorScheme: colorScheme,
            ),
            _ToolButton(
              icon: Icons.horizontal_rule,
              label: '分隔线',
              onTap: () => _insert(_Action.divider),
              colorScheme: colorScheme,
            ),
            _ToolButton(
              icon: Icons.table_chart_outlined,
              label: '表格',
              onTap: () => _insert(_Action.table),
              colorScheme: colorScheme,
            ),
          ],
        ),
      ),
    );
  }

  void _insert(_Action action) {
    HapticFeedback.lightImpact();

    switch (action) {
      case _Action.bold:
        MarkdownUtils.insertBold(controller);
      case _Action.italic:
        MarkdownUtils.insertItalic(controller);
      case _Action.strikethrough:
        MarkdownUtils.insertStrikethrough(controller);
      case _Action.heading:
        MarkdownUtils.insertHeading(controller);
      case _Action.link:
        MarkdownUtils.insertLink(controller);
      case _Action.unorderedList:
        MarkdownUtils.insertUnorderedList(controller);
      case _Action.orderedList:
        MarkdownUtils.insertOrderedList(controller);
      case _Action.todo:
        MarkdownUtils.insertTodo(controller);
      case _Action.code:
        MarkdownUtils.insertCode(controller);
      case _Action.codeBlock:
        MarkdownUtils.insertCodeBlock(controller);
      case _Action.quote:
        MarkdownUtils.insertQuote(controller);
      case _Action.divider:
        MarkdownUtils.insertDivider(controller);
      case _Action.image:
        MarkdownUtils.insertImage(controller);
      case _Action.table:
        MarkdownUtils.insertTable(controller);
    }
    onFormat?.call();
  }
}

enum _Action {
  bold,
  italic,
  strikethrough,
  heading,
  link,
  image,
  code,
  codeBlock,
  unorderedList,
  orderedList,
  todo,
  quote,
  divider,
  table,
}

class _ToolButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  State<_ToolButton> createState() => _ToolButtonState();
}

class _ToolButtonState extends State<_ToolButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.label,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.88 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: Container(
            width: 38,
            height: 38,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.icon,
              size: 20,
              color: widget.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  final ColorScheme colorScheme;

  const _VerticalDivider({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
    );
  }
}
