import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/components/background.dart';
import 'package:trainixprogram/components/button/logout_button.dart';
import 'package:trainixprogram/components/size.dart';
import 'package:trainixprogram/models/training/trainee_next_step.dart';
import 'package:trainixprogram/models/training/training_categories.dart';
import 'package:trainixprogram/screens/home/carousel.dart';
import 'package:trainixprogram/screens/auth/loginscreen.dart';
import 'package:trainixprogram/services/auth_service.dart';
import 'package:trainixprogram/screens/page/profile.dart';
import 'package:trainixprogram/screens/dev_test_screen.dart';
import 'package:trainixprogram/widgets/screen_help_button.dart';
import 'package:trainixprogram/widgets/next_step_banner.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: MiniTrainingProgress.guidanceRevision,
      builder: (context, _, __) {
        final next = TraineeNextStep.resolve();
        final needsProfile = !MiniTrainingProgress.isProfileComplete;
        final guided = MiniTrainingProgress.isGuideActive;
        final welcomeLine = needsProfile
            ? 'Welcome. Start by completing your profile so training can unlock.'
            : guided
            ? 'Welcome back. The guide highlights where to go next.'
            : 'Welcome back. Guide is off. Open Help if you need a reminder.';

        final header = Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          "Hello, ${ProfileData.shortName}!",
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontSize: context.responsiveFont(7)),
                        ),
                      ),
                      const Gap(5),
                      Image.asset('assets/images/hand.png', height: 25),
                    ],
                  ),
                  const Gap(6),
                  Text(
                    welcomeLine,
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                const ScreenHelpButton(content: ScreenHelpCatalog.home),
                HoverIconButton(
                  icon: Icons.logout_rounded,
                  tooltip: 'Log out',
                  onPressed: () async {
                    await AuthService.instance.signOut();
                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  },
                ),
              ],
            ),
          ],
        );

        return Scaffold(
          body: AppBackground(
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        header,
                        const Gap(16),
                        const NextStepBanner(
                          screen: TraineeNextStepScreen.home,
                          showSkipGuide: true,
                        ),
                      ],
                    ),
                    Carousel(
                      highlightCardId: guided ? next.carouselCardId : null,
                    ),
                    const Gap(12),
                    Text(
                      'Welcome back, ${ProfileData.displayName}',
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
