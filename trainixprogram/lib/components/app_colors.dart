import 'package:flutter/material.dart';
import 'package:trainixprogram/services/app_navigator.dart';

/// Semantic color API for TRAINIX.
/// Call sites use AppColors.*(context). Never hardcode product neutrals outside
/// the theme layer. Cool dark + cool soft light token maps.
class AppColors {
  AppColors._();

  static bool _isDark(BuildContext? context) {
    final ctx = context ?? AppNavigator.context;
    if (ctx == null) return true;
    return Theme.of(ctx).brightness == Brightness.dark;
  }

  static ColorScheme _scheme(BuildContext context) {
    return Theme.of(context).colorScheme;
  }

  static Color scaffold(BuildContext context) {
    if (_isDark(context)) return const Color(0xFF0B0F14);
    // Deeper cool base so white cards and tinted panels separate from it.
    return const Color(0xFFC6D5E6);
  }

  static Color surface(BuildContext context) {
    if (_isDark(context)) return const Color(0xFF12171F);
    return const Color(0xFFD9E5F1);
  }

  static Color card(BuildContext context) {
    if (_isDark(context)) return const Color(0xFF171D27);
    return const Color(0xFFFBFCFE);
  }

  static Color cardHover(BuildContext context) {
    if (_isDark(context)) return const Color(0xFF222A36);
    return const Color(0xFFE7EFF9);
  }

  static Color elevated(BuildContext context) {
    if (_isDark(context)) return const Color(0xFF1E2530);
    return const Color(0xFFFFFFFF);
  }

  static Color panel(BuildContext context) {
    if (_isDark(context)) return const Color(0xE6171D27);
    return const Color(0xFFF5F9FD);
  }

  static Color border(BuildContext context) {
    if (_isDark(context)) return const Color(0xFF2A3441);
    return const Color(0xFFA3B4C9);
  }

  static Color borderStrong(BuildContext context) {
    if (_isDark(context)) return const Color(0xFF3D4A5C);
    return const Color(0xFF5C7391);
  }

  static Color borderIdle(BuildContext context) {
    if (_isDark(context)) return const Color(0xFF2A3441);
    return const Color(0xFFB7C6D8);
  }

  static Color divider(BuildContext context) {
    if (_isDark(context)) return const Color(0xFF243040);
    return const Color(0xFFC8D5E4);
  }

  static Color textPrimary(BuildContext context) {
    if (_isDark(context)) return const Color(0xFFF1F5F9);
    return const Color(0xFF0A1220);
  }

  static Color textSecondary(BuildContext context) {
    if (_isDark(context)) return const Color(0xFF94A3B8);
    // Body support sits just under primary: hierarchy without losing contrast.
    return const Color(0xFF22314A);
  }

  static Color textMuted([BuildContext? context]) {
    if (_isDark(context)) return const Color(0xFF64748B);
    // Captions stay readable at 10-12px on cool light surfaces.
    return const Color(0xFF44576F);
  }

  static Color icon(BuildContext context) {
    return textPrimary(context);
  }

  static Color iconMuted(BuildContext context) {
    return textSecondary(context);
  }

  static Color primary(BuildContext context) {
    return _scheme(context).primary;
  }

  static Color onPrimary(BuildContext context) {
    return _scheme(context).onPrimary;
  }

  static Color secondary(BuildContext context) {
    return _scheme(context).secondary;
  }

  static Color onSecondary(BuildContext context) {
    return _scheme(context).onSecondary;
  }

  static Color success(BuildContext context) {
    return const Color(0xFF70BD8A);
  }

  static Color successStrong(BuildContext context) {
    return const Color(0xFF34D399);
  }

  static Color warning(BuildContext context) {
    return const Color(0xFFF59E0B);
  }

  static Color error(BuildContext context) {
    return _scheme(context).error;
  }

  static Color info(BuildContext context) {
    return const Color(0xFF3B82F6);
  }

  static Color overlay(BuildContext context) {
    if (_isDark(context))
      return const Color(0xFF0B0F14).withValues(alpha: 0.72);
    return const Color(0xFF07121F).withValues(alpha: 0.24);
  }

  static Color inputFill(BuildContext context) {
    if (_isDark(context)) return const Color(0xFF12171F);
    return const Color(0xFFE7EFF7);
  }

  static Color inputBorder(BuildContext context) {
    return border(context);
  }

  static Color inputFocus(BuildContext context) {
    return primary(context);
  }

  static Color chipBg(BuildContext context) {
    if (_isDark(context)) return const Color(0xFF1E2530);
    return const Color(0xFFD8E5F3);
  }

  static Color chipBorder(BuildContext context) {
    return border(context);
  }

  static Color completeTint(BuildContext context) {
    if (_isDark(context)) return const Color(0xFF152033);
    return const Color(0xFFD5E7FB);
  }

  static Color nextTint(BuildContext context) {
    if (_isDark(context)) return const Color(0xFF1A2E24);
    return const Color(0xFFD3F0E0);
  }

  static Color listBase(BuildContext context) {
    if (_isDark(context)) return const Color(0xFF171D27);
    return const Color(0xFFFFFFFF);
  }

  /// Brand accent wash for light cards, chips and active rows.
  static Color primaryWash(BuildContext context) {
    return primary(context).withValues(alpha: _isDark(context) ? 0.16 : 0.12);
  }

  static Color secondaryWash(BuildContext context) {
    return secondary(context).withValues(alpha: _isDark(context) ? 0.16 : 0.12);
  }

  /// Amber wash that reads on dark panels and on pale light cards.
  static Color warningWash(BuildContext context) {
    return brandWarning.withValues(alpha: _isDark(context) ? 0.5 : 0.14);
  }

