import 'package:flutter/material.dart';

class CheckProgress extends StatelessWidget {
  const CheckProgress({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: Color(0xFF0D82FE),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check, color: Colors.white, size: 20),
    );
  }
}
