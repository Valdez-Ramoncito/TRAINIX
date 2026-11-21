import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';

class HoverIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const HoverIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  State<HoverIconButton> createState() => HoverIconButtonState();
}

class HoverIconButtonState extends State<HoverIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = AppColors.textPrimary(context);
    final textMuted = AppColors.textMuted(context);
    final border = AppColors.border(context);
    final borderStrong = AppColors.borderStrong(context);
    final elevated = AppColors.elevated(context);
    final cardHover = AppColors.cardHover(context);

    final fill = isDark
        ? (textPrimary.withValues(alpha: _isHovered ? 0.18 : 0.06))
        : (_isHovered ? cardHover : elevated.withValues(alpha: 0.92));
    final borderColor = _isHovered ? borderStrong : border;
    // Light: always primary-dark icon so logout/help chrome stays visible.
    // Dark: muted idle, primary on hover.
    final iconColor = isDark
        ? (_isHovered ? textPrimary : textMuted)
        : textPrimary;

    return Tooltip(
      message: widget.tooltip,
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      textStyle: TextStyle(
        color: textPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: fill,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 1),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: _isHovered ? 0.08 : 0.04,
                        ),
                        blurRadius: _isHovered ? 10 : 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: AnimatedScale(
              scale: _isHovered ? 1.12 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Icon(
                widget.icon,
                size: 22,
                color: iconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
