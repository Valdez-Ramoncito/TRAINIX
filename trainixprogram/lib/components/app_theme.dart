import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color _scaffold = Color(0xFF0B0F14);
  static const Color _surface = Color(0xFF12171F);
  static const Color _card = Color(0xFF171D27);
  static const Color _elevated = Color(0xFF1E2530);
  static const Color _divider = Color(0xFF243040);
  static const Color _primary = Color(0xFF70BD8A);
  static const Color _secondary = Color(0xFF3B82F6);
  static const Color _error = Color(0xFFF87171);
  static const Color _inputFill = Color(0xFF12171F);
  static const Color _border = Color(0xFF2A3441);
  static const Color _borderStrong = Color(0xFF3D4A5C);
  static const Color _textPrimary = Color(0xFFF1F5F9);
  static const Color _textSecondary = Color(0xFF94A3B8);
  static const Color _textMuted = Color(0xFF64748B);

  static ThemeData dark() {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        surface: _surface,
        onSurface: _textPrimary,
        primary: _primary,
        onPrimary: Colors.white,
        secondary: _secondary,
        onSecondary: Colors.white,
        error: _error,
        onError: Colors.white,
        outline: _border,
      ),
      scaffoldBackgroundColor: _scaffold,
      cardColor: _card,
      dividerColor: _divider,
      appBarTheme: const AppBarTheme(
        backgroundColor: _surface,
        foregroundColor: _textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: _textSecondary,
        textColor: _textPrimary,
      ),
      cardTheme: CardThemeData(
        color: _card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _border, width: 0.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _elevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          color: _textPrimary,
          fontSize: 18,
        ),
        contentTextStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w400,
          color: _textSecondary,
          fontSize: 14,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _error, width: 1.5),
        ),
        labelStyle: GoogleFonts.poppins(color: _textSecondary, fontSize: 14),
        hintStyle: GoogleFonts.poppins(
          color: _textMuted,
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _border,
          disabledForegroundColor: _textSecondary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _textPrimary,
          side: const BorderSide(color: _borderStrong),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primary,
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primary;
          }
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primary.withValues(alpha: 0.35);
          }
          return Colors.white12;
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: _divider,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _elevated,
        contentTextStyle: GoogleFonts.poppins(
          color: _textPrimary,
          fontSize: 14,
        ),
        actionTextColor: _primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: _elevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border),
        ),
        textStyle: GoogleFonts.poppins(
          color: _textPrimary,
          fontSize: 12,
        ),
        waitDuration: const Duration(milliseconds: 400),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: _elevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: _border, width: 0.5),
        ),
        textStyle: GoogleFonts.poppins(
          color: _textPrimary,
          fontSize: 14,
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _inputFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _border),
          ),
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(_elevated),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: _border, width: 0.5),
            ),
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _primary,
        linearTrackColor: _border,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: _borderStrong, width: 1.5),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primary;
          }
          return _textSecondary;
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _elevated,
        selectedColor: _primary.withValues(alpha: 0.25),
        disabledColor: _border,
        labelStyle: GoogleFonts.poppins(
          color: _textPrimary,
          fontSize: 12,
        ),
        secondaryLabelStyle: GoogleFonts.poppins(
          color: _textSecondary,
          fontSize: 12,
        ),
        side: const BorderSide(color: _border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
        titleLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.w800,
          color: _textPrimary,
        ),
        titleMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          color: _textPrimary,
        ),
        titleSmall: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: _textPrimary,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          color: _textPrimary,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.w400,
          color: _textPrimary,
        ),
        bodySmall: GoogleFonts.poppins(
          fontWeight: FontWeight.w400,
          color: _textSecondary,
        ),
        labelLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: _textPrimary,
        ),
        labelMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          color: _textSecondary,
        ),
        labelSmall: GoogleFonts.poppins(
          fontWeight: FontWeight.w400,
          color: _textMuted,
        ),
      ),
    );
  }

  static const Color _lightScaffold = Color(0xFFC6D5E6);
  static const Color _lightSurface = Color(0xFFD9E5F1);
  static const Color _lightCard = Color(0xFFFBFCFE);
  static const Color _lightElevated = Color(0xFFFFFFFF);
  static const Color _lightDivider = Color(0xFFC8D5E4);
  static const Color _lightBorder = Color(0xFFA3B4C9);
  static const Color _lightBorderStrong = Color(0xFF5C7391);
  static const Color _lightInputFill = Color(0xFFE7EFF7);
  static const Color _lightTextPrimary = Color(0xFF0A1220);
  static const Color _lightTextSecondary = Color(0xFF22314A);
  static const Color _lightTextMuted = Color(0xFF44576F);
  static const Color _lightError = Color(0xFFC81E1E);
  static const Color _lightPrimary = Color(0xFF1B7A4C);
  static const Color _lightSecondary = Color(0xFF1D4ED8);

  static ThemeData light() {
    final base = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        surface: _lightSurface,
        onSurface: _lightTextPrimary,
        primary: _lightPrimary,
        onPrimary: Colors.white,
        secondary: _lightSecondary,
        onSecondary: Colors.white,
        error: _lightError,
        onError: Colors.white,
        outline: _lightBorder,
      ),
      scaffoldBackgroundColor: _lightScaffold,
      cardColor: _lightCard,
      dividerColor: _lightDivider,
      appBarTheme: const AppBarTheme(
        backgroundColor: _lightSurface,
        foregroundColor: _lightTextPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: _lightTextSecondary,
        textColor: _lightTextPrimary,
      ),
      cardTheme: CardThemeData(
        color: _lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _lightBorder, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _lightElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          color: _lightTextPrimary,
          fontSize: 18,
        ),
        contentTextStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w400,
          color: _lightTextSecondary,
          fontSize: 14,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightInputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _lightPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _lightError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _lightError, width: 1.5),
        ),
        labelStyle: GoogleFonts.poppins(
          color: _lightTextSecondary,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.poppins(
          color: _lightTextMuted,
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _lightInputFill,
          disabledForegroundColor: _lightBorderStrong,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _lightTextPrimary,
          side: const BorderSide(color: _lightBorderStrong),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _lightPrimary,
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _lightPrimary;
          }
          return _lightBorderStrong;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _lightPrimary.withValues(alpha: 0.35);
          }
          return Colors.black12;
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: _lightDivider,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _lightElevated,
        contentTextStyle: GoogleFonts.poppins(
          color: _lightTextPrimary,
          fontSize: 14,
        ),
        actionTextColor: _lightPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: _lightBorder),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: _lightElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _lightBorderStrong),
        ),
        textStyle: GoogleFonts.poppins(
          color: _lightTextPrimary,
          fontSize: 12,
        ),
        waitDuration: const Duration(milliseconds: 400),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: _lightElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: _lightBorder, width: 0.5),
        ),
        textStyle: GoogleFonts.poppins(
          color: _lightTextPrimary,
          fontSize: 14,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _lightPrimary,
        linearTrackColor: _lightBorder,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _lightPrimary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: _lightBorderStrong, width: 1.5),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _lightPrimary;
          }
          return _lightTextMuted;
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _lightInputFill,
        selectedColor: _lightPrimary.withValues(alpha: 0.2),
        disabledColor: _lightBorder,
        labelStyle: GoogleFonts.poppins(
          color: _lightTextPrimary,
          fontSize: 12,
        ),
        side: const BorderSide(color: _lightBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
        titleLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.w800,
          color: _lightTextPrimary,
        ),
        titleMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          color: _lightTextPrimary,
        ),
        titleSmall: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: _lightTextPrimary,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          color: _lightTextPrimary,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.w400,
          color: _lightTextPrimary,
        ),
        bodySmall: GoogleFonts.poppins(
          fontWeight: FontWeight.w400,
          color: _lightTextSecondary,
        ),
        labelLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: _lightTextPrimary,
        ),
        labelMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          color: _lightTextSecondary,
        ),
        labelSmall: GoogleFonts.poppins(
          fontWeight: FontWeight.w400,
          color: _lightTextMuted,
        ),
      ),
    );
  }
}
