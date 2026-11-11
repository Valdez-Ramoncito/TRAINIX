import 'package:trainixprogram/models/training/typing/typing_passage.dart';
import 'package:trainixprogram/models/training/typing/typing_result.dart';

class TypingPracticeStore {
  TypingPracticeStore._();

  static final List<TypingResult> _history = [];
  static final Map<String, TypingResult> _bestByKey = {};

  static List<TypingResult> get history =>
      List<TypingResult>.unmodifiable(_history);

  static TypingResult? bestFor({
    required int durationSeconds,
    required TypingPack pack,
  }) {
    return _bestByKey[_key(durationSeconds, pack)];
  }

  static TypingResult? get overallBest {
    if (_bestByKey.isEmpty) return null;
    TypingResult? best;
    for (final r in _bestByKey.values) {
      if (best == null || r.netWpm > best.netWpm) best = r;
    }
    return best;
  }

  static void record(TypingResult result) {
    _history.insert(0, result);
    if (_history.length > 20) {
      _history.removeRange(20, _history.length);
    }

    final key = _key(result.durationSeconds, result.pack);
    final existing = _bestByKey[key];
    if (existing == null ||
        result.netWpm > existing.netWpm ||
        (result.netWpm == existing.netWpm &&
            result.accuracyPercent > existing.accuracyPercent)) {
      _bestByKey[key] = result;
    }
  }

  static void reset() {
    _history.clear();
    _bestByKey.clear();
  }

  static String _key(int durationSeconds, TypingPack pack) {
    return '${durationSeconds}_${pack.name}';
  }
}
