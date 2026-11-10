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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
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
          title: const Text(
            'Progress Dashboard',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
          actions: const [
            ScreenHelpButton(content: ScreenHelpCatalog.progressDashboard),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F26),
                borderRadius: BorderRadius.circular(12),
              ),
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
                  Tab(text: 'Overview'),
                  Tab(text: 'Session History'),
                  Tab(text: 'Sector Fit'),
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: NextStepBanner(
                screen: TraineeNextStepScreen.progressDashboard,
                showSkipGuide: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF15201A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2E4A38)),
                ),
                child: const Text(
                  'Scores here are a 0-10 practice tool for training. Use them to spot strengths and what to practice next.',
                  style: TextStyle(
                    color: Color(0xFFD7E8DB),
                    fontSize: 12,
                    height: 1.35,
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
