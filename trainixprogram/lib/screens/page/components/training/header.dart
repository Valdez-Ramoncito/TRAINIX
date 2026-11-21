import 'package:trainixprogram/screens/page/profile.dart';
import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';
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
                    'Practice non-voice and voice customer sessions',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted(context),
                          fontSize: 13,
                        ),
                  ),
                ],
              ),
            ),
            const ScreenHelpButton(content: ScreenHelpCatalog.simulationHub),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const Profile()));
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(ProfileData.displayName),
                    const Gap(10),
                    Stack(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.borderStrong(context),
                          backgroundImage: const AssetImage(
                            'assets/images/defaultProfile.png',
                          ),
                          radius: 18,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryText(),
                              border: Border.all(
                                color: AppColors.card(context),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const Gap(10),
        const OnboardingIntroBanner(
          flagKey: 'simulation_intro',
          title: 'About Simulation Training',
          body:
              'Choose Non-Voice or Voice from the left menu. Locked modes open after you clear the matching Scenario Practice stage in Mini Training.',
        ),
      ],
    );
  }
}
