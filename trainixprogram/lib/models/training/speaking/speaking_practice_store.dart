import 'package:trainixprogram/models/training/speaking/speaking_prompt.dart';
import 'package:trainixprogram/models/training/speaking/speaking_result.dart';

class SpeakingPracticeStore {
  SpeakingPracticeStore._();

  static final List<SpeakingResult> _history = [];
  static final Map<String, SpeakingResult> _bestByKey = {};

  static List<SpeakingResult> get history =>
      List<SpeakingResult>.unmodifiable(_history);

  static SpeakingResult? bestFor({
    required SpeakingPack pack,
    required SpeakingPromptDifficulty difficulty,
  }) {
    return _bestByKey[_key(pack, difficulty)];
  }

  static SpeakingResult? get overallBest {
    if (_bestByKey.isEmpty) return null;
    SpeakingResult? best;
    for (final r in _bestByKey.values) {
      if (best == null || r.overallScore > best.overallScore) best = r;
    }
    return best;
  }

  static void record(SpeakingResult result) {
    _history.insert(0, result);
    if (_history.length > 20) {
      _history.removeRange(20, _history.length);
    }

    final key = _key(result.pack, result.difficulty);
    final existing = _bestByKey[key];
    if (existing == null || result.overallScore > existing.overallScore) {
      _bestByKey[key] = result;
    }
  }

  static void reset() {
    _history.clear();
    _bestByKey.clear();
  }

  static String _key(SpeakingPack pack, SpeakingPromptDifficulty difficulty) {
    return '${pack.name}_${difficulty.name}';
  }
}
