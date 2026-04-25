import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/file_service.dart';

class EditorState {
  final String filePath;
  final String content;
  final String originalContent;
  final bool isPreviewVisible;
  final bool isModified;

  const EditorState({
    this.filePath = '',
    this.content = '',
    this.originalContent = '',
    this.isPreviewVisible = false,
    this.isModified = false,
  });

  EditorState copyWith({
    String? filePath,
    String? content,
    String? originalContent,
    bool? isPreviewVisible,
    bool? isModified,
  }) {
    return EditorState(
      filePath: filePath ?? this.filePath,
      content: content ?? this.content,
      originalContent: originalContent ?? this.originalContent,
      isPreviewVisible: isPreviewVisible ?? this.isPreviewVisible,
      isModified: isModified ?? this.isModified,
    );
  }
}

final editorProvider = StateNotifierProvider<EditorNotifier, EditorState>((ref) {
  return EditorNotifier();
});

class EditorNotifier extends StateNotifier<EditorState> {
  Timer? _autoSaveTimer;

  EditorNotifier() : super(const EditorState());

  Future<void> loadFile(String path) async {
    try {
      final content = await FileService.readFile(path);
      state = EditorState(
        filePath: path,
        content: content,
        originalContent: content,
      );
    } catch (_) {
      state = const EditorState();
    }
  }

  void createNewFile() {
    state = const EditorState(
      content: '',
      originalContent: '',
    );
  }

  void updateContent(String content) {
    final isModified = content != state.originalContent;
    state = state.copyWith(content: content, isModified: isModified);
    _scheduleAutoSave();
  }

  void togglePreview() {
    state = state.copyWith(isPreviewVisible: !state.isPreviewVisible);
  }

  Future<bool> saveFile() async {
    if (state.filePath.isEmpty) return false;
    try {
      await FileService.writeFile(state.filePath, state.content);
      state = state.copyWith(
        originalContent: state.content,
        isModified: false,
      );
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
        isModified: false,
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
