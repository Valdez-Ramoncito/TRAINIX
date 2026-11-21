import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';

class AddButton extends StatefulWidget {
  const AddButton({super.key, required this.onTap});

  final VoidCallback? onTap;

  @override
  State<AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<AddButton> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final secondary = AppColors.secondary(context);
    final elevated = AppColors.elevated(context);
    final textPrimary = AppColors.textPrimary(context);
    final border = AppColors.border(context);

    return GestureDetector(
      onTap: widget.onTap,
      child: Tooltip(
        message: 'Add room',
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
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: AnimatedContainer(
            width: 40,
            duration: const Duration(milliseconds: 150),
            height: 40,
            decoration: BoxDecoration(
              color: secondary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isHovered ? secondary : Colors.transparent,
                  blurRadius: isHovered ? 10 : 0,
                  spreadRadius: isHovered ? 2 : 0,
                ),
              ],
            ),
            child: Icon(Icons.add, color: AppColors.onSecondary(context)),
          ),
        ),
      ),
    );
  }
}
