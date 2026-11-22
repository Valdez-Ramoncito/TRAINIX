import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/components/button/session_button.dart';
import 'package:trainixprogram/components/button/toolbar_button.dart';
import 'package:trainixprogram/models/training/training_categories.dart';
import 'package:trainixprogram/screens/dashboard.dart';
import 'package:trainixprogram/screens/home/homeScreen.dart';
import 'package:trainixprogram/screens/page/mini_training.dart';
import 'package:trainixprogram/screens/page/profile.dart';
import 'package:trainixprogram/screens/settings_screen.dart';

class RightToolbar extends StatelessWidget {
  final ValueChanged<int>? onSelectSessionType;

  const RightToolbar({super.key, this.onSelectSessionType});

  @override
  Widget build(BuildContext context) {
    final dashboardReady =
        MiniTrainingProgress.hasCompletedSimulationSession ||
        !MiniTrainingProgress.isGuideActive;

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: NewSessionButton(onSelectChoice: onSelectSessionType),
            ),
            const Gap(20),
            ToolbarIcon(
              icon: Icons.school_outlined,
              tooltip: 'Mini Training',
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MiniTraining()),
                );
              },
            ),
            ToolbarIcon(
              icon: Icons.person_outline_rounded,
              tooltip: 'Profile',
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const Profile()),
                );
              },
            ),
            ToolbarIcon(
              icon: Icons.bar_chart_rounded,
              tooltip: dashboardReady
                  ? 'Progress Dashboard'
                  : 'Finish a simulation session first',
              onTap: dashboardReady
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DashboardScreen(),
                        ),
                      );
                    }
                  : null,
            ),
            ToolbarIcon(
              icon: Icons.settings_outlined,
              tooltip: 'Settings',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            const Spacer(),
            ToolbarIcon(
              icon: Icons.reply_rounded,
              tooltip: 'Back',
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
