import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ==================== LIGHT THEME COLORS ====================
  static const primary = Color(0xFF5AB2FF); // Primary Blue
  static const primaryVariant = Color(0xFFFFD1DC); // Light Pink
  static const accent = Color(0xFFB5EAEA); // Pastel Blue
  static const background = Color(0xFFFFFFFF); // Pure White
  static const surface = Color(0xFFF8F9FA); // Very Light Grey
  static const surfaceVariant = Color(0xFFEDF2F7); // Light Grey
  static const surfaceLight = Color(0xFFFFFFFF);

  static const textPrimary = Color(0xFF2D3436); // Dark Charcoal
  static const textSecondary = Color(0xFF636E72); // Medium Grey
  static const textMuted = Color(0xFFB2BEC3); // Light Grey
  static const textWhite = Color(0xFFFFFFFF); // Pure White
  static const textBlack = Color(0xFF000000); // Pure Black

  // ==================== DARK THEME COLORS ====================
  static const darkBackground = Color(0xFF0D0D0D); // Deep Black
  static const darkSurface = Color(0xFF1A1A1A); // Dark Surface
  static const darkSurfaceVariant = Color(0xFF2D2D2D); // Slightly Lighter
  static const darkSurfaceLight = Color(0xFF333333);

  static const darkTextPrimary = Color(0xFFE8E8E8); // Light Text
  static const darkTextSecondary = Color(0xFFB0B0B0); // Medium Text
  static const darkTextMuted = Color(0xFF707070); // Muted Text

  static const darkShimmerBase = Color(0xFF2A2A2A);
  static const darkShimmerHighlight = Color(0xFF3D3D3D);

  // ==================== SHARED COLORS ====================
  static const error = Color(0xFFFF7675); // Pastel Red
  static const success = Color(0xFF55EFC4); // Pastel Green
  static const warning = Color(0xFFFFEAA7); // Pastel Yellow
  static const gold = Color(0xFFFFD700); // Pro Color

  // ==================== GRADIENTS ====================
  static const primaryGradient = LinearGradient(
    colors: [primary, primaryVariant],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const auroraGradient = LinearGradient(
    colors: [Color(0xFFB5EAEA), Color(0xFFC7CEEA)], // Pastel Blue to Purple
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const neonGradient = LinearGradient(
    colors: [Color(0xFFFFB7B2), Color(0xFFFFDAC1)], // Pastel Red to Orange
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const glassGradient = LinearGradient(
    colors: [Colors.white, Colors.white], // Flat
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const darkGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)], // Deep dark gradient
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const shimmerBase = Color(0xFFF0F0F0);
  static const shimmerHighlight = Color(0xFFFFFFFF);

  // ==================== LIGHT THEME ====================
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: surface,
        background: background,
        error: error,
      ),
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        headlineLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          color: textPrimary,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          color: textSecondary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: const CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: background,
        elevation: 0,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
    );
  }

  // ==================== DARK THEME ====================
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: darkSurface,
        background: darkBackground,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkTextPrimary,
        onBackground: darkTextPrimary,
      ),
      textTheme:
          GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        headlineLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
          letterSpacing: -0.5,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          color: darkTextPrimary,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          color: darkTextSecondary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: darkTextPrimary),
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: const CardThemeData(
        color: darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkBackground,
        elevation: 0,
        selectedItemColor: primary,
        unselectedItemColor: darkTextMuted,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: darkSurface,
        titleTextStyle: TextStyle(
            color: darkTextPrimary, fontSize: 20, fontWeight: FontWeight.bold),
        contentTextStyle: TextStyle(color: darkTextSecondary, fontSize: 14),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: darkSurfaceVariant,
        contentTextStyle: TextStyle(color: darkTextPrimary),
      ),
    );
  }

  // ==================== DECORATION HELPERS ====================
  static BoxDecoration pastelDecoration({
    Color? color,
    double borderRadius = 16,
    BoxBorder? border,
    bool isDark = false,
  }) {
    return BoxDecoration(
      color: color ?? (isDark ? darkSurface : surface),
      borderRadius: BorderRadius.circular(borderRadius),
      border: border ??
          Border.all(color: isDark ? darkSurfaceVariant : surfaceVariant),
    );
  }

  // Helper to get colors based on theme
  static Color getBackground(bool isDark) =>
      isDark ? darkBackground : background;
  static Color getSurface(bool isDark) => isDark ? darkSurface : surface;
  static Color getSurfaceVariant(bool isDark) =>
      isDark ? darkSurfaceVariant : surfaceVariant;
  static Color getTextPrimary(bool isDark) =>
      isDark ? darkTextPrimary : textPrimary;
  static Color getTextSecondary(bool isDark) =>
      isDark ? darkTextSecondary : textSecondary;
  static Color getTextMuted(bool isDark) => isDark ? darkTextMuted : textMuted;
  static Color getShimmerBase(bool isDark) =>
      isDark ? darkShimmerBase : shimmerBase;
  static Color getShimmerHighlight(bool isDark) =>
      isDark ? darkShimmerHighlight : shimmerHighlight;
}

class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 999;
}

class AppDurations {
  static const fast = Duration(milliseconds: 200);
  static const medium = Duration(milliseconds: 400);
  static const slow = Duration(milliseconds: 600);
}
