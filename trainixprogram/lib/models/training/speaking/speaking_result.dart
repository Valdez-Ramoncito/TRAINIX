import 'package:trainixprogram/models/scoring_transparency.dart';
import 'package:trainixprogram/models/training/speaking/speaking_prompt.dart';

class SpeakingIssue {
  final String quote;
  final String kind;
  final String suggestion;

  const SpeakingIssue({
    required this.quote,
    required this.kind,
    required this.suggestion,
  });
}

class SpeakingResult {
  final String promptId;
  final SpeakingPack pack;
  final SpeakingPromptDifficulty difficulty;
  final int durationSeconds;
  final String transcript;
  final int fillerCount;
  final int longPauseCount;
  final bool audioRetained;
  final DateTime finishedAt;
  final List<SpeakingIssue> issues;

  final double? grammarScore;
  final double? wordChoiceScore;
  final double? fluencyScore;
  final double? pronunciationClarityScore;
  final double? fillerUsageScore;
  final double? confidenceScore;
  final double? completenessScore;

  const SpeakingResult({
    required this.promptId,
    required this.pack,
    required this.difficulty,
    required this.durationSeconds,
    required this.transcript,
    required this.finishedAt,
    this.fillerCount = 0,
    this.longPauseCount = 0,
    this.audioRetained = false,
    this.issues = const [],
    this.grammarScore,
    this.wordChoiceScore,
    this.fluencyScore,
    this.pronunciationClarityScore,
    this.fillerUsageScore,
    this.confidenceScore,
    this.completenessScore,
  });

  int get wordCount {
    final parts = transcript.trim().split(RegExp(r'\s+'));
    if (parts.length == 1 && parts.first.isEmpty) return 0;
    return parts.length;
  }

  double get fillerRatio {
    final words = wordCount;
    if (words == 0) return 0;
    return fillerCount / words;
  }

  double get wordsPerMinute {
    if (durationSeconds <= 0) return 0;
    return wordCount / (durationSeconds / 60.0);
  }

  int get roundedWordsPerMinute => wordsPerMinute.round();

  Map<String, double?> get dimensionScores {
    return {
      'Grammar Accuracy': grammarScore,
      'Word Choice': wordChoiceScore,
      'Fluency': fluencyScore,
      'Pronunciation Clarity': pronunciationClarityScore,
      'Filler Usage': fillerUsageScore,
      'Speaking Confidence': confidenceScore,
      'Completeness': completenessScore,
    };
  }

  List<double> get scoredScores =>
      dimensionScores.values.whereType<double>().toList();

  double get overallScore {
    final scores = scoredScores;
    if (scores.isEmpty) return 0;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  int get roundedOverall => overallScore.round();

  String get bandLabel => ScoringTransparency.bandLabelFor(overallScore);

  ScoreLevel get band => ScoringTransparency.speakingBandFor(overallScore);

  bool get hasPartialScores => scoredScores.length < dimensionScores.length;

  int get unscoredCount => dimensionScores.length - scoredScores.length;
}
