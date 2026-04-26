import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';

import '../../../services/export_service.dart';
import '../reader_provider.dart';

enum _ExportFormat { png, pdf, docx }

class ExportBottomSheet extends ConsumerStatefulWidget {
  const ExportBottomSheet({super.key});

  @override
  ConsumerState<ExportBottomSheet> createState() => _ExportBottomSheetState();
}

class _ExportBottomSheetState extends ConsumerState<ExportBottomSheet> {
  _ExportFormat? _exporting;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top > 0 ? 0 : 8),
            // Share original
            _buildShareOption(context, colorScheme),
            const Divider(indent: 20, endIndent: 20),
            // Export section header
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '导出为',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),
            _buildOption(
              context: context,
              icon: Icons.image_outlined,
              title: '图片 (PNG)',
              subtitle: '渲染为图片文件',
              format: _ExportFormat.png,
              colorScheme: colorScheme,
            ),
            _buildOption(
              context: context,
              icon: Icons.picture_as_pdf_outlined,
              title: 'PDF 文档',
              subtitle: '导出为 PDF 格式',
              format: _ExportFormat.pdf,
              colorScheme: colorScheme,
            ),
            _buildOption(
              context: context,
              icon: Icons.description_outlined,
              title: 'Word 文档',
              subtitle: '导出为 DOCX 格式',
              format: _ExportFormat.docx,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(BuildContext context, ColorScheme colorScheme) {
    return ListTile(
      leading: Icon(Icons.share_outlined, color: colorScheme.primary),
      title: const Text('分享文件'),
      subtitle: Text(
        '分享原始 Markdown 文件',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.outline,
            ),
      ),
      onTap: () async {
        final file = ref.read(currentFileProvider).valueOrNull;
        if (file != null && file.path.isNotEmpty) {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
          await Share.shareXFiles([XFile(file.path)], text: file.name);
        }
      },
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required _ExportFormat format,
    required ColorScheme colorScheme,
  }) {
    final isExporting = _exporting == format;

    return ListTile(
      leading: isExporting
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            )
          : Icon(icon, color: colorScheme.primary),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.outline,
            ),
      ),
      enabled: _exporting == null,
      onTap: () => _export(format),
    );
  }

  Future<void> _export(_ExportFormat format) async {
    final file = ref.read(currentFileProvider).valueOrNull;
    if (file == null || file.content.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('文档为空，无法导出')),
        );
      }
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _exporting = format);

    try {
      final String path;
      final String fileName;

      switch (format) {
        case _ExportFormat.png:
          path = await ExportService.exportAsPng(file.content, context);
          fileName = '${_baseName(file.name)}.png';
        case _ExportFormat.pdf:
          path = await ExportService.exportAsPdf(file.content);
          fileName = '${_baseName(file.name)}.pdf';
        case _ExportFormat.docx:
          path = await ExportService.exportAsDocx(file.content);
          fileName = '${_baseName(file.name)}.docx';
      }

      if (mounted) {
        Navigator.pop(context);
        _showPostExportActions(path, fileName, format);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _exporting = null);
      }
    }
  }

  String _baseName(String fileName) {
    final dot = fileName.lastIndexOf('.');
    return dot > 0 ? fileName.substring(0, dot) : fileName;
  }

  void _showPostExportActions(String filePath, String fileName, _ExportFormat format) {
    HapticFeedback.lightImpact();
    final isImage = format == _ExportFormat.png;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).padding.bottom + 8),
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '导出成功',
                    style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.share_outlined, color: Theme.of(ctx).colorScheme.primary),
                title: const Text('分享'),
                subtitle: Text(
                  '通过系统分享发送文件',
                  style: TextStyle(fontSize: 12, color: Theme.of(ctx).colorScheme.outline),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Share.shareXFiles([XFile(filePath)], text: fileName);
                },
              ),
              if (isImage)
                ListTile(
                  leading: Icon(Icons.photo_library_outlined, color: Theme.of(ctx).colorScheme.primary),
                  title: const Text('保存到相册'),
                  subtitle: Text(
                    '直接存入系统相册',
                    style: TextStyle(fontSize: 12, color: Theme.of(ctx).colorScheme.outline),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _saveToGallery(filePath);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveToGallery(String filePath) async {
    try {
      HapticFeedback.mediumImpact();
      await Gal.putImage(filePath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已保存到相册'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存到相册失败: $e')),
        );
      }
    }
  }
}
