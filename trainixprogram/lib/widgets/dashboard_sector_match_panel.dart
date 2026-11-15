import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:trainixprogram/models/simulation_history.dart';
import 'package:trainixprogram/widgets/user_facing_messages.dart';

class SectorMatchPanel extends StatelessWidget {
  const SectorMatchPanel({super.key});

  static const int minSessions = 3;
  static const double passBar = 7.0;
  static const double strongBar = 8.5;

  Color _c(double score) {
    if (score >= strongBar) return const Color(0xFF70BD8A);
    if (score >= passBar) return const Color(0xFF3B82F6);
    if (score >= 5) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _band(double score) {
    if (score >= strongBar) return 'Excellent';
    if (score >= passBar) return 'Good';
    if (score >= 5) return 'Developing';
    return 'Needs work';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SimulationHistoryProvider>(
      builder: (context, history, _) {
        final liveSessions =
            history.sessions.where((s) => !isDebugSession(s)).toList();
        final liveEvals = history.evaluations
            .where((e) => !isDebugEvaluation(e))
            .toList();

        if (liveSessions.length < minSessions) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 21, 21, 21),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color.fromARGB(255, 42, 42, 43),
                        ),
                      ),
                      child: const Icon(
                        Icons.hub_outlined,
                        size: 36,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const Gap(16),
                    const Text(
                      'Sector fit not ready',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const Gap(8),
                    Text(
                      'Needs at least $minSessions real practice sessions so averages are stable enough to compare.\nYou have ${liveSessions.length} so far. Debug and sample runs do not count.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        height: 1.45,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final bySector = <String, List<double>>{};
        final passBySector = <String, int>{};
        for (final e in liveEvals) {
          if (e.sector.trim().isEmpty) continue;
          bySector.putIfAbsent(e.sector, () => []).add(e.overallScore);
          if (e.overallScore >= passBar) {
            passBySector[e.sector] = (passBySector[e.sector] ?? 0) + 1;
          }
        }

        if (bySector.isEmpty) {
          return const Center(
            child: Text(
              'No sector-tagged practice scores yet.',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          );
        }

        final averages = <String, double>{
          for (final entry in bySector.entries)
            entry.key:
                entry.value.reduce((a, b) => a + b) / entry.value.length,
        };
        final counts = <String, int>{
          for (final entry in bySector.entries) entry.key: entry.value.length,
        };
        final sorted = averages.entries.toList()
          ..sort((a, b) {
            final byScore = b.value.compareTo(a.value);
            if (byScore != 0) return byScore;
            return (counts[b.key] ?? 0).compareTo(counts[a.key] ?? 0);
          });

        final recommended = sorted.first.key;
        final recAvg = sorted.first.value;
        final recCount = counts[recommended] ?? 0;
        final recPass = passBySector[recommended] ?? 0;
        final recPassRate = recCount == 0 ? 0.0 : recPass / recCount;
        final maxScore = sorted.first.value;
        final minScore = sorted.last.value;
        final spread = maxScore - minScore;
        final runnerUp = sorted.length > 1 ? sorted[1] : null;
        final leadGap = runnerUp == null ? 0.0 : recAvg - runnerUp.value;

        String confidence;
        String confidenceDetail;
        if (recCount < 3 || spread < 0.5) {
          confidence = 'Low';
          confidenceDetail =
              'Small sample or tight spread. Treat this as a provisional signal and keep practicing more sectors.';
        } else if (recCount < 6 || spread < 1.0 || leadGap < 0.4) {
          confidence = 'Moderate';
          confidenceDetail =
              'Enough data to rank, but another strong sector could catch up. Keep balancing practice.';
        } else {
          confidence = 'High';
          confidenceDetail =
              'Lead average and sample size clearly separate the top sector from the rest.';
        }
        final confidenceColor = confidence == 'High'
            ? const Color(0xFF70BD8A)
            : confidence == 'Moderate'
                ? const Color(0xFF3B82F6)
                : const Color(0xFFF59E0B);

        final recScores = bySector[recommended]!;
        final recMin = recScores.reduce((a, b) => a < b ? a : b);
        final recMax = recScores.reduce((a, b) => a > b ? a : b);

        final whyLines = <String>[
          '$recommended has the highest average overall score among your real (non-debug) customers: ${recAvg.toStringAsFixed(2)} out of 10.',
          'That average is the mean of $recCount scored customer interaction${recCount == 1 ? '' : 's'} tagged with this sector.',
          if (runnerUp != null)
            'It leads ${runnerUp.key} by ${leadGap.toStringAsFixed(2)} points (${recAvg.toStringAsFixed(2)} vs ${runnerUp.value.toStringAsFixed(2)}).'
          else
            'It is currently the only sector with scored practice data.',
          'Pass-bar rate in $recommended is ${(recPassRate * 100).toStringAsFixed(0)}% ($recPass of $recCount customers at or above $passBar).',
          'Score range inside $recommended: ${recMin.toStringAsFixed(1)} to ${recMax.toStringAsFixed(1)}.',
        ];

        final analysis = StringBuffer()
          ..write(
            'Your strongest practice fit right now is $recommended because the mean of its customer overalls sits at the top of the ranking',
          );
        if (runnerUp != null) {
          analysis.write(
            ', ahead of ${runnerUp.key} by ${leadGap.toStringAsFixed(2)} points',
          );
        }
        analysis.write('. ');
        if (recAvg >= strongBar) {
          analysis.write(
            'That average is in the Excellent band (8.5+), so this sector is a solid showcase path if you keep consistency high. ',
          );
        } else if (recAvg >= passBar) {
          analysis.write(
            'That average clears the practice pass mark (7.0) but is not yet Excellent, so protect the lead with more full runs. ',
          );
        } else {
          analysis.write(
            'Even as the top sector, the average is still below the 7.0 pass mark, so prioritize fundamentals here before treating it as job-ready practice. ',
          );
        }
        if (sorted.length > 1 && minScore < passBar) {
          analysis.write(
            'Weaker sectors still sit below pass and need deliberate practice so fit does not become a single-sector comfort zone.',
          );
        } else if (sorted.length > 1) {
          analysis.write(
            'Other sectors are closer; balanced practice will keep the ranking honest.',
          );
        }

        return _DashboardScroll(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 21, 21, 21),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF70BD8A).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.emoji_events_outlined,
                                size: 20,
                                color: Color(0xFF70BD8A),
                              ),
                              Gap(8),
                              Text(
                                'Recommended sector fit',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const Gap(8),
                          Text(
                            recommended,
                            style: const TextStyle(
                              color: Color(0xFF70BD8A),
                              fontWeight: FontWeight.w800,
                              fontSize: 26,
                            ),
                          ),
                          const Gap(12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _statChip(
                                Icons.speed_rounded,
                                'Lead average',
                                '${recAvg.toStringAsFixed(2)} / 10',
                                _c(recAvg),
                              ),
                              _statChip(
                                Icons.people_outline_rounded,
                                'Sample size',
                                '$recCount customers',
                                const Color(0xFF3B82F6),
                              ),
                              _statChip(
                                Icons.verified_outlined,
                                'Pass rate',
                                '${(recPassRate * 100).toStringAsFixed(0)}%',
                                const Color(0xFFA78BFA),
                              ),
                              _statChip(
                                Icons.stacked_bar_chart_rounded,
                                'Spread',
                                '${spread.toStringAsFixed(2)} pts',
                                const Color(0xFF0EA5E9),
                              ),
                              _statChip(
                                Icons.shield_outlined,
                                'Confidence',
                                confidence,
                                confidenceColor,
                              ),
                            ],
                          ),
                          const Gap(12),
                          Text(
                            confidenceDetail,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(14),
                    _sectionCard(
                      icon: Icons.rule_folder_outlined,
                      iconColor: const Color(0xFF60A5FA),
                      title: 'Formula and rules',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sector score = mean of overall scores for every real scored customer in that sector.',
                            style: TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const Gap(8),
                          const Text(
                            'Recommended sector = sector with the highest sector score. If two sectors tie on average, the larger sample wins.',
                            style: TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const Gap(10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF151515),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF2A2A2B)),
                            ),
                            child: const Text(
                              'sector_score(S) = sum(overall of customers in S) / count(customers in S)\n'
                              'recommend = argmax over S of sector_score(S)\n'
                              'Debug and sample runs are excluded from every total.',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                                height: 1.45,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          const Gap(10),
                          const Text(
                            'This is a practice ranking only. It is not a TESDA grade, hiring decision, or certification result.',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(14),
                    _sectionCard(
                      icon: Icons.calculate_outlined,
                      iconColor: const Color(0xFFA78BFA),
                      title: 'Computation for your data',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Using ${liveSessions.length} real sessions and ${liveEvals.length} scored customers after debug filtering.',
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                          const Gap(12),
                          ...sorted.map((e) {
                            final n = counts[e.key] ?? 0;
                            final sum = bySector[e.key]!
                                .fold<double>(0, (a, b) => a + b);
                            final isTop = e.key == recommended;
                            final color = _c(e.value);
                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF151515),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isTop
                                      ? const Color(0xFF70BD8A)
                                          .withValues(alpha: 0.5)
                                      : const Color(0xFF2A2A2B),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          e.key,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: isTop
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      if (isTop)
                                        Container(
                                          margin:
                                              const EdgeInsets.only(right: 8),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF70BD8A)
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: const Color(0xFF70BD8A),
                                            ),
                                          ),
                                          child: const Text(
                                            'WINNER',
                                            style: TextStyle(
                                              color: Color(0xFF70BD8A),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      Text(
                                        e.value.toStringAsFixed(2),
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Gap(6),
                                  Text(
                                    'sum ${sum.toStringAsFixed(2)} ÷ $n customer${n == 1 ? '' : 's'} = ${e.value.toStringAsFixed(2)}  ·  band ${_band(e.value)}',
                                    style: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 12,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const Gap(14),
                    _sectionCard(
                      icon: Icons.help_outline_rounded,
                      iconColor: const Color(0xFFFBBF24),
                      title: 'Why $recommended',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...whyLines.map(
                            (line) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Icon(
                                      Icons.check_circle_outline,
                                      size: 14,
                                      color: Color(0xFF70BD8A),
                                    ),
                                  ),
                                  const Gap(8),
                                  Expanded(
                                    child: Text(
                                      line,
                                      style: const TextStyle(
                                        color: Color(0xFFCBD5E1),
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(14),
                    _sectionCard(
                      icon: Icons.psychology_outlined,
                      iconColor: const Color(0xFF0EA5E9),
                      title: 'General analysis',
                      child: Text(
                        analysis.toString(),
                        style: const TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const Gap(14),
                    _sectionCard(
                      icon: Icons.menu_book_outlined,
                      iconColor: const Color(0xFFA78BFA),
                      title: 'How to read the ranking',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _rubricRow(
                            '9.0 – 10.0',
                            'Excellent sector average',
                            const Color(0xFF70BD8A),
                          ),
                          _rubricRow(
                            '7.0 – 8.4',
                            'Good / practice pass band',
                            const Color(0xFF3B82F6),
                          ),
                          _rubricRow(
                            '5.0 – 6.9',
                            'Developing — keep guided practice',
                            const Color(0xFFF59E0B),
                          ),
                          _rubricRow(
                            '0.0 – 4.9',
                            'Needs work — prioritize fundamentals',
                            const Color(0xFFEF4444),
                          ),
                          const Gap(8),
                          const Text(
                            'Overall per customer is still the mean of the 10 skill scores on that interaction. Sector fit only averages those customer overalls by sector tag.',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(14),
                    const Row(
                      children: [
                        Icon(
                          Icons.hub_outlined,
                          size: 18,
                          color: Color(0xFFA78BFA),
                        ),
                        Gap(8),
                        Text(
                          'Sector readiness ranking',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const Gap(10),
                    ...sorted.map((e) {
                      final isTop = e.key == recommended;
                      final n = counts[e.key] ?? 0;
                      final color = _c(e.value);
                      final pct = (e.value / 10.0).clamp(0.0, 1.0);
                      final passN = passBySector[e.key] ?? 0;
                      final passPct = n == 0 ? 0 : ((passN / n) * 100).round();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 21, 21, 21),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isTop
                                ? const Color(0xFF70BD8A)
                                : const Color.fromARGB(255, 42, 42, 43),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    e.key,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: isTop
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                if (isTop)
                                  Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF70BD8A)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFF70BD8A),
                                      ),
                                    ),
                                    child: const Text(
                                      'TOP FIT',
                                      style: TextStyle(
                                        color: Color(0xFF70BD8A),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                Text(
                                  e.value.toStringAsFixed(2),
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const Gap(8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 8,
                                backgroundColor: const Color(0xFF2A2A2A),
                                color: color,
                              ),
                            ),
                            const Gap(6),
                            Text(
                              '$n customers · $passPct% ≥ $passBar · ${_band(e.value)}',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statChip(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2B)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const Gap(8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 21, 21, 21),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color.fromARGB(255, 42, 42, 43)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const Gap(8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const Gap(12),
          child,
        ],
      ),
    );
  }

  Widget _rubricRow(String range, String meaning, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const Gap(10),
          SizedBox(
            width: 88,
            child: Text(
              range,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              meaning,
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardScroll extends StatefulWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  const _DashboardScroll({
    required this.children,
    required this.padding,
  });

  @override
  State<_DashboardScroll> createState() => _DashboardScrollState();
}

class _DashboardScrollState extends State<_DashboardScroll> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _controller,
      child: ListView(
        controller: _controller,
        padding: widget.padding,
        children: widget.children,
      ),
    );
  }
}
