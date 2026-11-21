import 'package:flutter/material.dart';

/// Caps wide-screen content so panels keep a comfortable width on large
/// monitors instead of stretching edge to edge.
class ContentBounds extends StatelessWidget {
  const ContentBounds({
    super.key,
    required this.child,
    this.maxWidth = 1100,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
