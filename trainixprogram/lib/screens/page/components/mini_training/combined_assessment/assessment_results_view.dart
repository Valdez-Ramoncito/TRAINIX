import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/screens/page/components/mini_training/combined_assessment/assessment_models.dart';

class AssessmentResultsView extends StatelessWidget {
  final String title;
  final bool passed;
  final int correctCount;
  final int totalCount;
  final List<MissedItem> missed;
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
    this.continueLabel = 'Continue',
  });

  @override
  Widget build(BuildContext context) {
    final summary = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          passed ? Icons.check_circle : Icons.cancel,
          size: 48,
          color: passed ? Colors.green : Colors.redAccent,
        ),
        const Gap(14),
        Text(
          passed ? 'You passed this assessment' : 'Not passed yet',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const Gap(12),
        Text(
          'Score: $correctCount / $totalCount'
          '${totalCount > 0 ? '  (${((correctCount / totalCount) * 100).round()}%)' : ''}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, color: Colors.white70),
        ),
        const Gap(6),
        const Text(
          'Pass mark: 75%',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.white54),
        ),
        const Gap(10),
        Text(
          passed
              ? (correctCount == totalCount && totalCount > 0
                    ? 'Full score. This step is cleared. Retake anytime if you want more practice.'
                    : 'Passed (75% or higher). This step is cleared. Retake is optional.')
              : 'Below 75%. Review what you missed, then try again to clear this step.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            height: 1.45,
            color: Colors.white60,
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF1A1A1A),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Expanded(
                  child: !passed && missed.isNotEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            summary,
                            const Gap(20),
                            const Text(
                              "What to review",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Gap(10),
                            Expanded(
                              child: ListView.separated(
                                itemCount: missed.length,
                                separatorBuilder: (_, __) => const Gap(10),
                                itemBuilder: (context, index) {
                                  final m = missed[index];
                                  return Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A1A1A),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFF333333),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          m.prompt,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            height: 1.35,
                                          ),
                                        ),
                                        const Gap(10),
                                        Text(
                                          "Your answer: ${m.yourAnswer}",
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.redAccent,
                                            height: 1.35,
                                          ),
                                        ),
                                        const Gap(4),
                                        Text(
                                          "Correct answer: ${m.correctAnswer}",
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.green,
                                            height: 1.35,
                                          ),
                                        ),
                                        const Gap(8),
                                        Text(
                                          m.reason,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.white70,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        )
                      : Center(child: summary),
                ),
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
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
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
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
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
      ),
    );
  }
}
