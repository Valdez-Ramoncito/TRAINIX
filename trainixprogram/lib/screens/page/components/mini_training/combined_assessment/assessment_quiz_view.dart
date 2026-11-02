import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/screens/page/components/mini_training/combined_assessment/assessment_models.dart';

class AssessmentQuizView extends StatelessWidget {
  final ShuffledQuestion question;
  final int questionNumber;
  final int questionTotal;
  final int? selectedOption;
  final bool lockedIn;
  final String? immediateFeedback;
  final ValueChanged<int> onSelectOption;

  const AssessmentQuizView({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.questionTotal,
    required this.selectedOption,
    required this.lockedIn,
    required this.immediateFeedback,
    required this.onSelectOption,
  });

  @override
  Widget build(BuildContext context) {
    final q = question;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F26),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2A323C)),
          ),
          child: Text(
            'Question $questionNumber of $questionTotal',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
              letterSpacing: 0.3,
            ),
          ),
        ),
        const Gap(16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: const Color(0xFF141A20),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A323C)),
          ),
          child: Text(
            q.question,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.45,
              color: Colors.white,
            ),
          ),
        ),
        const Gap(18),
        ...List.generate(q.options.length, (i) {
          final isSelected = selectedOption == i;
          final showResult = lockedIn;
          final isCorrect = i == q.correctIndex;

          Color borderColor = const Color(0xFF2A323C);
          Color bgColor = const Color(0xFF1A1F26);

          if (!lockedIn && isSelected) {
            borderColor = const Color(0xFF70BD8A);
            bgColor = const Color(0xFF12261A);
          }

          if (showResult) {
            if (isCorrect) {
              borderColor = const Color(0xFF70BD8A);
              bgColor = const Color(0xFF1A3A1A);
            } else if (isSelected && !isCorrect) {
              borderColor = const Color(0xFFEF4444);
              bgColor = const Color(0xFF3A1A1A);
            }
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: lockedIn ? null : () => onSelectOption(i),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 1.4),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF70BD8A)
                                : const Color(0xFF6B7280),
                            width: 2,
                          ),
                          color: isSelected && !lockedIn
                              ? const Color(0xFF70BD8A)
                              : Colors.transparent,
                        ),
                        child: isSelected && !lockedIn
                            ? const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const Gap(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              q.options[i],
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.35,
                                color: Colors.white,
                              ),
                            ),
                            if (showResult && isCorrect) ...[
                              const SizedBox(height: 4),
                              const Text(
                                'Correct',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF86EFAC),
                                ),
                              ),
                            ],
                            if (showResult && isSelected && !isCorrect) ...[
                              const SizedBox(height: 4),
                              const Text(
                                'Wrong',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFCA5A5),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        if (immediateFeedback != null) ...[
          const Gap(8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F26),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF374151)),
            ),
            child: Text(
              immediateFeedback!,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                color: Color(0xFFD1D5DB),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
