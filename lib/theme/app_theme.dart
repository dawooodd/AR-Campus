import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color primaryGreen = Color(0xFF699757);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF333333);
  static const Color textGray = Color(0xFF888888);
  static const Color buttonDisabled = Color(0xFFD3D3D3);

  // Text Styles
  static const TextStyle titleStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textDark,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textDark,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textDark,
  );

  static const TextStyle smallStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textGray,
  );

  // ThemeData
  static ThemeData get themeData {
    return ThemeData(
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundLight,
        elevation: 0,
        iconTheme: IconThemeData(color: textDark),
        titleTextStyle: titleStyle,
      ),
      textTheme: const TextTheme(
        displayLarge: titleStyle,
        titleLarge: subtitleStyle,
        bodyMedium: bodyStyle,
        bodySmall: smallStyle,
      ),
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: primaryGreen,
        surface: backgroundLight,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primaryGreen,
        unselectedItemColor: textGray,
        backgroundColor: backgroundLight,
      ),
    );
  }
}
