import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:trainixprogram/models/simulation_history.dart';

class SectorMatchPanel extends StatelessWidget {
  const SectorMatchPanel({super.key});

  static const int minSessions = 3;

  Color _c(double score) {
    if (score >= 8.5) return const Color(0xFF34D399);
    if (score >= 7) return const Color(0xFF60A5FA);
    if (score >= 5) return const Color(0xFFFBBF24);
    return const Color(0xFFF87171);
  }

  Widget _fact(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SimulationHistoryProvider>(
      builder: (context, history, _) {
        if (history.sessions.length < minSessions) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Sector fit unlocks after $minSessions sessions.\nYou have ${history.sessions.length} so far. Keep training across sectors so the dashboard can compare your averages.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, height: 1.4),
              ),
            ),
          );
        }

        final recommended = history.recommendedSector;
        final averages = history.sectorAverages;
        final maxScore = averages.values.isEmpty
            ? 10.0
            : averages.values.reduce(math.max);
        final minScore = averages.values.isEmpty
            ? 0.0
            : averages.values.reduce(math.min);
        final spread = maxScore - minScore;

        // Count customers per sector for justification
        final counts = <String, int>{};
        for (final e in history.evaluations) {
          if (e.sector.isEmpty) continue;
          counts[e.sector] = (counts[e.sector] ?? 0) + 1;
        }

        return _DashboardScroll(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F26),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF34D399).withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Best current sector fit',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const Gap(6),
                  Text(
                    recommended ?? 'Not enough data',
                    style: const TextStyle(
                      color: Color(0xFF34D399),
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                  const Gap(8),
                  if (recommended != null) ...[
                    const Gap(10),
                    _fact(
                      'Lead average',
                      '${(averages[recommended] ?? 0).toStringAsFixed(1)} / 10',
                    ),
                    _fact(
                      'Sample size',
                      '${counts[recommended] ?? 0} scored customer(s) in $recommended',
                    ),
                    _fact(
                      'How selected',
                      'Best average score by sector across all scored customers (not a single lucky run).',
                    ),
                    const Gap(8),
                    const Text(
                      'Other sector averages',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    const Gap(6),
                    ...averages.entries
                        .where((e) => e.key != recommended)
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• ${e.key}: ${e.value.toStringAsFixed(1)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    const Gap(10),
                    Text(
                      spread < 0.8
                          ? 'Spread is only ${spread.toStringAsFixed(1)} points, so fit is provisional until more sessions separate the bands.'
                          : 'Spread is ${spread.toStringAsFixed(1)} points, so the top sector is meaningfully ahead of the lowest.',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Gap(16),
            const Text(
              'How to read this',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const Gap(8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Sector fit is a training signal, not a hiring decision. It ranks sectors by average evaluation score from your simulations. Practice priority should start with the top fit, then close gaps in weaker sectors before claiming job readiness.',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
            const Gap(16),
            const Text(
              'Sector readiness',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const Gap(10),
            ...averages.entries.map((e) {
              final ratio = maxScore <= 0 ? 0.0 : e.value / 10.0;
              final isTop = e.key == recommended;
              final n = counts[e.key] ?? 0;
              final color = _c(e.value);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1F26),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isTop
                        ? const Color(0xFF34D399)
                        : const Color(0xFF2A323C),
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
                                  : FontWeight.w500,
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
                              color: const Color(
                                0xFF34D399,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF34D399),
                              ),
                            ),
                            child: const Text(
                              'Top fit',
                              style: TextStyle(
                                color: Color(0xFF34D399),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        Text(
                          e.value.toStringAsFixed(1),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const Gap(8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio.clamp(0.0, 1.0),
                        minHeight: 7,
                        backgroundColor: const Color(0xFF2A2A2A),
                        color: color,
                      ),
                    ),
                    const Gap(8),
                    Text(
                      e.value >= 8.5
                          ? 'Strong sector profile for entry conversations.'
                          : e.value >= 7
                          ? 'Passing in this sector with room to sharpen.'
                          : 'Needs more guided practice in this sector.',
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      'Based on $n scored customer(s) in ${e.key}. Average is overall score for that sector only.',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const Gap(8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Suggested next step: run at least two more sessions in your weakest sector, then recheck fit. Consistent 8+ averages in a sector are a better application signal than a single high score.',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DashboardScroll extends StatefulWidget {
  final EdgeInsets padding;
  final List<Widget> children;

  const _DashboardScroll({required this.padding, required this.children});

  @override
  State<_DashboardScroll> createState() => _DashboardScrollState();
}

class _DashboardScrollState extends State<_DashboardScroll> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _controller,
      thumbVisibility: true,
      interactive: true,
      child: ListView(
        controller: _controller,
        primary: false,
        padding: widget.padding,
        children: widget.children,
      ),
    );
  }
}
