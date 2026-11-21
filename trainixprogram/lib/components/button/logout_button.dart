import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';
import 'package:trainixprogram/services/auth_service.dart';

class LogoutButton extends StatefulWidget {
  final VoidCallback? onTap;

  /// Use over photography or artwork that stays dark in both themes. Keeps
  /// the outline and label light in dark mode; light mode always uses the
  /// theme text color because its cover surfaces are pale.
  final bool onImage;

  const LogoutButton({super.key, this.onTap, this.onImage = false});

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onPhoto = widget.onImage && isDark;
    final textPrimary =
        onPhoto ? AppColors.onImage(context) : AppColors.textPrimary(context);
    final scaffold =
        onPhoto ? const Color(0xFF0A1220) : AppColors.scaffold(context);

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
            color: _isHovered ? textPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  onPhoto ? textPrimary.withValues(alpha: 0.55) : textPrimary,
              width: onPhoto ? 1 : 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.logout_rounded,
                size: 16,
                color: _isHovered ? scaffold : textPrimary,
              ),
              const SizedBox(width: 8),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: _isHovered ? scaffold : textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
