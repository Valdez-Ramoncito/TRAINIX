import 'package:flutter/material.dart';

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
    return GestureDetector(
      onTap: widget.onTap,
      child: Tooltip(
        message: "Add room",
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
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: AnimatedContainer(
            width: 40,
            duration: Duration(milliseconds: 150),
            height: 40,
            decoration: BoxDecoration(
              color: Color(0xFF0D82FE),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isHovered
                      ? const Color(0xFF0D82FE)
                      : Colors.transparent,
                  blurRadius: isHovered ? 10 : 0,
                  spreadRadius: isHovered ? 2 : 0,
                ),
              ],
            ),
            child: Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}
