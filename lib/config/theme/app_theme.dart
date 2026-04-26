import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_themes.dart';
import 'color_schemes.dart';

class AppTheme {
  AppTheme._();

  static final Map<_ThemeCacheKey, ThemeData> _cache = {};

  // Cache Google Fonts TextTheme globally (fonts won't change at runtime)
  static TextTheme? _cachedLightTextTheme;
  static TextTheme? _cachedDarkTextTheme;

  static ThemeData buildTheme(
    AppThemeVariant variant, {
    String? fontFamily,
    double fontSize = 16.0,
  }) {
    final key = _ThemeCacheKey(
      variant,
      fontFamily ?? '',
      fontSize,
    );
    return _cache.putIfAbsent(key, () => _buildTheme(variant, fontFamily: fontFamily, fontSize: fontSize));
  }

  static ThemeData _buildTheme(
    AppThemeVariant variant, {
    String? fontFamily,
    double fontSize = 16.0,
  }) {
    final colorScheme = _getColorScheme(variant);
    final brightness = variant.brightness;
    final textTheme = _buildTextTheme(brightness, fontFamily: fontFamily, fontSize: fontSize);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surface.withValues(alpha: 0.95),
        foregroundColor: colorScheme.onSurface,
        centerTitle: true,
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface, size: 22),
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        color: colorScheme.surface,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        thickness: 0.5,
        space: 1,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        dragHandleColor: colorScheme.outlineVariant,
        dragHandleSize: const Size(32, 4),
        showDragHandle: true,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.primaryContainer,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withValues(alpha: 0.12),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _EditorialPageTransition(),
        },
      ),
    );
  }

  static ColorScheme _getColorScheme(AppThemeVariant variant) {
    switch (variant) {
      case AppThemeVariant.light:
        return ColorSchemes.light;
      case AppThemeVariant.sepia:
        return ColorSchemes.sepia;
      case AppThemeVariant.dark:
        return ColorSchemes.dark;
      case AppThemeVariant.oled:
        return ColorSchemes.oled;
      case AppThemeVariant.warmBrown:
        return ColorSchemes.warmBrown;
      case AppThemeVariant.coldGray:
        return ColorSchemes.coldGray;
    }
  }

  static TextTheme _buildTextTheme(
    Brightness brightness, {
    String? fontFamily,
    double fontSize = 16.0,
  }) {
    TextTheme base;
    try {
      if (brightness == Brightness.light) {
        _cachedLightTextTheme ??= GoogleFonts.notoSansScTextTheme();
        base = _cachedLightTextTheme!;
      } else {
        _cachedDarkTextTheme ??= GoogleFonts.notoSansScTextTheme(ThemeData.dark().textTheme);
        base = _cachedDarkTextTheme!;
      }
    } catch (_) {
      base = ThemeData(brightness: brightness).textTheme;
    }

    final scaledTextTheme = _scaleTextTheme(base, fontSize / 16.0);

    if (fontFamily != null && fontFamily.isNotEmpty) {
      try {
        return _applyFontFamily(scaledTextTheme, fontFamily);
      } catch (_) {
        return scaledTextTheme;
      }
    }
    return scaledTextTheme;
  }

  static TextTheme _scaleTextTheme(TextTheme base, double scale) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontSize: (base.displayLarge?.fontSize ?? 57) * scale),
      displayMedium: base.displayMedium?.copyWith(fontSize: (base.displayMedium?.fontSize ?? 45) * scale),
      displaySmall: base.displaySmall?.copyWith(fontSize: (base.displaySmall?.fontSize ?? 36) * scale),
      headlineLarge: base.headlineLarge?.copyWith(fontSize: (base.headlineLarge?.fontSize ?? 32) * scale, fontWeight: FontWeight.w600, letterSpacing: -0.5),
      headlineMedium: base.headlineMedium?.copyWith(fontSize: (base.headlineMedium?.fontSize ?? 28) * scale, fontWeight: FontWeight.w600, letterSpacing: -0.3),
      headlineSmall: base.headlineSmall?.copyWith(fontSize: (base.headlineSmall?.fontSize ?? 24) * scale, fontWeight: FontWeight.w600),
      titleLarge: base.titleLarge?.copyWith(fontSize: (base.titleLarge?.fontSize ?? 22) * scale, fontWeight: FontWeight.w600),
      titleMedium: base.titleMedium?.copyWith(fontSize: (base.titleMedium?.fontSize ?? 16) * scale, fontWeight: FontWeight.w600, letterSpacing: 0.15),
      titleSmall: base.titleSmall?.copyWith(fontSize: (base.titleSmall?.fontSize ?? 14) * scale, fontWeight: FontWeight.w600, letterSpacing: 0.1),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: (base.bodyLarge?.fontSize ?? 16) * scale, height: 1.75, letterSpacing: 0.2),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: (base.bodyMedium?.fontSize ?? 14) * scale, height: 1.6, letterSpacing: 0.15),
      bodySmall: base.bodySmall?.copyWith(fontSize: (base.bodySmall?.fontSize ?? 12) * scale, height: 1.5),
      labelLarge: base.labelLarge?.copyWith(fontSize: (base.labelLarge?.fontSize ?? 14) * scale, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      labelMedium: base.labelMedium?.copyWith(fontSize: (base.labelMedium?.fontSize ?? 12) * scale, letterSpacing: 0.4),
      labelSmall: base.labelSmall?.copyWith(fontSize: (base.labelSmall?.fontSize ?? 11) * scale, letterSpacing: 0.3),
    );
  }

  static TextTheme _applyFontFamily(TextTheme textTheme, String fontFamily) {
    try {
      return GoogleFonts.getTextTheme(fontFamily, textTheme);
    } catch (_) {
      return textTheme;
    }
  }
}

class _ThemeCacheKey {
  final AppThemeVariant variant;
  final String fontFamily;
  final double fontSize;

  const _ThemeCacheKey(this.variant, this.fontFamily, this.fontSize);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ThemeCacheKey &&
          variant == other.variant &&
          fontFamily == other.fontFamily &&
          fontSize == other.fontSize;

  @override
  int get hashCode => Object.hash(variant, fontFamily, fontSize);
}

class _EditorialPageTransition extends PageTransitionsBuilder {
  const _EditorialPageTransition();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curved),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
