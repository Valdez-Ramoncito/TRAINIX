import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/components/button/back_button.dart';
import 'package:trainixprogram/components/button/menu_button_training.dart';
import 'package:trainixprogram/components/size.dart';
import 'package:trainixprogram/screens/home/homeScreen.dart';

class LeftMenu extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onMenuSelected;

  const LeftMenu({
    super.key,
    required this.selectedIndex,
    required this.onMenuSelected,
  });

  void _goHome(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sessions',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: context.responsiveFont(3.5),
                    ),
                  ),
                  const Gap(8),
                  MenuButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Non-Voice',
                    isSelected: selectedIndex == 0,
                    onTap: () => onMenuSelected(0),
                  ),
                  MenuButton(
                    icon: Icons.phone_in_talk_outlined,
                    label: 'Voice',
                    isSelected: selectedIndex == 1,
                    onTap: () => onMenuSelected(1),
                  ),
                  const Gap(24),
                  Text(
                    'History',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: context.responsiveFont(3.5),
                    ),
                  ),
                  const Gap(8),
                  MenuButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Non-Voice Sessions',
                    isSelected: selectedIndex == 2,
                    onTap: () => onMenuSelected(2),
                  ),
                  MenuButton(
                    icon: Icons.phone_in_talk_outlined,
                    label: 'Voice Sessions',
                    isSelected: selectedIndex == 3,
                    onTap: () => onMenuSelected(3),
                  ),
                  MenuButton(
                    icon: Icons.history_rounded,
                    label: 'All Sessions',
                    isSelected: selectedIndex == 4,
                    onTap: () => onMenuSelected(4),
                  ),
                  MenuButton(
                    icon: Icons.forum_outlined,
                    label: 'Messages',
                    isSelected: selectedIndex == 5,
                    onTap: () => onMenuSelected(5),
                  ),
                ],
              ),
            ),
          ),
          TrainingBackButton(onTap: () => _goHome(context)),
        ],
      ),
    );
  }
}
