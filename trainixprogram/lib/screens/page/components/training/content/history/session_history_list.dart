import 'package:flutter/material.dart';
import 'package:trainixprogram/screens/report_ui/report_ui.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:trainixprogram/components/decoration/box_decoration.dart';
import 'package:trainixprogram/models/simulation_history.dart';
import 'package:trainixprogram/screens/session_report_screen.dart';
import 'package:trainixprogram/models/simulation_phase.dart';

class SessionHistoryList extends StatelessWidget {
  final SimulationMode? modeFilter;

  const SessionHistoryList({super.key, this.modeFilter});

  String get _title {
    switch (modeFilter) {
      case SimulationMode.chat:
        return 'Non-Voice Session History';
      case SimulationMode.voice:
        return 'Voice Session History';
      case SimulationMode.hybrid:
        return 'Voice Session History';
      case null:
        return 'All Sessions';
    }
  }

  String get _emptyHint {
    switch (modeFilter) {
      case SimulationMode.chat:
        return 'No non-voice sessions yet.\nStart one from Non-Voice under Sessions.';
      case SimulationMode.voice:
        return 'No voice sessions yet.\nStart one from Voice under Sessions.';
      case SimulationMode.hybrid:
        return 'No voice sessions yet.\nStart one from Voice under Sessions.';
      case null:
        return 'No sessions yet.\nStart a simulation from Non-Voice or Voice.';
    }
  }

  String _modeLabel(SimulationMode mode) {
    switch (mode) {
      case SimulationMode.chat:
        return 'Non-Voice';
      case SimulationMode.voice:
        return 'Voice';
      case SimulationMode.hybrid:
        return 'Voice';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const Gap(8),
          Text(
            modeFilter == null
                ? 'Past simulation runs from every mode.'
                : 'Past runs for this session type only.',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          const Gap(20),
          Expanded(
            child: Consumer<SimulationHistoryProvider>(
              builder: (context, history, _) {
                final source = modeFilter == null
                    ? history.sessions
                    : history.sessionsForMode(modeFilter!);
                if (source.isEmpty) {
                  return Center(
                    child: Text(
                      _emptyHint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  );
                }

                final reversed = source.reversed.toList();
                return ListView.builder(
                  itemCount: reversed.length,
                  itemBuilder: (_, index) {
                    final session = reversed[index];
                    final number = reversed.length - index;
                    final names = session.evaluations
                        .map((e) => e.customerName)
                        .where((n) => n.isNotEmpty)
                        .take(3)
                        .join(', ');
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
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        decoration: boxDecoration(
                          false,
                          true,
                          isDark:
                              Theme.of(context).brightness == Brightness.dark,
                        ),
                        child: Row(
                          children: [
                            Text(
                              '#$number',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const Gap(16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    session.sector.isEmpty
                                        ? 'Session'
                                        : session.sector,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Gap(4),
                                  Text(
                                    '${_modeLabel(session.mode)} · ${session.evaluations.length} customer(s)',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white54,
                                    ),
                                  ),
                                  if (names.isNotEmpty) ...[
                                    const Gap(4),
                                    Text(
                                      names,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  displayScore10(
                                    session.overallScore,
                                  ).toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: Color(0xFF70BD8A),
                                  ),
                                ),
                                const Text(
                                  'View report',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: Color(0xFF9CA3AF),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MessagesArchiveList extends StatelessWidget {
  const MessagesArchiveList({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Messages',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const Gap(6),
          const Text(
            'Saved chat and voice conversation stacks from completed customers.',
            style: TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const Gap(16),
          Expanded(
            child: Consumer<SimulationHistoryProvider>(
              builder: (context, history, _) {
                final items = history.evaluations
                    .where((e) => e.conversation.isNotEmpty)
                    .toList()
                    .reversed
                    .toList();
                if (items.isEmpty) {
                  return const Center(
                    child: Text(
                      'No saved conversations yet.\nComplete a simulation so message stacks appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, height: 1.4),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final e = items[i];
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                SessionReportScreen(evaluations: [e]),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: boxDecoration(
                          false,
                          true,
                          isDark:
                              Theme.of(context).brightness == Brightness.dark,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    e.customerName.isEmpty
                                        ? 'Customer'
                                        : e.customerName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Text(
                                  e.channel.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: e.channel == 'voice'
                                        ? const Color(0xFF70BD8A)
                                        : const Color(0xFF3B82F6),
                                  ),
                                ),
                              ],
                            ),
                            const Gap(4),
                            Text(
                              [
                                if (e.sector.isNotEmpty) e.sector,
                                if (e.problem.isNotEmpty) e.problem,
                              ].join(' · '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white54,
                              ),
                            ),
                            const Gap(8),
                            Text(
                              [
                                '${e.conversation.length} turns',
                                'score ${displayScore10(e.overallScore).toStringAsFixed(1)}',
                                if (e.customerRating != null)
                                  'CSAT ${e.customerRating}/5',
                              ].join(' · '),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                            if (e.customerComment != null &&
                                e.customerComment!.isNotEmpty) ...[
                              const Gap(4),
                              Text(
                                e.customerComment!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF9CA3AF),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
