enum MDBlockType {
  paragraph,
  heading1,
  heading2,
  heading3,
  code,
  quote,
  bulletList,
  numberedList,
  todo,
  divider,
  table,
  image,
}

class MDBlock {
  final String id;
  final MDBlockType type;
  final String content;
  final bool isChecked;
  final String? language;

  const MDBlock({
    required this.id,
    required this.type,
    this.content = '',
    this.isChecked = false,
    this.language,
  });

  MDBlock copyWith({
    String? id,
    MDBlockType? type,
    String? content,
    bool? isChecked,
    String? language,
  }) {
    return MDBlock(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      isChecked: isChecked ?? this.isChecked,
      language: language ?? this.language,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MDBlock &&
          id == other.id &&
          type == other.type &&
          content == other.content &&
          isChecked == other.isChecked &&
          language == other.language;

  @override
  int get hashCode => Object.hash(id, type, content, isChecked, language);
}
