import 'package:flutter/material.dart';

class ProfileCameraButton extends StatefulWidget {
  final VoidCallback? onTap;

  const ProfileCameraButton({super.key, this.onTap});

  @override
  State<ProfileCameraButton> createState() => _ProfileCameraButtonState();
}

class _ProfileCameraButtonState extends State<ProfileCameraButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _isHovered ? 1.12 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              color: _isHovered
                  ? const Color.fromARGB(255, 98, 106, 245)
                  : const Color.fromARGB(100, 65, 65, 70),
              border: Border.all(
                color: _isHovered
                    ? const Color.fromARGB(255, 98, 106, 245)
                    : const Color.fromARGB(99, 137, 137, 145),
                width: .5,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.camera_alt_rounded,
                size: 14,
                color: _isHovered ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
