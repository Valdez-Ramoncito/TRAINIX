import 'package:flutter/material.dart';
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
    final diffIndex = isIncorrect
        ? _firstDiffIndex(normalizedInput, normalizedTarget)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Type the same meaning as the target. Exact wording is not required.",
          style: TextStyle(fontSize: 13, color: Colors.white54),
        ),
        const Gap(10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF333333)),
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
          style: const TextStyle(fontSize: 15, color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF333333)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF333333)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.green),
            ),
            hintText: 'Type here...',
            hintStyle: const TextStyle(color: Color(0xFFB0B8C4)),
          ),
        ),
        const Gap(14),
        if (!widget.lockedIn)
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: widget.onCheck,
              child: const Text("Check"),
            ),
          ),
        if (isCorrect) ...[
          const Gap(12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A3A1A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.withOpacity(0.5)),
            ),
            child: const Text(
              "Correct",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.green,
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
              color: const Color(0xFF3A1A1A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Incorrect",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.redAccent,
                  ),
                ),
                const Gap(10),
                const Text(
                  "Your answer",
                  style: TextStyle(fontSize: 12, color: Colors.white54),
                ),
                const Gap(4),
                Text(
                  normalizedInput.isEmpty ? "(blank)" : normalizedInput,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.redAccent,
                    height: 1.4,
                  ),
                ),
                const Gap(10),
                const Text(
                  "Target text",
                  style: TextStyle(fontSize: 12, color: Colors.white54),
                ),
                const Gap(4),
                Text(
                  normalizedTarget,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.green,
                    height: 1.4,
                  ),
                ),
                if (diffIndex != null) ...[
                  const Gap(10),
                  Text(
                    "First difference around character ${diffIndex + 1}. Check spelling, spacing, and punctuation from that point.",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
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
                  const Text(
                    "Hint",
                    style: TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                  const Gap(4),
                  Text(
                    _hintText(normalizedTarget),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
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
