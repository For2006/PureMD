class RecentFileEntry {
  final String path;
  final String displayName;
  final DateTime lastOpenedAt;
  final String contentPreview;

  const RecentFileEntry({
    required this.path,
    required this.displayName,
    required this.lastOpenedAt,
    required this.contentPreview,
  });

  Map<String, dynamic> toJson() => {
        'path': path,
        'displayName': displayName,
        'lastOpenedAt': lastOpenedAt.toIso8601String(),
        'contentPreview': contentPreview,
      };

  factory RecentFileEntry.fromJson(Map<String, dynamic> json) {
    return RecentFileEntry(
      path: json['path'] as String,
      displayName: json['displayName'] as String,
      lastOpenedAt: DateTime.parse(json['lastOpenedAt'] as String),
      contentPreview: json['contentPreview'] as String? ?? '',
    );
  }

  RecentFileEntry copyWith({
    String? path,
    String? displayName,
    DateTime? lastOpenedAt,
    String? contentPreview,
  }) {
    return RecentFileEntry(
      path: path ?? this.path,
      displayName: displayName ?? this.displayName,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      contentPreview: contentPreview ?? this.contentPreview,
    );
  }
}
