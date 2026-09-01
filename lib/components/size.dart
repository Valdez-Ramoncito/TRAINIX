import 'package:flutter/material.dart';

extension SizeHelper on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;

  double get screenHeight => MediaQuery.of(this).size.height;

  double responsiveFont(double fontSize) {
    return (fontSize / 375.0) * screenWidth;
  }

  double responsiveWidth(double width) {
    return (width / 375.0) * screenWidth;
  }

  double responsiveHeight(double height) {
    return (height / 812.0) * screenHeight;
  }
}
