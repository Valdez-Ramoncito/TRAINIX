// ── Reusable icon toolbar button ─────────────────────────────────────────────
import 'package:flutter/material.dart';

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
    return Tooltip(
      message: widget.tooltip,
      preferBelow: false,
      verticalOffset: 28,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 35, 39, 43),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12),
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _isHovered
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isHovered
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.transparent,
              ),
            ),
            child: Icon(
              widget.icon,
              size: 24,
              color: _isHovered ? Colors.white : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
