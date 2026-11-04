import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData dark() {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        surface: Color(0xFF141414),
        onSurface: Colors.white,
        primary: Color(0xFF70BD8A),
        onPrimary: Colors.white,
        secondary: Color(0xFF3B82F6),
        onSecondary: Colors.white,
        error: Color(0xFFF87171),
      ),
      scaffoldBackgroundColor: const Color(0xFF0F0F0F),
      cardColor: const Color(0xFF1A1F26),
      dividerColor: const Color(0xFF2A2A2B),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF141414),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: Colors.white70,
        textColor: Colors.white,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF70BD8A);
          }
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF70BD8A).withValues(alpha: 0.35);
          }
          return Colors.white12;
        }),
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
        titleLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
        titleMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        titleSmall: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
        bodySmall: GoogleFonts.poppins(
          fontWeight: FontWeight.w400,
          color: Colors.white70,
        ),
      ),
    );
  }

  static ThemeData light() {
    final base = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF111827),
        primary: Color(0xFF15803D),
        onPrimary: Colors.white,
        secondary: Color(0xFF2563EB),
        onSecondary: Colors.white,
        error: Color(0xFFDC2626),
      ),
      scaffoldBackgroundColor: const Color(0xFFF3F4F6),
      cardColor: Colors.white,
      dividerColor: const Color(0xFFE5E7EB),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF111827),
        elevation: 0,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: Color(0xFF4B5563),
        textColor: Color(0xFF111827),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF15803D);
          }
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF15803D).withValues(alpha: 0.35);
          }
          return Colors.black12;
        }),
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
        titleLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.w800,
          color: const Color(0xFF111827),
        ),
        titleMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF111827),
        ),
        titleSmall: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF111827),
        ),
        bodyLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          color: const Color(0xFF111827),
        ),
        bodyMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.w400,
          color: const Color(0xFF1F2937),
        ),
        bodySmall: GoogleFonts.poppins(
          fontWeight: FontWeight.w400,
          color: const Color(0xFF6B7280),
        ),
      ),
    );
  }
}
