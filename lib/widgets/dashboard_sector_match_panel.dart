import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainixprogram/models/simulation_history.dart';

//recommends a sector once an agent completes at least 3 sessions
//third tab of the Analytics Dashboard.
class SectorMatchPanel extends StatelessWidget {
  const SectorMatchPanel({super.key});

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
