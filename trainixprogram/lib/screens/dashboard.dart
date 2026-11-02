import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainixprogram/models/session_score.dart';
import 'package:trainixprogram/models/simulation_history.dart';
import 'package:trainixprogram/models/simulation_phase.dart';
import 'package:trainixprogram/models/training/training_categories.dart';
import 'package:trainixprogram/screens/home/homeScreen.dart';
import 'package:trainixprogram/widgets/dashboard_performance_stats_panel.dart';
import 'package:trainixprogram/widgets/dashboard_session_history_panel.dart';
import 'package:trainixprogram/widgets/dashboard_sector_match_panel.dart';
import 'package:trainixprogram/widgets/screen_help_button.dart';
import 'package:trainixprogram/widgets/next_step_banner.dart';
import 'package:trainixprogram/models/trainix_debug.dart';

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

  SessionEvaluation _sample({
    required String sector,
    required String channel,
    required double base,
    required String name,
    required List<String> strengths,
    required List<String> improvements,
    required DateTime at,
  }) {
    double c(double v) => v.clamp(0, 10).toDouble();
    final scores = [
      c(base),
      c(base - 0.2),
      c(base + 0.15),
      c(base - 0.1),
      c(base + 0.05),
      c(base),
      c(base + 0.25),
      c(base - 0.15),
      c(base - 0.35),
      c(base + 0.1),
    ];
    final overall = scores.reduce((a, b) => a + b) / scores.length;
    return SessionEvaluation(
      sector: sector,
      openingSpielScore: scores[0],
      positiveScriptingScore: scores[1],
      empathyScore: scores[2],
      activeListeningScore: scores[3],
      problemIdentificationScore: scores[4],
      solutionDeliveryScore: scores[5],
      communicationClarityScore: scores[6],
      toneScore: scores[7],
      sectorKnowledgeScore: scores[8],
      closingSpielScore: scores[9],
      overallScore: double.parse(overall.toStringAsFixed(1)),
      strengths: strengths,
      areasForImprovement: improvements,
      feedback: 'DEBUG profile seed for dashboard testing.',
      evaluatedAt: at,
      customerName: name,
      channel: channel,
      problem: 'Sample $sector concern',
      conversation: [
        {'role': 'customer', 'text': 'I need help with a sample issue.'},
        {
          'role': 'agent',
          'text': 'Thank you for contacting support. I can help.',
        },
      ],
    );
  }

  void _seedProfile(BuildContext context, String label, double base) {
    final history = Provider.of<SimulationHistoryProvider>(
      context,
      listen: false,
    );
    final now = DateTime.now();
    final strengths = base >= 8.5
        ? [
            'Clear communication',
            'Strong active listening',
            'Confident opening spiel',
          ]
        : base >= 7
        ? ['Clear communication', 'Steady tone']
        : base >= 5
        ? ['Shows willingness to follow structure']
        : ['Shows up for practice'];
    final improvements = base >= 8.5
        ? ['Sector knowledge polish']
        : base >= 7
        ? ['Closing spiel', 'Sector knowledge']
        : base >= 5
        ? ['Closing spiel', 'Sector knowledge', 'Positive scripting']
        : [
            'Opening Spiel',
            'Active Listening',
            'Problem Identification',
            'Closing Spiel',
          ];

    final sectors = ['Healthcare', 'Tech Support', 'Finance', 'Telco'];
    final batch = <SessionEvaluation>[];
    for (var i = 0; i < sectors.length; i++) {
      final sector = sectors[i];
      // slight sector variance so fit ranking is visible
      final sectorBias = (i == 0)
          ? 0.4
          : (i == 1)
          ? -0.2
          : (i == 2)
          ? 0.1
          : -0.5;
      batch.add(
        _sample(
          sector: sector,
          channel: i.isEven ? 'chat' : 'voice',
          base: base + sectorBias,
          name: 'Demo $sector Customer',
          strengths: strengths,
          improvements: improvements,
          at: now.subtract(Duration(hours: i + 1)),
        ),
      );
      batch.add(
        _sample(
          sector: sector,
          channel: i.isEven ? 'voice' : 'chat',
          base: base + sectorBias - 0.3,
          name: 'Demo $sector Caller',
          strengths: strengths,
          improvements: improvements,
          at: now.subtract(Duration(hours: i + 5)),
        ),
      );
    }

    for (final e in batch) {
      history.saveEvaluation(e);
    }
    // 4 sessions so Sector Fit unlocks
    // countForGuide false: seed is for UI only, must not skip Simulation in the guide
    for (var i = 0; i < 4; i++) {
      final slice = batch.skip(i * 2).take(2).toList();
      history.saveSession(
        evaluations: slice,
        multitaskingScore: i == 0 ? 70.0 : null,
        mode: i == 0 ? SimulationMode.hybrid : SimulationMode.chat,
        countForGuide: false,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('DEBUG: Seeded $label profile (Sector Fit ready)'),
      ),
    );
  }

  void _showDebugMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1F26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'DEBUG: Seed trainee profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Each option adds multi-sector sessions so Overview, Session History, and Sector Fit all have data.',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  _debugTile(
                    ctx,
                    'Red / newbie stats',
                    'Overall around 3.5 to 4.5. Weak across Mini Training categories.',
                    const Color(0xFFF87171),
                    () => _seedProfile(context, 'red/newbie', 3.8),
                  ),
                  _debugTile(
                    ctx,
                    'Mid / developing stats',
                    'Overall around 5.5 to 6.5. Mixed pass/fail customers.',
                    const Color(0xFFFBBF24),
                    () => _seedProfile(context, 'mid/developing', 5.8),
                  ),
                  _debugTile(
                    ctx,
                    'Good / passing stats',
                    'Overall around 7.0 to 7.8. Clears pass bar with gaps.',
                    const Color(0xFF60A5FA),
                    () => _seedProfile(context, 'good/passing', 7.3),
                  ),
                  _debugTile(
                    ctx,
                    'Outstanding / job-ready stats',
                    'Overall around 8.7 to 9.3. Strong sector fit signal.',
                    const Color(0xFF34D399),
                    () => _seedProfile(context, 'outstanding', 9.0),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _debugTile(
    BuildContext ctx,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: const Color(0xFF0F1419),
        leading: CircleAvatar(backgroundColor: color, radius: 8),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        onTap: () {
          Navigator.pop(ctx);
          onTap();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F1419),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F1419),
          foregroundColor: Colors.white,
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
          actions: [
            const ScreenHelpButton(
              content: ScreenHelpCatalog.progressDashboard,
            ),
            if (TrainixDebug.unlocked)
              TextButton(
                onPressed: () => _showDebugMenu(context),
                child: const Text(
                  'DEBUG: Seed',
                  style: TextStyle(color: Color(0xFF70BD8A), fontSize: 12),
                ),
              ),
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
                  'Scores here are a 0-10 practice tool for training. TESDA panel criteria stay a separate competency checklist.',
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
