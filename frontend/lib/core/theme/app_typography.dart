import 'package:flutter/material.dart';

/// Typography configuration for LexIndia-AI.
/// Configured for high legibility during extended reading of legal provisions.
/// Fallback font list includes 'Noto Sans Telugu' for Telugu glyphs and
/// system Latin fonts ('Segoe UI', 'Roboto', 'sans-serif') without hardcoded external asset dependencies.
abstract class AppTypography {
  static const List<String> fontFallbacks = [
    'Noto Sans Telugu',
    'Segoe UI',
    'Roboto',
    'sans-serif',
  ];

  static TextTheme textTheme(Color textPrimary, Color textSecondary) {
    return TextTheme(
      // Large screen titles and primary legal headings
      displaySmall: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.25,
        color: textPrimary,
        fontFamilyFallback: fontFallbacks,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.3,
        color: textPrimary,
        fontFamilyFallback: fontFallbacks,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.35,
        color: textPrimary,
        fontFamilyFallback: fontFallbacks,
      ),

      // Section titles and card headers
      titleLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.4,
        color: textPrimary,
        fontFamilyFallback: fontFallbacks,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: textPrimary,
        fontFamilyFallback: fontFallbacks,
      ),
      titleSmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: textSecondary,
        fontFamilyFallback: fontFallbacks,
      ),

      // Primary reading body text — comfortable line height (1.6) for dense legal provisions
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
        letterSpacing: 0.1,
        color: textPrimary,
        fontFamilyFallback: fontFallbacks,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.55,
        letterSpacing: 0.1,
        color: textPrimary,
        fontFamilyFallback: fontFallbacks,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.2,
        color: textSecondary,
        fontFamilyFallback: fontFallbacks,
      ),

      // Controls, badges, tags, and button labels
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: textPrimary,
        fontFamilyFallback: fontFallbacks,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        color: textSecondary,
        fontFamilyFallback: fontFallbacks,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        color: textSecondary,
        fontFamilyFallback: fontFallbacks,
      ),
    );
  }
}
