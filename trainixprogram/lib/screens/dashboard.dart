import 'package:flutter/material.dart';
import 'package:trainixprogram/models/training/training_categories.dart';
import 'package:trainixprogram/screens/home/homeScreen.dart';
import 'package:trainixprogram/widgets/dashboard_performance_stats_panel.dart';
import 'package:trainixprogram/widgets/dashboard_session_history_panel.dart';
import 'package:trainixprogram/widgets/dashboard_sector_match_panel.dart';
import 'package:trainixprogram/widgets/screen_help_button.dart';
import 'package:trainixprogram/widgets/next_step_banner.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MiniTrainingProgress.markProgressDashboardReviewed();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          leading: IconButton(
            mouseCursor: SystemMouseCursors.click,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              }
            },
          ),
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.insights_rounded, size: 20, color: Color(0xFF70BD8A)),
              SizedBox(width: 8),
              Text(
                'Progress Dashboard',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          centerTitle: true,
          actions: const [
            ScreenHelpButton(content: ScreenHelpCatalog.progressDashboard),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 21, 21, 21),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color.fromARGB(255, 42, 42, 43),
                    ),
                  ),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: const TabBar(
                    indicator: BoxDecoration(
                      color: Color(0xFF243447),
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Color(0xFF70BD8A),
                    unselectedLabelColor: Color(0xFF9CA3AF),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    tabs: [
                      Tab(
                        height: 40,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.analytics_outlined, size: 16),
                            SizedBox(width: 6),
                            Text('Overview'),
                          ],
                        ),
                      ),
                      Tab(
                        height: 40,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_rounded, size: 16),
                            SizedBox(width: 6),
                            Text('Session History'),
                          ],
                        ),
                      ),
                      Tab(
                        height: 40,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.hub_outlined, size: 16),
                            SizedBox(width: 6),
                            Text('Sector Fit'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: NextStepBanner(
                    screen: TraineeNextStepScreen.progressDashboard,
                    showSkipGuide: true,
                  ),
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF15201A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF2E4A38)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: Color(0xFF70BD8A),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Scores are a 0-10 practice tool. Use them to spot strengths, track trends, and choose what to practice next. They are not a TESDA grade.',
                            style: TextStyle(
                              color: Color(0xFFD7E8DB),
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  PerformanceStatsPanel(),
                  SessionHistoryPanel(),
                  SectorMatchPanel(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
