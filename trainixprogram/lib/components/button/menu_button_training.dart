import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';

class MenuButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isSelected;

  MenuButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.isSelected = false,
  });

  @override
  State<MenuButton> createState() => MenuButtonState();
}

class MenuButtonState extends State<MenuButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isSelected || _isHovered;
    final primary = AppColors.primary(context);
    final textPrimary = AppColors.textPrimary(context);
    final textSecondary = AppColors.textSecondary(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? primary.withValues(alpha: 0.18)
                : _isHovered
                    ? textPrimary.withValues(alpha: 0.08)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: widget.isSelected
                ? Border.all(
                    color: primary.withValues(alpha: 0.5),
                    width: 0.5,
                  )
                : Border.all(color: Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: active ? primary : textSecondary,
              ),
              const SizedBox(width: 15),
              Text(
                widget.label,
                style: TextStyle(
                  color: active ? textPrimary : textSecondary,
                  fontSize: 13,
                  fontWeight: widget.isSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
