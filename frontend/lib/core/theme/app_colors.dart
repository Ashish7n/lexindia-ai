import 'package:flutter/material.dart';

/// Centralized color palette for LexIndia-AI.
/// Adheres strictly to the professional legal visual identity:
/// - Legal Navy: #14253F
/// - Ivory: #F8F5EE
/// - Antique Gold: #B58B3B
/// - White: #FFFFFF
/// - Body Text: #354153
abstract class AppColors {
  // Core Brand Colors
  static const Color legalNavy = Color(0xFF14253F);
  static const Color ivory = Color(0xFFF8F5EE);
  static const Color antiqueGold = Color(0xFFB58B3B);
  static const Color antiqueGoldLight = Color(0xFFD4AF37);
  static const Color white = Color(0xFFFFFFFF);
  static const Color bodyText = Color(0xFF354153);

  // Light Mode Surfaces & Text
  static const Color lightBackground = ivory;
  static const Color lightSurface = white;
  static const Color lightSurfaceVariant = Color(0xFFF1EDE4);
  static const Color lightTextPrimary = bodyText;
  static const Color lightTextSecondary = Color(0xFF5A687C);
  static const Color lightTextMuted = Color(0xFF7E8B9B);
  static const Color lightBorder = Color(0xFFE2DDD2);
  static const Color lightDivider = Color(0xFFE8E4DA);

  // Dark Mode Surfaces & Text
  static const Color darkBackground = Color(0xFF0C1726);
  static const Color darkSurface = Color(0xFF14253F);
  static const Color darkSurfaceVariant = Color(0xFF1B3152);
  static const Color darkTextPrimary = Color(0xFFE5EDF6);
  static const Color darkTextSecondary = Color(0xFFA5B5C8);
  static const Color darkTextMuted = Color(0xFF718295);
  static const Color darkBorder = Color(0xFF263D5C);
  static const Color darkDivider = Color(0xFF1E3350);

  // Functional & Semantic States
  static const Color statusSuccess = Color(0xFF15803D);
  static const Color statusWarning = Color(0xFFB45309);
  static const Color statusError = Color(0xFFB91C1C);
  static const Color statusInfo = Color(0xFF1D4ED8);
}
