import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';
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
    if (score >= strongBar) return AppColors.primaryText();
    if (score >= passBar) return AppColors.secondaryText();
    if (score >= 5) return AppColors.warningText();
    return AppColors.errorStrongText();
  }

  String _band(double score) {
    if (score >= strongBar) return 'Excellent';
    if (score >= passBar) return 'Good';
    if (score >= 5) return 'Developing';
    return 'Needs work';
  }

  IconData _sectorIcon(String sector) {
    final s = sector.toLowerCase();
    if (s.contains('telco') || s.contains('telecom')) {
      return Icons.cell_tower_rounded;
    }
    if (s.contains('finance') || s.contains('bank')) {
      return Icons.account_balance_rounded;
    }
    if (s.contains('health')) return Icons.local_hospital_outlined;
    if (s.contains('tech') || s.contains('support')) {
      return Icons.support_agent_rounded;
    }
    return Icons.business_center_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SimulationHistoryProvider>(
      builder: (context, history, _) {
        final liveSessions =
            history.sessions.where((s) => !isDebugSession(s)).toList();
        final liveEvals =
            history.evaluations.where((e) => !isDebugEvaluation(e)).toList();

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
                        color: AppColors.listBase(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.border(context),
                        ),
                      ),
                      child: Icon(
                        Icons.hub_outlined,
                        size: 36,
                        color: AppColors.textMuted(context),
                      ),
                    ),
                    const Gap(16),
                    Text(
                      'Sector fit not ready',
                      style: TextStyle(
                        color: AppColors.textPrimary(context),
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const Gap(8),
                    Text(
                      'Needs at least $minSessions real practice sessions so averages are stable enough to compare.\nYou have ${liveSessions.length} so far. Debug and sample runs do not count.',
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
          return Center(
            child: Text(
              'No sector-tagged practice scores yet.',
              style: TextStyle(color: AppColors.textSecondary(context)),
            ),
          );
        }

        final averages = <String, double>{
          for (final entry in bySector.entries)
            entry.key: entry.value.reduce((a, b) => a + b) / entry.value.length,
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
            ? AppColors.primaryText()
            : confidence == 'Moderate'
                ? AppColors.secondaryText()
                : AppColors.warningText();

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
                        color: AppColors.listBase(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primaryText().withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.emoji_events_outlined,
                                size: 20,
                                color: AppColors.primaryText(),
                              ),
                              Gap(8),
                              Text(
                                'Recommended sector fit',
                                style: TextStyle(
                                  color: AppColors.textPrimary(context),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const Gap(8),
                          Text(
                            recommended,
                            style: TextStyle(
                              color: AppColors.primaryText(),
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
                                context,
                                Icons.speed_rounded,
                                'Lead average',
                                '${recAvg.toStringAsFixed(2)} / 10',
                                _c(recAvg),
                              ),
                              _statChip(
                                context,
                                Icons.people_outline_rounded,
                                'Sample size',
                                '$recCount customers',
                                AppColors.secondaryText(),
                              ),
                              _statChip(
                                context,
                                Icons.verified_outlined,
                                'Pass rate',
                                '${(recPassRate * 100).toStringAsFixed(0)}%',
                                AppColors.secondaryText(),
                              ),
                              _statChip(
                                context,
                                Icons.stacked_bar_chart_rounded,
                                'Spread',
                                '${spread.toStringAsFixed(2)} pts',
                                AppColors.secondaryText(),
                              ),
                              _statChip(
                                context,
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
                            style: TextStyle(
                              color: AppColors.textSecondary(context),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(14),
                    _sectionCard(
                      context: context,
                      icon: Icons.rule_folder_outlined,
                      iconColor: AppColors.secondaryText(),
                      title: 'Formula and rules',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sector score = mean of overall scores for every real scored customer in that sector.',
                            style: TextStyle(
                              color: AppColors.textSecondary(context),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const Gap(8),
                          Text(
                            'Recommended sector = sector with the highest sector score. If two sectors tie on average, the larger sample wins.',
                            style: TextStyle(
                              color: AppColors.textSecondary(context),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const Gap(10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.listBase(context),
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: AppColors.border(context)),
                            ),
                            child: Text(
                              'sector_score(S) = sum(overall of customers in S) / count(customers in S)\n'
                              'recommend = argmax over S of sector_score(S)\n'
                              'Debug and sample runs are excluded from every total.',
                              style: TextStyle(
                                color: AppColors.textSecondary(context),
                                fontSize: 12,
                                height: 1.45,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          const Gap(10),
                          Text(
                            'This is a practice ranking only. It is not a TESDA grade, hiring decision, or certification result.',
                            style: TextStyle(
                              color: AppColors.textMuted(context),
                              fontSize: 11,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(14),
                    _sectionCard(
                      context: context,
                      icon: Icons.calculate_outlined,
                      iconColor: AppColors.secondaryText(),
                      title: 'Computation for your data',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Using ${liveSessions.length} real sessions and ${liveEvals.length} scored customers after debug filtering.',
                            style: TextStyle(
                              color: AppColors.textSecondary(context),
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
                                color: AppColors.listBase(context),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isTop
                                      ? AppColors.primaryText()
                                          .withValues(alpha: 0.5)
                                      : AppColors.border(context),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _sectorIcon(e.key),
                                        size: 18,
                                        color: isTop
                                            ? AppColors.primaryText()
                                            : AppColors.secondaryText(),
                                      ),
                                      const Gap(8),
                                      Expanded(
                                        child: Text(
                                          e.key,
                                          style: TextStyle(
                                            color:
                                                AppColors.textPrimary(context),
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
                                            color: AppColors.primaryText()
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: AppColors.primaryText(),
                                            ),
                                          ),
                                          child: Text(
                                            'WINNER',
                                            style: TextStyle(
                                              color: AppColors.primaryText(),
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
                                    style: TextStyle(
                                      color: AppColors.textSecondary(context),
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
                      context: context,
                      icon: Icons.help_outline_rounded,
                      iconColor: AppColors.warningText(),
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
                                  Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Icon(
                                      Icons.check_circle_outline,
                                      size: 14,
                                      color: AppColors.primaryText(),
                                    ),
                                  ),
                                  const Gap(8),
                                  Expanded(
                                    child: Text(
                                      line,
                                      style: TextStyle(
                                        color: AppColors.textSecondary(context),
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
                      context: context,
                      icon: Icons.psychology_outlined,
                      iconColor: AppColors.secondaryText(),
                      title: 'General analysis',
                      child: Text(
                        analysis.toString(),
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const Gap(14),
                    _sectionCard(
                      context: context,
                      icon: Icons.menu_book_outlined,
                      iconColor: AppColors.secondaryText(),
                      title: 'How to read the ranking',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _rubricRow(
                            context,
                            '9.0 – 10.0',
                            'Excellent sector average',
                            AppColors.primaryText(),
                          ),
                          _rubricRow(
                            context,
                            '7.0 – 8.4',
                            'Good / practice pass band',
                            AppColors.secondaryText(),
                          ),
                          _rubricRow(
                            context,
                            '5.0 – 6.9',
                            'Developing — keep guided practice',
                            AppColors.warningText(),
                          ),
                          _rubricRow(
                            context,
                            '0.0 – 4.9',
                            'Needs work — prioritize fundamentals',
                            AppColors.errorStrongText(),
                          ),
                          const Gap(8),
                          Text(
                            'Overall per customer is still the mean of the 10 skill scores on that interaction. Sector fit only averages those customer overalls by sector tag.',
                            style: TextStyle(
                              color: AppColors.textSecondary(context),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(14),
                    Row(
                      children: [
                        Icon(
                          Icons.hub_outlined,
                          size: 18,
                          color: AppColors.secondaryText(),
                        ),
                        Gap(8),
                        Text(
                          'Sector readiness ranking',
                          style: TextStyle(
                            color: AppColors.textPrimary(context),
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
                          color: AppColors.listBase(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isTop
                                ? AppColors.primaryText()
                                : AppColors.border(context),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _sectorIcon(e.key),
                                  size: 18,
                                  color: isTop
                                      ? AppColors.primaryText()
                                      : AppColors.secondaryText(),
                                ),
                                const Gap(8),
                                Expanded(
                                  child: Text(
                                    e.key,
                                    style: TextStyle(
                                      color: AppColors.textPrimary(context),
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
                                      color: AppColors.primaryText()
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppColors.primaryText(),
                                      ),
                                    ),
                                    child: Text(
                                      'TOP FIT',
                                      style: TextStyle(
                                        color: AppColors.primaryText(),
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
                                backgroundColor: AppColors.border(context),
                                color: color,
                              ),
                            ),
                            const Gap(6),
                            Text(
                              '$n customers · $passPct% ≥ $passBar · ${_band(e.value)}',
                              style: TextStyle(
                                color: AppColors.textMuted(context),
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

  Widget _statChip(BuildContext context, IconData icon, String label,
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
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.listBase(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
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
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
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

  Widget _rubricRow(
      BuildContext context, String range, String meaning, Color color) {
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
              style: TextStyle(
                color: AppColors.textSecondary(context),
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
