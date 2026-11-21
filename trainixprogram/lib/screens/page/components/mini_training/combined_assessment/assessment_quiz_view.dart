import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';
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
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Text(
            'Question $questionNumber of $questionTotal',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted(context),
              letterSpacing: 0.3,
            ),
          ),
        ),
        const Gap(16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Text(
            q.question,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.45,
              color: AppColors.textPrimary(context),
            ),
          ),
        ),
        const Gap(18),
        ...List.generate(q.options.length, (i) {
          final isSelected = selectedOption == i;
          final showResult = lockedIn;
          final isCorrect = i == q.correctIndex;

          Color borderColor = AppColors.border(context);
          Color bgColor = AppColors.card(context);

          if (!lockedIn && isSelected) {
            borderColor = AppColors.primaryText();
            bgColor = AppColors.nextTint(context);
          }

          if (showResult) {
            if (isCorrect) {
              borderColor = AppColors.primaryText();
              bgColor = AppColors.nextTint(context);
            } else if (isSelected && !isCorrect) {
              borderColor = AppColors.errorStrongText();
              bgColor = AppColors.elevated(context);
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
                                ? AppColors.primaryText()
                                : AppColors.textMuted(context),
                            width: 2,
                          ),
                          color: isSelected && !lockedIn
                              ? AppColors.primaryText()
                              : Colors.transparent,
                        ),
                        child: isSelected && !lockedIn
                            ? Icon(
                                Icons.check,
                                size: 14,
                                color: AppColors.onPrimary(context),
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
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.35,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                            if (showResult && isCorrect) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Correct',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.successText(),
                                ),
                              ),
                            ],
                            if (showResult && isSelected && !isCorrect) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Wrong',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.errorText(),
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
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderStrong(context)),
            ),
            child: Text(
              immediateFeedback!,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
