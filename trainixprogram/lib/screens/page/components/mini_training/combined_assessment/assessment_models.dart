enum AssessmentItemKind { quiz, typing, voice }

/// One scored assessment item, kept so the results panel can justify the
/// number with the rule that produced it and the evidence observed.
class AssessmentItemResult {
  final String title;
  final AssessmentItemKind kind;
  final bool passed;
  final String scoreText;
  final int earned;
  final int available;
  final List<String> parts;
  final String basis;
  final List<String> evidence;
  final List<String> notes;

  const AssessmentItemResult({
    required this.title,
    required this.kind,
    required this.passed,
    required this.scoreText,
    required this.earned,
    required this.available,
    required this.basis,
    this.parts = const [],
    this.evidence = const [],
    this.notes = const [],
  });

  double get fraction => available == 0 ? 0 : earned / available;

  String get kindLabel {
    switch (kind) {
      case AssessmentItemKind.quiz:
        return 'Quiz';
      case AssessmentItemKind.typing:
        return 'Typing';
      case AssessmentItemKind.voice:
        return 'Voice';
    }
  }
}

class ShuffledQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String? explanation;

  ShuffledQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanation,
  });
}

class MissedItem {
  final String prompt;
  final String yourAnswer;
  final String correctAnswer;
  final String reason;

  MissedItem({
    required this.prompt,
    required this.yourAnswer,
    required this.correctAnswer,
    required this.reason,
  });
}
