import 'package:flutter/material.dart';

class AppTheme {
  // Dark Slate ColorScheme (Obsidian, Electric Cobalt, Emerald Accent)
  static final ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: const Color(0xFF0284C7), // Electric Cobalt
    onPrimary: const Color(0xFFFFFFFF),
    primaryContainer: const Color(0xFF0369A1),
    onPrimaryContainer: const Color(0xFFE0F2FE),
    secondary: const Color(0xFF10B981), // Emerald
    onSecondary: const Color(0xFFFFFFFF),
    secondaryContainer: const Color(0xFF065F46),
    onSecondaryContainer: const Color(0xFFD1FAE5),
    tertiary: const Color(0xFF8B5CF6), // Purple / Analytics
    onTertiary: const Color(0xFFFFFFFF),
    tertiaryContainer: const Color(0xFF5B21B6),
    onTertiaryContainer: const Color(0xFFEDE9FE),
    error: const Color(0xFFEF4444),
    onError: const Color(0xFFFFFFFF),
    errorContainer: const Color(0xFF7F1D1D),
    onErrorContainer: const Color(0xFFFEE2E2),
    surface: const Color(0xFF0F172A), // Slate 900
    onSurface: const Color(0xFFF8FAFC), // Slate 50
    surfaceContainerLow: const Color(0xFF1E293B), // Slate 800
    surfaceContainer: const Color(0xFF1E293B), // Slate 800
    surfaceContainerHighest: const Color(0xFF334155), // Slate 700
    onSurfaceVariant: const Color(0xFF94A3B8), // Slate 400
    outline: const Color(0xFF475569), // Slate 600
    outlineVariant: const Color(0xFF334155),
  );

  // Executive Light ColorScheme (Clean Crisp White, Ice Blue Tint, Obsidian Text)
  static final ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: const Color(0xFF0369A1), // Deep Cobalt
    onPrimary: const Color(0xFFFFFFFF),
    primaryContainer: const Color(0xFFE0F2FE),
    onPrimaryContainer: const Color(0xFF0C4A6E),
    secondary: const Color(0xFF059669), // Deep Emerald
    onSecondary: const Color(0xFFFFFFFF),
    secondaryContainer: const Color(0xFFD1FAE5),
    onSecondaryContainer: const Color(0xFF064E3B),
    tertiary: const Color(0xFF7C3AED),
    onTertiary: const Color(0xFFFFFFFF),
    tertiaryContainer: const Color(0xFFEDE9FE),
    onTertiaryContainer: const Color(0xFF4C1D95),
    error: const Color(0xFFDC2626),
    onError: const Color(0xFFFFFFFF),
    errorContainer: const Color(0xFFFEE2E2),
    onErrorContainer: const Color(0xFF7F1D1D),
    surface: const Color(0xFFF8FAFC), // Slate 50
    onSurface: const Color(0xFF0F172A), // Slate 900
    surfaceContainerLow: const Color(0xFFF1F5F9), // Slate 100
    surfaceContainer: const Color(0xFFFFFFFF),
    surfaceContainerHighest: const Color(0xFFE2E8F0), // Slate 200
    onSurfaceVariant: const Color(0xFF64748B), // Slate 500
    outline: const Color(0xFFCBD5E1), // Slate 300
    outlineVariant: const Color(0xFFE2E8F0),
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: darkColorScheme,
      scaffoldBackgroundColor: darkColorScheme.surface,
      canvasColor: darkColorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: darkColorScheme.surface,
        foregroundColor: darkColorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: darkColorScheme.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: darkColorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: DividerThemeData(
        color: darkColorScheme.outlineVariant,
        thickness: 1,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: lightColorScheme,
      scaffoldBackgroundColor: lightColorScheme.surface,
      canvasColor: lightColorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: lightColorScheme.surface,
        foregroundColor: lightColorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: lightColorScheme.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: lightColorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: DividerThemeData(
        color: lightColorScheme.outlineVariant,
        thickness: 1,
      ),
    );
  }
}
