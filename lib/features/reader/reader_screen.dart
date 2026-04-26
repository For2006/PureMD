import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/markdown_file.dart';
import '../editor/editor_provider.dart';
import '../settings/settings_provider.dart';
import 'reader_provider.dart';
import 'widgets/markdown_renderer.dart';
import 'widgets/export_bottom_sheet.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen>
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  late AnimationController _fabAnimController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimController,
      curve: Curves.easeOutBack,
    );
    _fabAnimController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fabAnimController.dispose();
    super.dispose();
  }

  void _handleTap(TapDownDetails details) {
    final isFocusMode = ref.read(isFocusModeProvider);
    if (!isFocusMode) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final dx = details.localPosition.dx;
    final dy = details.localPosition.dy;

    // Center tap toggles chrome
    if (dx > screenWidth * 0.25 &&
        dx < screenWidth * 0.75 &&
        dy > screenHeight * 0.25 &&
        dy < screenHeight * 0.75) {
      ref.read(isFocusModeProvider.notifier).state = false;
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileAsync = ref.watch(currentFileProvider);
    final isFocusMode = ref.watch(isFocusModeProvider);
    final fontSize = ref.watch(settingsProvider.select((s) => s.valueOrNull?.fontSize));
    final colorScheme = Theme.of(context).colorScheme;

    return fileAsync.when(
      loading: () => Scaffold(
        body: _buildLoadingState(colorScheme),
      ),
      error: (e, _) => Scaffold(
        body: _buildErrorState(context, e, colorScheme),
      ),
      data: (file) {
        if (file == null) {
          return Scaffold(
            body: _buildEmptyState(context, colorScheme),
          );
        }

        Widget body = _buildReaderBody(context, file, fontSize, isFocusMode, colorScheme);

        if (isFocusMode) {
          body = GestureDetector(
            onTapDown: _handleTap,
            child: body,
          );
        }

        return body;
      },
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '加载中...',
            style: TextStyle(
              color: colorScheme.outline,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object e, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: colorScheme.error,
                size: 28,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '无法加载文件',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '$e',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 32),
            FilledButton.tonal(
              onPressed: () => context.go('/files'),
              child: const Text('浏览文件'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.menu_book_outlined,
                color: colorScheme.primary.withValues(alpha: 0.7),
                size: 36,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              '打开一个 Markdown 文件',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '浏览文件或创建新笔记\n开启您的阅读之旅',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.outline,
                    height: 1.6,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton.tonal(
                  onPressed: () => context.go('/files'),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.folder_open_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('浏览文件'),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.tonal(
                  onPressed: () {
                    ref.read(editorProvider.notifier).createNewFile();
                    context.go('/editor');
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 18),
                      SizedBox(width: 8),
                      Text('新建笔记'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReaderBody(
    BuildContext context,
    MarkdownFile file,
    double? fontSize,
    bool isFocusMode,
    ColorScheme colorScheme,
  ) {
    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification) {
            ref.read(scrollPositionProvider.notifier).state =
                _scrollController.offset;
          }
          return false;
        },
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  AnimatedOpacity(
                    opacity: isFocusMode ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: IgnorePointer(
                      ignoring: isFocusMode,
                      child: _buildTopBar(context, file.name, colorScheme),
                    ),
                  ),
                  Expanded(
                    child: Scrollbar(
                      controller: _scrollController,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: isFocusMode ? 32 : 20,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                          child: MarkdownRenderer(
                            data: file.content,
                            fontSize: fontSize,
                          ),
                        ),
                      ),
                    ),
                  ),
                  AnimatedSlide(
                    offset: isFocusMode ? const Offset(0, 1) : Offset.zero,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: AnimatedOpacity(
                      opacity: isFocusMode ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: IgnorePointer(
                        ignoring: isFocusMode,
                        child: _buildProgressBar(colorScheme),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isFocusMode)
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  opacity: isFocusMode ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    ignoring: !isFocusMode,
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '点击任意位置退出专注模式',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: colorScheme.outline,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: isFocusMode
          ? null
          : FadeTransition(
              opacity: _fabAnimation,
              child: ScaleTransition(
                scale: _fabAnimation,
                child: FloatingActionButton(
                  heroTag: 'edit',
                  mini: true,
                  elevation: 2,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.read(editorProvider.notifier).loadFile(file.path);
                    context.go('/editor?path=${Uri.encodeComponent(file.path)}');
                  },
                  child: const Icon(Icons.edit_outlined, size: 20),
                ),
              ),
            ),
    );
  }

  Widget _buildTopBar(BuildContext context, String fileName, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/files'),
            icon: const Icon(Icons.folder_outlined),
            tooltip: '文件',
            iconSize: 22,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                fileName,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.read(isFocusModeProvider.notifier).state = true;
            },
            icon: const Icon(Icons.center_focus_strong_outlined),
            tooltip: '专注模式',
            iconSize: 22,
          ),
          IconButton(
            onPressed: () => context.go('/settings'),
            icon: const Icon(Icons.settings_outlined),
            tooltip: '设置',
            iconSize: 22,
          ),
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              showModalBottomSheet(
                context: context,
                showDragHandle: true,
                builder: (ctx) => const ExportBottomSheet(),
              );
            },
            icon: const Icon(Icons.ios_share_outlined),
            tooltip: '分享与导出',
            iconSize: 22,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(ColorScheme colorScheme) {
    return Container(
      height: 3,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double progress = 0.0;
          try {
            if (_scrollController.hasClients &&
                _scrollController.position.maxScrollExtent > 0) {
              final maxScroll = _scrollController.position.maxScrollExtent;
              progress = (_scrollController.offset / maxScroll).clamp(0.0, 1.0);
            }
          } catch (_) {}
          return FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.4),
                    colorScheme.primary,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
