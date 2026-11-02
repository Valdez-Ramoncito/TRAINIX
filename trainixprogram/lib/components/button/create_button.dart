import 'package:flutter/material.dart';
import 'package:trainixprogram/components/size.dart';

class CreateButton extends StatefulWidget {
  final String text;
  final VoidCallback? onTap;
  const CreateButton({super.key, required this.text, required this.onTap});

  @override
  State<CreateButton> createState() => _CreateButtonState();
}

class _CreateButtonState extends State<CreateButton> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => isHovered = true),
        onExit: (_) => setState(() => isHovered = false),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 80),
          width: 70,
          height: 40,
          decoration: BoxDecoration(
            color: widget.text == "Exit"
                ? Colors.transparent
                : isHovered
                ? Color.fromARGB(255, 59, 53, 64)
                : Color.fromARGB(255, 38, 34, 41),
            borderRadius: .circular(10),
            border: .all(color: Color.fromARGB(109, 235, 218, 253)),
          ),
          child: Center(
            child: Text(
              widget.text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: context.responsiveFont(4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
