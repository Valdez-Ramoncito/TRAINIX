import 'package:flutter/material.dart';
import 'package:trainixprogram/components/class/animations.dart';

BoxDecoration boxDecoration(bool isComplete, bool isNext) {
  const base = Color(0xFF151515);
  const completeBg = Color(0xFF152033);
  const nextBg = Color(0xFF141C18);
  const idleBorder = Color(0xFF2F2F2F);
  return BoxDecoration(
    color: isComplete
        ? completeBg
        : isNext
        ? nextBg
        : base,
    borderRadius: BorderRadius.circular(15),
    border: Border.all(
      color: isComplete
          ? const Color(0xFF3B82F6)
          : isNext
          ? const Color(0xFF70BD8A)
          : idleBorder,
      width: 1,
    ),
    boxShadow: isNext
        ? [
            BoxShadow(
              color: const Color(0xFF70BD8A).withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ]
        : null,
  );
}

class ListContainer extends StatelessWidget {
  const ListContainer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color.fromARGB(180, 21, 21, 21),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color.fromARGB(255, 49, 48, 48),
          width: 0.3,
        ),
      ),
      child: child,
    );
  }
}

class BoxHovering extends StatefulWidget {
  const BoxHovering({super.key, required this.child});

  final Widget child;
  @override
  State<BoxHovering> createState() => _BoxHoveringState();
}

class _BoxHoveringState extends State<BoxHovering> {
  bool isHover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHover = true),
      onExit: (_) => setState(() => isHover = false),

      child: AnimatedContainer(
        height: 100,
        duration: const Duration(milliseconds: 30),
        decoration: BoxDecoration(
          color: isHover
              ? const Color.fromARGB(255, 38, 34, 41)
              : const Color.fromARGB(180, 21, 21, 21),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isHover
                ? Color.fromARGB(109, 235, 218, 253)
                : const Color.fromARGB(255, 49, 48, 48),
            width: .3,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

class ContainerDecoration extends StatefulWidget {
  const ContainerDecoration({
    super.key,
    required this.data,
    required this.child,
    required this.isFocused,
    required this.onTap,
    this.isHighlighted = false,
    this.isGuideLocked = false,
  });

  final lottieAnimation data;
  final Widget child;
  final bool isFocused;
  final bool isHighlighted;
  final bool isGuideLocked;
  final VoidCallback? onTap;
  @override
  State<ContainerDecoration> createState() => _ContainerDecorationState();
}

class _ContainerDecorationState extends State<ContainerDecoration> {
  bool isHovered = false;
  @override
  Widget build(BuildContext context) {
    final highlight = widget.isHighlighted;
    final locked = widget.isGuideLocked;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: DecorationImage(
              image: AssetImage(widget.data.background),
              fit: BoxFit.cover,
              colorFilter: locked
                  ? ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.72),
                      BlendMode.darken,
                    )
                  : null,
            ),
            border: Border.all(
              color: highlight
                  ? const Color(0xFF70BD8A)
                  : locked
                  ? const Color(0xFF4B5563)
                  : const Color.fromARGB(255, 49, 48, 48),
              width: highlight ? 2.5 : 0.3,
            ),
            boxShadow: highlight
                ? [
                    BoxShadow(
                      color: const Color(0xFF70BD8A).withValues(alpha: 0.35),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              Opacity(opacity: locked ? 0.38 : 1, child: widget.child),
              if (highlight)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF70BD8A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'NEXT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
