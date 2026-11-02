import 'package:flutter/material.dart';

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
                ? const Color.fromARGB(
                    255,
                    213,
                    169,
                    249,
                  ).withValues(alpha: 0.18)
                : _isHovered
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: widget.isSelected
                ? Border.all(
                    color: const Color.fromARGB(
                      255,
                      213,
                      169,
                      249,
                    ).withValues(alpha: 0.5),
                    width: .5,
                  )
                : Border.all(color: Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: active
                    ? const Color.fromARGB(255, 242, 216, 248)
                    : Colors.grey,
              ),
              const SizedBox(width: 15),
              Text(
                widget.label,
                style: TextStyle(
                  color: active
                      ? const Color.fromARGB(255, 242, 216, 248)
                      : Colors.grey,
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
