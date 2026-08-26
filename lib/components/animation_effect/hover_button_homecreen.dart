import 'package:flutter/material.dart';

class HoverIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const HoverIconButton({
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
    return Tooltip(
      message: widget.tooltip,
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
              color: _isHovered
                  ? Colors.white.withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: _isHovered
                    ? Colors.white.withOpacity(0.6)
                    : Colors.white.withOpacity(0.1),
                width: 1,
              ),
              // boxShadow: _isHovered
              //     ? [
              //         BoxShadow(
              //           color: Colors.white.withOpacity(0.25),
              //           blurRadius: 8,
              //           spreadRadius: 1,
              //         ),
              //       ]
              //     : [],
            ),
            child: AnimatedScale(
              scale: _isHovered ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Icon(
                widget.icon,
                size: 22,
                color: _isHovered
                    ? Colors.white
                    : Colors.white.withOpacity(0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
