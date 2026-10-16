import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  // Colors mapped directly from Figma palette
  static const Color primaryGreen = AppColors.primaryGreen;
  static const Color accentGreen = AppColors.accentGreen;
  static const Color softYellow = AppColors.softYellow;
  static const Color lightPinkCream = AppColors.lightPinkCream;
  static const Color neutralGray = AppColors.neutralGray;
  static const Color backgroundLight = AppColors.white;
  static const Color textDark = AppColors.primaryGreen;
  static const Color textBody = AppColors.black;
  static const Color textGray = AppColors.neutralGray;
  static const Color buttonDisabled = AppColors.neutralGray;

  // Typography (Inter Font Family from Figma specification)
  static TextStyle heading1 = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600, // Semi Bold
    color: AppColors.primaryGreen,
  );

  static TextStyle heading2 = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600, // Semi Bold
    color: Colors.white,
  );

  static TextStyle body = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.normal, // Regular
    color: AppColors.black,
  );

  static TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.normal, // Regular
    color: AppColors.textSecondary,
  );

  static TextStyle navLabel = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.bold, // Bold
    color: AppColors.primaryGreen,
  );

  static TextStyle scoreBig = GoogleFonts.inter(
    fontSize: 48,
    fontWeight: FontWeight.bold, // Bold
    color: AppColors.primaryGreen,
  );

  // Backward compatibility aliases
  static TextStyle get titleStyle => heading1;
  static TextStyle get subtitleStyle => heading2.copyWith(color: textDark);
  static TextStyle get bodyStyle => body;
  static TextStyle get smallStyle => caption;

  // ThemeData configured for Campus Hunto
  static ThemeData get themeData {
    return ThemeData(
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: heading1.copyWith(color: Colors.white),
      ),
      textTheme: TextTheme(
        displayLarge: heading1,
        titleLarge: heading2,
        bodyMedium: body,
        bodySmall: caption,
      ),
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: primaryGreen,
        secondary: accentGreen,
        surface: backgroundLight,
      ),
    );
  }
}
