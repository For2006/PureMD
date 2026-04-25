import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/md_block.dart';
import '../../core/utils/markdown_utils.dart';
import '../../services/file_service.dart';

class EditorState {
  final String filePath;
  final List<MDBlock> blocks;
  final String originalContent;
  final bool isPreviewVisible;
  final String? errorMessage;

  const EditorState({
    this.filePath = '',
    this.blocks = const [],
    this.originalContent = '',
    this.isPreviewVisible = false,
    this.errorMessage,
  });

  String get content => MarkdownUtils.serializeBlocks(blocks);
  bool get isModified => content != originalContent;

  EditorState copyWith({
    String? filePath,
    List<MDBlock>? blocks,
    String? originalContent,
    bool? isPreviewVisible,
    String? errorMessage,
    bool clearError = false,
  }) {
    return EditorState(
      filePath: filePath ?? this.filePath,
      blocks: blocks ?? this.blocks,
      originalContent: originalContent ?? this.originalContent,
      isPreviewVisible: isPreviewVisible ?? this.isPreviewVisible,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final editorProvider = StateNotifierProvider<EditorNotifier, EditorState>((ref) {
  return EditorNotifier();
});

class EditorNotifier extends StateNotifier<EditorState> {
  Timer? _autoSaveTimer;
  int _idCounter = 0;

  String _nextBlockId() => 'b${++_idCounter}';

  EditorNotifier() : super(const EditorState());

  Future<void> loadFile(String path) async {
    try {
      final content = await FileService.readFile(path);
      final blocks = MarkdownUtils.parseToBlocks(content);
      _idCounter = blocks.length;
      state = EditorState(
        filePath: path,
        blocks: blocks,
        originalContent: content,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: '无法加载文件: $e');
    }
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }

  void createNewFile() {
    _idCounter = 1;
    state = EditorState(
      blocks: [MDBlock(id: _nextBlockId(), type: MDBlockType.paragraph)],
      originalContent: '',
    );
  }

  void updateBlockContent(int index, String content) {
    if (index >= state.blocks.length) return;
    final newBlocks = [...state.blocks];
    newBlocks[index] = newBlocks[index].copyWith(content: content);
    state = state.copyWith(blocks: newBlocks);
    _scheduleAutoSave();
  }

  void insertBlock(int index, {MDBlockType type = MDBlockType.paragraph, String content = ''}) {
    final newBlock = MDBlock(id: _nextBlockId(), type: type, content: content);
    final newBlocks = [...state.blocks];
    newBlocks.insert(index, newBlock);
    state = state.copyWith(blocks: newBlocks);
  }

  void deleteBlock(int index) {
    if (state.blocks.length <= 1) {
      final newBlocks = [MDBlock(id: _nextBlockId(), type: MDBlockType.paragraph)];
      state = state.copyWith(blocks: newBlocks);
      return;
    }
    final newBlocks = [...state.blocks]..removeAt(index);
    state = state.copyWith(blocks: newBlocks);
  }

  void changeBlockType(int index, MDBlockType type) {
    if (index >= state.blocks.length) return;
    final newBlocks = [...state.blocks];
    newBlocks[index] = newBlocks[index].copyWith(type: type);
    state = state.copyWith(blocks: newBlocks);
  }

  void toggleTodoChecked(int index) {
    if (index >= state.blocks.length) return;
    final block = state.blocks[index];
    if (block.type != MDBlockType.todo) return;
    final newBlocks = [...state.blocks];
    newBlocks[index] = block.copyWith(isChecked: !block.isChecked);
    state = state.copyWith(blocks: newBlocks);
    _scheduleAutoSave();
  }

  void togglePreview() {
    state = state.copyWith(isPreviewVisible: !state.isPreviewVisible);
  }

  Future<bool> saveFile() async {
    if (state.filePath.isEmpty) return false;
    try {
      await FileService.writeFile(state.filePath, state.content);
      state = state.copyWith(originalContent: state.content);
      _autoSaveTimer?.cancel();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> saveNewFile(String filePath) async {
    try {
      await FileService.writeFile(filePath, state.content);
      state = state.copyWith(
        filePath: filePath,
        originalContent: state.content,
      );
      _autoSaveTimer?.cancel();
      return true;
    } catch (_) {
      return false;
    }
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 5), () {
      if (state.isModified && state.filePath.isNotEmpty) {
        saveFile();
      }
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}
