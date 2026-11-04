import 'package:flutter/material.dart';

extension SizeHelper on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;

  double get screenHeight => MediaQuery.of(this).size.height;

  // Desktop-first: mild scale only. Large monitors must not inflate layout.
  double get _scaleWidth => screenWidth.clamp(1024.0, 1440.0);

  double get _scaleHeight => screenHeight.clamp(700.0, 1000.0);

  // App design units are small (title ~7, body ~4). Map to readable desktop px,
  // then apply a tight width scale so fonts stay stable across laptop/desktop.
  double responsiveFont(double fontSize) {
    final mapped = fontSize * 3.5;
    final scale = (_scaleWidth / 1280.0).clamp(0.92, 1.08);
    return mapped * scale;
  }

  double responsiveWidth(double width) {
    return (width / 1280.0) * _scaleWidth;
  }

  double responsiveHeight(double height) {
    return (height / 900.0) * _scaleHeight;
  }
}
