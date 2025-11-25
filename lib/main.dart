import 'package:flutter/material.dart';
import 'colors.dart';
import 'constants/navigator_key.dart';
import 'pages/splash_screen.dart';
import 'services/api/base_api.dart';

void main() {
  // Initialize API service
  ApiService.init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'HolloDrive',
      debugShowCheckedModeBanner: false,
      // Light theme
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: AppColors.lightPrimary,
          secondary: AppColors.lightSecondary,
          surface: AppColors.lightSurface,
          error: AppColors.lightError,
          onPrimary: Colors.white, // On primary = white
          onSecondary: Colors.black, // On secondary = black
          onSurface: Colors.white, // On surface = white
          onError: Colors.white, // On error = white
        ),
      ),
      // Dark theme
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: AppColors.darkPrimary,
          secondary: AppColors.darkSecondary,
          surface: AppColors.darkSurface,
          error: AppColors.darkError,
          onPrimary: Colors.white, // On primary = white
          onSecondary: Colors.black, // On secondary = black
          onSurface: Colors.white, // On surface = white
          onError: Colors.white, // On error = white
        ),
      ),
      // Default to dark theme
      themeMode: ThemeMode.dark,
      // Start with splash screen
      home: const SplashScreen(),
    );
  }
}
