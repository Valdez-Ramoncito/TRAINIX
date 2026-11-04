import 'package:trainixprogram/screens/page/profile.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/components/size.dart';
import 'package:trainixprogram/widgets/screen_help_button.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Mini Training",
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize: context.responsiveFont(7),
              ),
            ),
            Gap(10),
            Text(
              "Practice the basics and slowly build your confidence",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white54,
                fontSize: 13,
              ),
            ),
          ],
        ),
        Row(
          children: [
            const ScreenHelpButton(content: ScreenHelpCatalog.miniTraining),
            const Gap(4),
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
                          backgroundColor: const Color(0xFF374151),
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
                              color: const Color.fromARGB(255, 138, 251, 9),
                              border: Border.all(
                                color: const Color.fromARGB(255, 23, 23, 23),
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
      ],
    );
  }
}
