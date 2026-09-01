import 'package:flutter/material.dart';

class AppColors {
  // Figma Design System Tokens (Key: pi2pfoA51g6uOxY4xUuz6Q)
  static const Color primaryGreen = Color(0xFF273826);    // Dark green - headers, primary text
  static const Color accentGreen = Color(0xFF96B55F);     // Buttons, active states, badges
  static const Color softYellow = Color(0xFFF7FAC7);      // Card backgrounds, highlights, bottom nav
  static const Color lightPinkCream = Color(0xFFF6EFEF);  // Input backgrounds, soft surfaces
  static const Color neutralGray = Color(0xFFD9D9D9);     // Placeholders, borders, disabled
  static const Color white = Color(0xFFFFFFFF);           // Backgrounds
  static const Color black = Color(0xFF000000);           // Body text

  // Semantic mappings
  static const Color outlineGreen = accentGreen;
  static const Color backgroundWhite = white;
  static const Color cardBackground = softYellow;
  static const Color accentYellow = Color(0xFFFFC107);    // Gold/Star color
  static const Color textPrimary = primaryGreen;
  static const Color textSecondary = Color(0xFF555555);
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color borderCard = neutralGray;
}
