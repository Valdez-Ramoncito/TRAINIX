import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainixprogram/models/session_score.dart';
import 'package:trainixprogram/models/simulation_history.dart';

//this gives the agent a long term view of their performance across
//many sessions
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Analytics Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              //performance stats - shown where there is at least
              //one evaluation
              Tab(text: 'Performance Stats'),

              //session history - a simple table of every evaluation
              //newest first
              Tab(text: 'Session History'),

              //sector match - shows the recommended sector
              Tab(text: 'Sector Match'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PerformanceStatsPanel(),
            _SessionHistoryPanel(),
            _SectorMatchPanel(),
          ],
        ),
      ),
    );
  }
}

//performance stats
class _PerformanceStatsPanel extends StatelessWidget {
  const _PerformanceStatsPanel();

  //build the UI
  @override
  Widget build(BuildContext context) {
    return Consumer<SimulationHistoryProvider>(
      builder: (context, history, _) {
        if (history.evaluations.isEmpty) {
          return const Center(
            child: Text(
              'No sessions yet.\nComplete a simulation to see your performance.',
              textAlign: TextAlign.center,
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //build the metrics
              _buildMetricCards(history),
              const SizedBox(height: 24),

              //build the score breakdown
              _buildScoreBreakdown(history),
              const SizedBox(height: 24),

              //build the score trend
              _buildScoreTrend(history),
            ],
          ),
        );
      },
    );
  }

  //buid Metric Cards UI
  Widget _buildMetricCards(SimulationHistoryProvider history) {
    return Row(
      children: [
        //build everything that is needed for each metric
        //build the metric for total sessions
        Expanded(
          child: _buildMetricCard(
            'Total Sessions',
            '${history.sessions.length}',
          ),
        ),
        const SizedBox(width: 12),

        //build the metric for average score
        Expanded(
          child: _buildMetricCard(
            'Average Score',
            '${history.averageOverallScore.toStringAsFixed(1)} / 10',
          ),
        ),
        const SizedBox(width: 12),

        //build the metric for best overall score
        Expanded(
          child: _buildMetricCard(
            'Best Score',
            '${history.bestOverallScore.toStringAsFixed(1)} / 10',
          ),
        ),
        const SizedBox(width: 12),

        //build the metric for sectors played
        Expanded(
          child: _buildMetricCard(
            'Sectors Played',
            '${history.sectorAverages.keys.length}',
          ),
        ),
        const SizedBox(width: 12),

        //build the metric for average multitasking score
        Expanded(
          child: _buildMetricCard(
            'Avg Multitasking',
            history.averageMultitaskingScore != null
                ? '${history.averageMultitaskingScore!.toStringAsFixed(0)}%'
                : '—',
          ),
        ),
      ],
    );
  }

  //build the metric card UI
  Widget _buildMetricCard(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  //build the score breakdown UI
  Widget _buildScoreBreakdown(SimulationHistoryProvider history) {
    //for every category that we have, assign them in categories
    final categories = <(String, double Function(SessionEvaluation))>[
      ('Opening Spiel', (e) => e.openingSpielScore),
      ('Positive Scripting', (e) => e.positiveScriptingScore),
      ('Empathy', (e) => e.empathyScore),
      ('Active Listening', (e) => e.activeListeningScore),
      ('Problem Identification', (e) => e.problemIdentificationScore),
      ('Solution Delivery', (e) => e.solutionDeliveryScore),
      ('Communication Clarity', (e) => e.communicationClarityScore),
      ('Tone', (e) => e.toneScore),
      ('Sector Knowledge', (e) => e.sectorKnowledgeScore),
      ('Closing Spiel', (e) => e.closingSpielScore),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Average by Category',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        //then map the categories out
        ...categories.map((cat) {
          final avg = history.averageCategoryScore(cat.$2);

          //build a score bar for visualization
          return _buildScoreBar(cat.$1, avg);
        }),
      ],
    );
  }

