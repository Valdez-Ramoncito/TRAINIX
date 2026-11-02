import 'package:flutter/material.dart';
import 'package:trainixprogram/screens/menu_screen.dart';

class HoverIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const HoverIconButton({
    super.key,
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

class LogoutButton extends StatefulWidget {
  final VoidCallback? onTap;

  const LogoutButton({super.key, this.onTap});

  @override
  State<LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<LogoutButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          decoration: BoxDecoration(
            color: _isHovered ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white, width: 0.5),
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: _isHovered ? Colors.black : Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            child: const Text('Logout'),
          ),
        ),
      ),
    );
  }
}

class TrainingBackButton extends StatefulWidget {
  const TrainingBackButton();

  @override
  State<TrainingBackButton> createState() => TrainingBackButtonState();
}

class TrainingBackButtonState extends State<TrainingBackButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainMenuScreen()),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _isHovered
                ? const Color.fromARGB(255, 55, 62, 70)
                : const Color.fromARGB(255, 35, 39, 43),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _isHovered
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.transparent,
            ),
          ),
          child: Row(
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
        ),
      ),
    );
  }
}

class MenuButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isSelected;

  const MenuButton({
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
              const SizedBox(width: 8),
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
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: _isHovered
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: _isHovered
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.transparent,
              ),
            ),
            child: Icon(
              widget.icon,
              size: 20,
              color: _isHovered ? Colors.white : const Color(0xFFD1D5DB),
            ),
          ),
        ),
      ),
    );
  }
}
