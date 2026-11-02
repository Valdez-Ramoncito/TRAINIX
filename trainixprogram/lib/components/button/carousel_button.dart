import 'package:flutter/material.dart';

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
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 30),
        decoration: BoxDecoration(
          shape: .circle,
          color: Color.fromARGB(255, 21, 21, 21).withValues(alpha: 0.08),
          border: .all(
            color: isHovered
                ? Color.fromARGB(255, 246, 244, 244)
                : Color.fromARGB(255, 155, 150, 150),
          ),
        ),
        child: IconButton(
          onPressed: widget.onTap,
          icon: widget.icon,
          color: isHovered
              ? Color.fromARGB(255, 255, 255, 255)
              : Color.fromARGB(255, 155, 150, 150),
          style: IconButton.styleFrom(
            enabledMouseCursor: SystemMouseCursors.click,
          ),
        ),
      ),
    );
  }
}
