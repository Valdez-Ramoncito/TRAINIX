import 'package:flutter/material.dart';
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
    final currentLabelColor = _isFocused ? Colors.white : widget.labelColor;

    return TextFormField(
      controller: widget.controller,
      focusNode: _effectiveFocusNode,
      obscureText: widget.isPassword && _obscure,
      cursorColor: Colors.white,
      validator: widget.validator,
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
        prefixIconColor:
            _isFocused ? Colors.white : (widget.labelColor ?? Colors.grey),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 205, 205, 205),
            width: .5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 255, 255, 255),
            width: 1,
          ),
        ),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        suffixIcon: widget.isPassword
            ? IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                style: IconButton.styleFrom(
                  enabledMouseCursor: SystemMouseCursors.click,
                ),
              )
            : null,
      ),
    );
  }
}
