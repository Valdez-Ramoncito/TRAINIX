class VoiceScoreResult {
  final String transcript;
  final int contentScore;
  final int deliveryScore;
  final int totalScore;
  final bool passed;
  final bool criticalFail;
  final String criticalFailReason;
  final List<String> contentNotes;
  final List<String> deliveryNotes;
  final bool deliveryEvaluated;

  const VoiceScoreResult({
    required this.transcript,
    required this.contentScore,
    required this.deliveryScore,
    required this.totalScore,
    required this.passed,
    required this.criticalFail,
    required this.criticalFailReason,
    required this.contentNotes,
    required this.deliveryNotes,
    required this.deliveryEvaluated,
  });
}
