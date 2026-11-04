import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:trainixprogram/models/simulation_history.dart';
import 'package:trainixprogram/screens/session_report_screen.dart';

class SessionHistoryPanel extends StatelessWidget {
  const SessionHistoryPanel({super.key});

  Color _color(double score) {
    if (score >= 8.5) return const Color(0xFF34D399);
    if (score >= 7) return const Color(0xFF60A5FA);
    if (score >= 5) return const Color(0xFFFBBF24);
    return const Color(0xFFF87171);
  }

  String _when(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SimulationHistoryProvider>(
      builder: (context, history, _) {
        if (history.sessions.isEmpty) {
          return const Center(
            child: Text(
              'Session history is empty.\nCompleted simulation runs will appear here with mode, sector, score, and customers.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, height: 1.4),
            ),
          );
        }

        final items = history.sessions;
        final avg = history.averageOverallScore;
        final passCount = history.sessions
            .where((s) => s.overallScore >= 7)
            .length;

        return _DashboardScroll(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F26),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Session history',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const Gap(6),
                  Text(
                    '${items.length} completed run(s) · average ${avg.toStringAsFixed(1)} · $passCount at or above pass bar. Tap any row for the full session report and per-customer detail.',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(14),
            ...items.asMap().entries.map((entry) {
              final i = entry.key;
              final session = entry.value;
              final number = items.length - i;
              final mode = session.mode.name.toUpperCase();
              final score = session.overallScore;
              final color = _color(score);
              final names = session.evaluations
                  .map((e) => e.customerName)
                  .where((n) => n.isNotEmpty)
                  .toList();
              final channels = session.evaluations
                  .map((e) => e.channel)
                  .toSet()
                  .join('/');
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SessionReportScreen(
                        evaluations: session.evaluations,
                        multitaskingScore: session.multitaskingScore,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1F26),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF2A323C)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 42,
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
                                  'Session #$number · ${session.sector.isEmpty ? "Mixed sectors" : session.sector}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Gap(4),
                                Text(
                                  '$mode · ${session.evaluations.length} customer(s) · channels $channels · ${_when(session.completedAt)}',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                score.toStringAsFixed(1),
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                              const Text(
                                'Open report',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Gap(10),
                      Text(
                        score >= 7
                            ? 'Outcome: at or above the training pass bar for this run.'
                            : 'Outcome: below the training pass bar. Review competency notes in the report.',
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (names.isNotEmpty) ...[
                        const Gap(8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: names
                              .map(
                                (n) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF243447),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    n,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      if (session.multitaskingScore != null) ...[
                        const Gap(8),
                        Text(
                          'Session attentiveness: ${session.multitaskingScore!.toStringAsFixed(0)}% (Account Lookup, guides, notes, and tool follow-through).',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                      if (session.topStrength.isNotEmpty) ...[
                        const Gap(6),
                        Text(
                          'Logged strength: ${session.topStrength}',
                          style: const TextStyle(
                            color: Color(0xFF34D399),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
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
