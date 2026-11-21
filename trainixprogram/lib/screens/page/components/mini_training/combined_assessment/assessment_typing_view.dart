import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';
import 'package:trainixprogram/models/training/script_personalization.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/models/training/training_categories.dart';

class AssessmentTypingView extends StatefulWidget {
  final Assessment item;
  final TextEditingController controller;
  final bool lockedIn;
  final String? typingFeedback;
  final VoidCallback onCheck;

  const AssessmentTypingView({
    super.key,
    required this.item,
    required this.controller,
    required this.lockedIn,
    required this.typingFeedback,
    required this.onCheck,
  });

  @override
  State<AssessmentTypingView> createState() => _AssessmentTypingViewState();
}

class _AssessmentTypingViewState extends State<AssessmentTypingView> {
  bool _hintVisible = false;

  @override
  void didUpdateWidget(covariant AssessmentTypingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.lockedIn && oldWidget.lockedIn) {
      _hintVisible = false;
    }
  }

  String _normalize(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  int? _firstDiffIndex(String a, String b) {
    final left = a.toLowerCase();
    final right = b.toLowerCase();
    final maxLen = left.length < right.length ? left.length : right.length;
    for (int i = 0; i < maxLen; i++) {
      if (left[i] != right[i]) return i;
    }
    if (left.length != right.length) return maxLen;
    return null;
  }

  String _hintText(String target) {
    final words = target.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return target;
    final keep = (words.length * 0.4).ceil().clamp(1, words.length);
    final shown = words.take(keep).join(' ');
    return "$shown ...";
  }

  @override
  Widget build(BuildContext context) {
    final target = ScriptPersonalization.resolve(
      widget.item.typingTargetText ?? "",
    );
    final input = widget.controller.text;
    final isCorrect = widget.typingFeedback == "Correct";
    final isIncorrect = widget.typingFeedback == "Incorrect";
    final normalizedTarget = _normalize(target);
    final normalizedInput = _normalize(input);
    final diffIndex =
        isIncorrect ? _firstDiffIndex(normalizedInput, normalizedTarget) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Type the same meaning as the target. Exact wording is not required.",
          style: TextStyle(fontSize: 13, color: AppColors.textMuted(context)),
        ),
        const Gap(10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.elevated(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Text(
            target,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        ),
        const Gap(16),
        TextField(
          controller: widget.controller,
          enabled: !widget.lockedIn,
          autofocus: !widget.lockedIn,
          maxLines: 3,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (!widget.lockedIn) widget.onCheck();
          },
          style: TextStyle(fontSize: 15, color: AppColors.textPrimary(context)),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.elevated(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.border(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.border(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.primary(context)),
            ),
            hintText: 'Type here...',
            hintStyle: TextStyle(color: AppColors.textSecondary(context)),
          ),
        ),
        const Gap(14),
        if (!widget.lockedIn)
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary(context),
                foregroundColor: AppColors.onPrimary(context),
              ),
              onPressed: widget.onCheck,
              child: Text("Check"),
            ),
          ),
        if (isCorrect) ...[
          const Gap(12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.nextTint(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.primary(context).withValues(alpha: 0.5)),
            ),
            child: Text(
              "Correct",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary(context),
              ),
            ),
          ),
        ],
        if (isIncorrect) ...[
          const Gap(12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.elevated(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.errorText().withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Incorrect",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.errorText(),
                  ),
                ),
                const Gap(10),
                Text(
                  "Your answer",
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textMuted(context)),
                ),
                const Gap(4),
                Text(
                  normalizedInput.isEmpty ? "(blank)" : normalizedInput,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.errorText(),
                    height: 1.4,
                  ),
                ),
                const Gap(10),
                Text(
                  "Target text",
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textMuted(context)),
                ),
                const Gap(4),
                Text(
                  normalizedTarget,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary(context),
                    height: 1.4,
                  ),
                ),
                if (diffIndex != null) ...[
                  const Gap(10),
                  Text(
                    "First difference around character ${diffIndex + 1}. Check spelling, spacing, and punctuation from that point.",
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary(context),
                      height: 1.4,
                    ),
                  ),
                ],
                const Gap(12),
                if (!_hintVisible)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _hintVisible = true;
                      });
                    },
                    child: const Text("Show hint"),
                  ),
                if (_hintVisible) ...[
                  Text(
                    "Hint",
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textMuted(context)),
                  ),
                  const Gap(4),
                  Text(
                    _hintText(normalizedTarget),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary(context),
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
