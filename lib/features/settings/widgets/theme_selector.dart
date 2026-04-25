import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_themes.dart';
import '../settings_provider.dart';

class ThemeSelector extends ConsumerWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final currentTheme = settings?.themeVariant ?? AppThemeVariant.light;
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: AppThemeVariant.values.map((variant) {
        final isSelected = variant == currentTheme;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            ref.read(settingsProvider.notifier).setTheme(variant);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            width: 88,
            height: 96,
            decoration: BoxDecoration(
              color: _getSurfaceColor(variant, colorScheme),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: isSelected ? 1.0 : 0.85,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getAccentColor(variant),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      variant.icon,
                      size: 16,
                      color: variant.isDark
                          ? Colors.white.withValues(alpha: 0.9)
                          : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  variant.displayName,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _getTextColor(variant),
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 10,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isSelected) ...[
                  const SizedBox(height: 4),
                  AnimatedOpacity(
                    opacity: isSelected ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.check_circle,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getSurfaceColor(AppThemeVariant variant, ColorScheme cs) {
    switch (variant) {
      case AppThemeVariant.light:
        return const Color(0xFFFAFAFA);
      case AppThemeVariant.sepia:
        return const Color(0xFFF5F0E8);
      case AppThemeVariant.dark:
        return const Color(0xFF1C1B1F);
      case AppThemeVariant.oled:
        return const Color(0xFF050505);
      case AppThemeVariant.warmBrown:
        return const Color(0xFF1A1612);
      case AppThemeVariant.coldGray:
        return const Color(0xFF1A1C1E);
    }
  }

  Color _getAccentColor(AppThemeVariant variant) {
    switch (variant) {
      case AppThemeVariant.light:
        return const Color(0xFF2D5A7B);
      case AppThemeVariant.sepia:
        return const Color(0xFF7A5A3A);
      case AppThemeVariant.dark:
        return const Color(0xFF8FC9E8);
      case AppThemeVariant.oled:
        return const Color(0xFF8FC9E8);
      case AppThemeVariant.warmBrown:
        return const Color(0xFFD4A574);
      case AppThemeVariant.coldGray:
        return const Color(0xFF90CAF9);
    }
  }

  Color _getTextColor(AppThemeVariant variant) {
    if (variant.isDark) {
      return Colors.white.withValues(alpha: 0.85);
    }
    return Colors.black.withValues(alpha: 0.75);
  }
}
