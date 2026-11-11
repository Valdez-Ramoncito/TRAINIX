import 'package:trainixprogram/models/training/typing/typing_passage.dart';

class TypingResult {
  final int durationSeconds;
  final TypingPack pack;
  final int correctChars;
  final int incorrectChars;
  final int totalKeystrokes;
  final int passagesCompleted;
  final DateTime finishedAt;
  final bool completedByTime;
  final bool noBackspace;

  const TypingResult({
    required this.durationSeconds,
    required this.pack,
    required this.correctChars,
    required this.incorrectChars,
    required this.totalKeystrokes,
    required this.passagesCompleted,
    required this.finishedAt,
    required this.completedByTime,
    this.noBackspace = false,
  });

  double get minutes {
    if (durationSeconds <= 0) return 1 / 60;
    return durationSeconds / 60.0;
  }

  double get netWpm {
    final net = correctChars / 5.0;
    return net / minutes;
  }

  double get rawWpm {
    final raw = totalKeystrokes / 5.0;
    return raw / minutes;
  }

  double get accuracyPercent {
    if (totalKeystrokes <= 0) return 100;
    final correct = totalKeystrokes - incorrectChars;
    if (correct <= 0) return 0;
    return (correct / totalKeystrokes) * 100;
  }

  int get roundedNetWpm => netWpm.round();

  int get roundedRawWpm => rawWpm.round();

  int get roundedAccuracy => accuracyPercent.round().clamp(0, 100);
}
