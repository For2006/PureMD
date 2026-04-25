import 'package:flutter/material.dart';

enum AppThemeVariant {
  light,
  sepia,
  dark,
  oled,
  warmBrown,
  coldGray;

  String get displayName {
    switch (this) {
      case AppThemeVariant.light:
        return '浅色';
      case AppThemeVariant.sepia:
        return '暖纸';
      case AppThemeVariant.dark:
        return '深色';
      case AppThemeVariant.oled:
        return '纯黑 OLED';
      case AppThemeVariant.warmBrown:
        return '暖棕';
      case AppThemeVariant.coldGray:
        return '冷灰';
    }
  }

  IconData get icon {
    switch (this) {
      case AppThemeVariant.light:
        return Icons.light_mode_outlined;
      case AppThemeVariant.sepia:
        return Icons.auto_stories_outlined;
      case AppThemeVariant.dark:
        return Icons.dark_mode_outlined;
      case AppThemeVariant.oled:
        return Icons.phone_android;
      case AppThemeVariant.warmBrown:
        return Icons.coffee_outlined;
      case AppThemeVariant.coldGray:
        return Icons.ac_unit;
    }
  }

  Brightness get brightness {
    switch (this) {
      case AppThemeVariant.light:
      case AppThemeVariant.sepia:
        return Brightness.light;
      case AppThemeVariant.dark:
      case AppThemeVariant.oled:
      case AppThemeVariant.warmBrown:
      case AppThemeVariant.coldGray:
        return Brightness.dark;
    }
  }

  bool get isDark => brightness == Brightness.dark;
}
