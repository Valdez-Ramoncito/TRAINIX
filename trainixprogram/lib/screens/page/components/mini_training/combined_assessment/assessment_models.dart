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
