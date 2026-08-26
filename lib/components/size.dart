import 'package:flutter/material.dart';

extension SizeHelper on BuildContext {
  /// Returns the screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Returns the screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Returns a responsive font size based on the screen width.
  /// It assumes a standard mobile design width of 375.0 points.
  double responsiveFont(double fontSize) {
    return (fontSize / 375.0) * screenWidth;
  }

  /// Returns a responsive width based on the screen width.
  /// It assumes a standard mobile design width of 375.0 points.
  double responsiveWidth(double width) {
    return (width / 375.0) * screenWidth;
  }

  /// Returns a responsive height based on the screen height.
  /// It assumes a standard mobile design height of 812.0 points.
  double responsiveHeight(double height) {
    return (height / 812.0) * screenHeight;
  }
}
