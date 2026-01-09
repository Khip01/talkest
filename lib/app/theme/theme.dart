import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';
import 'text_styles.dart';

export 'colors.dart';
export 'text_styles.dart';

/// Light theme configuration
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: AppColors.lightColorScheme,
  fontFamily: GoogleFonts.inter().fontFamily,

  // Typography
  textTheme: TextTheme(
    displayLarge: AppTextStyles.displayLarge,
    displayMedium: AppTextStyles.displayMedium,
    displaySmall: AppTextStyles.displaySmall,
    headlineLarge: AppTextStyles.headlineLarge,
    headlineMedium: AppTextStyles.headlineMedium,
    headlineSmall: AppTextStyles.headlineSmall,
    titleLarge: AppTextStyles.titleLarge,
    titleMedium: AppTextStyles.titleMedium,
    titleSmall: AppTextStyles.titleSmall,
    bodyLarge: AppTextStyles.bodyLarge,
    bodyMedium: AppTextStyles.bodyMedium,
    bodySmall: AppTextStyles.bodySmall,
    labelLarge: AppTextStyles.labelLarge,
    labelMedium: AppTextStyles.labelMedium,
    labelSmall: AppTextStyles.labelSmall,
  ),

  // App Bar
  appBarTheme: AppBarTheme(
    centerTitle: false,
    elevation: 0,
    scrolledUnderElevation: 1,
    backgroundColor: AppColors.lightColorScheme.surface,
    foregroundColor: AppColors.lightColorScheme.onSurface,
    titleTextStyle: AppTextStyles.titleLarge.copyWith(
      color: AppColors.lightColorScheme.onSurface,
    ),
  ),

  // Card
  cardTheme: CardThemeData(
    elevation: 1,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    clipBehavior: Clip.antiAlias,
  ),

  // Input Decoration
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.lightColorScheme.surfaceContainerHighest.withOpacity(
      0.3,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.lightColorScheme.outline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.lightColorScheme.outline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: AppColors.lightColorScheme.primary,
        width: 2,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.lightColorScheme.error),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),

  // Elevated Button
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 1,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: AppTextStyles.labelLarge,
    ),
  ),

  // Filled Button
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: AppTextStyles.labelLarge,
    ),
  ),

  // Text Button
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: AppTextStyles.labelLarge,
    ),
  ),

  // Outlined Button
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(color: AppColors.lightColorScheme.outline),
      textStyle: AppTextStyles.labelLarge,
    ),
  ),

  // Floating Action Button
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),

  // Dialog
  dialogTheme: DialogThemeData(
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    titleTextStyle: AppTextStyles.headlineSmall.copyWith(
      color: AppColors.lightColorScheme.onSurface,
    ),
    contentTextStyle: AppTextStyles.bodyMedium.copyWith(
      color: AppColors.lightColorScheme.onSurfaceVariant,
    ),
  ),

  // Bottom Sheet
  bottomSheetTheme: const BottomSheetThemeData(
    elevation: 3,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    clipBehavior: Clip.antiAlias,
  ),

  // Chip
  chipTheme: ChipThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    labelStyle: AppTextStyles.labelSmall,
  ),

  // Divider
  dividerTheme: DividerThemeData(
    color: AppColors.lightColorScheme.outlineVariant,
    thickness: 1,
    space: 1,
  ),

  // Icon Button
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
);

/// Dark theme configuration
final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: AppColors.darkColorScheme,
  fontFamily: GoogleFonts.inter().fontFamily,

  // Typography
  textTheme: TextTheme(
    displayLarge: AppTextStyles.displayLarge,
    displayMedium: AppTextStyles.displayMedium,
    displaySmall: AppTextStyles.displaySmall,
    headlineLarge: AppTextStyles.headlineLarge,
    headlineMedium: AppTextStyles.headlineMedium,
    headlineSmall: AppTextStyles.headlineSmall,
    titleLarge: AppTextStyles.titleLarge,
    titleMedium: AppTextStyles.titleMedium,
    titleSmall: AppTextStyles.titleSmall,
    bodyLarge: AppTextStyles.bodyLarge,
    bodyMedium: AppTextStyles.bodyMedium,
    bodySmall: AppTextStyles.bodySmall,
    labelLarge: AppTextStyles.labelLarge,
    labelMedium: AppTextStyles.labelMedium,
    labelSmall: AppTextStyles.labelSmall,
  ),

  // App Bar
  appBarTheme: AppBarTheme(
    centerTitle: false,
    elevation: 0,
    scrolledUnderElevation: 1,
    backgroundColor: AppColors.darkColorScheme.surface,
    foregroundColor: AppColors.darkColorScheme.onSurface,
    titleTextStyle: AppTextStyles.titleLarge.copyWith(
      color: AppColors.darkColorScheme.onSurface,
    ),
  ),

  // Card
  cardTheme: CardThemeData(
    elevation: 1,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    clipBehavior: Clip.antiAlias,
  ),

  // Input Decoration
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.darkColorScheme.surfaceContainerHighest.withOpacity(
      0.3,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.darkColorScheme.outline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.darkColorScheme.outline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: AppColors.darkColorScheme.primary,
        width: 2,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.darkColorScheme.error),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),

  // Elevated Button
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 1,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: AppTextStyles.labelLarge,
    ),
  ),

  // Filled Button
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: AppTextStyles.labelLarge,
    ),
  ),

  // Text Button
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: AppTextStyles.labelLarge,
    ),
  ),

  // Outlined Button
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(color: AppColors.darkColorScheme.outline),
      textStyle: AppTextStyles.labelLarge,
    ),
  ),

  // Floating Action Button
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),

  // Dialog
  dialogTheme: DialogThemeData(
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    titleTextStyle: AppTextStyles.headlineSmall.copyWith(
      color: AppColors.darkColorScheme.onSurface,
    ),
    contentTextStyle: AppTextStyles.bodyMedium.copyWith(
      color: AppColors.darkColorScheme.onSurfaceVariant,
    ),
  ),

  // Bottom Sheet
  bottomSheetTheme: const BottomSheetThemeData(
    elevation: 3,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    clipBehavior: Clip.antiAlias,
  ),

  // Chip
  chipTheme: ChipThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    labelStyle: AppTextStyles.labelSmall,
  ),

  // Divider
  dividerTheme: DividerThemeData(
    color: AppColors.darkColorScheme.outlineVariant,
    thickness: 1,
    space: 1,
  ),

  // Icon Button
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
);
