import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

enum ScenarioFeedbackKind { success, error }

class ScenarioFeedbackBanner extends StatelessWidget {
  final ScenarioFeedbackKind kind;
  final String title;
  final String message;

  const ScenarioFeedbackBanner({
    super.key,
    required this.kind,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isSuccess = kind == ScenarioFeedbackKind.success;
    final border = isSuccess ? const Color(0xFF059669) : const Color(0xFFDC2626);
    final bg = isSuccess ? const Color(0xFF064E3B) : const Color(0xFF450A0A);
    final fg = isSuccess ? const Color(0xFF34D399) : const Color(0xFFFCA5A5);
    final icon = isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 22),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: fg,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Gap(4),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
