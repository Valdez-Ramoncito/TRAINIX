import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/components/background.dart';
import 'package:trainixprogram/components/button/logout_button.dart';
import 'package:trainixprogram/components/size.dart';
import 'package:trainixprogram/screens/home/trainer/carousel.dart';
import 'package:trainixprogram/screens/auth/loginscreen.dart';
import 'package:trainixprogram/services/auth_service.dart';
import 'package:trainixprogram/screens/page/profile.dart';

class HomeScreenTrainer extends StatelessWidget {
  const HomeScreenTrainer({super.key});

  @override
  Widget build(BuildContext context) {
    final header = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              "Hello, ${ProfileData.shortName}!",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: context.responsiveFont(7),
              ),
            ),
            const Gap(5),
            Image.asset('assets/images/hand.png', height: 25),
          ],
        ),
        Row(
          children: [
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
            Gap(10),
            HoverIconButton(
              icon: Icons.bug_report_rounded,
              tooltip: 'Developer Test',
              onPressed: () {
                //   Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (_) => const DevTestScreen()),
                // ),
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
              children: [header, Carousel(), Text("Last Log in")],
            ),
          ),
        ),
      ),
    );
  }
}
