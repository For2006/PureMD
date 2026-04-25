import 'package:flutter/material.dart';

class EditorScaffold extends StatelessWidget {
  final Widget editor;
  final Widget preview;
  final Widget toolbar;
  final bool showPreview;
  final bool isLandscape;

  const EditorScaffold({
    super.key,
    required this.editor,
    required this.preview,
    required this.toolbar,
    required this.showPreview,
    required this.isLandscape,
  });

  @override
  Widget build(BuildContext context) {
    if (isLandscape) {
      return Row(
        children: [
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(child: editor),
                toolbar,
              ],
            ),
          ),
          VerticalDivider(
            width: 1,
            thickness: 0.5,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          Expanded(
            flex: 1,
            child: preview,
          ),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: showPreview ? preview : editor,
        ),
        if (!showPreview) toolbar,
      ],
    );
  }
}
