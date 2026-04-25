import 'package:flutter/material.dart';

class MarkdownUtils {
  MarkdownUtils._();

  static void wrapSelection(
    TextEditingController controller, {
    required String prefix,
    String suffix = '',
  }) {
    final text = controller.text;
    final selection = controller.selection;
    final hasValidSelection = selection.start >= 0 && selection.end >= 0 &&
        selection.start <= text.length && selection.end <= text.length;
    final selectedText = hasValidSelection ? selection.textInside(text) : '';
    final hasSelection = hasValidSelection && selectedText.isNotEmpty;

    String newText;
    int cursorStart;
    int cursorEnd;

    if (hasSelection && selectedText.isNotEmpty) {
      newText = text.replaceRange(
        selection.start,
        selection.end,
        '$prefix$selectedText$suffix',
      );
      cursorStart = selection.start;
      cursorEnd = cursorStart + prefix.length + selectedText.length + suffix.length;
    } else {
      final insertPoint = hasSelection ? selection.start : text.length;
      newText = text.replaceRange(
        insertPoint,
        insertPoint,
        '$prefix$suffix',
      );
      cursorStart = insertPoint + prefix.length;
      cursorEnd = cursorStart;
    }

    controller.text = newText;
    controller.selection = TextSelection(
      baseOffset: cursorStart,
      extentOffset: cursorEnd,
    );
  }

  static void insertBold(TextEditingController controller) {
    wrapSelection(controller, prefix: '**', suffix: '**');
  }

  static void insertItalic(TextEditingController controller) {
    wrapSelection(controller, prefix: '*', suffix: '*');
  }

  static void insertStrikethrough(TextEditingController controller) {
    wrapSelection(controller, prefix: '~~', suffix: '~~');
  }

  static void insertLink(TextEditingController controller) {
    final selection = controller.selection;
    final hasValidSelection = selection.start >= 0 && selection.end >= 0 &&
        selection.start <= controller.text.length && selection.end <= controller.text.length;
    final selectedText = hasValidSelection ? selection.textInside(controller.text) : '';
    if (selectedText.isNotEmpty) {
      wrapSelection(controller, prefix: '[', suffix: '](url)');
    } else {
      wrapSelection(controller, prefix: '[链接文本](url)');
    }
  }

  static void insertHeading(TextEditingController controller, {int level = 2}) {
    final prefix = '${'#' * level} ';
    wrapSelection(controller, prefix: prefix);
  }

  static void insertUnorderedList(TextEditingController controller) {
    wrapSelection(controller, prefix: '- ');
  }

  static void insertOrderedList(TextEditingController controller) {
    wrapSelection(controller, prefix: '1. ');
  }

  static void insertTodo(TextEditingController controller) {
    wrapSelection(controller, prefix: '- [ ] ');
  }

  static void insertCode(TextEditingController controller) {
    final selection = controller.selection;
    final hasValidSelection = selection.start >= 0 && selection.end >= 0 &&
        selection.start <= controller.text.length && selection.end <= controller.text.length;
    final selectedText = hasValidSelection ? selection.textInside(controller.text) : '';
    if (selectedText.contains('\n')) {
      wrapSelection(controller, prefix: '```\n', suffix: '\n```');
    } else {
      wrapSelection(controller, prefix: '`', suffix: '`');
    }
  }

  static void insertQuote(TextEditingController controller) {
    wrapSelection(controller, prefix: '> ');
  }

  static void insertDivider(TextEditingController controller) {
    final text = controller.text;
    final cursorPos = controller.selection.start >= 0
        ? controller.selection.start
        : text.length;
    final needsNewline = cursorPos > 0 && text[cursorPos - 1] != '\n';
    final prefix = needsNewline ? '\n---\n' : '---\n';
    wrapSelection(controller, prefix: prefix);
  }
}
