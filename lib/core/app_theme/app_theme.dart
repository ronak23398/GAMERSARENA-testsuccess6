import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary color palette
  static const Color _primaryColor = Color(0xFF5b70d7);
  static const Color _backgroundColor = Color(0xFFF0F4FF);
  static const Color _darkBackgroundColor = Color(0xFF1A1A2E);

  // Accent colors
  static const Color _successColor = Color(0xFF4CAF50);
  static const Color _errorColor = Color(0xFFFF5252);
  static const Color _warningColor = Color(0xFFFFC107);

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    primaryColor: _primaryColor,
    scaffoldBackgroundColor: _backgroundColor,

    // Modern, clean typography
    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      displayLarge: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        color: Colors.black87,
      ),
    ),

    // Neumorphic-inspired AppBar
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: _backgroundColor,
      foregroundColor: _primaryColor,
      iconTheme: const IconThemeData(color: _primaryColor),
      titleTextStyle: GoogleFonts.poppins(
        color: _primaryColor,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Neumorphic Button Styling
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 3,
        shadowColor: _primaryColor.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    // Soft Card Design
    cardTheme: CardTheme(
      elevation: 5,
      shadowColor: _primaryColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: Colors.white,
    ),

    // Color Scheme
    colorScheme: ColorScheme.light(
      primary: _primaryColor,
      secondary: _primaryColor.withOpacity(0.7),
      surface: Colors.white,
      error: _errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black87,
      onError: Colors.white,
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    primaryColor: _primaryColor,
    scaffoldBackgroundColor: _darkBackgroundColor,

    // Modern, clean typography
    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      displayLarge: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        color: Colors.white,
      ),
    ),

    // Neumorphic-inspired AppBar
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: _darkBackgroundColor,
      foregroundColor: _primaryColor,
      iconTheme: const IconThemeData(color: _primaryColor),
      titleTextStyle: GoogleFonts.poppins(
        color: _primaryColor,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Neumorphic Button Styling
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 3,
        shadowColor: _primaryColor.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    // Soft Card Design
    cardTheme: CardTheme(
      elevation: 5,
      shadowColor: _primaryColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: const Color.fromARGB(255, 39, 41, 61),
    ),

    // Color Scheme
    colorScheme: ColorScheme.dark(
      primary: _primaryColor,
      secondary: _primaryColor.withOpacity(0.7),
      surface: const Color.fromARGB(255, 39, 41, 61),
      error: _errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onError: Colors.white,
    ),
  );

  // Game-Specific Accent Colors
  static Color getChallengeAccentColor(String gameType) {
    switch (gameType.toLowerCase()) {
      case 'fortnite':
        return const Color(0xFF7E57C2); // Purple accent
      case 'valorant':
        return const Color(0xFFFF4655); // Valorant Red
      case 'pubg':
        return const Color(0xFF4CAF50); // Green accent
      default:
        return _primaryColor;
    }
  }

  // State-Based Colors
  static Color getStateColor(String state) {
    switch (state.toLowerCase()) {
      case 'success':
        return _successColor;
      case 'error':
        return _errorColor;
      case 'warning':
        return _warningColor;
      default:
        return _primaryColor;
    }
  }
}
