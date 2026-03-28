import 'package:flutter/material.dart';
import 'package:exam_ace/core/theme/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light(AppColorPalette palette) => _build(Brightness.light, palette);

  static ThemeData dark(AppColorPalette palette) => _build(Brightness.dark, palette);

  static ThemeData _build(Brightness brightness, AppColorPalette palette) {
    var colorScheme = ColorScheme.fromSeed(
      seedColor: palette.seedColor,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );

    if (brightness == Brightness.light) {
      colorScheme = colorScheme.copyWith(
        surface: palette.lightSurface,
        surfaceContainerLowest: palette.lightSurface,
        surfaceContainerLow: palette.lightSurfaceContainerLow,
        surfaceContainer: palette.lightSurfaceContainerLow,
        surfaceContainerHigh: palette.lightSurfaceContainerHigh,
        surfaceContainerHighest: palette.lightSurfaceContainerHighest,
        tertiary: palette.completionTertiary,
        onTertiary: palette.onCompletionTertiary,
        tertiaryContainer: palette.completionTertiaryContainer,
        onTertiaryContainer: palette.onCompletionTertiaryContainer,
      );
    } else {
      colorScheme = colorScheme.copyWith(
        tertiary: palette.completionTertiaryDark,
        onTertiary: palette.onCompletionTertiaryDark,
        tertiaryContainer: palette.completionTertiaryContainerDark,
        onTertiaryContainer: palette.onCompletionTertiaryContainerDark,
      );
    }

    const radius = 12.0;
    final borderRadius = BorderRadius.circular(radius);
    final outlineBorder = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: colorScheme.outlineVariant),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? palette.lightSurface
          : colorScheme.surface,
      canvasColor: brightness == Brightness.light
          ? palette.lightSurface
          : colorScheme.surface,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: colorScheme.surfaceContainerLow,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.55)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: outlineBorder,
        enabledBorder: outlineBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      navigationBarTheme: NavigationBarThemeData(
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: colorScheme.secondaryContainer,
        height: 72,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    );
  }
}
