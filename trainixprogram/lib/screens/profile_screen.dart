import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:trainixprogram/components/animation_effect/hover_button.dart';
import 'package:trainixprogram/components/size.dart';
import 'package:trainixprogram/providers/simulation_provider.dart';
import 'package:trainixprogram/screens/dashboard.dart';
import 'package:trainixprogram/screens/mock_call_screen.dart';
import 'package:trainixprogram/screens/profile_account.dart';
import 'package:trainixprogram/screens/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  int indexPage = 0;
  int selectNavigation = 0;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);

    tabController.addListener(() {
      if (!tabController.indexIsChanging) {
        setState(() {
          indexPage = tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 150,
            height: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text(
                        'TRAINIX',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontSize: context.responsiveFont(5)),
                      ),
                      const Gap(40),
                      MenuButton(
                        icon: Icons.person_outline_rounded,
                        label: 'Account',
                        isSelected: selectNavigation == 0,
                        onTap: () {
                          setState(() {
                            selectNavigation = 0;
                          });
                        },
                      ),
                      MenuButton(
                        icon: Icons.computer_rounded,
                        label: 'Training',
                        onTap: () {
                          final sector = Provider.of<SimulationProvider>(
                            context,
                            listen: false,
                          ).pickNextSector();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MockCallScreen(sector: sector),
                            ),
                          );
                        },
                      ),
                      MenuButton(
                        icon: Icons.bar_chart_rounded,
                        label: 'Progress',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DashboardScreen(),
                            ),
                          );
                        },
                      ),
                      MenuButton(
                        icon: Icons.settings_outlined,
                        label: 'Settings',
                        isSelected: selectNavigation == 1,
                        onTap: () {
                          setState(() {
                            selectNavigation = 1;
                          });
                        },
                      ),
                    ],
                  ),
                  const TrainingBackButton(),
                ],
              ),
            ),
          ),
          const VerticalDivider(
            width: .5,
            thickness: .3,
            color: Color.fromARGB(255, 105, 106, 106),
          ),
          Expanded(
            child: KeyedSubtree(
              key: ValueKey(selectNavigation),
              child: buildProfileContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildProfileContent() {
    switch (selectNavigation) {
      case 0:
        return ProfileAccount(
          tabController: tabController,
          indexPage: indexPage,
        );
      case 1:
        return const SettingsScreen();
      default:
        return ProfileAccount(
          tabController: tabController,
          indexPage: indexPage,
        );
    }
  }
}
