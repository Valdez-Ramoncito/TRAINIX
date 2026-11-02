import 'package:trainixprogram/models/training/voice_scoring/voice_score_result.dart';

class VoiceScriptScorer {
  static String normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z0-9\s']"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static List<String> tokens(String input) {
    final n = normalize(input);
    if (n.isEmpty) return [];
    return n.split(' ').where((t) => t.isNotEmpty).toList();
  }

  static bool containsAny(String haystack, List<String> needles) {
    for (final n in needles) {
      if (haystack.contains(n)) return true;
    }
    return false;
  }

  static double tokenCoverage(String transcript, String target) {
    final tTokens = tokens(target).toSet();
    if (tTokens.isEmpty) return 0;
    final sTokens = tokens(transcript).toSet();
    int hit = 0;
    for (final t in tTokens) {
      if (sTokens.contains(t)) hit++;
    }
    return hit / tTokens.length;
  }

  static VoiceScoreResult scoreScriptOnly({
    required String transcript,
    required String targetScript,
  }) {
    final notes = <String>[];
    final t = normalize(transcript);
    final target = normalize(targetScript);

    if (t.isEmpty) {
      return VoiceScoreResult(
        transcript: transcript,
        contentScore: 0,
        deliveryScore: 0,
        totalScore: 0,
        passed: false,
        criticalFail: false,
        criticalFailReason: '',
        contentNotes: ['No speech was detected. Please try again.'],
        deliveryNotes: const [],
        deliveryEvaluated: false,
      );
    }

    int content = 0;
    final isOpening =
        target.contains('thank you for calling') ||
        target.contains('how may i help') ||
        target.contains('how can i help');
    final isClosing =
        target.contains('anything else') ||
        (target.contains('thank you for calling') &&
            target.contains('good day')) ||
        target.contains('have a good');

    if (isOpening && target.contains('this is')) {
      final thanks = containsAny(t, ['thank you', 'thanks']);
      final company =
          containsAny(t, [
            'calling',
            'support',
            'company',
            'horizon',
            'service',
            'center',
          ]) ||
          tokenCoverage(t, target) >= 0.35;
      final name =
          RegExp(r'\bthis is\s+\w+').hasMatch(t) ||
          RegExp(r'\bmy name is\s+\w+').hasMatch(t);
      final help = containsAny(t, [
        'how may i help',
        'how can i help',
        'how may i assist',
        'how can i assist',
        'what can i do for you',
      ]);

      content += thanks ? 10 : 0;
      content += company ? 10 : 0;
      content += name ? 15 : 0;
      content += help ? 15 : 0;

      if (!thanks) notes.add('Missing courtesy / thanks for calling.');
      if (!company)
        notes.add('Missing clear company or channel identification.');
      if (!name) notes.add('Missing agent name introduction.');
      if (!help) notes.add('Missing offer of help.');

      final criticalFail = !name || !help;
      final criticalReason = !name
          ? 'Missing agent name in Opening Spiel.'
          : (!help ? 'No offer of help in Opening Spiel.' : '');

      final total = ((content / 50) * 100).round();
      final passed = !criticalFail && total >= 75;

      return VoiceScoreResult(
        transcript: transcript,
        contentScore: content,
        deliveryScore: 0,
        totalScore: total,
        passed: passed,
        criticalFail: criticalFail,
        criticalFailReason: criticalReason,
        contentNotes: notes,
        deliveryNotes: const [],
        deliveryEvaluated: false,
      );
    }

    if (isClosing) {
      final summary = tokenCoverage(t, target) >= 0.25;
      final further = containsAny(t, [
        'anything else',
        'help you with',
        'further assistance',
        'more help',
      ]);
      final thanks = containsAny(t, ['thank you', 'thanks']);
      final ending = containsAny(t, [
        'good day',
        'good afternoon',
        'good morning',
        'goodbye',
        'take care',
        'have a great',
        'have a good',
      ]);

      content += summary ? 15 : 0;
      content += further ? 15 : 0;
      content += thanks ? 10 : 0;
      content += ending ? 10 : 0;

      if (!summary) notes.add('Missing clear summary or close framing.');
      if (!further) notes.add('Missing offer of further help.');
      if (!thanks) notes.add('Missing polite thanks.');
      if (!ending) notes.add('Missing clear polite ending.');

      final total = ((content / 50) * 100).round();
      return VoiceScoreResult(
        transcript: transcript,
        contentScore: content,
        deliveryScore: 0,
        totalScore: total,
        passed: total >= 75,
        criticalFail: false,
        criticalFailReason: '',
        contentNotes: notes,
        deliveryNotes: const [],
        deliveryEvaluated: false,
      );
    }

    final coverage = tokenCoverage(t, target);
    if (coverage >= 0.75) {
      content = 50;
      notes.add('Target meaning and key phrase are present.');
    } else if (coverage >= 0.55) {
      content = 42;
      notes.add('Most of the target phrase is present.');
    } else if (coverage >= 0.40) {
      content = 30;
      notes.add('Some target words are present, but the line is incomplete.');
    } else if (coverage >= 0.25) {
      content = 18;
      notes.add('Only a small part of the target phrase was detected.');
    } else {
      content = 0;
      notes.add('Spoken line does not match the target phrase closely enough.');
    }

    final total = ((content / 50) * 100).round();
    return VoiceScoreResult(
      transcript: transcript,
      contentScore: content,
      deliveryScore: 0,
      totalScore: total,
      passed: total >= 75,
      criticalFail: false,
      criticalFailReason: '',
      contentNotes: notes,
      deliveryNotes: const [],
      deliveryEvaluated: false,
    );
  }
}
