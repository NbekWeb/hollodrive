import 'package:flutter/material.dart';

class AppColors {
  // Dark theme colors
  static const Color darkPrimary = Color(0xFF1B1B1B);
  static const Color darkSecondary = Color(0xFFFED326); // Sariq
  static const Color darkSurface = Color(0xFF262626);
  static const Color darkError = Color(0xFFE52A00); // Qizil
  static const Color darkSuccess = Color(0xFF28A745); // Yashil
  static const Color darkGrey = Color(0xFF262626); // Dark grey for inputs
  static const Color grey50 = Color(0xFF555555); // Grey 50% for user icon

  // Light theme colors (hozircha dark ranglar bilan bir xil)
  static const Color lightPrimary = Color(0xFF1B1B1B);
  static const Color lightSecondary = Color(0xFFFED326); // Sariq
  static const Color lightSurface = Color(0xFF262626);
  static const Color lightError = Color(0xFFE52A00); // Qizil
  static const Color lightSuccess = Color(0xFF28A745); // Yashil
  static const Color lightGrey = Color(0xFF262626); // Dark grey for inputs
  static const Color lightGrey50 = Color(0xFF555555); // Grey 50% for user icon

  // Get colors based on brightness
  static Color getPrimaryColor(Brightness brightness) {
    return brightness == Brightness.dark ? darkPrimary : lightPrimary;
  }

  static Color getSecondaryColor(Brightness brightness) {
    return brightness == Brightness.dark ? darkSecondary : lightSecondary;
  }

  static Color getSurfaceColor(Brightness brightness) {
    return brightness == Brightness.dark ? darkSurface : lightSurface;
  }

  static Color getErrorColor(Brightness brightness) {
    return brightness == Brightness.dark ? darkError : lightError;
  }

  static Color getSuccessColor(Brightness brightness) {
    return brightness == Brightness.dark ? darkSuccess : lightSuccess;
  }

  static Color getGreyColor(Brightness brightness) {
    return brightness == Brightness.dark ? darkGrey : lightGrey;
  }

  static Color getGrey50Color(Brightness brightness) {
    return brightness == Brightness.dark ? grey50 : lightGrey50;
  }
}

