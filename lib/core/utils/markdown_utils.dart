import 'package:flutter/material.dart';

import '../models/md_block.dart';

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

  static void insertImage(TextEditingController controller) {
    final selection = controller.selection;
    final hasValidSelection = selection.start >= 0 && selection.end >= 0 &&
        selection.start <= controller.text.length && selection.end <= controller.text.length;
    final selectedText = hasValidSelection ? selection.textInside(controller.text) : '';
    if (selectedText.isNotEmpty) {
      wrapSelection(controller, prefix: '![', suffix: '](url)');
    } else {
      wrapSelection(controller, prefix: '![图片描述](url)');
    }
  }

  static void insertCodeBlock(TextEditingController controller) {
    final selection = controller.selection;
    final hasValidSelection = selection.start >= 0 && selection.end >= 0 &&
        selection.start <= controller.text.length && selection.end <= controller.text.length;
    final selectedText = hasValidSelection ? selection.textInside(controller.text) : '';
    final prefix = '```\n';
    final suffix = '\n```';
    if (selectedText.isNotEmpty && !selectedText.contains('\n')) {
      wrapSelection(controller, prefix: '$prefix$selectedText', suffix: suffix);
    } else {
      wrapSelection(controller, prefix: prefix, suffix: suffix);
    }
  }

  static void insertTable(TextEditingController controller) {
    final text = controller.text;
    final cursorPos = controller.selection.start >= 0
        ? controller.selection.start
        : text.length;
    final needsNewline = cursorPos > 0 && text[cursorPos - 1] != '\n';
    final prefix = needsNewline ? '\n' : '';
    final table = '$prefix| 列1 | 列2 | 列3 |\n| --- | --- | --- |\n| 内容 | 内容 | 内容 |';
    wrapSelection(controller, prefix: table);
  }

  static List<MDBlock> parseToBlocks(String markdown) {
    // Normalize line endings: CRLF and lone CR → LF
    final normalized = markdown.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = normalized.split('\n');
    final blocks = <MDBlock>[];
    int idCounter = 0;
    String id() => 'b${++idCounter}';

    int i = 0;
    while (i < lines.length) {
      final line = lines[i];

      if (line.trimLeft().startsWith('```')) {
        // Extract language tag: ```python → 'python'
        final fenceContent = line.trimLeft().substring(3).trim();
        final language = fenceContent.isNotEmpty ? fenceContent : null;
        final codeLines = <String>[];
        i++;
        while (i < lines.length && !lines[i].trimLeft().startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }
        blocks.add(MDBlock(
          id: id(),
          type: MDBlockType.code,
          content: codeLines.join('\n'),
          language: language,
        ));
        i++;
        continue;
      }

      if (line.trim() == '---' || line.trim() == '***' || line.trim() == '___') {
        blocks.add(MDBlock(id: id(), type: MDBlockType.divider));
        i++;
        continue;
      }

      if (line.startsWith('### ')) {
        blocks.add(MDBlock(id: id(), type: MDBlockType.heading3, content: line.substring(4)));
        i++;
        continue;
      }
      if (line.startsWith('## ')) {
        blocks.add(MDBlock(id: id(), type: MDBlockType.heading2, content: line.substring(3)));
        i++;
        continue;
      }
      if (line.startsWith('# ')) {
        blocks.add(MDBlock(id: id(), type: MDBlockType.heading1, content: line.substring(2)));
        i++;
        continue;
      }

      final todoMatch = RegExp(r'^- \[([ xX])] ').matchAsPrefix(line);
      if (todoMatch != null) {
        final isChecked = todoMatch.group(1)!.toLowerCase() == 'x';
        blocks.add(MDBlock(
          id: id(),
          type: MDBlockType.todo,
          content: line.substring(todoMatch.end),
          isChecked: isChecked,
        ));
        i++;
        continue;
      }

      if (line.startsWith('> ')) {
        // Merge consecutive quote lines into one block
        final quoteLines = <String>[line.substring(2)];
        i++;
        while (i < lines.length && lines[i].startsWith('> ')) {
          quoteLines.add(lines[i].substring(2));
          i++;
        }
        blocks.add(MDBlock(
          id: id(),
          type: MDBlockType.quote,
          content: quoteLines.join('\n'),
        ));
        continue;
      }

      // Table detection — contiguous lines starting with |
      if (line.trimLeft().startsWith('|')) {
        final tableLines = <String>[line];
        i++;
        while (i < lines.length && lines[i].trimLeft().startsWith('|')) {
          tableLines.add(lines[i]);
          i++;
        }
        blocks.add(MDBlock(
          id: id(),
          type: MDBlockType.table,
          content: tableLines.join('\n'),
        ));
        continue;
      }

      if (line.startsWith('- ')) {
        blocks.add(MDBlock(id: id(), type: MDBlockType.bulletList, content: line.substring(2)));
        i++;
        continue;
      }

      final numMatch = RegExp(r'^\d+\. ').matchAsPrefix(line);
      if (numMatch != null) {
        blocks.add(MDBlock(id: id(), type: MDBlockType.numberedList, content: line.substring(numMatch.end)));
        i++;
        continue;
      }

      // Image block detection — line is primarily a markdown image
      final imageMatch = RegExp(r'^\s*!\[([^\]]*)\]\(([^)]+)\)\s*$').matchAsPrefix(line);
      if (imageMatch != null) {
        blocks.add(MDBlock(
          id: id(),
          type: MDBlockType.image,
          content: line.trim(),
        ));
        i++;
        continue;
      }

      blocks.add(MDBlock(id: id(), type: MDBlockType.paragraph, content: line));
      i++;
    }

    if (blocks.isEmpty) {
      blocks.add(MDBlock(id: id(), type: MDBlockType.paragraph));
    }

    return blocks;
  }

  static String serializeBlocks(List<MDBlock> blocks) {
    return blocks.map((block) {
      switch (block.type) {
        case MDBlockType.paragraph:
          return block.content;
        case MDBlockType.heading1:
          return '# ${block.content}';
        case MDBlockType.heading2:
          return '## ${block.content}';
        case MDBlockType.heading3:
          return '### ${block.content}';
        case MDBlockType.code:
          final lang = block.language ?? '';
          return lang.isNotEmpty ? '```$lang\n${block.content}\n```' : '```\n${block.content}\n```';
        case MDBlockType.quote:
          return '> ${block.content}';
        case MDBlockType.bulletList:
          return '- ${block.content}';
        case MDBlockType.numberedList:
          return '1. ${block.content}';
        case MDBlockType.todo: {
          final checkbox = block.isChecked ? '[x]' : '[ ]';
          return '- $checkbox ${block.content}';
        }
        case MDBlockType.divider:
          return '---';
        case MDBlockType.table:
          return block.content;
        case MDBlockType.image:
          return block.content;
      }
    }).join('\n');
  }
}
