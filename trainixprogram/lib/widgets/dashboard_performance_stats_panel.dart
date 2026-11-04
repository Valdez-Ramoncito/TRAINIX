import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:trainixprogram/models/session_score.dart';
import 'package:trainixprogram/models/simulation_history.dart';
import 'package:trainixprogram/screens/session_report_screen.dart';
import 'package:trainixprogram/widgets/user_facing_messages.dart';

class PerformanceStatsPanel extends StatelessWidget {
  const PerformanceStatsPanel({super.key});

  static const double passBar = 7.0;
  static const double strongBar = 8.5;

  static const Map<String, List<String>> skillBlurb = {
    'Opening Spiel': [
      'Mini Training category: Opening Spiel',
      'What it measures: Professional greeting, company/agent ID, and clear purpose.',
      'Example: "Thank you for contacting Trainix Support. This is Alex. I can help with your billing concern."',
    ],
    'Empathy': [
      'Mini Training category: Empathy',
      'What it measures: Acknowledging customer emotion before process talk.',
      'Example: "I understand this has been frustrating, and I will help you sort it out."',
    ],
    'Active Listening': [
      'Mini Training category: Active Listening',
      'What it measures: Confirming understanding of the stated issue.',
      'Example: "Just to confirm, the app freezes on the startup screen after yesterday\'s update."',
    ],
    'Problem Identification': [
      'Mini Training category: Problem Identification',
      'What it measures: Naming the core issue accurately before solving.',
      'Example: "The main issue is a failed login after the password reset."',
    ],
    'Solution Delivery': [
      'Mini Training category: Solution Delivery',
      'What it measures: Clear next steps the customer can follow.',
      'Example: "Please restart the app, then try the recovery link I will send."',
    ],
    'Communication Clarity': [
      'Mini Training category: Communication Clarity',
      'What it measures: Plain language and structured instructions.',
      'Example: Short sentences, one instruction at a time, no jargon dumps.',
    ],
    'Sector Knowledge': [
      'Mini Training category: Sector Knowledge',
      'What it measures: Sector-safe checks and correct terms.',
      'Example (Healthcare): Verify identity before discussing claim status.',
    ],
    'Closing Spiel': [
      'Mini Training category: Closing Spiel',
      'What it measures: Summary, confirmation, offer of more help, polite end.',
      'Example: "Your claim status is updated. Is there anything else I can help with today?"',
    ],
  };

  String stage(double avg) {
    if (avg >= strongBar) return 'Job-ready path';
    if (avg >= passBar) return 'Passing trainee';
    if (avg >= 5) return 'Developing trainee';
    return 'Newbie';
  }