  //build the score bar UI
  Widget _buildScoreBar(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: value / 10,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text(
              value.toStringAsFixed(1),
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  //build the score trend UI
  Widget _buildScoreTrend(SimulationHistoryProvider history) {
    const maxBarHeight = 80.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Score Trend',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: maxBarHeight + 36,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              //one bar per completed session (its averaged overall
              //score), not one bar per individual evaluation
              children: history.sessions.asMap().entries.map((entry) {
                final idx = entry.key;
                final session = entry.value;
                final barH = (session.overallScore / 10) * maxBarHeight;
                return Container(
                  width: 44,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        session.overallScore.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 9),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        height: barH,
                        width: 32,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('#${idx + 1}', style: const TextStyle(fontSize: 9)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

//simple table of every evaluation, starting at newest
class _SessionHistoryPanel extends StatelessWidget {
  const _SessionHistoryPanel();

  @override
  Widget build(BuildContext context) {
    return Consumer<SimulationHistoryProvider>(
      builder: (context, history, _) {
        if (history.sessions.isEmpty) {
          return const Center(
            child: Text(
              'No sessions yet.\nComplete a simulation to see your history.',
              textAlign: TextAlign.center,
            ),
          );
        }

        //one row per completed session, not per individual evaluation —
        //a session that resolved 3 customers now shows as 1 row here
        final reversed = history.sessions.reversed.toList();

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTableHeader(),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: reversed.length,
                  itemBuilder: (_, index) => _buildSessionRow(
                    reversed.length - index,
                    reversed[index],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  //build a table header UI
  Widget _buildTableHeader() {
    return const Row(
      children: [
        SizedBox(
          width: 36,
          child: Text('#', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          flex: 3,
          child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          flex: 2,
          child: Text('Sector', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          flex: 1,
          child: Text('Score', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          flex: 3,
          child: Text(
            'Top Strength',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  //build a session row UI
  Widget _buildSessionRow(int sessionNumber, PlayedSession session) {
    final dt = session.completedAt;
    final date =
        '${dt.month}/${dt.day}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text('$sessionNumber', style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            flex: 3,
            child: Text(date, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: Chip(
              label: Text(session.sector, style: const TextStyle(fontSize: 11)),
              padding: EdgeInsets.zero,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              session.overallScore.toStringAsFixed(1),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              session.topStrength,
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

//recommends a sector once an agent completes at least 3 sessions
class _SectorMatchPanel extends StatelessWidget {
  const _SectorMatchPanel();

  static const int _minimumSessions = 3;

  @override
  Widget build(BuildContext context) {
    return Consumer<SimulationHistoryProvider>(
      builder: (context, history, _) {
        if (history.sessions.length < _minimumSessions) {
          return Center(
            child: Text(
              'Complete at least $_minimumSessions sessions to unlock Sector Match.\n'
              '${history.sessions.length} / $_minimumSessions completed.',
              textAlign: TextAlign.center,
            ),
          );
        }

        //get the recommended sector
        final recommended = history.recommendedSector;

        //get the sector average
        final averages = history.sectorAverages;

        //make the max score
        final maxScore = averages.values.isEmpty
            ? 10.0
            : averages.values.reduce(math.max);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //build the recommendation
              _buildRecommendationCard(recommended, history),
              const SizedBox(height: 24),

              //build the sector bar
              _buildSectorBars(averages, maxScore, recommended),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //build strengths
                  Expanded(child: _buildStrengths(history)),
                  const SizedBox(width: 16),

                  //build improvements
                  Expanded(child: _buildImprovements(history)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  //build recommendation card UI
  Widget _buildRecommendationCard(
    String? recommended,
    SimulationHistoryProvider history,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recommended Sector', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Text(
              recommended ?? '—',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Based on ${history.sessions.length} session(s) '
              'across ${history.sectorAverages.keys.length} sector(s).',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  //build the sector bar UI
  Widget _buildSectorBars(
    Map<String, double> averages,
    double maxScore,
    String? recommended,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Suitability by Sector',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        //map the averages out
        ...averages.entries.map((entry) {
          //check if that very key is the recommended sector
          final isTop = entry.key == recommended;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Row(
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isTop ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                Expanded(
                  child: LinearProgressIndicator(
                    value: maxScore > 0 ? entry.value / maxScore : 0,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${entry.value.toStringAsFixed(1)} / 10',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isTop ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  //build the strengths UI
  Widget _buildStrengths(SimulationHistoryProvider history) {
    //get the strengths
    final strengths = history.aggregateStrengths;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Key Strengths',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (strengths.isEmpty)
          const Text('—')
        else
          //then map them out
          ...strengths.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text('• $s', style: const TextStyle(fontSize: 12)),
            ),
          ),
      ],
    );
  }

  //build the improvements UI
  Widget _buildImprovements(SimulationHistoryProvider history) {
    //get the improvements
    final improvements = history.aggregateAreasForImprovement;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Skills to Improve',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (improvements.isEmpty)
          const Text('—')
        else
          //then map them out
          ...improvements.map(
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text('• $i', style: const TextStyle(fontSize: 12)),
            ),
          ),
      ],
    );
  }
}
