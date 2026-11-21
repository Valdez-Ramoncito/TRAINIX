import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';
import 'package:trainixprogram/components/class/animations.dart';

/// Theme-aware list/card decoration for complete / next / idle states.
/// Complete rows carry a blue edge accent, next rows a green one.
BoxDecoration themedBoxDecoration(
  BuildContext context, {
  required bool isComplete,
  required bool isNext,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final base = AppColors.listBase(context);
  final completeBg = AppColors.completeTint(context);
  final nextBg = AppColors.nextTint(context);
  final idleBorder = AppColors.borderIdle(context);
  final primary = AppColors.primary(context);
  final secondary = AppColors.secondary(context);
  final accent = isComplete ? secondary : primary;
  final fill = isComplete
      ? completeBg
      : isNext
          ? nextBg
          : base;

  // Flat fill plus a slim rail on the leading edge. A wide wash reads as a
  // smudge across tall rows, so the accent never spreads into the body.
  final rail = accent.withValues(alpha: isDark ? 0.9 : 0.85);
  return BoxDecoration(
    gradient: isComplete || isNext
        ? LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [rail, rail, fill, fill],
            stops: const [0, 0.004, 0.005, 1],
          )
        : null,
    color: isComplete || isNext ? null : base,
    borderRadius: BorderRadius.circular(15),
    border: Border.all(
      color: isComplete
          ? secondary
          : isNext
              ? primary
              : idleBorder,
      width: 1,
    ),
    boxShadow: isNext
        ? [
            BoxShadow(
              color: primary.withValues(alpha: isDark ? 0.12 : 0.22),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ]
        : isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.shadow(context),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
  );
}

class ListContainer extends StatelessWidget {
  const ListContainer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.panel(context),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDark
              ? AppColors.borderIdle(context)
              : AppColors.border(context),
          width: isDark ? 0.3 : 1.0,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.shadow(context),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: child,
    );
  }
}

class BoxHovering extends StatefulWidget {
  const BoxHovering({super.key, required this.child});

  final Widget child;
  @override
  State<BoxHovering> createState() => _BoxHoveringState();
}

class _BoxHoveringState extends State<BoxHovering> {
  bool isHover = false;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHover = true),
      onExit: (_) => setState(() => isHover = false),
      child: AnimatedContainer(
        height: 100,
        duration: const Duration(milliseconds: 30),
        decoration: BoxDecoration(
          color:
              isHover ? AppColors.cardHover(context) : AppColors.panel(context),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isHover
                ? AppColors.borderStrong(context)
                : AppColors.borderIdle(context),
            width: isHover ? 1.1 : 0.9,
          ),
          boxShadow: !isDark
              ? [
                  BoxShadow(
                    color: AppColors.shadow(context).withValues(
                      alpha: isHover ? 0.16 : 0.09,
                    ),
                    blurRadius: isHover ? 20.0 : 10.0,
                    offset: Offset(0, isHover ? 7.0 : 4.0),
                  ),
                ]
              : null,
        ),
        child: widget.child,
      ),
    );
  }
}

class ContainerDecoration extends StatefulWidget {
  const ContainerDecoration({
    super.key,
    required this.data,
    required this.child,
    required this.isFocused,
    required this.onTap,
    this.isHighlighted = false,
    this.isGuideLocked = false,
  });

  final lottieAnimation data;
  final Widget child;
  final bool isFocused;
  final bool isHighlighted;
  final bool isGuideLocked;
  final VoidCallback? onTap;
  @override
  State<ContainerDecoration> createState() => _ContainerDecorationState();
}

class _ContainerDecorationState extends State<ContainerDecoration> {
  bool isHovered = false;

  String _backgroundForTheme(BuildContext context) {
    final path = widget.data.background;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) return path;
    if (path.endsWith('.png')) {
      final lightPath = path.replaceAll('.png', '_light.png');
      return lightPath;
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final highlight = widget.isHighlighted;
    final locked = widget.isGuideLocked;
    final focused = widget.isFocused;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.primary(context);
    final borderIdle = AppColors.borderIdle(context);
    final borderStrong = AppColors.borderStrong(context);
    final muted = AppColors.textMuted(context);
    final hovered = isHovered || highlight;

    // Border color only. Width stays fixed for idle/hover so text does not shift.
    final borderColor = highlight
        ? primary
        : locked
            ? muted
            : hovered
                ? borderStrong
                : (focused && !isDark)
                    ? primary.withValues(alpha: 0.55)
                    : borderIdle;
    final borderWidth = highlight ? 2.5 : (isDark ? 0.3 : 1.0);

    final bgPath = _backgroundForTheme(context);

    // Shadow depends on page focus / guide highlight only, not mouse hover,
    // so PNG corner glow is never swapped for a flat fill on hover.
    final List<BoxShadow>? shadows = highlight
        ? [
            BoxShadow(
              color: primary.withValues(alpha: isDark ? 0.35 : 0.26),
              blurRadius: 20,
              spreadRadius: 1,
            ),
          ]
        : isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.shadow(context).withValues(
                    alpha: focused ? 0.18 : 0.09,
                  ),
                  blurRadius: focused ? 26.0 : 14.0,
                  offset: Offset(0, focused ? 10.0 : 6.0),
                ),
                if (focused)
                  BoxShadow(
                    color: primary.withValues(alpha: 0.10),
                    blurRadius: 30,
                    spreadRadius: 1,
                  ),
              ];

    // Image layer is fully static vs hover. Only locked / page-focus / theme
    // affect fill and colorFilter. Hover must not rebuild DecorationImage.
    final Color? lightBase = isDark
        ? null
        : (focused ? AppColors.card(context) : AppColors.surface(context));

    final imageDecoration = BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      color: lightBase,
      image: DecorationImage(
        image: AssetImage(bgPath),
        fit: BoxFit.cover,
        colorFilter: locked
            ? ColorFilter.mode(
                (isDark ? Colors.black : Colors.white)
                    .withValues(alpha: isDark ? 0.72 : 0.45),
                isDark ? BlendMode.darken : BlendMode.lighten,
              )
            : (!isDark && !focused)
                ? ColorFilter.mode(
                    AppColors.surface(context).withValues(alpha: 0.18),
                    BlendMode.srcATop,
                  )
                : null,
      ),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: shadows,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(decoration: imageDecoration),
                Opacity(opacity: locked ? 0.42 : 1, child: widget.child),
                if (highlight)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'NEXT',
                        style: TextStyle(
                          color: AppColors.onPrimary(context),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
