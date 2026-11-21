import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';
import 'package:trainixprogram/components/size.dart';

class AppTextField extends StatefulWidget {
  final String label;
  final bool isPassword;
  final bool isDense;
  final Widget? prefixIcon;
  final Color? labelColor;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;

  const AppTextField({
    super.key,
    required this.label,
    this.isPassword = false,
    this.isDense = false,
    this.prefixIcon,
    this.labelColor,
    this.controller,
    this.focusNode,
    this.validator,
    this.onSubmitted,
    this.textInputAction,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscure = true;
  late FocusNode _internalFocusNode;
  bool _isFocused = false;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = FocusNode();
    _effectiveFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _effectiveFocusNode.hasFocus;
      });
    }
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      (oldWidget.focusNode ?? _internalFocusNode).removeListener(
        _onFocusChange,
      );
      _effectiveFocusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_onFocusChange);
    _internalFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimary(context);
    final textSecondary = AppColors.textSecondary(context);
    final textMuted = AppColors.textMuted(context);
    final border = AppColors.border(context);
    final focus = AppColors.inputFocus(context);

    final currentLabelColor = _isFocused
        ? textPrimary
        : (widget.labelColor ?? textSecondary);

    return TextFormField(
      controller: widget.controller,
      focusNode: _effectiveFocusNode,
      obscureText: widget.isPassword && _obscure,
      cursorColor: textPrimary,
      validator: widget.validator,
      textInputAction: widget.textInputAction ??
          (widget.isPassword ? TextInputAction.done : TextInputAction.next),
      onFieldSubmitted: widget.onSubmitted,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(fontSize: context.responsiveFont(4.5)),
      decoration: InputDecoration(
        label: Text(
          widget.label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: context.responsiveFont(4),
            color: currentLabelColor,
          ),
        ),
        prefixIcon: widget.prefixIcon,
        prefixIconColor: _isFocused
            ? textPrimary
            : (widget.labelColor ?? textMuted),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: border,
            width: 0.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: focus,
            width: 1.5,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        suffixIcon: widget.isPassword
            ? IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                color: textSecondary,
                style: IconButton.styleFrom(
                  enabledMouseCursor: SystemMouseCursors.click,
                ),
              )
            : null,
      ),
    );
  }
}
