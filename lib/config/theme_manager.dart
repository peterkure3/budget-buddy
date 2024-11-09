import 'package:flutter/material.dart';

class ThemeManager {
  static const _themeDuration = Duration(milliseconds: 300);
  static const _themeCurve = Curves.easeInOut;

  static ThemeData getTheme(bool isDark, Color primaryColor) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: isDark ? Brightness.dark : Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
      ),
      listTileTheme: ListTileThemeData(
        tileColor: colorScheme.surface,
        iconColor: colorScheme.primary,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static AnimationController createThemeController(TickerProvider vsync) {
    return AnimationController(
      duration: _themeDuration,
      vsync: vsync,
    );
  }
}