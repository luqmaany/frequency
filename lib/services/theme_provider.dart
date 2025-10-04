import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage_service.dart';

// Theme provider that manages dark mode state
class ThemeNotifier extends StateNotifier<bool> {
  ThemeNotifier() : super(true) {
    _loadThemePreference();
  }

  // Load theme preference from storage
  Future<void> _loadThemePreference() async {
    try {
      final preferences = await StorageService.loadAppPreferences();
      state = preferences['darkMode'] ?? true;
    } catch (e) {
      // Default to dark mode if there's an error
      state = true;
    }
  }

  // Toggle theme and save to storage
  Future<void> toggleTheme() async {
    state = !state;
    try {
      await StorageService.saveAppPreferences(darkMode: state);
    } catch (e) {
      // Revert if save fails
      state = !state;
    }
  }

  // Set theme directly and save to storage
  Future<void> setTheme(bool isDark) async {
    if (state != isDark) {
      state = isDark;
      try {
        await StorageService.saveAppPreferences(darkMode: state);
      } catch (e) {
        // Revert if save fails
        state = !isDark;
      }
    }
  }
}

// Provider for theme state
final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  return ThemeNotifier();
});

// Provider for light theme
final lightThemeProvider = Provider<ThemeData>((ref) {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color.fromARGB(255, 255, 255, 255), // Light purple
      brightness: Brightness.light,
    ),
    useMaterial3: true,
    // Customize light theme colors
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    // Card theme for consistent styling
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    // Global page transitions
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
        TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
        TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
      },
    ),
    // Text theme
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
      bodyLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        color: Colors.black,
      ),
    ),
  );
});

// Provider for dark theme
final darkThemeProvider = Provider<ThemeData>((ref) {
  const Color darkBg =
      Color.fromARGB(255, 11, 16, 32); // Match HomeScreen background
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color.fromARGB(255, 255, 255, 255), // Purple
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    // Customize dark theme colors - softer palette
    scaffoldBackgroundColor: darkBg,
    canvasColor: darkBg,
    dialogBackgroundColor: darkBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFFE0E0E0)), // Softer white
      titleTextStyle: TextStyle(
        color: Color(0xFFE0E0E0), // Softer white
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    // Global page transitions
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
        TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
        TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
      },
    ),
    // Card theme for consistent styling
    cardTheme: CardThemeData(
      color: const Color(0xFF3A3A3A), // Lighter card background
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    // Text theme with softer colors
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Color.fromARGB(255, 255, 255, 255), // Softer white
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Color.fromARGB(255, 255, 255, 255), // Softer white
      ),
      bodyLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color.fromARGB(255, 246, 246, 246), // Softer white
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        color: Color.fromARGB(255, 255, 255, 255), // Softer grey
      ),
    ),
  );
});

// Provider for current theme based on dark mode state
final currentThemeProvider = Provider<ThemeData>((ref) {
  final isDark = ref.watch(themeProvider);
  return isDark ? ref.watch(darkThemeProvider) : ref.watch(lightThemeProvider);
});
