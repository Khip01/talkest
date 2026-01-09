import 'package:flutter/material.dart';

/// Central brand color definition
/// Change the primary brand color by modifying this value only
class AppColors {
  // ============================================================================
  // BRAND COLOR - Change here to update entire app theme
  // ============================================================================
  static const Color _brandPrimary = Color(0xFF1563A3); // Neutral Blue

  // ============================================================================
  // LIGHT MODE COLOR SCHEME
  // ============================================================================
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    // Primary brand colors
    primary: _brandPrimary,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD3E4F8),
    onPrimaryContainer: Color(0xFF001D35),

    // Secondary accent colors (derived from primary)
    secondary: Color(0xFF535F70),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFD7E3F7),
    onSecondaryContainer: Color(0xFF101C2B),

    // Tertiary colors
    tertiary: Color(0xFF6B5778),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFF2DAFF),
    onTertiaryContainer: Color(0xFF251431),

    // Error colors
    error: Color(0xFF9C2A2A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF9DEDC),
    onErrorContainer: Color(0xFF410E0B),

    // Surface colors
    surface: Color(0xFFFAFCFF),
    onSurface: Color(0xFF191C1E),
    surfaceContainerHighest: Color(0xFFE1E2E5),
    onSurfaceVariant: Color(0xFF42474E),

    // Outline and dividers
    outline: Color(0xFF72777F),
    outlineVariant: Color(0xFFC2C7CF),

    // Shadows and overlays
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF2E3133),
    onInverseSurface: Color(0xFFEFF1F4),
    inversePrimary: Color(0xFFA4C9FF),
  );

  // ============================================================================
  // DARK MODE COLOR SCHEME
  // ============================================================================
  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    // Primary brand colors
    primary: Color(0xFFA4C9FF),
    onPrimary: Color(0xFF003258),
    primaryContainer: Color(0xFF00497D),
    onPrimaryContainer: Color(0xFFD3E4F8),

    // Secondary accent colors
    secondary: Color(0xFFBBC7DB),
    onSecondary: Color(0xFF253140),
    secondaryContainer: Color(0xFF3B4858),
    onSecondaryContainer: Color(0xFFD7E3F7),

    // Tertiary colors
    tertiary: Color(0xFFD6BEE4),
    onTertiary: Color(0xFF3B2948),
    tertiaryContainer: Color(0xFF52405F),
    onTertiaryContainer: Color(0xFFF2DAFF),

    // Error colors
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),

    // Surface colors
    surface: Color(0xFF191C1E),
    onSurface: Color(0xFFE1E2E5),
    surfaceContainerHighest: Color(0xFF42474E),
    onSurfaceVariant: Color(0xFFC2C7CF),

    // Outline and dividers
    outline: Color(0xFF8C9199),
    outlineVariant: Color(0xFF42474E),

    // Shadows and overlays
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE1E2E5),
    onInverseSurface: Color(0xFF2E3133),
    inversePrimary: _brandPrimary,
  );

  // ============================================================================
  // SEMANTIC COLOR HELPERS
  // ============================================================================

  /// Get the appropriate color scheme based on brightness
  static ColorScheme getColorScheme(Brightness brightness) {
    return brightness == Brightness.light ? lightColorScheme : darkColorScheme;
  }
}
