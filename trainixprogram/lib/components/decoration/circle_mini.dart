import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';

Widget node(bool isComplete, bool isNext, BuildContext context) {
  final secondary = AppColors.secondary(context);
  final primary = AppColors.primary(context);
  final listBase = AppColors.listBase(context);
  final nextTint = AppColors.nextTint(context);
  final textMuted = AppColors.textMuted(context);

  if (isComplete) {
    return Container(
      width: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: secondary,
      ),
    );
  } else if (isNext) {
    return Stack(
      children: [
        Container(
          width: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: listBase,
            border: Border.all(color: nextTint),
          ),
        ),
        Positioned(
          child: Center(
            child: Container(
              width: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary,
              ),
            ),
          ),
        ),
      ],
    );
  } else {
    return Container(
      width: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: textMuted.withValues(alpha: 0.45),
      ),
    );
  }
}
