import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:trainixprogram/components/class/live_training_session.dart';
import 'package:trainixprogram/models/session_score.dart';
import 'package:trainixprogram/models/simulation_history.dart';
import 'package:trainixprogram/screens/page/profile.dart';
import 'package:trainixprogram/screens/session_report_screen.dart';
import 'package:trainixprogram/widgets/user_facing_messages.dart';

Color _scoreColor(double score) {
  if (score >= 8.5) return AppColors.primaryText();
  if (score >= 7) return AppColors.secondaryText();
  if (score >= 5) return AppColors.warningText();
  return AppColors.errorStrongText();
}

String _when(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

String _levelLabel(double score) {
  if (score >= 8.5) return 'Excellent';
  if (score >= 7) return 'Good';
  if (score >= 5) return 'Developing';
  return 'Needs work';
}

Widget _iconChip(
    BuildContext context, IconData icon, String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.45)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const Gap(4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

Widget _emptyState({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String body,
}) {
  return Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.listBase(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.border(context),
                ),
              ),
              child: Icon(icon, size: 36, color: AppColors.textMuted(context)),
            ),
            const Gap(16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const Gap(8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary(context),
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
      return _emptyState(
        context: context,
        icon: Icons.groups_outlined,
        title: 'No live coaching yet',
        body:
            'When a trainer ends a room with you, the star rating, feedback, checklist, and notes appear here.',
      );
    }

    final rated = liveEntries.where((e) => e.rating != null).toList();
    final avgRating = rated.isEmpty
        ? null
        : rated.map((e) => e.rating!).reduce((a, b) => a + b) / rated.length;
    final followUps = liveEntries.where((e) => e.needsFollowUp).length;

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
                    color: AppColors.listBase(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primaryText().withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.groups_outlined,
                            size: 20,
                            color: AppColors.primaryText(),
                          ),
                          Gap(8),
                          Text(
                            'Live coaching history',
                            style: TextStyle(
                              color: AppColors.textPrimary(context),
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const Gap(6),
                      Text(
                        'One-on-one trainer rooms. Ratings use a 1-5 star scale from the trainer, not the 0-10 simulation score.',
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      const Gap(14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _summaryChip(
                            Icons.event_available_outlined,
                            'Sessions',
                            '${liveEntries.length}',
                            AppColors.primaryText(),
                          ),
                          _summaryChip(
                            Icons.star_rounded,
                            'Avg rating',
                            avgRating == null
                                ? '—'
                                : '${avgRating.toStringAsFixed(1)}/5',
                            AppColors.warningText(),
                          ),
                          _summaryChip(
                            Icons.flag_outlined,
                            'Follow-ups',
                            '$followUps',
                            AppColors.warningText(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Gap(14),
                ...liveEntries.map((e) => _LiveSessionCard(entry: e)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryChip(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.listBase(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
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
                style: TextStyle(
                  color: AppColors.textMuted(context),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveSessionCard extends StatelessWidget {
  final LiveTrainingHistoryEntry entry;

  const _LiveSessionCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final rating = entry.rating;
    final color = rating == null
        ? AppColors.textMuted(context)
        : _scoreColor(rating * 2.0);

    return Container(
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
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.roomName.isEmpty
                                    ? 'Live room'
                                    : entry.roomName,
                                style: TextStyle(
                                  color: AppColors.textPrimary(context),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const Gap(4),
                              Text(
                                'With ${entry.trainerName} · ${_when(entry.endedAt)}',
                                style: TextStyle(
                                  color: AppColors.textSecondary(context),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(5, (i) {
                                final on = rating != null && rating > i;
                                return Icon(
                                  on
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  size: 16,
                                  color: on
                                      ? color
                                      : AppColors.borderStrong(context),
                                );
                              }),
                            ),
                            const Gap(4),
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
                    const Gap(10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _iconChip(
                          context,
                          Icons.tune_rounded,
                          entry.mode.name.toUpperCase(),
                          AppColors.primaryText(),
                        ),
                        if (entry.checklistTotal > 0)
                          _iconChip(
                            context,
                            Icons.checklist_rounded,
                            '${entry.checklistDone}/${entry.checklistTotal} checklist',
                            AppColors.secondaryText(),
                          ),
                        if (entry.noteCount > 0 ||
                            entry.notes.any((n) => n.body.trim().isNotEmpty))
                          _iconChip(
                            context,
                            Icons.sticky_note_2_outlined,
                            '${entry.noteCount > 0 ? entry.noteCount : entry.notes.where((n) => n.body.trim().isNotEmpty).length} notes',
                            AppColors.secondaryText(),
                          ),
                        if (entry.needsFollowUp)
                          _iconChip(
                            context,
                            Icons.flag_outlined,
                            'Follow-up',
                            AppColors.warningText(),
                          ),
                      ],
                    ),
                    if (entry.feedback.trim().isNotEmpty) ...[
                      const Gap(12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.listBase(context),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.record_voice_over_outlined,
                                  size: 14,
                                  color: AppColors.textSecondary(context),
                                ),
                                Gap(6),
                                Text(
                                  'Trainer feedback',
                                  style: TextStyle(
                                    color: AppColors.textSecondary(context),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const Gap(6),
                            Text(
                              entry.feedback.trim(),
                              style: TextStyle(
                                color: AppColors.textSecondary(context),
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (entry.takeaway.trim().isNotEmpty) ...[
                      const Gap(10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.nextTint(context),
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: AppColors.nextTint(context)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lightbulb_outline_rounded,
                              size: 16,
                              color: AppColors.primaryText(),
                            ),
                            const Gap(8),
                            Expanded(
                              child: Text(
                                entry.takeaway.trim(),
                                style: TextStyle(
                                  color: AppColors.primaryText(),
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (entry.notes.any((n) => n.body.trim().isNotEmpty)) ...[
                      const Gap(10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.listBase(context),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.sticky_note_2_outlined,
                                  size: 14,
                                  color: AppColors.secondaryText(),
                                ),
                                const Gap(6),
                                Text(
                                  'Trainer notes (${entry.notes.where((n) => n.body.trim().isNotEmpty).length})',
                                  style: TextStyle(
                                    color: AppColors.secondaryText(),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const Gap(8),
                            ...entry.notes
                                .where((n) => n.body.trim().isNotEmpty)
                                .map(
                                  (n) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          n.title.trim().isEmpty
                                              ? 'Note'
                                              : n.title.trim(),
                                          style: TextStyle(
                                            color: AppColors.textSecondary(
                                                context),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const Gap(2),
                                        Text(
                                          n.body.trim(),
                                          style: TextStyle(
                                            color: AppColors.textSecondary(
                                                context),
                                            fontSize: 12,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ],
                    if (entry.checklist.isNotEmpty) ...[
                      const Gap(8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: entry.checklist.take(6).map((item) {
                          final done = item.done;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: done
                                  ? AppColors.primaryText()
                                      .withValues(alpha: 0.12)
                                  : AppColors.listBase(context),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: done
                                    ? AppColors.primaryText()
                                        .withValues(alpha: 0.45)
                                    : AppColors.border(context),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  done
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked,
                                  size: 12,
                                  color: done
                                      ? AppColors.primaryText()
                                      : AppColors.textMuted(context),
                                ),
                                const Gap(4),
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    color: done
                                        ? AppColors.primaryText()
                                        : AppColors.textSecondary(context),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SimulationHistoryPanel extends StatelessWidget {
  const SimulationHistoryPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SimulationHistoryProvider>(
      builder: (context, history, _) {
        final items =
            history.sessions.where((s) => !isDebugSession(s)).toList();
        final avg = items.isEmpty
            ? 0.0
            : items.map((s) => s.overallScore).reduce((a, b) => a + b) /
                items.length;
        final passCount = items.where((s) => s.overallScore >= 7).length;
        final best = items.isEmpty
            ? 0.0
            : items.map((s) => s.overallScore).reduce((a, b) => a > b ? a : b);

        if (items.isEmpty) {
          return _emptyState(
            context: context,
            icon: Icons.smart_toy_outlined,
            title: 'No simulation runs yet',
            body:
                'Completed Non-Voice and Voice practice sessions appear here with 0-10 scores. Debug runs are hidden.',
          );
        }

        final recent = items.take(12).toList().reversed.toList();
        final skillAverages = <String, double>{};
        final skillKeys = <String, double Function(SessionEvaluation)>{
          'Opening Spiel': (e) => e.openingSpielScore,
          'Empathy': (e) => e.empathyScore,
          'Active Listening': (e) => e.activeListeningScore,
          'Problem Identification': (e) => e.problemIdentificationScore,
          'Solution Delivery': (e) => e.solutionDeliveryScore,
          'Tone': (e) => e.toneScore,
          'Closing Spiel': (e) => e.closingSpielScore,
        };
        for (final entry in skillKeys.entries) {
          final vals = <double>[];
          for (final s in items) {
            for (final e in s.evaluations) {
              if (isDebugEvaluation(e)) continue;
              vals.add(entry.value(e));
            }
          }
          if (vals.isNotEmpty) {
            skillAverages[entry.key] =
                vals.reduce((a, b) => a + b) / vals.length;
          }
        }
        final weakSkills = skillAverages.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));
        final topWeak = weakSkills.take(3).where((e) => e.value < 8.5).toList();

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
                        color: AppColors.listBase(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              AppColors.secondaryText().withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.smart_toy_outlined,
                                size: 20,
                                color: AppColors.secondaryText(),
                              ),
                              Gap(8),
                              Text(
                                'Simulation history',
                                style: TextStyle(
                                  color: AppColors.textPrimary(context),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const Gap(6),
                          Text(
                            'Real practice runs scored 0-10. Debug and sample sessions are excluded. Tap a card to open the full session report.',
                            style: TextStyle(
                              color: AppColors.textSecondary(context),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                          const Gap(14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _simChip(
                                context,
                                Icons.play_circle_outline_rounded,
                                'Runs',
                                '${items.length}',
                                AppColors.secondaryText(),
                              ),
                              _simChip(
                                context,
                                Icons.analytics_outlined,
                                'Average',
                                avg.toStringAsFixed(1),
                                _scoreColor(avg),
                              ),
                              _simChip(
                                context,
                                Icons.verified_outlined,
                                'Pass rate',
                                '${items.isEmpty ? 0 : ((passCount / items.length) * 100).round()}%',
                                AppColors.secondaryText(),
                              ),
                              _simChip(
                                context,
                                Icons.emoji_events_outlined,
                                'Best',
                                best.toStringAsFixed(1),
                                AppColors.primaryText(),
                              ),
                            ],
                          ),
                          if (recent.length >= 2) ...[
                            const Gap(16),
                            Row(
                              children: [
                                Icon(
                                  Icons.show_chart_rounded,
                                  size: 16,
                                  color: AppColors.secondaryText(),
                                ),
                                Gap(6),
                                Text(
                                  'Score trend (older → newer)',
                                  style: TextStyle(
                                    color: AppColors.textSecondary(context),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const Gap(10),
                            SizedBox(
                              height: 88,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  for (var i = 0; i < recent.length; i++) ...[
                                    if (i > 0) const Gap(5),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            recent[i]
                                                .overallScore
                                                .toStringAsFixed(1),
                                            style: TextStyle(
                                              color: _scoreColor(
                                                recent[i].overallScore,
                                              ),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const Gap(4),
                                          Container(
                                            height: (recent[i].overallScore /
                                                    10.0 *
                                                    56)
                                                .clamp(6.0, 56.0),
                                            decoration: BoxDecoration(
                                              color: _scoreColor(
                                                recent[i].overallScore,
                                              ).withValues(alpha: 0.9),
                                              borderRadius:
                                                  BorderRadius.circular(5),
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
                          if (topWeak.isNotEmpty) ...[
                            const Gap(14),
                            Row(
                              children: [
                                Icon(
                                  Icons.flag_outlined,
                                  size: 16,
                                  color: AppColors.warningText(),
                                ),
                                Gap(6),
                                Text(
                                  'Focus areas across history',
                                  style: TextStyle(
                                    color: AppColors.textSecondary(context),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const Gap(8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: topWeak.map((e) {
                                final c = _scoreColor(e.value);
                                return _iconChip(
                                  context,
                                  Icons.trending_down_rounded,
                                  '${e.key}: ${e.value.toStringAsFixed(1)}',
                                  c,
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Gap(14),
                    Row(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 18,
                          color: AppColors.textSecondary(context),
                        ),
                        Gap(8),
                        Text(
                          'Past sessions',
                          style: TextStyle(
                            color: AppColors.textPrimary(context),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const Gap(10),
                    ...items.asMap().entries.map((entry) {
                      final i = entry.key;
                      final session = entry.value;
                      final number = items.length - i;
                      return _SimulationSessionCard(
                        session: session,
                        number: number,
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

  Widget _simChip(BuildContext context, IconData icon, String label,
      String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.listBase(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
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
                style: TextStyle(
                  color: AppColors.textMuted(context),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SimulationSessionCard extends StatelessWidget {
  final PlayedSession session;
  final int number;

  const _SimulationSessionCard({
    required this.session,
    required this.number,
  });

  @override
  Widget build(BuildContext context) {
    final score = session.overallScore;
    final color = _scoreColor(score);
    final level = _levelLabel(score);
    final mode = session.mode.name.toLowerCase() == 'voice' ? 'VOICE' : 'CHAT';
    final isVoice = mode == 'VOICE';
    final names = session.evaluations
        .map((e) => friendlyCustomerName(e.customerName))
        .where((n) => n.isNotEmpty)
        .toSet()
        .toList();
    final channels = session.evaluations.map((e) => e.channel).toSet().toList();
    final strength = friendlyEvalText(session.topStrength);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MouseRegion(
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
              decoration: BoxDecoration(
                color: AppColors.listBase(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.border(context),
                ),
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
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Session #$number · ${session.sector.isEmpty ? "Mixed sectors" : session.sector}',
                                        style: TextStyle(
                                          color: AppColors.textPrimary(context),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const Gap(3),
                                      Text(
                                        '${session.evaluations.length} customer${session.evaluations.length == 1 ? "" : "s"} · ${_when(session.completedAt)}',
                                        style: TextStyle(
                                          color:
                                              AppColors.textSecondary(context),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          score.toStringAsFixed(1),
                                          style: TextStyle(
                                            color: color,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 20,
                                            height: 1,
                                          ),
                                        ),
                                        Text(
                                          ' /10',
                                          style: TextStyle(
                                            color: AppColors.textMuted(context),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Gap(4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: color),
                                      ),
                                      child: Text(
                                        level,
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Gap(6),
                                Icon(
                                  Icons.chevron_right,
                                  color: AppColors.textMuted(context),
                                  size: 20,
                                ),
                              ],
                            ),
                            const Gap(10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _iconChip(
                                  context,
                                  isVoice
                                      ? Icons.mic_rounded
                                      : Icons.chat_bubble_outline_rounded,
                                  mode,
                                  isVoice
                                      ? AppColors.primaryText()
                                      : AppColors.secondaryText(),
                                ),
                                _iconChip(
                                  context,
                                  session.guidedMode
                                      ? Icons.menu_book_outlined
                                      : Icons.school_outlined,
                                  session.guidedMode ? 'Guided' : 'Unguided',
                                  session.guidedMode
                                      ? AppColors.secondaryText()
                                      : AppColors.secondaryText(),
                                ),
                                if (session.sector.isNotEmpty)
                                  _iconChip(
                                    context,
                                    Icons.category_outlined,
                                    session.sector,
                                    AppColors.textMuted(context),
                                  ),
                                if (channels.length > 1)
                                  _iconChip(
                                    context,
                                    Icons.layers_outlined,
                                    channels.join(' / ').toUpperCase(),
                                    AppColors.secondaryText(),
                                  ),
                                _iconChip(
                                  context,
                                  score >= 7
                                      ? Icons.verified_outlined
                                      : Icons.priority_high_rounded,
                                  score >= 7
                                      ? 'Pass bar met'
                                      : 'Below pass bar',
                                  score >= 7
                                      ? AppColors.primaryText()
                                      : AppColors.warningText(),
                                ),
                              ],
                            ),
                            if (names.isNotEmpty) ...[
                              const Gap(10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: names
                                    .take(4)
                                    .map(
                                      (n) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.listBase(context),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: AppColors.border(context),
                                          ),
                                        ),
                                        child: Text(
                                          n,
                                          style: TextStyle(
                                            color: AppColors.textSecondary(
                                                context),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                            const Gap(10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (score / 10).clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: AppColors.border(context),
                                color: color,
                              ),
                            ),
                            if (strength.isNotEmpty) ...[
                              const Gap(10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 14,
                                    color: AppColors.primaryText(),
                                  ),
                                  const Gap(6),
                                  Expanded(
                                    child: Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'Strength: ',
                                            style: TextStyle(
                                              color: AppColors.primaryText(),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              height: 1.35,
                                            ),
                                          ),
                                          TextSpan(
                                            text: strength,
                                            style: TextStyle(
                                              color: AppColors.primaryText(),
                                              fontSize: 12,
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
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
      ),
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
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.listBase(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.border(context),
                    ),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      color: AppColors.completeTint(context),
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: AppColors.primaryText(),
                    unselectedLabelColor: AppColors.textMuted(context),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    tabs: [
                      Tab(
                        height: 40,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.groups_outlined, size: 16),
                            SizedBox(width: 6),
                            Text('Live Coaching'),
                          ],
                        ),
                      ),
                      Tab(
                        height: 40,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.smart_toy_outlined, size: 16),
                            SizedBox(width: 6),
                            Text('Simulation'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                LiveCoachingHistoryPanel(),
                SimulationHistoryPanel(),
              ],
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