  /// Brand green tuned for text and icons. Use instead of [brandPrimary]
  /// whenever green sits on a light surface.
  static Color primaryText([BuildContext? context]) {
    if (_isDark(context)) return brandPrimary;
    return const Color(0xFF1B7A4C);
  }

  /// Readable success text on tinted banners.
  static Color successText([BuildContext? context]) {
    if (_isDark(context)) return brandSuccessStrong;
    return const Color(0xFF116B45);
  }

  /// Readable error text on tinted banners.
  static Color errorText([BuildContext? context]) {
    if (_isDark(context)) return brandError;
    return const Color(0xFFB91C1C);
  }

  /// Amber tuned for text and icons on light surfaces.
  static Color warningText([BuildContext? context]) {
    if (_isDark(context)) return brandWarning;
    return const Color(0xFFB45309);
  }

  /// Blue tuned for text and icons on light surfaces.
  static Color secondaryText([BuildContext? context]) {
    if (_isDark(context)) return brandSecondary;
    return const Color(0xFF1D4ED8);
  }

  /// Strong red tuned for text and icons on light surfaces.
  static Color errorStrongText([BuildContext? context]) {
    if (_isDark(context)) return brandErrorStrong;
    return const Color(0xFF991B1B);
  }

  /// Light text over photography, artwork or brand artwork bands.
  static Color onImage(BuildContext context) {
    return const Color(0xFFF8FAFC);
  }

  static Color onImageMuted(BuildContext context) {
    return const Color(0xFFE2E8F0);
  }

  /// Soft top-down scrim so photos can carry light text in both themes.
  static List<Color> photoScrim(BuildContext context) {
    return const [
      Color(0xB3081320),
      Color(0x4D081320),
      Color(0x00081320),
    ];
  }

  /// Text shadow for headings sitting on light surfaces or photography.
  static List<Shadow> lightTextShadow(BuildContext context) {
    if (_isDark(context)) return const [];
    return const [
      Shadow(
        color: Color(0x33000000),
        blurRadius: 6,
        offset: Offset(0, 1),
      ),
    ];
  }

  /// Soft card elevation shadow. Invisible in dark mode.
  static Color shadow(BuildContext context) {
    if (_isDark(context)) return Colors.transparent;
    return const Color(0xFF0A1626).withValues(alpha: 0.12);
  }

  /// Stronger drop shadow for floating panels and dialogs in light mode.
  static Color shadowStrong(BuildContext context) {
    if (_isDark(context)) return Colors.transparent;
    return const Color(0xFF0A1626).withValues(alpha: 0.18);
  }

  /// Subtle amber tint behind hold and waiting states.
  static Color warningTint(BuildContext context) {
    if (_isDark(context)) return brandWarning.withValues(alpha: 0.20);
    return warningText(context).withValues(alpha: 0.10);
  }

  /// Selected type-pack card. Dark keeps its deep stage tint.
  static Color stageSelected(BuildContext context) {
    if (_isDark(context)) return const Color(0xFF141C18);
    return nextTint(context);
  }

  /// Ready-made card drop shadow. Empty in dark mode.
  static List<BoxShadow> cardShadow(
    BuildContext context, {
    double blur = 14,
    Offset offset = const Offset(0, 4),
  }) {
    if (_isDark(context)) return const [];
    return [
      BoxShadow(color: shadow(context), blurRadius: blur, offset: offset),
    ];
  }

  /// Light-mode atmosphere glows. Transparent in dark (the PNG carries it).
  static Color atmospherePrimary(BuildContext context) {
    if (_isDark(context)) return Colors.transparent;
    return brandPrimary.withValues(alpha: 0.16);
  }

  static Color atmosphereSecondary(BuildContext context) {
    if (_isDark(context)) return Colors.transparent;
    return brandSecondary.withValues(alpha: 0.14);
  }

  /// Frozen brand and status colors. Safe in const contexts.
  static const Color brandPrimary = Color(0xFF70BD8A);
  static const Color brandSecondary = Color(0xFF3B82F6);
  static const Color brandWarning = Color(0xFFF59E0B);
  static const Color brandError = Color(0xFFF87171);
  static const Color brandErrorStrong = Color(0xFFEF4444);
  static const Color brandSuccessStrong = Color(0xFF34D399);

  /// Darkens the known brand accents in light mode so text, icons and markers
  /// keep contrast on pale surfaces. Returns [color] untouched in dark mode.
  static Color readable(Color color, [BuildContext? context]) {
    if (_isDark(context)) return color;
    if (color == brandPrimary) return primaryText(context);
    if (color == brandSecondary) return secondaryText(context);
    if (color == brandWarning) return warningText(context);
    if (color == brandError) return errorText(context);
    if (color == brandErrorStrong) return errorStrongText(context);
    if (color == brandSuccessStrong) return successText(context);
    if (color == const Color(0xFF10B981)) return const Color(0xFF047857);
    return color;
  }

  /// Score level colors. Frozen for report meaning, darkened in light so
  /// score text and markers stay legible on pale cards.
  static Color levelExcellent(BuildContext context) =>
      _isDark(context) ? brandPrimary : const Color(0xFF1B7A4C);

  static Color levelGood(BuildContext context) =>
      _isDark(context) ? brandSecondary : const Color(0xFF1D4ED8);

  static Color levelDeveloping(BuildContext context) =>
      _isDark(context) ? brandWarning : const Color(0xFFB45309);

  static Color levelNeedsWork(BuildContext context) =>
      _isDark(context) ? brandErrorStrong : const Color(0xFF991B1B);

  static Color levelForScore(BuildContext context, double score) {
    if (score >= 8.5) return levelExcellent(context);
    if (score >= 7.0) return levelGood(context);
    if (score >= 5.0) return levelDeveloping(context);
    return levelNeedsWork(context);
  }
}
