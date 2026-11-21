import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:trainixprogram/models/session_score.dart';
import 'package:trainixprogram/models/simulation_history.dart';
import 'package:trainixprogram/models/simulation_phase.dart';
import 'package:trainixprogram/screens/report_ui/report_ui.dart';
import 'package:trainixprogram/screens/session_report_screen.dart';
import 'package:trainixprogram/widgets/user_facing_messages.dart';

class SessionHistoryList extends StatefulWidget {
  final SimulationMode? modeFilter;

  const SessionHistoryList({super.key, this.modeFilter});

  @override
  State<SessionHistoryList> createState() => _SessionHistoryListState();
}

class _SessionHistoryListState extends State<SessionHistoryList> {
  String _sectorFilter = 'All';
  String _guidedFilter = 'All';
  String _sort = 'Newest';

  String get _title {
    switch (widget.modeFilter) {
      case SimulationMode.chat:
        return 'Non-Voice Session History';
      case SimulationMode.voice:
        return 'Voice Session History';
      case null:
        return 'All Sessions';
    }
  }

  String get _emptyHint {
    switch (widget.modeFilter) {
      case SimulationMode.chat:
        return 'No non-voice sessions yet.\nStart one from Non-Voice under Sessions.';
      case SimulationMode.voice:
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
    }
  }

  Color _scoreColor(double score) {
    if (score >= 8.5) return AppColors.primaryText();
    if (score >= 7.0) return AppColors.secondaryText();
    if (score >= 5.0) return AppColors.warningText();
    return AppColors.errorStrongText();
  }

  String _scoreBand(double score) {
    if (score >= 8.5) return 'Excellent';
    if (score >= 7.0) return 'Good';
    if (score >= 5.0) return 'Developing';
    return 'Needs work';
  }

