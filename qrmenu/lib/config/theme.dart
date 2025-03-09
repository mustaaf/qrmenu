import 'package:flutter/material.dart';

class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // App's main theme
  static ThemeData get darkTheme => ThemeData(
        fontFamily: 'ViaodaLibre',
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        cardTheme: const CardTheme(
          color:
              Color(0xFF121212), // Slightly lighter than pure black for cards
        ),
        colorScheme: const ColorScheme.dark(
          surface: Colors.black,
          primary: Colors.white,
          onPrimary: Colors.black,
          secondary: Colors.white70,
          onSecondary: Colors.black,
          onSurface: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
          titleSmall: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
      );

  // Text styles
  static const TextStyle cardTitleStyle = TextStyle(
    color: Colors.black,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle cardDescriptionStyle = TextStyle(
    color: Colors.black,
    fontSize: 14,
  );

  static const TextStyle cardPriceStyle = TextStyle(
    color: Colors.black,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  // Button styles
  static final ButtonStyle detailsButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.zero,
      side: BorderSide(color: Colors.white, width: 1.0),
    ),
  );

  // Social media icon styles
  static BoxDecoration socialIconDecoration = BoxDecoration(
    border: Border.all(color: Colors.white, width: 0.5),
    shape: BoxShape.circle,
  );
}
