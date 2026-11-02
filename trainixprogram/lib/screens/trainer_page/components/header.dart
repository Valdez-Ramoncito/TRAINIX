import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/components/size.dart';
import 'package:trainixprogram/screens/page/profile.dart';

class TrainerHeader extends StatelessWidget {
  const TrainerHeader({super.key});

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
              'Create Room',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize: context.responsiveFont(7),
              ),
            ),
            const Gap(8),
            Text(
              'Set up a one-on-one coaching room with a trainee.\n'
              'Public rooms show their code; private rooms stay locked until the code is entered.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white54,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Text(ProfileData.displayName),
            const Gap(10),
            Stack(
              children: [
                CircleAvatar(
                  backgroundImage: const AssetImage(
                    'assets/images/defaultProfile.png',
                  ),
                  radius: context.responsiveWidth(6),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
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
    );
  }
}