  List<PlayedSession> _applyFilters(List<PlayedSession> source) {
    var list = source.where((s) => !isDebugSession(s)).toList();
    if (_sectorFilter != 'All') {
      list = list.where((s) => s.sector == _sectorFilter).toList();
    }
    if (_guidedFilter == 'Guided') {
      list = list.where((s) => s.guidedMode).toList();
    } else if (_guidedFilter == 'Unguided') {
      list = list.where((s) => !s.guidedMode).toList();
    }
    switch (_sort) {
      case 'Oldest':
        list.sort((a, b) => a.completedAt.compareTo(b.completedAt));
        break;
      case 'Highest score':
        list.sort((a, b) => b.overallScore.compareTo(a.overallScore));
        break;
      case 'Lowest score':
        list.sort((a, b) => a.overallScore.compareTo(b.overallScore));
        break;
      case 'Newest':
      default:
        list.sort((a, b) => b.completedAt.compareTo(a.completedAt));
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _title,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const Gap(6),
          Text(
            widget.modeFilter == null
                ? 'Past simulation runs from every mode. Debug runs are hidden.'
                : 'Past runs for this session type only. Debug runs are hidden.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary(context),
              height: 1.4,
            ),
          ),
          const Gap(16),
          Consumer<SimulationHistoryProvider>(
            builder: (context, history, _) {
              final base = widget.modeFilter == null
                  ? history.sessions
                  : history.sessionsForMode(widget.modeFilter!);
              final sectors = <String>{
                'All',
                ...base
                    .where((s) => !isDebugSession(s) && s.sector.isNotEmpty)
                    .map((s) => s.sector),
              }.toList();
              final filtered = _applyFilters(base);

              return Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _filterChip(
                          label: 'Sector',
                          value: _sectorFilter,
                          options: sectors,
                          onChanged: (v) => setState(() => _sectorFilter = v),
                        ),
                        _filterChip(
                          label: 'Guidance',
                          value: _guidedFilter,
                          options: const ['All', 'Guided', 'Unguided'],
                          onChanged: (v) => setState(() => _guidedFilter = v),
                        ),
                        _filterChip(
                          label: 'Sort',
                          value: _sort,
                          options: const [
                            'Newest',
                            'Oldest',
                            'Highest score',
                            'Lowest score',
                          ],
                          onChanged: (v) => setState(() => _sort = v),
                        ),
                      ],
                    ),
                    const Gap(14),
                    if (filtered.isEmpty)
                      Expanded(
                        child: Center(
                          child: Text(
                            _emptyHint,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary(context),
                              height: 1.4,
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (_, index) {
                            final session = filtered[index];
                            final number = filtered.length - index;
                            final score = displayScore10(session.overallScore);
                            final color = _scoreColor(score);
                            final names = session.evaluations
                                .where((e) => !isDebugEvaluation(e))
                                .map(
                                  (e) => friendlyCustomerName(e.customerName),
                                )
                                .where((n) => n.isNotEmpty)
                                .toSet()
                                .take(4)
                                .join(', ');
                            return _sessionCard(
                              context: context,
                              session: session,
                              number: number,
                              score: score,
                              color: color,
                              names: names,
                            );
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.listBase(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(6),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: options.contains(value) ? value : options.first,
              dropdownColor: AppColors.card(context),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary(context),
                fontWeight: FontWeight.w600,
              ),
              items: options
                  .map(
                    (o) => DropdownMenuItem(
                      value: o,
                      child: Text(o),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sessionCard({
    required BuildContext context,
    required PlayedSession session,
    required int number,
    required double score,
    required Color color,
    required String names,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(14),
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
                  guidedMode: session.guidedMode,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.listBase(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(13),
                        bottomLeft: Radius.circular(13),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryWash(context),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Icon(
                                  session.mode == SimulationMode.voice
                                      ? Icons.mic_rounded
                                      : Icons.chat_bubble_outline_rounded,
                                  size: 18,
                                  color: AppColors.secondaryText(),
                                ),
                              ),
                              const Gap(10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      session.sector.isEmpty
                                          ? 'Session #$number'
                                          : '${session.sector}  ·  #$number',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: AppColors.textPrimary(context),
                                      ),
                                    ),
                                    const Gap(4),
                                    Text(
                                      '${_modeLabel(session.mode)} · ${session.evaluations.length} customer(s)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary(context),
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
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                      color: color,
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: color.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Text(
                                      _scoreBand(score),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Gap(10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _metaChip(
                                session.mode == SimulationMode.voice
                                    ? Icons.mic_rounded
                                    : Icons.chat_bubble_outline_rounded,
                                _modeLabel(session.mode),
                                session.mode == SimulationMode.voice
                                    ? AppColors.primaryText()
                                    : AppColors.secondaryText(),
                              ),
                              _metaChip(
                                session.guidedMode
                                    ? Icons.menu_book_outlined
                                    : Icons.school_outlined,
                                session.guidedMode ? 'Guided' : 'Unguided',
                                session.guidedMode
                                    ? AppColors.secondaryText()
                                    : AppColors.secondaryText(),
                              ),
                              if (score >= 7)
                                _metaChip(
                                  Icons.verified_outlined,
                                  'Pass bar met',
                                  AppColors.primaryText(),
                                ),
                            ],
                          ),
                          if (names.isNotEmpty) ...[
                            const Gap(10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: names.split(', ').map((n) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.card(context),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.border(context),
                                    ),
                                  ),
                                  child: Text(
                                    n,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary(context),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                          const Gap(8),
                          Row(
                            children: [
                              Text(
                                'View report',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary(context),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Gap(4),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 16,
                                color: AppColors.textSecondary(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const Gap(4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class MessagesArchiveList extends StatefulWidget {
  const MessagesArchiveList({super.key});

  @override
  State<MessagesArchiveList> createState() => _MessagesArchiveListState();
}

class _MessagesArchiveListState extends State<MessagesArchiveList> {
  String _channelFilter = 'All';
  String _sectorFilter = 'All';
  String _sort = 'Newest';

  Color _scoreColor(double score) {
    if (score >= 8.5) return AppColors.primaryText();
    if (score >= 7.0) return AppColors.secondaryText();
    if (score >= 5.0) return AppColors.warningText();
    return AppColors.errorStrongText();
  }

  List<SessionEvaluation> _applyFilters(List<SessionEvaluation> source) {
    var list = source
        .where((e) => e.conversation.isNotEmpty && !isDebugEvaluation(e))
        .toList();
    if (_channelFilter == 'Non-Voice') {
      list = list.where((e) => e.channel.toLowerCase() != 'voice').toList();
    } else if (_channelFilter == 'Voice') {
      list = list.where((e) => e.channel.toLowerCase() == 'voice').toList();
    }
    if (_sectorFilter != 'All') {
      list = list.where((e) => e.sector == _sectorFilter).toList();
    }
    switch (_sort) {
      case 'Oldest':
        list.sort((a, b) => a.evaluatedAt.compareTo(b.evaluatedAt));
        break;
      case 'Highest score':
        list.sort((a, b) => b.overallScore.compareTo(a.overallScore));
        break;
      case 'Lowest score':
        list.sort((a, b) => a.overallScore.compareTo(b.overallScore));
        break;
      case 'Newest':
      default:
        list.sort((a, b) => b.evaluatedAt.compareTo(a.evaluatedAt));
        break;
    }
    return list;
  }

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
          Text(
            'Saved chat and voice conversation stacks from completed customers.',
            style: TextStyle(
                fontSize: 13, color: AppColors.textSecondary(context)),
          ),
          const Gap(16),
          Expanded(
            child: Consumer<SimulationHistoryProvider>(
              builder: (context, history, _) {
                final all = history.evaluations
                    .where(
                      (e) => e.conversation.isNotEmpty && !isDebugEvaluation(e),
                    )
                    .toList();
                final sectors = <String>{
                  'All',
                  ...all.where((e) => e.sector.isNotEmpty).map((e) => e.sector),
                }.toList();
                final items = _applyFilters(history.evaluations);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _msgFilter(
                          'Channel',
                          _channelFilter,
                          const ['All', 'Non-Voice', 'Voice'],
                          (v) => setState(() => _channelFilter = v),
                        ),
                        _msgFilter(
                          'Sector',
                          _sectorFilter,
                          sectors,
                          (v) => setState(() => _sectorFilter = v),
                        ),
                        _msgFilter(
                          'Sort',
                          _sort,
                          const [
                            'Newest',
                            'Oldest',
                            'Highest score',
                            'Lowest score',
                          ],
                          (v) => setState(() => _sort = v),
                        ),
                      ],
                    ),
                    const Gap(14),
                    if (items.isEmpty)
                      Expanded(
                        child: Center(
                          child: Text(
                            'No saved conversations yet.\nComplete a simulation so message stacks appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary(context),
                              height: 1.4,
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (_, i) {
                            final e = items[i];
                            final score = displayScore10(e.overallScore);
                            final color = _scoreColor(score);
                            final isVoice = e.channel.toLowerCase() == 'voice';
                            return MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  mouseCursor: SystemMouseCursors.click,
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SessionReportScreen(
                                          evaluations: [e],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.listBase(context),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: AppColors.border(context),
                                      ),
                                      boxShadow: AppColors.cardShadow(
                                        context,
                                        blur: 12,
                                        offset: const Offset(0, 3),
                                      ),
                                    ),
                                    child: IntrinsicHeight(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Container(
                                            width: 4,
                                            decoration: BoxDecoration(
                                              color: color,
                                              borderRadius:
                                                  const BorderRadius.only(
                                                topLeft: Radius.circular(13),
                                                bottomLeft: Radius.circular(13),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.all(14),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          e.customerName.isEmpty
                                                              ? 'Customer'
                                                              : friendlyCustomerName(
                                                                  e.customerName,
                                                                ),
                                                          style:
                                                              const TextStyle(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            fontSize: 15,
                                                          ),
                                                        ),
                                                      ),
                                                      Text(
                                                        score
                                                            .toStringAsFixed(1),
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          fontSize: 16,
                                                          color: color,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const Gap(8),
                                                  Wrap(
                                                    spacing: 8,
                                                    runSpacing: 6,
                                                    children: [
                                                      _msgChip(
                                                        isVoice
                                                            ? Icons.mic_rounded
                                                            : Icons
                                                                .chat_bubble_outline_rounded,
                                                        isVoice
                                                            ? 'VOICE'
                                                            : 'CHAT',
                                                        isVoice
                                                            ? AppColors
                                                                .primaryText()
                                                            : AppColors
                                                                .secondaryText(),
                                                      ),
                                                      if (e.sector.isNotEmpty)
                                                        _msgChip(
                                                          Icons
                                                              .apartment_rounded,
                                                          e.sector,
                                                          AppColors.textMuted(
                                                              context),
                                                        ),
                                                      _msgChip(
                                                        Icons.forum_outlined,
                                                        '${e.conversation.length} turns',
                                                        AppColors
                                                            .secondaryText(),
                                                      ),
                                                    ],
                                                  ),
                                                  if (e.problem.isNotEmpty) ...[
                                                    const Gap(8),
                                                    Text(
                                                      e.problem,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: AppColors
                                                            .textSecondary(
                                                                context),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _msgFilter(
    String label,
    String value,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.listBase(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(6),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: options.contains(value) ? value : options.first,
              dropdownColor: AppColors.card(context),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary(context),
                fontWeight: FontWeight.w600,
              ),
              items: options
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _msgChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const Gap(4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
