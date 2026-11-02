import 'package:trainixprogram/screens/page/profile.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/components/size.dart';
import 'package:trainixprogram/widgets/screen_help_button.dart';
import 'package:trainixprogram/widgets/onboarding_intro_banner.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Simulation Training',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: context.responsiveFont(6),
                    ),
                  ),
                  const Gap(6),
                  Text(
                    'Practice chat, voice, and hybrid customer sessions',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const ScreenHelpButton(content: ScreenHelpCatalog.simulationHub),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(ProfileData.displayName),
                const Gap(10),
                Stack(
                  children: [
                    CircleAvatar(
                      backgroundImage: const AssetImage(
                        'assets/images/defaultProfile.png',
                      ),
                      radius: context.responsiveWidth(6).clamp(14, 22),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color.fromARGB(255, 138, 251, 9),
                          border: Border.all(
                            color: const Color.fromARGB(255, 23, 23, 23),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        const Gap(10),
        const OnboardingIntroBanner(
          flagKey: 'simulation_intro',
          title: 'About Simulation Training',
          body:
              'Choose Chat, Voice, or Hybrid from the left menu. Locked modes open after you clear the matching Scenario Practice stage in Mini Training.',
        ),
      ],
    );
  }
}
