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
}

class MDBlock {
  final String id;
  final MDBlockType type;
  final String content;

  const MDBlock({
    required this.id,
    required this.type,
    this.content = '',
  });

  MDBlock copyWith({
    String? id,
    MDBlockType? type,
    String? content,
  }) {
    return MDBlock(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MDBlock &&
          id == other.id &&
          type == other.type &&
          content == other.content;

  @override
  int get hashCode => Object.hash(id, type, content);
}
