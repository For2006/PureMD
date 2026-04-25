import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/recent_file_entry.dart';

class FileListTile extends StatelessWidget {
  final RecentFileEntry entry;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const FileListTile({
    super.key,
    required this.entry,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('MM/dd HH:mm');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.description_outlined,
                      color: colorScheme.primary.withValues(alpha: 0.8),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.displayName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 11,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateFormat.format(entry.lastOpenedAt),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colorScheme.outline,
                                  fontSize: 11,
                                ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              entry.contentPreview.replaceAll('\n', ' '),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.outline.withValues(alpha: 0.7),
                                    fontSize: 11,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 16,
                      color: colorScheme.outline.withValues(alpha: 0.5),
                    ),
                    onPressed: onDelete,
                    tooltip: '移除',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
