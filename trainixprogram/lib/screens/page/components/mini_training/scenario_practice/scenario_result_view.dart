import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/models/scoring_transparency.dart';
import 'package:trainixprogram/models/training/scenarios/scenario_models.dart';
import 'package:trainixprogram/widgets/rubric/rubric_widgets.dart';

class ScenarioResultView extends StatelessWidget {
  final ScenarioDefinition scenario;
  final bool passed;
  final int mistakes;
  final VoidCallback onContinue;
  final VoidCallback onRetry;

  const ScenarioResultView({
    super.key,
    required this.scenario,
    required this.passed,
    required this.mistakes,
    required this.onContinue,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final allowed = scenario.maxMistakes <= 0 ? 1 : scenario.maxMistakes;
    final used = mistakes.clamp(0, allowed);
    final remaining = (allowed - used).clamp(0, allowed);
    final fraction =
        scenario.isGuided ? (passed ? 1.0 : 0.0) : remaining / allowed;
    final percent = fraction * 100;
    final level = ScoringTransparency.levelForPercent(percent);
    final bandColor = AppColors.readable(Color(level.colorValue), context);

    return Scaffold(
      backgroundColor: AppColors.inputFill(context),
      appBar: AppBar(
        title: Text(scenario.title),
        backgroundColor: AppColors.elevated(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Icon(
                  passed ? Icons.check_circle : Icons.cancel,
                  size: 52,
                  color:
                      passed ? AppColors.primaryText() : AppColors.errorText(),
                ),
                const Gap(14),
                Text(
                  passed ? 'Scenario cleared' : 'Not cleared yet',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Gap(10),
                Text(
                  passed
                      ? 'Nice work. This scenario counts toward unlocking the next stage. You can continue, or retry to practice again.'
                      : 'You hit the mistake limit. Read the guided lines again, then retry when ready.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary(context),
                    height: 1.4,
                  ),
                ),
                if (!scenario.isGuided) ...[
                  const Gap(8),
                  Text(
                    'Mistakes: $mistakes / ${scenario.maxMistakes}',
                    style: TextStyle(
                        fontSize: 14, color: AppColors.textMuted(context)),
                  ),
                ],
                const Gap(20),
                RubricHowScoredCard(
                  title: 'How this scenario was scored',
                  formula: scenario.isGuided
                      ? 'Guided run: clear every guided action in order. Mistakes are recorded here but do not lock a guided run.'
                      : 'Non-guided run: clear the scenario before mistakes pass the limit. The limit for this scenario is $allowed.',
                  rules: [
                    'Mistakes recorded in this run: $used of $allowed.',
                    'Guided actions completed: ${passed ? 'yes' : 'not yet'}.',
                    'Retakes are unlimited and do not change earlier runs.',
                    'This is scenario completion, not the 10-dimension competency rubric.',
                  ],
                  showBands: false,
                  footer:
                      'Dashboard and Session Report use the 10 shared competency dimensions for scored practice.',
                ),
                const Gap(12),
                RubricDimensionTile(
                  label: 'Mistake budget',
                  bandLabel: ScoringTransparency.chipText(level),
                  color: bandColor,
                  scoreText: scenario.isGuided
                      ? (passed ? 'Clear' : 'Blocked')
                      : '$remaining / $allowed',
                  fraction: fraction,
                  basis: scenario.isGuided
                      ? 'Guided scenarios clear when the guided action list is complete.'
                      : 'A non-guided scenario clears while mistakes stay under the limit.',
                  icon: Icons.shield_outlined,
                  parts: [
                    'Mistakes used: $used',
                    'Mistake limit: $allowed',
                    'Mistakes still allowed: $remaining',
                    'Clear state: ${passed ? 'cleared' : 'not cleared'}',
                  ],
                  evidence: [
                    if (used == 0)
                      'No mistakes were recorded in this run.'
                    else if (passed)
                      'Stayed within the limit with $used of $allowed mistakes used.'
                    else
                      'Reached the limit with $used of $allowed mistakes used.',
                  ],
                  notes: passed
                      ? const []
                      : [
                          'Retry the scenario and use the guided lines before answering.',
                          'Watch for the order of steps: the run checks each guided action.',
                        ],
                  initiallyOpen: !passed,
                ),
                const Gap(20),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryText(),
                        foregroundColor: AppColors.onPrimary(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: onContinue,
                      child: Text(passed ? 'Continue' : 'Close'),
                    ),
                  ),
                ),
                const Gap(10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      onPressed: onRetry,
                      child: Text(
                        passed ? 'Practice again' : 'Retry scenario',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
