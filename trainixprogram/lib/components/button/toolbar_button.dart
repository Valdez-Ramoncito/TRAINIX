import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';

class ToolbarIcon extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const ToolbarIcon({required this.icon, required this.tooltip, this.onTap});

  @override
  State<ToolbarIcon> createState() => ToolbarIconState();
}

class ToolbarIconState extends State<ToolbarIcon> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final elevated = AppColors.elevated(context);
    final textPrimary = AppColors.textPrimary(context);
    final textMuted = AppColors.textMuted(context);
    final border = AppColors.border(context);

    return Tooltip(
      message: widget.tooltip,
      preferBelow: false,
      verticalOffset: 28,
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
        cursor: widget.onTap == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        onEnter: (_) {
          if (widget.onTap != null) setState(() => _isHovered = true);
        },
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _isHovered && widget.onTap != null
                  ? textPrimary.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isHovered && widget.onTap != null
                    ? textPrimary.withValues(alpha: 0.15)
                    : Colors.transparent,
              ),
            ),
            child: Icon(
              widget.icon,
              size: 24,
              color: widget.onTap == null
                  ? textMuted
                  : (_isHovered ? textPrimary : AppColors.textSecondary(context)),
            ),
          ),
        ),
      ),
    );
  }
}
