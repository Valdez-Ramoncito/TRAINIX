import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';

class ProfileCameraButton extends StatelessWidget {
  const ProfileCameraButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        color: AppColors.elevated(context).withValues(alpha: 0.7),
        border: Border.all(
          color: AppColors.border(context),
          width: 0.5,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.camera_alt_rounded,
          size: 14,
          color: AppColors.textPrimary(context),
        ),
      ),
    );
  }
}
