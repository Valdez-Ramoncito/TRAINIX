import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/models/scoring_transparency.dart';
import 'package:trainixprogram/screens/page/components/mini_training/combined_assessment/assessment_models.dart';
import 'package:trainixprogram/widgets/rubric/rubric_widgets.dart';

class AssessmentResultsView extends StatelessWidget {
  final String title;
  final bool passed;
  final int correctCount;
  final int totalCount;
  final List<MissedItem> missed;
  final List<AssessmentItemResult> results;
  final VoidCallback onRetry;
  final VoidCallback onContinue;
  final String continueLabel;

  const AssessmentResultsView({
    super.key,
    required this.title,
    required this.passed,
    required this.correctCount,
    required this.totalCount,
    required this.missed,
    required this.onRetry,
    required this.onContinue,
    this.results = const [],
    this.continueLabel = 'Continue',
  });

  double get _percent => totalCount > 0 ? (correctCount / totalCount) * 100 : 0;

  List<String> _instrumentRules() {
    final rules = <String>[];
    if (results.any((r) => r.kind == AssessmentItemKind.quiz)) {
      rules.add(ScoringTransparency.quizInstrumentLine);
    }
    if (results.any((r) => r.kind == AssessmentItemKind.typing)) {
      rules.add(ScoringTransparency.typingInstrumentLine);
    }
    final voice = results.where((r) => r.kind == AssessmentItemKind.voice);
    if (voice.isNotEmpty) {
      rules.add(ScoringTransparency.voiceInstrumentLine);
      rules.add(ScoringTransparency.scriptContentLine);
      rules.add(ScoringTransparency.openingContentLine);
      rules.add(ScoringTransparency.closingContentLine);
      if (voice.any((r) => r.parts.any(
            (p) => p.startsWith('Delivery Quality: not scored'),
          ))) {
        rules.add(ScoringTransparency.pendingDeliveryLine);
      } else {
        rules.add(ScoringTransparency.deliveryRubricLine);
      }
    }
    return rules;
  }

  IconData _iconFor(AssessmentItemKind kind) {
    switch (kind) {
      case AssessmentItemKind.quiz:
        return Icons.quiz_outlined;
      case AssessmentItemKind.typing:
        return Icons.keyboard_rounded;
      case AssessmentItemKind.voice:
        return Icons.mic_none_rounded;
    }
  }

  Widget _scoreLine(BuildContext context) {
    final level = ScoringTransparency.levelForPercent(_percent);
    final color = AppColors.readable(Color(level.colorValue), context);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        Text(
          'Score: $correctCount / $totalCount'
          '${totalCount > 0 ? '  (${_percent.round()}%)' : ''}',
          textAlign: TextAlign.center,
          style:
              TextStyle(fontSize: 18, color: AppColors.textSecondary(context)),
        ),
        RubricBandChip(
          label: ScoringTransparency.chipText(level),
          color: color,
          fontSize: 11,
        ),
      ],
    );
  }

  Widget _missedFallback(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'What to review',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary(context),
          ),
        ),
        const Gap(10),
        for (final m in missed)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.listBase(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border(context)),
              boxShadow: AppColors.cardShadow(context, blur: 10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.prompt,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const Gap(10),
                Text(
                  'Your answer: ${m.yourAnswer}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.errorText(context),
                    height: 1.35,
                  ),
                ),
                const Gap(4),
                Text(
                  'Correct answer: ${m.correctAnswer}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primaryText(context),
                    height: 1.35,
                  ),
                ),
                const Gap(8),
                Text(
                  m.reason,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary(context),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          passed ? Icons.check_circle : Icons.cancel,
          size: 48,
          color: passed
              ? AppColors.primaryText(context)
              : AppColors.errorText(context),
        ),
        const Gap(14),
        Text(
          passed ? 'You passed this assessment' : 'Not passed yet',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary(context),
          ),
        ),
        const Gap(12),
        _scoreLine(context),
        const Gap(6),
        Text(
          'Pass mark: 75%. Retake is optional after you pass.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textMuted(context),
          ),
        ),
        const Gap(10),
        Text(
          passed
              ? (correctCount == totalCount && totalCount > 0
                  ? 'Full score. This step is cleared. Retake anytime if you want more practice.'
                  : 'Passed (75% or higher). This step is cleared. Retake is optional.')
              : 'Below 75%. Review the evidence below, then try again to clear this step.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            height: 1.45,
            color: AppColors.textSecondary(context),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.inputFill(context),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.elevated(context),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(28),
            children: [
              summary,
              const Gap(18),
              RubricHowScoredCard(
                title: 'How this was scored',
                formula: ScoringTransparency.assessmentFormulaLine,
                rules: _instrumentRules(),
                footer:
                    'Open any item below for the score breakdown and the evidence observed in your attempt.',
              ),
              if (results.isNotEmpty) ...[
                const Gap(18),
                Text(
                  'Item-by-item basis and evidence',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const Gap(10),
                for (final r in results)
                  Builder(
                    builder: (context) {
                      final level =
                          ScoringTransparency.levelForPercent(r.fraction * 100);
                      final color =
                          AppColors.readable(Color(level.colorValue), context);
                      return RubricDimensionTile(
                        label: '${r.kindLabel}: ${r.title}',
                        bandLabel: ScoringTransparency.chipText(level),
                        color: color,
                        scoreText: r.scoreText,
                        fraction: r.fraction,
                        basis: r.basis,
                        parts: r.parts,
                        evidence: r.evidence,
                        notes: r.notes,
                        icon: _iconFor(r.kind),
                        initiallyOpen: !r.passed,
                      );
                    },
                  ),
              ] else if (!passed && missed.isNotEmpty) ...[
                const Gap(18),
                _missedFallback(context),
              ],
              const Gap(16),
              if (passed) ...[
                Align(
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary(context),
                          foregroundColor: AppColors.onPrimary(context),
                        ),
                        onPressed: onContinue,
                        child: Text(continueLabel),
                      ),
                    ),
                  ),
                ),
                const Gap(10),
                Align(
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton(
                        onPressed: onRetry,
                        child: const Text('Retake (optional)'),
                      ),
                    ),
                  ),
                ),
              ] else
                Align(
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary(context),
                          foregroundColor: AppColors.onPrimary(context),
                        ),
                        onPressed: onRetry,
                        child: const Text('Retry Assessment'),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
