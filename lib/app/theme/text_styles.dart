import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography definitions without colors
/// Colors should be applied from ThemeData or ColorScheme at runtime
/// Uses Google Fonts Inter for optimal readability and modern aesthetic
class AppTextStyles {
  // ============================================================================
  // DISPLAY STYLES - Large, prominent text
  // ============================================================================
  static TextStyle get displayLarge => GoogleFonts.inter(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    height: 1.12,
  );

  static TextStyle get displayMedium => GoogleFonts.inter(
    fontSize: 45,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.16,
  );

  static TextStyle get displaySmall => GoogleFonts.inter(
    fontSize: 36,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.22,
  );

  // ============================================================================
  // HEADLINE STYLES - Section headers
  // ============================================================================
  static TextStyle get headlineLarge => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.25,
  );

  static TextStyle get headlineMedium => GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.29,
  );

  static TextStyle get headlineSmall => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.33,
  );

  // ============================================================================
  // TITLE STYLES - Medium emphasis headers
  // ============================================================================
  static TextStyle get titleLarge => GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.27,
  );

  static TextStyle get titleMedium => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.50,
  );

  static TextStyle get titleSmall => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
  );

  // ============================================================================
  // BODY STYLES - Main content text
  // ============================================================================
  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.50,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );

  // ============================================================================
  // LABEL STYLES - Buttons, tabs, labels
  // ============================================================================
  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
  );

  static TextStyle get labelMedium => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.33,
  );

  static TextStyle get labelSmall => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.45,
  );

  // ============================================================================
  // SPECIAL STYLES - Custom use cases
  // ============================================================================

  /// Quote or italic text style
  static TextStyle get quote => GoogleFonts.inter(
    fontSize: 14,
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );

  /// Link text style (use with primary color from theme)
  static TextStyle get link => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
    decoration: TextDecoration.underline,
  );

  /// Caption text for small metadata
  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );

  /// Overline text for labels above content
  static TextStyle get overline => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
    height: 1.6,
  );
}
