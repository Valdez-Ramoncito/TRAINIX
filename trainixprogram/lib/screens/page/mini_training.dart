import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/components/button/back_button.dart';
import 'package:trainixprogram/components/button/menu_button_training.dart';
import 'package:trainixprogram/components/layout/content_bounds.dart';
import 'package:trainixprogram/components/size.dart';
import 'package:trainixprogram/screens/home/homeScreen.dart';
import 'package:trainixprogram/screens/page/components/mini_training/category_timeline.dart';
import 'package:trainixprogram/screens/page/components/mini_training/header.dart';
import 'package:trainixprogram/screens/page/components/mini_training/scenario_practice_tab.dart';
import 'package:trainixprogram/screens/page/components/mini_training/training_notification_banner.dart';
import 'package:trainixprogram/screens/page/components/mini_training/speaking_practice/speaking_practice_tab.dart';
import 'package:trainixprogram/screens/page/components/mini_training/typing_practice/typing_practice_tab.dart';
import 'package:trainixprogram/screens/page/training.dart';
import 'package:trainixprogram/screens/dashboard.dart';
import 'package:trainixprogram/screens/settings_screen.dart';
import 'package:trainixprogram/widgets/onboarding_intro_banner.dart';
import 'package:trainixprogram/widgets/next_step_banner.dart';
import 'package:trainixprogram/models/training/trainee_next_step.dart';

class MiniTraining extends StatefulWidget {
  const MiniTraining({super.key});

  @override
  State<MiniTraining> createState() => _MiniTrainingState();
}

class _MiniTrainingState extends State<MiniTraining>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TrainingNotificationHost(
      child: Scaffold(
        body: Row(
          children: [
            SizedBox(
              width: 260,
              height: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 30,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Text(
                          'TRAINIX',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontSize: context.responsiveFont(7)),
                        ),
                        const Gap(40),
                        MenuButton(
                          icon: Icons.school_outlined,
                          label: 'Mini Training',
                          isSelected: true,
                          onTap: () {},
                        ),
                        MenuButton(
                          icon: Icons.computer_rounded,
                          label: 'Training Session',
                          onTap: () {
                            if (!TraineeNextStep.canOpenCarouselCard(3)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    TraineeNextStep.lockReasonForCarouselCard(
                                      3,
                                    ),
                                  ),
                                ),
                              );
                              return;
                            }
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TrainingSession(),
                              ),
                            );
                          },
                        ),
                        MenuButton(
                          icon: Icons.bar_chart_rounded,
                          label: 'Progress Dashboard',
                          onTap: () {
                            if (!TraineeNextStep.canOpenCarouselCard(5)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    TraineeNextStep.lockReasonForCarouselCard(
                                      5,
                                    ),
                                  ),
                                ),
                              );
                              return;
                            }
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
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SettingsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    TrainingBackButton(
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => HomeScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            VerticalDivider(
              width: .5,
              thickness: .3,
              color: AppColors.textMuted(context),
            ),
            Expanded(
              child: ContentBounds(
                maxWidth: 1100,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Header(),
                      const Gap(12),
                      const NextStepBanner(
                        screen: TraineeNextStepScreen.miniTraining,
                        showSkipGuide: true,
                        margin: EdgeInsets.only(bottom: 12),
                      ),
                      const OnboardingIntroBanner(
                        flagKey: 'mini_intro',
                        title: 'How Mini Training works',
                        body:
                            'Lessons unlock in order. Finish a category final to open the next category. After all categories, take the Grand Final to unlock Scenario Practice.',
                      ),
                      TabBar(
                        controller: _tabController,
                        labelColor: AppColors.textPrimary(context),
                        unselectedLabelColor: AppColors.textMuted(context),
                        indicatorColor: AppColors.primary(context),
                        indicatorSize: TabBarIndicatorSize.tab,
                        tabs: const [
                          Tab(
                            icon: Icon(Icons.menu_book_outlined, size: 18),
                            text: 'Knowledge',
                          ),
                          Tab(
                            icon: Icon(Icons.theater_comedy_outlined, size: 18),
                            text: 'Scenarios',
                          ),
                          Tab(
                            icon: Icon(Icons.keyboard_rounded, size: 18),
                            text: 'Typing',
                          ),
                          Tab(
                            icon: Icon(Icons.mic_none_rounded, size: 18),
                            text: 'Speaking',
                          ),
                        ],
                      ),
                      const Gap(20),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            const CategoryTimeline(),
                            ScenarioPracticeTab(
                              onOpenKnowledgePath: () {
                                _tabController.animateTo(0);
                              },
                            ),
                            const TypingPracticeTab(),
                            const SpeakingPracticeTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
