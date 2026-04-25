class MarkdownFile {
  final String path;
  final String name;
  final String content;
  final DateTime lastModified;

  const MarkdownFile({
    required this.path,
    required this.name,
    required this.content,
    required this.lastModified,
  });

  String get contentPreview {
    if (content.length <= 100) return content;
    return '${content.substring(0, 100)}...';
  }

  MarkdownFile copyWith({
    String? path,
    String? name,
    String? content,
    DateTime? lastModified,
  }) {
    return MarkdownFile(
      path: path ?? this.path,
      name: name ?? this.name,
      content: content ?? this.content,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}
