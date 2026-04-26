import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class MarkdownRenderer extends StatelessWidget {
  final String data;
  final double? fontSize;
  final VoidCallback? onLinkTap;

  const MarkdownRenderer({
    super.key,
    required this.data,
    this.fontSize,
    this.onLinkTap,
  });

  static final Map<_MarkdownStyleKey, MarkdownStyleSheet> _styleCache = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveFontSize = fontSize ?? theme.textTheme.bodyLarge?.fontSize ?? 16.0;

    final styleKey = _MarkdownStyleKey(
      colorScheme: colorScheme,
      fontSize: effectiveFontSize,
    );
    final styleSheet = _styleCache.putIfAbsent(styleKey, () => _buildStyleSheet(
      theme: theme,
      colorScheme: colorScheme,
      effectiveFontSize: effectiveFontSize,
    ));

    return MarkdownBody(
      data: data,
      styleSheet: styleSheet,
      selectable: true,
      onTapLink: (text, href, title) {
        if (href != null) {
          final uri = Uri.parse(href);
          launchUrl(uri);
        }
        onLinkTap?.call();
      },
    );
  }

  static MarkdownStyleSheet _buildStyleSheet({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required double effectiveFontSize,
  }) {
    return MarkdownStyleSheet(
      h1: theme.textTheme.headlineLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
      h2: theme.textTheme.headlineMedium?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
      h3: theme.textTheme.headlineSmall?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
      p: theme.textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurface,
        fontSize: effectiveFontSize,
        height: 1.8,
      ),
      code: theme.textTheme.bodySmall?.copyWith(
        fontFamily: 'monospace',
        backgroundColor: colorScheme.surfaceContainerHighest,
        color: colorScheme.primary,
      ),
      codeblockDecoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      codeblockPadding: const EdgeInsets.all(16),
      blockquote: TextStyle(
        color: colorScheme.onSurface.withValues(alpha: 0.7),
        fontSize: effectiveFontSize,
        height: 1.8,
      ),
      blockquoteDecoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: colorScheme.primary, width: 3),
        ),
      ),
      blockquotePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      listBullet: TextStyle(
        color: colorScheme.primary,
        fontSize: effectiveFontSize,
      ),
      listIndent: 24,
      tableHead: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
      tableBody: TextStyle(color: colorScheme.onSurface),
      tableBorder: TableBorder.all(
        color: colorScheme.outlineVariant,
        width: 0.5,
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      strong: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
      em: TextStyle(fontStyle: FontStyle.italic, color: colorScheme.onSurface),
      a: TextStyle(
        color: colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
    );
  }
}

class _MarkdownStyleKey {
  final ColorScheme colorScheme;
  final double fontSize;

  const _MarkdownStyleKey({
    required this.colorScheme,
    required this.fontSize,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _MarkdownStyleKey &&
          colorScheme == other.colorScheme &&
          fontSize == other.fontSize;

  @override
  int get hashCode => Object.hash(colorScheme, fontSize);
}
