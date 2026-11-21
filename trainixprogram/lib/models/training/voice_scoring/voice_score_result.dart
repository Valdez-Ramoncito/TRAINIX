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
  final int clarityScore;
  final int paceScore;
  final int toneScore;
  final int confidenceScore;

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
    this.clarityScore = 0,
    this.paceScore = 0,
    this.toneScore = 0,
    this.confidenceScore = 0,
  });
}
