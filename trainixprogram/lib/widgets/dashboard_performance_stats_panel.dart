import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainixprogram/models/session_score.dart';
import 'package:trainixprogram/models/simulation_history.dart';

//performance stats
//first tab of the Analytics Dashboard.
class PerformanceStatsPanel extends StatelessWidget {
  const PerformanceStatsPanel({super.key});

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
              //one bar per completed session
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