  Color stageColor(double avg) {
    if (avg >= strongBar) return const Color(0xFF34D399);
    if (avg >= passBar) return const Color(0xFF60A5FA);
    if (avg >= 5) return const Color(0xFFFBBF24);
    return const Color(0xFFF87171);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SimulationHistoryProvider>(
      builder: (context, history, _) {
        if (history.evaluations.isEmpty) {
          return Center(
            child: Text(
              'No activity yet.\nFinish a simulation session to see scores and trends here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.55),
                height: 1.4,
              ),
            ),
          );
        }

        final avg = history.averageOverallScore;
        final csat = history.averageCustomerRating;
        final color = stageColor(avg);
        final cats = <(String, double Function(SessionEvaluation))>[
          ('Opening Spiel', (e) => e.openingSpielScore),
          ('Empathy', (e) => e.empathyScore),
          ('Active Listening', (e) => e.activeListeningScore),
          ('Problem Identification', (e) => e.problemIdentificationScore),
          ('Solution Delivery', (e) => e.solutionDeliveryScore),
          ('Communication Clarity', (e) => e.communicationClarityScore),
          ('Sector Knowledge', (e) => e.sectorKnowledgeScore),
          ('Closing Spiel', (e) => e.closingSpielScore),
        ];
        final catAvgs = {
          for (final c in cats) c.$1: history.averageCategoryScore(c.$2),
        };
        final weakest = catAvgs.entries.reduce(
          (a, b) => a.value <= b.value ? a : b,
        );
        final strongest = catAvgs.entries.reduce(
          (a, b) => a.value >= b.value ? a : b,
        );
        final passCount = history.evaluations
            .where((e) => e.overallScore >= passBar)
            .length;
        final passRate = passCount / history.evaluations.length;

        final strengths = <String>{};
        final improvements = <String>{};
        for (final e in history.evaluations) {
          for (final s in e.strengths) {
            final cleaned = friendlyEvalText(s);
            if (cleaned.isNotEmpty) strengths.add(cleaned);
          }
          for (final s in e.areasForImprovement) {
            final cleaned = friendlyEvalText(s);
            if (cleaned.isNotEmpty) improvements.add(cleaned);
          }
        }

        SessionEvaluation? bestCustomer;
        for (final e in history.evaluations) {
          if (bestCustomer == null ||
              e.overallScore > bestCustomer.overallScore) {
            bestCustomer = e;
          }
        }
        var bestSession = history.sessions.isEmpty
            ? null
            : history.sessions.first;
        for (final s in history.sessions) {
          if (bestSession == null ||
              s.overallScore > bestSession.overallScore) {
            bestSession = s;
          }
        }

        return _DashboardScroll(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.25),
                    const Color(0xFF1A1F26),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: color.withValues(alpha: 0.2),
                    child: Text(
                      avg.toStringAsFixed(1),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const Gap(14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stage(avg),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          avg >= strongBar
                              ? 'Strong practice results. Keep polishing weaker skills, then you can treat this as hiring-ready practice.'
                              : avg >= passBar
                              ? 'You are at or above the practice pass mark (7.0 average). Build consistency with more full sessions.'
                              : avg >= 5
                              ? 'Results are mixed. Stay with guided practice and focus on the lowest skill scores below.'
                              : 'Early stage. Use Mini Training and the Script Guide on every simulation before free practice.',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Gap(14),
            Row(
              children: [
                Expanded(
                  child: _kpi(
                    context,
                    'Sessions',
                    '${history.sessions.length}',
                    'Completed simulation runs',
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: _kpi(
                    context,
                    'Customers',
                    '${history.evaluations.length}',
                    'Scored customer interactions',
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: _kpi(
                    context,
                    'Avg CSAT',
                    csat == null ? '—' : '${csat.toStringAsFixed(1)}/5',
                    'Customer satisfaction from finished conversations',
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: _kpi(
                    context,
                    'Pass rate',
                    '${(passRate * 100).toStringAsFixed(0)}%',
                    '$passCount of ${history.evaluations.length} customers scored ≥ $passBar',
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: _kpi(
                    context,
                    'Best',
                    history.bestOverallScore.toStringAsFixed(1),
                    'Highest single-customer score',
                  ),
                ),
              ],
            ),
            const Gap(10),
            Text(
              'Pass rate counts each customer score. A customer counts as pass when the overall is at least $passBar out of 10.',
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
                height: 1.35,
              ),
            ),
            const Gap(14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F26),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coaching focus',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    'Strongest Mini Training category: ${strongest.key} (${strongest.value.toStringAsFixed(1)}).',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const Gap(6),
                  Text(
                    'Weakest Mini Training category: ${weakest.key} (${weakest.value.toStringAsFixed(1)}). Open Mini Training → ${weakest.key} next, then retest in Simulation Training.',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const Gap(10),
                  Text(
                    avg >= strongBar
                        ? 'Application note: scores support starting applications, with continued practice on ${weakest.key}.'
                        : avg >= passBar
                        ? 'Application note: not ready to rely on these scores alone. Aim for sustained 8+ averages.'
                        : 'Application note: stay in training. Do not use current averages for hiring claims yet.',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            if (strengths.isNotEmpty || improvements.isNotEmpty) ...[
              const Gap(14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _chipColumn(
                      context,
                      'Recurring strengths',
                      strengths.take(5).toList(),
                      const Color(0xFF34D399),
                      'From practice feedback on communication, empathy, and resolution.',
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    child: _chipColumn(
                      context,
                      'Recurring focus areas',
                      improvements.take(5).toList(),
                      const Color(0xFFFBBF24),
                      'From practice feedback about closing, product knowledge, and clear scripts.',
                    ),
                  ),
                ],
              ),
            ],
            if (bestSession != null || bestCustomer != null) ...[
              const Gap(14),
              Text(
                'Highlights',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const Gap(10),
              if (bestSession != null)
                _linkCard(
                  context,
                  title:
                      'Best session · ${bestSession.sector.isEmpty ? "Session" : bestSession.sector}',
                  subtitle:
                      'Score ${bestSession.overallScore.toStringAsFixed(1)} · ${bestSession.mode.name.toUpperCase()} · ${bestSession.evaluations.length} customer(s)',
                  color: stageColor(bestSession.overallScore),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SessionReportScreen(
                          evaluations: bestSession!.evaluations,
                          multitaskingScore: bestSession.multitaskingScore,
                        ),
                      ),
                    );
                  },
                ),
              if (bestCustomer != null) ...[
                const Gap(8),
                _linkCard(
                  context,
                  title:
                      'Best customer · ${bestCustomer.customerName.isEmpty ? "Customer" : bestCustomer.customerName}',
                  subtitle:
                      'Score ${bestCustomer.overallScore.toStringAsFixed(1)} · ${bestCustomer.channel.toUpperCase()} · ${bestCustomer.sector}',
                  color: stageColor(bestCustomer.overallScore),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SessionReportScreen(evaluations: [bestCustomer!]),
                      ),
                    );
                  },
                ),
              ],
            ],
            const Gap(14),
            Text(
              'Skill pulse',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const Gap(6),
            const Text(
              'Hover a skill for a short definition and example. Each score is the average across your scored customers.',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
            const Gap(10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: catAvgs.entries.map((e) {
                final c = stageColor(e.value);
                return Tooltip(
                  richMessage: TextSpan(
                    children: [
                      for (
                        int i = 0;
                        i < (skillBlurb[e.key] ?? [e.key]).length;
                        i++
                      ) ...[
                        if (i > 0) const TextSpan(text: '\n\n'),
                        TextSpan(
                          text: (skillBlurb[e.key] ?? [e.key])[i],
                          style: TextStyle(
                            color: i == 0 ? Colors.white : Colors.white70,
                            fontSize: i == 0 ? 13 : 12,
                            fontWeight: i == 0
                                ? FontWeight.w700
                                : FontWeight.w400,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  waitDuration: const Duration(milliseconds: 120),
                  showDuration: const Duration(seconds: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  preferBelow: true,
                  child: Container(
                    width: 168,

                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1F26),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.withValues(alpha: 0.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.key,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                        const Gap(6),
                        Text(
                          e.value.toStringAsFixed(1),
                          style: TextStyle(
                            color: c,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                        const Gap(6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (e.value / 10).clamp(0.0, 1.0),
                            minHeight: 5,
                            backgroundColor: const Color(0xFF2A2A2A),
                            color: c,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const Gap(16),
            Text(
              'Recent sessions',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const Gap(10),
            SizedBox(
              height: 120,
              child: ListView.separated(
                primary: false,
                scrollDirection: Axis.horizontal,
                itemCount: history.sessions.length,
                separatorBuilder: (_, __) => const Gap(8),
                itemBuilder: (_, i) {
                  final s = history.sessions[i];
                  final c = stageColor(s.overallScore);
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SessionReportScreen(
                            evaluations: s.evaluations,
                            multitaskingScore: s.multitaskingScore,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 100,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1F26),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2A323C)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            s.overallScore.toStringAsFixed(1),
                            style: TextStyle(
                              color: c,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Gap(6),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: 28,
                                height: (s.overallScore / 10 * 48).clamp(
                                  8.0,
                                  48.0,
                                ),
                                decoration: BoxDecoration(
                                  color: c,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                          const Gap(6),
                          Text(
                            '#${i + 1}',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                            ),
                          ),
                          const Text(
                            'Open',
                            style: TextStyle(
                              color: Colors.white30,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Gap(16),
            Text(
              'Recent customers',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const Gap(10),
            ...history.evaluations.reversed.take(6).map((e) {
              final c = stageColor(e.overallScore);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _linkCard(
                  context,
                  title: e.customerName.isEmpty ? 'Customer' : e.customerName,
                  subtitle:
                      '${e.channel.toUpperCase()} · ${e.sector} · ${e.overallScore.toStringAsFixed(1)}'
                      '${e.problem.isEmpty ? "" : " · ${e.problem}"}',
                  color: c,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SessionReportScreen(evaluations: [e]),
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _kpi(BuildContext context, String title, String value, String hint) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.55),
              fontSize: 11,
            ),
          ),
          const Gap(6),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const Gap(4),
          Text(
            hint,
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _chipColumn(
    BuildContext context,
    String title,
    List<String> items,
    Color color,
    String footnote,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const Gap(8),
          if (items.isEmpty)
            const Text(
              'None logged yet.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            )
          else
            ...items.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '• $s',
                  style: TextStyle(color: color, fontSize: 12, height: 1.3),
                ),
              ),
            ),
          const Gap(6),
          Text(
            footnote,
            style: const TextStyle(
              color: Colors.white30,
              fontSize: 10,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.55),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color, size: 18),
          ],
        ),
      ),
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
