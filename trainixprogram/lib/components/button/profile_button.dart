import 'package:flutter/material.dart';

class ProfileCameraButton extends StatelessWidget {
  const ProfileCameraButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        color: const Color.fromARGB(100, 65, 65, 70),
        border: Border.all(
          color: const Color.fromARGB(99, 137, 137, 145),
          width: .5,
        ),
      ),
      child: const Center(
        child: Icon(Icons.camera_alt_rounded, size: 14, color: Colors.black),
      ),
    );
  }
}
