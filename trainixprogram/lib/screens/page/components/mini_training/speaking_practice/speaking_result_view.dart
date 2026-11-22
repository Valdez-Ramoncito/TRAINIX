import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/components/app_colors.dart';
import 'package:trainixprogram/models/scoring_transparency.dart';
import 'package:trainixprogram/models/training/speaking/speaking_prompt.dart';
import 'package:trainixprogram/models/training/speaking/speaking_result.dart';
import 'package:trainixprogram/widgets/rubric/rubric_widgets.dart';

class SpeakingResultView extends StatelessWidget {
  final SpeakingResult result;
  final SpeakingPrompt prompt;
  final bool aiAvailable;
  final String? aiNote;
  final VoidCallback onRetake;
  final VoidCallback onNewPrompt;
  final VoidCallback onDone;

  const SpeakingResultView({
    super.key,
    required this.result,
    required this.prompt,
    required this.onRetake,
    required this.onNewPrompt,
    required this.onDone,
    this.aiAvailable = true,
    this.aiNote,
  });

  @override
  Widget build(BuildContext context) {
    final band = result.band;
    final bandColor = Color(band.colorValue);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TextButton.icon(
                    onPressed: onDone,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Done'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary(context),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: bandColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: bandColor.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Text(
                      result.bandLabel,
                      style: TextStyle(
                        color: bandColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(12),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 780),
                    child: ListView(
                      children: [
                        Text(
                          prompt.label,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          '${prompt.pack.label} · ${prompt.difficulty.label}',
                          style: TextStyle(
                            color: AppColors.textMuted(context),
                            fontSize: 13,
                          ),
                        ),
                        const Gap(14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _metric(
                              context,
                              'Overall',
                              result.scoredScores.isEmpty
                                  ? '-'
                                  : result.overallScore.toStringAsFixed(1),
                            ),
                            _metric(
                              context,
                              'Duration',
                              '${result.durationSeconds}s',
                            ),
                            _metric(
                              context,
                              'WPM',
                              '${result.roundedWordsPerMinute}',
                            ),
                            _metric(
                              context,
                              'Fillers',
                              '${result.fillerCount}',
                            ),
                            _metric(
                              context,
                              'Words',
                              '${result.wordCount}',
                            ),
                          ],
                        ),
                        if (!aiAvailable) ...[
                          const Gap(12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.warningWash(context),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              aiNote ??
                                  'AI scores unavailable. Measured metrics are still saved for this session.',
                              style: TextStyle(
                                color: AppColors.warningText(),
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                        const Gap(16),
                        RubricHowScoredCard(
                          title: 'How this was scored',
                          formula:
                              'Each speaking dimension starts at 10. The evaluator deducts only for observed gaps in the transcript or audio. Overall is the average of scored dimensions. Practice pass mark is 7.0. Excellent is 8.5 and above.',
                          rules: const [
                            'Evidence rule: if the model cannot cite a concrete quote or audio moment, that category stays at 10 (full marks).',
                            'Measured WPM and filler counts are computed locally from the transcript and duration.',
                            'Pronunciation Clarity and Speaking Confidence need clear audio. Without audio they show Not scored.',
                            'Expand each skill for criteria, possible deductions, evidence quotes, and a stronger line when available.',
                          ],
                          showBands: true,
                          footer:
                              'Bands match Dashboard and Session Report: 9-10 Excellent, 7-8 Good, 5-6 Developing, 0-4 Needs work.',
                          notice: !aiAvailable
                              ? (aiNote ??
                                  'AI was unavailable. Local measured dimensions still use the same rubric anchors.')
                              : null,
                        ),
                        const Gap(12),
                        ...ScoringTransparency.speakingDimensions.map((dim) {
                          final score = result.dimensionScores[dim.label];
                          final notScored = score == null;
                          final color = notScored
                              ? AppColors.textMuted(context)
                              : AppColors.levelForScore(context, score);
                          final issues = result.issues
                              .where(
                                (i) => _issueMatchesDimension(i.kind, dim.key),
                              )
                              .toList();
                          final evidence = issues
                              .map((i) => i.quote)
                              .where((q) => q.isNotEmpty)
                              .toList();
                          final stronger = issues
                              .map((i) => i.suggestion)
                              .where((s) => s.isNotEmpty)
                              .toList();
                          final deducted = notScored
                              ? null
                              : ScoringTransparency.deductedFromTen(score);
                          final level = notScored
                              ? null
                              : ScoringTransparency.levelFor(score);
                          final justification = notScored
                              ? null
                              : _bandJustification(dim, level!);
                          return RubricDimensionTile(
                            label: dim.label,
                            bandLabel: notScored
                                ? 'Not scored'
                                : ScoringTransparency.bandLabelFor(score),
                            color: color,
                            scoreText: notScored
                                ? '-'
                                : score.toStringAsFixed(1),
                            fraction: notScored ? 0 : score / 10.0,
                            basis: dim.short,
                            summary: justification,
                            parts: [
                              'Excellent (9-10): ${dim.excellent}',
                              'Good (7-8): ${dim.good}',
                              'Developing (5-6): ${dim.developing}',
                              'Needs work (0-4): ${dim.needsWork}',
                              if (dim.gapExamples.isNotEmpty)
                                'Gap examples: ${dim.gapExamples}',
                              if (deducted != null && deducted > 0.05)
                                'This take: deducted ${deducted.toStringAsFixed(1)} from 10.',
                              if (deducted != null && deducted <= 0.05)
                                'This take: full marks (no deduction applied).',
                            ],
                            anchors: dim.deductionAnchors,
                            sourceNote: dim.sourceNote,
                            evidence: evidence,
                            strongerLine:
                                stronger.isEmpty ? null : stronger.first,
                            notScored: notScored,
                            notScoredReason: notScored
                                ? _notScoredReason(dim.key, result)
                                : null,
                            icon: ScoringTransparency.iconFor(dim.label),
                            initiallyOpen: issues.isNotEmpty,
                          );
                        }),
                        const Gap(8),
                        Text(
                          'Transcript',
                          style: TextStyle(
                            color: AppColors.textMuted(context),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const Gap(8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.card(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.borderIdle(context),
                            ),
                          ),
                          child: Text(
                            result.transcript.isEmpty
                                ? '(empty)'
                                : result.transcript,
                            style: TextStyle(
                              color: AppColors.textPrimary(context),
                              fontSize: 14,
                              height: 1.45,
                            ),
                          ),
                        ),
                        if (result.issues.isNotEmpty) ...[
                          const Gap(12),
                          Text(
                            'Issue highlights',
                            style: TextStyle(
                              color: AppColors.textMuted(context),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const Gap(8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: result.issues.map((i) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.chipBg(context),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${i.kind}: "${i.quote}"',
                                  style: TextStyle(
                                    color: AppColors.textSecondary(context),
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                        const Gap(24),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: onRetake,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retake'),
                  ),
                  const Gap(10),
                  OutlinedButton.icon(
                    onPressed: onNewPrompt,
                    icon: const Icon(Icons.shuffle_rounded, size: 18),
                    label: const Text('New prompt'),
                  ),
                  const Gap(10),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: onDone,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Done'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryText(),
                          foregroundColor: AppColors.onPrimary(context),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _bandJustification(ScoringDimension dim, ScoreLevel level) {
    final criterion = dim.criterionForScore(
      level.id == 'excellent'
          ? 9.5
          : level.id == 'proficient'
              ? 8.0
              : level.id == 'developing'
                  ? 6.0
                  : 3.0,
    );
    return '${level.label} (${level.rangeLabel}): $criterion ${level.meaning}';
  }

  bool _issueMatchesDimension(String kind, String dimKey) {
    final k = kind.toLowerCase().replaceAll(' ', '_');
    final key = dimKey.toLowerCase();
    if (key.contains('grammar')) return k.contains('grammar');
    if (key.contains('word')) {
      return k.contains('word');
    }
    if (key.contains('fluency')) return k.contains('fluency');
    if (key.contains('pronun')) return k.contains('pronun');
    if (key.contains('filler')) return k.contains('filler');
    if (key.contains('confidence')) return k.contains('confidence');
    if (key.contains('complete')) return k.contains('complete');
    return false;
  }

  String _notScoredReason(String key, SpeakingResult r) {
    final k = key.toLowerCase();
    if (k.contains('pronun')) {
      if (!r.audioRetained) {
        return 'Pronunciation needs retained audio. Other dimensions were still scored.';
      }
      return 'Pronunciation could not be scored on this take.';
    }
    return 'No score available for this dimension on this take.';
  }

  Widget _metric(BuildContext context, String label, String value) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderIdle(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textMuted(context),
              fontSize: 11,
            ),
          ),
          const Gap(2),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
