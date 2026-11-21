import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';

class NewSessionButton extends StatefulWidget {
  final ValueChanged<int>? onSelectChoice;

  const NewSessionButton({super.key, this.onSelectChoice});

  @override
  State<NewSessionButton> createState() => NewSessionButtonState();
}

class NewSessionButtonState extends State<NewSessionButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isOpen = false;
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.125,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  Widget _buildChoiceItem({
    required IconData icon,
    required String label,
    required Color color,
    required int index,
    required double delayFactor,
  }) {
    return _SessionChoiceItem(
      icon: icon,
      label: label,
      color: color,
      animation: _expandAnimation,
      delayFactor: delayFactor,
      onTap: () {
        _toggle();
        widget.onSelectChoice?.call(index);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final secondary = AppColors.secondary(context);
    final error = AppColors.error(context);
    final elevated = AppColors.elevated(context);
    final textPrimary = AppColors.textPrimary(context);
    final border = AppColors.border(context);
    final primary = AppColors.primary(context);

    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Tooltip(
            message: _isOpen ? 'Close' : 'New Session',
            preferBelow: false,
            verticalOffset: 28,
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: border),
            ),
            textStyle: TextStyle(
              color: textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: GestureDetector(
                onTap: _toggle,
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isOpen
                          ? error
                          : (_isHovered
                              ? secondary.withValues(alpha: 0.9)
                              : secondary),
                      boxShadow: [
                        BoxShadow(
                          color: (_isOpen ? error : secondary).withValues(
                            alpha: _isHovered || _isOpen ? 0.45 : 0.25,
                          ),
                          blurRadius: _isHovered || _isOpen ? 12 : 6,
                          spreadRadius: _isHovered || _isOpen ? 2 : 0,
                        ),
                      ],
                    ),
                    child: Center(
                      child: RotationTransition(
                        turns: _rotationAnimation,
                        child: Icon(
                          Icons.add_rounded,
                          color: AppColors.onSecondary(context),
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _expandAnimation,
            axisAlignment: -1.0,
            child: SizedBox(
              width: double.infinity,
              child: FadeTransition(
                opacity: _expandAnimation,
                child: Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildChoiceItem(
                        icon: Icons.call_rounded,
                        label: 'Voice',
                        color: secondary,
                        index: 0,
                        delayFactor: 0.1,
                      ),
                      const SizedBox(height: 6),
                      _buildChoiceItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Non-Voice',
                        color: primary,
                        index: 1,
                        delayFactor: 0.3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionChoiceItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Animation<double> animation;
  final double delayFactor;
  final VoidCallback onTap;

  const _SessionChoiceItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.animation,
    required this.delayFactor,
    required this.onTap,
  });

  @override
  State<_SessionChoiceItem> createState() => _SessionChoiceItemState();
}

class _SessionChoiceItemState extends State<_SessionChoiceItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final elevated = AppColors.elevated(context);
    final border = AppColors.border(context);
    final textPrimary = AppColors.textPrimary(context);
    final textSecondary = AppColors.textSecondary(context);

    return SizedBox(
      width: 42,
      child: Center(
        child: Tooltip(
          message: widget.label,
          preferBelow: false,
          verticalOffset: 24,
          decoration: BoxDecoration(
            color: elevated,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: border),
          ),
          textStyle: TextStyle(
            color: textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: GestureDetector(
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 36,
                height: 36,
                transform: Matrix4.identity()..scale(_isHovered ? 1.08 : 1.0),
                transformAlignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isHovered
                      ? widget.color.withValues(alpha: 0.12)
                      : elevated.withValues(alpha: 0.55),
                  border: Border.all(
                    color: _isHovered ? widget.color : border,
                    width: 0.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    widget.icon,
                    color: _isHovered ? widget.color : textSecondary,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
