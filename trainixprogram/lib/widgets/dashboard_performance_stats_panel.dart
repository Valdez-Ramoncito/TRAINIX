import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:trainixprogram/models/scoring_transparency.dart';
import 'package:trainixprogram/models/session_score.dart';
import 'package:trainixprogram/models/simulation_history.dart';
import 'package:trainixprogram/screens/report_ui/report_ui.dart';
import 'package:trainixprogram/screens/session_report_screen.dart';
import 'package:trainixprogram/widgets/user_facing_messages.dart';

class PerformanceStatsPanel extends StatelessWidget {
  const PerformanceStatsPanel({super.key});

  static const double passBar = 7.0;
  static const double strongBar = 8.5;

  String stage(double avg) {
    if (avg >= strongBar) return 'Job-ready path';
    if (avg >= passBar) return 'Passing trainee';
    if (avg >= 5) return 'Developing trainee';
    return 'Newbie';
  }

  Color stageColor(double avg) {
    if (avg >= strongBar) return const Color(0xFF70BD8A);
    if (avg >= passBar) return const Color(0xFF3B82F6);
    if (avg >= 5) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SimulationHistoryProvider>(
      builder: (context, history, _) {
        final liveSessions = history.sessions
            .where((s) => !isDebugSession(s))
            .toList();
        final liveEvals = history.evaluations
            .where((e) => !isDebugEvaluation(e))
            .toList();

        if (liveEvals.isEmpty && liveSessions.isEmpty) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.insights_outlined,
                      size: 42,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.35),
                    ),
                    const Gap(12),
                    Text(
                      'No practice activity yet',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const Gap(6),
                    Text(
                      'Debug and sample runs are hidden. Finish a real simulation session to see scores and trends here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.55),
                        height: 1.4,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final avg = liveEvals.isEmpty
            ? 0.0
            : liveEvals.map((e) => e.overallScore).reduce((a, b) => a + b) /
                liveEvals.length;
        final rated = liveEvals.where((e) => e.customerRating != null).toList();
        final csat = rated.isEmpty
            ? null
            : rated.map((e) => e.customerRating!.toDouble()).reduce((a, b) => a + b) /
                rated.length;
        final color = stageColor(avg);
        final cats = <(String, double Function(SessionEvaluation))>[
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
        final catAvgs = <String, double>{
          for (final c in cats)
            c.$1: liveEvals.isEmpty
                ? 0.0
                : liveEvals.map(c.$2).reduce((a, b) => a + b) / liveEvals.length,
        };
        final weakest = catAvgs.entries.reduce(
          (a, b) => a.value <= b.value ? a : b,
        );
        final strongest = catAvgs.entries.reduce(
          (a, b) => a.value >= b.value ? a : b,
        );
        final passCount =
            liveEvals.where((e) => e.overallScore >= passBar).length;
        final passRate =
            liveEvals.isEmpty ? 0.0 : passCount / liveEvals.length;
        final bestScore = liveEvals.isEmpty
            ? 0.0
            : liveEvals.map((e) => e.overallScore).reduce((a, b) => a > b ? a : b);

        final strengths = <String>{};
        final improvements = <String>{};
        for (final e in liveEvals) {
          for (final s in e.strengths) {
            final cleaned = friendlyEvalText(s);
            if (cleaned.isNotEmpty) strengths.add(cleaned);
          }
          for (final s in e.areasForImprovement) {
            final cleaned = friendlyEvalText(s);
            if (cleaned.isNotEmpty) improvements.add(cleaned);
          }
        }

        final bandCounts = <String, int>{
          'Excellent': 0,
          'Good': 0,
          'Developing': 0,
          'Needs work': 0,
        };
        for (final e in liveEvals) {
          final s = e.overallScore;
          if (s >= strongBar) {
            bandCounts['Excellent'] = bandCounts['Excellent']! + 1;
          } else if (s >= passBar) {
            bandCounts['Good'] = bandCounts['Good']! + 1;
          } else if (s >= 5) {
            bandCounts['Developing'] = bandCounts['Developing']! + 1;
          } else {
            bandCounts['Needs work'] = bandCounts['Needs work']! + 1;
          }
        }

        final recent = liveSessions.take(10).toList().reversed.toList();
        final sortedSkills = catAvgs.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return _DashboardScroll(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _heroCard(
                      context,
                      avg: avg,
                      color: color,
                      stageLabel: stage(avg),
                      customerCount: liveEvals.length,
                      sessionCount: liveSessions.length,
                    ),
                    const Gap(14),
                    _kpiRow(
                      context,
                      sessions: liveSessions.length,
                      customers: liveEvals.length,
                      csat: csat,
                      passRate: passRate,
                      passCount: passCount,
                      best: bestScore,
                    ),
                    const Gap(14),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 720;
                        final trend = _trendCard(context, recent);
                        final passDonut = _passDonutCard(
                          context,
                          passRate: passRate,
                          passCount: passCount,
                          total: liveEvals.length,
                          bands: bandCounts,
                        );
                        if (wide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: trend),
                              const Gap(12),
                              Expanded(flex: 2, child: passDonut),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            trend,
                            const Gap(12),
                            passDonut,
                          ],
                        );
                      },
                    ),
                    const Gap(14),
                    _skillsCard(context, sortedSkills),
                    const Gap(14),
                    _generalAnalysisCard(
                      context,
                      strongest: strongest,
                      weakest: weakest,
                      strengths: strengths.take(5).toList(),
                      improvements: improvements.take(5).toList(),
                      avg: avg,
                      passRate: passRate,
                    ),
                    const Gap(14),
                    _rubricExplainerCard(context),
                    const Gap(14),
                    _sectionTitle(
                      Icons.people_outline_rounded,
                      'Recent customers',
                      const Color(0xFF70BD8A),
                    ),
                    const Gap(10),
                    ...liveEvals.reversed.take(6).map((e) {
                      final c = stageColor(e.overallScore);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _linkCard(
                          context,
                          title: e.customerName.isEmpty
                              ? 'Customer'
                              : friendlyCustomerName(e.customerName),
                          subtitle:
                              '${e.channel.toUpperCase()} · ${e.sector} · ${e.overallScore.toStringAsFixed(1)}'
                              '${e.problem.isEmpty ? "" : " · ${e.problem}"}',
                          color: c,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    SessionReportScreen(evaluations: [e]),
                              ),
                            );
                          },
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

  Widget _heroCard(
    BuildContext context, {
    required double avg,
    required Color color,
    required String stageLabel,
    required int customerCount,
    required int sessionCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 28, 28, 28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromARGB(255, 42, 42, 43)),
      ),
      child: Row(
        children: [
          reportScoreRing(score: avg, color: color, size: 100, stroke: 9),
          const Gap(20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color),
                      ),
                      child: Text(
                        stageLabel.toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const Gap(8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$sessionCount sessions · $customerCount customers',
                        style: const TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(10),
                const Text(
                  'Overall practice average',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Gap(4),
                Text(
                  avg >= strongBar
                      ? 'Strong practice results. Keep polishing weaker skills, then treat this as hiring-ready practice.'
                      : avg >= passBar
                          ? 'At or above the practice pass mark (7.0). Build consistency with more full sessions.'
                          : avg >= 5
                              ? 'Mixed results. Stay with guided practice and focus on the lowest skill scores below.'
                              : 'Early stage. Use Mini Training and the Script Guide on every simulation before free practice.',
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiRow(
    BuildContext context, {
    required int sessions,
    required int customers,
    required double? csat,
    required double passRate,
    required int passCount,
    required double best,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 700;
        final items = [
          _kpiTile(
            Icons.play_circle_outline_rounded,
            'Sessions',
            '$sessions',
            'Completed runs',
            const Color(0xFF3B82F6),
          ),
          _kpiTile(
            Icons.people_outline_rounded,
            'Customers',
            '$customers',
            'Scored interactions',
            const Color(0xFF70BD8A),
          ),
          _kpiTile(
            Icons.star_rounded,
            'Avg CSAT',
            csat == null ? '—' : '${csat.toStringAsFixed(1)}/5',
            'Customer stars',
            const Color(0xFFFBBF24),
          ),
          _kpiTile(
            Icons.verified_outlined,
            'Pass rate',
            '${(passRate * 100).toStringAsFixed(0)}%',
            '$passCount ≥ $passBar',
            const Color(0xFFA78BFA),
          ),
          _kpiTile(
            Icons.emoji_events_outlined,
            'Best',
            best.toStringAsFixed(1),
            'Highest overall',
            const Color(0xFF0EA5E9),
          ),
        ];
        if (narrow) {
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: items
                .map(
                  (w) => SizedBox(
                    width: (constraints.maxWidth - 10) / 2,
                    child: w,
                  ),
                )
                .toList(),
          );
        }
        return Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const Gap(10),
              Expanded(child: items[i]),
            ],
          ],
        );
      },
    );
  }

  Widget _kpiTile(
    IconData icon,
    String title,
    String value,
    String hint,
    Color accent,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              Icon(icon, size: 16, color: accent),
              const Gap(6),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Gap(8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const Gap(2),
          Text(
            hint,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _trendCard(BuildContext context, List<PlayedSession> recent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255,  21, 21, 21),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color.fromARGB(255, 42, 42, 43)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.show_chart_rounded, size: 18, color: Color(0xFF3B82F6)),
              Gap(8),
              Text(
                'Session score trend',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Gap(4),
          const Text(
            'Older sessions on the left, newer on the right. Bars use the same level colors as reports.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11, height: 1.35),
          ),
          const Gap(14),
          if (recent.length < 2)
            const Text(
              'Complete at least two sessions to see a trend.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            )
          else
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < recent.length; i++) ...[
                    if (i > 0) const Gap(6),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            recent[i].overallScore.toStringAsFixed(1),
                            style: TextStyle(
                              color: stageColor(recent[i].overallScore),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Gap(4),
                          Container(
                            height: (recent[i].overallScore / 10.0 * 78)
                                .clamp(6.0, 78.0),
                            decoration: BoxDecoration(
                              color: stageColor(recent[i].overallScore)
                                  .withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _passDonutCard(
    BuildContext context, {
    required double passRate,
    required int passCount,
    required int total,
    required Map<String, int> bands,
  }) {
    final segments = <_DonutSegment>[
      _DonutSegment(bands['Excellent']!.toDouble(), const Color(0xFF70BD8A)),
      _DonutSegment(bands['Good']!.toDouble(), const Color(0xFF3B82F6)),
      _DonutSegment(bands['Developing']!.toDouble(), const Color(0xFFF59E0B)),
      _DonutSegment(bands['Needs work']!.toDouble(), const Color(0xFFEF4444)),
    ].where((s) => s.value > 0).toList();

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
          const Row(
            children: [
              Icon(Icons.pie_chart_outline_rounded,
                  size: 18, color: Color(0xFFA78BFA)),
              Gap(8),
              Text(
                'Score bands',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Gap(4),
          Text(
            'Pass rate ${(passRate * 100).toStringAsFixed(0)}% · $passCount of $total customers ≥ $passBar',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              height: 1.35,
            ),
          ),
          const Gap(14),
          Row(
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: CustomPaint(
                  painter: _DonutPainter(segments: segments),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(passRate * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const Text(
                          'pass',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  children: [
                    _legendRow('Excellent (8.5+)', bands['Excellent']!,
                        const Color(0xFF70BD8A)),
                    _legendRow(
                        'Good (7.0–8.4)', bands['Good']!, const Color(0xFF3B82F6)),
                    _legendRow('Developing (5.0–6.9)', bands['Developing']!,
                        const Color(0xFFF59E0B)),
                    _legendRow('Needs work (<5)', bands['Needs work']!,
                        const Color(0xFFEF4444)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
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
          const Gap(8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _skillsCard(
    BuildContext context,
    List<MapEntry<String, double>> sortedSkills,
  ) {
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
          const Row(
            children: [
              Icon(Icons.grid_view_rounded, size: 18, color: Color(0xFFA78BFA)),
              Gap(8),
              Text(
                'Skill averages',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Gap(4),
          const Text(
            'Mean of each competency across all scored customers. Sorted strongest to weakest.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11, height: 1.35),
          ),
          const Gap(14),
          ...sortedSkills.map((e) {
            final c = stageColor(e.value);
            final pct = (e.value / 10.0).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Icon(
                      ScoringTransparency.iconFor(e.key),
                      size: 16,
                      color: c,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      e.key,
                      style: const TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 8,
                        backgroundColor: const Color(0xFF2A2A2A),
                        color: c,
                      ),
                    ),
                  ),
                  const Gap(10),
                  SizedBox(
                    width: 36,
                    child: Text(
                      e.value.toStringAsFixed(1),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: c,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _generalAnalysisCard(
    BuildContext context, {
    required MapEntry<String, double> strongest,
    required MapEntry<String, double> weakest,
    required List<String> strengths,
    required List<String> improvements,
    required double avg,
    required double passRate,
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
          const Row(
            children: [
              Icon(Icons.psychology_outlined, size: 18, color: Color(0xFF0EA5E9)),
              Gap(8),
              Text(
                'General analysis',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Gap(4),
          Text(
            'Based on ${avg.toStringAsFixed(1)} average overall and ${(passRate * 100).toStringAsFixed(0)}% pass rate across your scored customers.',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              height: 1.35,
            ),
          ),
          const Gap(12),
          Row(
            children: [
              Expanded(
                child: _miniStat(
                  'Strongest skill',
                  strongest.key,
                  strongest.value.toStringAsFixed(1),
                  const Color(0xFF70BD8A),
                  ScoringTransparency.iconFor(strongest.key),
                ),
              ),
              const Gap(10),
              Expanded(
                child: _miniStat(
                  'Focus skill',
                  weakest.key,
                  weakest.value.toStringAsFixed(1),
                  const Color(0xFFF59E0B),
                  ScoringTransparency.iconFor(weakest.key),
                ),
              ),
            ],
          ),
          const Gap(12),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 640;
              final well = _focusListCard(
                title: 'What went well',
                icon: Icons.check_circle_outline_rounded,
                accent: const Color(0xFF70BD8A),
                items: strengths,
                empty: 'Strength notes will appear after more scored sessions.',
              );
              final focus = _focusListCard(
                title: 'Focus next',
                icon: Icons.flag_outlined,
                accent: const Color(0xFFF59E0B),
                items: improvements,
                empty: 'Practice areas will appear after more scored sessions.',
              );
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: well),
                    const Gap(10),
                    Expanded(child: focus),
                  ],
                );
              }
              return Column(
                children: [
                  well,
                  const Gap(10),
                  focus,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _miniStat(
    String label,
    String skill,
    String score,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2B)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(2),
                Text(
                  skill,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            score,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _focusListCard({
    required String title,
    required IconData icon,
    required Color accent,
    required List<String> items,
    required String empty,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accent),
              const Gap(6),
              Text(
                title,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const Gap(10),
          if (items.isEmpty)
            Text(
              empty,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                height: 1.35,
              ),
            )
          else
            ...items.map(
              (text) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(icon, size: 13, color: accent),
                    ),
                    const Gap(6),
                    Expanded(
                      child: Text(
                        text,
                        style: const TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _rubricExplainerCard(BuildContext context) {
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
          const Row(
            children: [
              Icon(Icons.rule_folder_outlined, size: 18, color: Color(0xFF60A5FA)),
              Gap(8),
              Text(
                'How practice scoring works',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Gap(10),
          const Text(
            'Each skill starts at 10. Observed gaps lower the score. Overall is the average of the 10 skills. Pass practice mark is 7.0. Excellent is 8.5 and above.',
            style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, height: 1.4),
          ),
          const Gap(10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _BandChip('9–10 Excellent', Color(0xFF70BD8A)),
              _BandChip('7–8.4 Good', Color(0xFF3B82F6)),
              _BandChip('5–6.9 Developing', Color(0xFFF59E0B)),
              _BandChip('0–4.9 Needs work', Color(0xFFEF4444)),
            ],
          ),
          const Gap(10),
          const Text(
            'Open any session report for the full scoring guide, CSAT formula, and per-customer skill breakdown.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const Gap(8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _linkCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(12),
          child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 21, 21, 21),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withValues(alpha: 0.8)),
          ],
        ),
          ),
        ),
      ),
    );
  }
}

class _BandChip extends StatelessWidget {
  final String label;
  final Color color;

  const _BandChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DonutSegment {
  final double value;
  final Color color;
  const _DonutSegment(this.value, this.color);
}

class _DonutPainter extends CustomPainter {
  final List<_DonutSegment> segments;

  _DonutPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<double>(0, (a, b) => a + b.value);
    if (total <= 0) {
      final paint = Paint()
        ..color = const Color(0xFF2A2A2A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12;
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        size.width / 2 - 8,
        paint,
      );
      return;
    }

    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2 - 8,
    );
    var start = -math.pi / 2;
    for (final seg in segments) {
      final sweep = (seg.value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
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
