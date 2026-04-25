import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

extension BuildContextExt on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  bool get isLandscape =>
      MediaQuery.of(this).orientation == Orientation.landscape;
}

extension AsyncValueExt<T> on AsyncValue<T> {
  Widget whenData(Widget Function(T data) builder) {
    return when(
      data: builder,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}
