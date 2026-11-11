import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:trainixprogram/components/class/live_training_session.dart';
import 'package:trainixprogram/models/simulation_history.dart';
import 'package:trainixprogram/screens/page/profile.dart';
import 'package:trainixprogram/screens/session_report_screen.dart';
import 'package:trainixprogram/widgets/user_facing_messages.dart';

Color _scoreColor(double score) {
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

class LiveCoachingHistoryPanel extends StatefulWidget {
  const LiveCoachingHistoryPanel({super.key});

  @override
  State<LiveCoachingHistoryPanel> createState() =>
      _LiveCoachingHistoryPanelState();
}

class _LiveCoachingHistoryPanelState extends State<LiveCoachingHistoryPanel> {
  @override
  void initState() {
    super.initState();
    LiveSessionStore.instance.addListener(_onLive);
    LiveSessionStore.instance.loadFromRemote();
  }

  @override
  void dispose() {
    LiveSessionStore.instance.removeListener(_onLive);
    super.dispose();
  }

  void _onLive() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final liveEntries = LiveSessionStore.instance.historyForTrainee(
      ProfileData.displayName,
    );

    if (liveEntries.isEmpty) {
      return const Center(
        child: Text(
          'No live coaching sessions yet.\nWhen a trainer ends a room with you, the rating, notes, and feedback appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, height: 1.4),
        ),
      );
    }

    return _DashboardScroll(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF15201A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF2E4A38)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F3D2C),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'LIVE COACHING',
                      style: TextStyle(
                        color: Color(0xFF70BD8A),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const Gap(10),
                  Text(
                    '${liveEntries.length} session(s)',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
              const Gap(8),
              const Text(
                'One-on-one rooms with a trainer. Score is a 1-5 star rating from the trainer, not the 0-10 simulation scale.',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const Gap(12),
        ...liveEntries.map((e) {
          final rating = e.rating;
          final color = rating == null
              ? Colors.white54
              : _scoreColor(rating * 2.0);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF15201A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2E4A38)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    Text(
                      e.roomName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...List.generate(5, (i) {
                          final on = rating != null && rating > i;
                          return Icon(
                            on
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 16,
                            color: on ? color : Colors.white24,
                          );
                        }),
                        const Gap(6),
                        Text(
                          rating != null ? '$rating / 5' : 'No rating',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Gap(6),
                Text(
                  'With ${e.trainerName} · ${e.mode.name} · ${_when(e.endedAt)}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                if (e.feedback.trim().isNotEmpty) ...[
                  const Gap(10),
                  const Text(
                    'Trainer feedback',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(3),
                  Text(
                    e.feedback.trim(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
                if (e.takeaway.trim().isNotEmpty) ...[
                  const Gap(8),
                  Text(
                    'Key takeaway: ${e.takeaway.trim()}',
                    style: const TextStyle(
                      color: Color(0xFF70BD8A),
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
                if (e.notes.any((n) => n.body.trim().isNotEmpty)) ...[
                  const Gap(8),
                  const Text(
                    'Trainer notes',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(3),
                  ...e.notes
                      .where((n) => n.body.trim().isNotEmpty)
                      .take(3)
                      .map(
                        (n) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            '• ${n.title.isEmpty ? "Note" : n.title}: ${n.body.trim()}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                ],
                if (e.checklist.isNotEmpty) ...[
                  const Gap(10),
                  const Text(
                    'Checklist',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(4),
                  ...e.checklist.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            c.done
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                            size: 16,
                            color: c.done
                                ? const Color(0xFF70BD8A)
                                : Colors.white38,
                          ),
                          const Gap(8),
                          Expanded(
                            child: Text(
                              c.label,
                              style: TextStyle(
                                color: c.done
                                    ? Colors.white70
                                    : Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (e.needsFollowUp)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Follow-up needed',
                        style: TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ] else if (e.checklistTotal > 0) ...[
                  const Gap(8),
                  Text(
                    'Checklist ${e.checklistDone}/${e.checklistTotal}'
                    '${e.needsFollowUp ? " · follow-up needed" : ""}',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}

class SimulationHistoryPanel extends StatelessWidget {
  const SimulationHistoryPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SimulationHistoryProvider>(
      builder: (context, history, _) {
        final items = history.sessions
            .where((s) => !isDebugSession(s))
            .toList();
        final avg = items.isEmpty
            ? 0.0
            : items.map((s) => s.overallScore).reduce((a, b) => a + b) /
                  items.length;
        final passCount = items.where((s) => s.overallScore >= 7).length;

        if (items.isEmpty) {
          return const Center(
            child: Text(
              'No simulation runs yet.\nCompleted chat and voice practice sessions appear here with 0-10 scores.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, height: 1.4),
            ),
          );
        }

        return _DashboardScroll(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Container(
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2A3A),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'SIMULATION',
                          style: TextStyle(
                            color: Color(0xFF60A5FA),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const Gap(10),
                      Text(
                        '${items.length} run(s)',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Gap(8),
                  Text(
                    'Practice runs scored 0-10. Average ${avg.toStringAsFixed(1)} · $passCount at or above pass bar. Tap a row for the full report.',
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
              final color = _scoreColor(score);
              final names = session.evaluations
                  .map((e) => friendlyCustomerName(e.customerName))
                  .where((n) => n.isNotEmpty)
                  .toSet()
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
                        averageTypingWpm: session.averageTypingWpm,
                        averageWpm: session.averageSpeakingWpm,
                        fillerWordCount: session.fillerWordCount,
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
                                    color: const Color(0xFF243041),
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
                          'Session attentiveness: ${session.multitaskingScore!.toStringAsFixed(0)}% (tools, notes, and follow-through; Account Lookup only when required).',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                      if (friendlyEvalText(session.topStrength).isNotEmpty) ...[
                        const Gap(6),
                        Text(
                          'Logged strength: ${friendlyEvalText(session.topStrength)}',
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

class SessionHistoryPanel extends StatelessWidget {
  const SessionHistoryPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F26),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A323C)),
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
                  Tab(text: 'Live Coaching'),
                  Tab(text: 'Simulation'),
                ],
              ),
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [LiveCoachingHistoryPanel(), SimulationHistoryPanel()],
            ),
          ),
        ],
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
