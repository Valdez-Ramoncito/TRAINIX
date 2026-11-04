import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/models/training/scenarios/scenario_models.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(scenario.title),
        backgroundColor: const Color(0xFF1A1A1A),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const Spacer(),
                Icon(
                  passed ? Icons.check_circle : Icons.cancel,
                  size: 52,
                  color: passed ? Colors.green : Colors.redAccent,
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
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
                const Gap(8),
                if (!scenario.isGuided)
                  Text(
                    'Mistakes: $mistakes / ${scenario.maxMistakes}',
                    style: const TextStyle(fontSize: 14, color: Colors.white54),
                  ),
                const Spacer(),
                Align(
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: onContinue,
                        child: Text(passed ? 'Continue' : 'Close'),
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
                        child: Text(
                          passed ? 'Practice again' : 'Retry scenario',
                        ),
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
