import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';

class CarouselButton extends StatefulWidget {
  const CarouselButton({super.key, required this.icon, required this.onTap});

  final Icon icon;
  final VoidCallback? onTap;

  @override
  State<CarouselButton> createState() => _CarouselButtonState();
}

class _CarouselButtonState extends State<CarouselButton> {
  bool isHovered = false;

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
        ? AppColors.scaffold(context).withValues(alpha: isHovered ? 0.35 : 0.12)
        : (isHovered ? cardHover : elevated.withValues(alpha: 0.92));

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fill,
          border: Border.all(
            color: isHovered ? borderStrong : border,
            width: isHovered ? 1.1 : 1.0,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isHovered ? 0.08 : 0.04),
                    blurRadius: isHovered ? 10 : 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: IconButton(
          onPressed: widget.onTap,
          icon: widget.icon,
          color: isHovered ? textPrimary : textMuted,
          style: IconButton.styleFrom(
            enabledMouseCursor: SystemMouseCursors.click,
          ),
        ),
      ),
    );
  }
}
