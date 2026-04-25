import '../config/theme/app_themes.dart';

class AppSettings {
  final AppThemeVariant themeVariant;
  final String fontFamily;
  final double fontSize;
  final bool useSystemDarkMode;

  const AppSettings({
    this.themeVariant = AppThemeVariant.light,
    this.fontFamily = '',
    this.fontSize = 16.0,
    this.useSystemDarkMode = true,
  });

  Map<String, dynamic> toJson() => {
        'themeVariant': themeVariant.name,
        'fontFamily': fontFamily,
        'fontSize': fontSize,
        'useSystemDarkMode': useSystemDarkMode,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeVariant: AppThemeVariant.values.firstWhere(
        (v) => v.name == json['themeVariant'],
        orElse: () => AppThemeVariant.light,
      ),
      fontFamily: json['fontFamily'] as String? ?? '',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 16.0,
      useSystemDarkMode: json['useSystemDarkMode'] as bool? ?? true,
    );
  }

  AppSettings copyWith({
    AppThemeVariant? themeVariant,
    String? fontFamily,
    double? fontSize,
    bool? useSystemDarkMode,
  }) {
    return AppSettings(
      themeVariant: themeVariant ?? this.themeVariant,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      useSystemDarkMode: useSystemDarkMode ?? this.useSystemDarkMode,
    );
  }
}
