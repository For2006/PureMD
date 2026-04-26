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
  final int listNumber;

  const MDBlock({
    required this.id,
    required this.type,
    this.content = '',
    this.isChecked = false,
    this.language,
    this.listNumber = 1,
  });

  MDBlock copyWith({
    String? id,
    MDBlockType? type,
    String? content,
    bool? isChecked,
    String? language,
    int? listNumber,
  }) {
    return MDBlock(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      isChecked: isChecked ?? this.isChecked,
      language: language ?? this.language,
      listNumber: listNumber ?? this.listNumber,
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
          language == other.language &&
          listNumber == other.listNumber;

  @override
  int get hashCode => Object.hash(id, type, content, isChecked, language, listNumber);
}
