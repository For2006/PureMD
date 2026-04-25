import 'package:flutter/material.dart';

import '../../../models/recent_file_entry.dart';
import 'file_list_tile.dart';

class RecentFileList extends StatelessWidget {
  final List<RecentFileEntry> files;
  final ValueChanged<RecentFileEntry> onFileTap;
  final ValueChanged<String>? onFileDelete;

  const RecentFileList({
    super.key,
    required this.files,
    required this.onFileTap,
    this.onFileDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.folder_open_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 12),
              Text(
                '暂无最近文件',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final entry = files[index];
        return FileListTile(
          entry: entry,
          onTap: () => onFileTap(entry),
          onDelete: () => onFileDelete?.call(entry.path),
        );
      },
    );
  }
}
