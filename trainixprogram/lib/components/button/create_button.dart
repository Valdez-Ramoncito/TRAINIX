import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';
import 'package:trainixprogram/components/size.dart';

class CreateButton extends StatefulWidget {
  final String text;
  final VoidCallback? onTap;
  final IconData? icon;

  const CreateButton({
    super.key,
    required this.text,
    required this.onTap,
    this.icon,
  });

  @override
  State<CreateButton> createState() => _CreateButtonState();
}

class _CreateButtonState extends State<CreateButton> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final icon = widget.icon;
    final elevated = AppColors.elevated(context);
    final cardHover = AppColors.cardHover(context);
    final border = AppColors.borderStrong(context);

    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => isHovered = true),
        onExit: (_) => setState(() => isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          height: 40,
          constraints: const BoxConstraints(minWidth: 70),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: widget.text == 'Exit'
                ? Colors.transparent
                : isHovered
                    ? cardHover
                    : elevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: isHovered
                      ? AppColors.textPrimary(context)
                      : AppColors.textSecondary(context),
                ),
                const SizedBox(width: 7),
              ],
              Text(
                widget.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: context.responsiveFont(4),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
