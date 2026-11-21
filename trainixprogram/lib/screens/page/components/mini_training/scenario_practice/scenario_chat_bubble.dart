import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';
import 'package:gap/gap.dart';

class ScenarioChatBubbleData {
  final String text;
  final bool isAgent;
  final bool isCustomer;

  const ScenarioChatBubbleData({
    required this.text,
    this.isAgent = false,
    this.isCustomer = false,
  });
}

class ScenarioChatBubble extends StatelessWidget {
  final ScenarioChatBubbleData bubble;
  final String customerName;

  const ScenarioChatBubble({
    super.key,
    required this.bubble,
    required this.customerName,
  });

  @override
  Widget build(BuildContext context) {
    final align = bubble.isAgent ? Alignment.centerRight : Alignment.centerLeft;
    final color = bubble.isAgent
        ? AppColors.nextTint(context)
        : AppColors.elevated(context);
    final label = bubble.isAgent ? 'You' : customerName;

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 460),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style:
                  TextStyle(fontSize: 11, color: AppColors.textMuted(context)),
            ),
            const Gap(4),
            Text(
              bubble.text,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
