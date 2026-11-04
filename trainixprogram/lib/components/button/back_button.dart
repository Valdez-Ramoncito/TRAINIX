import 'package:flutter/material.dart';

class TrainingBackButton extends StatefulWidget {
  TrainingBackButton({super.key, required this.onTap, this.expand = true});

  final VoidCallback? onTap;

  /// When true, fills the parent width (sidebars). When false, stays compact.
  final bool expand;

  @override
  State<TrainingBackButton> createState() => TrainingBackButtonState();
}

class TrainingBackButtonState extends State<TrainingBackButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: widget.expand ? double.infinity : null,
      padding: EdgeInsets.symmetric(
        horizontal: widget.expand ? 12 : 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: _isHovered
            ? const Color.fromARGB(255, 55, 62, 70)
            : const Color.fromARGB(255, 35, 39, 43),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isHovered
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.arrow_back_ios_rounded,
            size: 14,
            color: _isHovered ? Colors.white : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            'Back',
            style: TextStyle(
              color: _isHovered ? Colors.white : Colors.grey,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: widget.expand
            ? content
            : Align(alignment: Alignment.centerLeft, child: content),
      ),
    );
  }
}
