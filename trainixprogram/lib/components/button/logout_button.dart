import 'package:flutter/material.dart';
import 'package:trainixprogram/services/auth_service.dart';

class LogoutButton extends StatefulWidget {
  final VoidCallback? onTap;

  const LogoutButton({super.key, this.onTap});

  @override
  State<LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<LogoutButton> {
  bool _isHovered = false;

  Future<void> _confirmThenRun() async {
    final action = widget.onTap;
    if (action == null) return;
    final confirmed = await AuthService.confirmSignOut(context);
    if (confirmed) action();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: _confirmThenRun,
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
