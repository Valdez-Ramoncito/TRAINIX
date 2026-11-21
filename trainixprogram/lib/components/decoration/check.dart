import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';

class CheckProgress extends StatelessWidget {
  const CheckProgress({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.secondary(context),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.check,
        color: AppColors.onSecondary(context),
        size: 20,
      ),
    );
  }
}
