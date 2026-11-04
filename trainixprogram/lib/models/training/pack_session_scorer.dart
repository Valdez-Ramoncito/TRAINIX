import 'package:trainixprogram/models/messages.dart';
import 'package:trainixprogram/models/session_score.dart';
import 'package:trainixprogram/models/simulation_coach.dart';
import 'package:trainixprogram/models/training/simulation_case_packs.dart';

class PackSessionScorer {
  static SessionEvaluation scoreChat({
    required List<Message> messages,
    required String sector,
    required String customerName,
    required String problem,
    required String emotion,
    required bool toolWorkDone,
    required bool accountSelected,
    required bool needsAccount,
    required bool acwSubmitted,
    required String acwDisposition,
    double? handleSeconds,
  }) {
    final agentTexts = messages
        .where((m) => m.role == 'user')
        .map(
          (m) => SimulationCoach.stripInternalFields(m.message).toLowerCase(),
        )
        .toList();
    final joined = agentTexts.join(' ');

    double opening = _scoreOpening(joined);
    double empathy = _scoreEmpathy(joined);
    double listening = _scoreListening(joined);
    double problemId = _scoreProblem(joined, problem);
    double solution = _scoreSolution(joined, toolWorkDone);
    double clarity = agentTexts.any((t) => t.split(' ').length >= 6)
        ? 7.5
        : 5.5;
    double tone = empathy >= 7 ? 7.5 : 6.0;
    double sectorK = problemId;
    double positive = empathy >= 6.5 ? 7.2 : 5.8;
    double closing = _scoreClosing(joined);

    if (needsAccount && !accountSelected) {
      solution = (solution - 1.5).clamp(3.0, 10.0);
      problemId = (problemId - 0.8).clamp(3.0, 10.0);
    }
    if (needsAccount && accountSelected && toolWorkDone) {
      solution = (solution + 0.8).clamp(0.0, 10.0);
    }
    if (!acwSubmitted || acwDisposition.trim().isEmpty) {
      closing = (closing - 1.0).clamp(3.0, 10.0);
    } else {
      closing = (closing + 0.5).clamp(0.0, 10.0);
    }

    final scores = [
      opening,
      positive,
      empathy,
      listening,
      problemId,
      solution,
      clarity,
      tone,
      sectorK,
      closing,
    ];
    final overall = scores.reduce((a, b) => a + b) / scores.length;

    final strengths = <String>[];
    final improvements = <String>[];
    if (opening >= 7)
      strengths.add('Clear opening and company identification.');
    if (empathy >= 7) strengths.add('Acknowledged the customer concern.');
    if (solution >= 7)
      strengths.add('Moved the case toward a concrete next step.');
    if (closing >= 7) strengths.add('Closing pattern was present.');
    if (opening < 6.5) {
      improvements.add('Open with company name and your name earlier.');
    }
    if (needsAccount && !accountSelected) {
      improvements.add('Use Account Lookup before promising account fixes.');
    }
    if (solution < 6.5) {
      improvements.add('Offer one clear fix or next step tied to the problem.');
    }
    if (!acwSubmitted) {
      improvements.add('Complete after-chat work notes for every customer.');
    }
    if (strengths.isEmpty) {
      strengths.add('Completed the customer interaction.');
    }
    if (improvements.isEmpty) {
      improvements.add('Keep replies concise and confirm understanding.');
    }

    return SessionEvaluation(
      sector: sector,
      openingSpielScore: _r(opening),
      positiveScriptingScore: _r(positive),
      empathyScore: _r(empathy),
      activeListeningScore: _r(listening),
      problemIdentificationScore: _r(problemId),
      solutionDeliveryScore: _r(solution),
      communicationClarityScore: _r(clarity),
      toneScore: _r(tone),
      sectorKnowledgeScore: _r(sectorK),
      closingSpielScore: _r(closing),
      overallScore: double.parse(overall.toStringAsFixed(1)),
      strengths: strengths,
      areasForImprovement: improvements,
      feedback:
          'Practice score from case-pack session rules. Pass bar is about 7.0 overall.',
      evaluatedAt: DateTime.now(),
      ahtHandleSeconds: handleSeconds,
      ahtOverLimit: handleSeconds != null && handleSeconds > 600,
      customerName: customerName,
      channel: 'chat',
      problem: problem,
      conversation: messages
          .map(
            (m) => {
              'role': m.role == 'user' ? 'agent' : 'customer',
              'text': SimulationCoach.stripInternalFields(m.message),
            },
          )
          .toList(),
    );
  }

  static double _r(double v) => double.parse(v.clamp(0, 10).toStringAsFixed(1));

  static double _scoreOpening(String t) {
    var s = 5.0;
    if (t.contains('thank you for contacting') ||
        t.contains('thank you for calling')) {
      s += 2;
    }
    if (t.contains('this is') || t.contains('my name is')) s += 1.5;
    if (t.contains('trainix')) s += 0.5;
    return s.clamp(3, 10);
  }

  static double _scoreEmpathy(String t) {
    var s = 5.0;
    if (t.contains('sorry') ||
        t.contains('understand') ||
        t.contains('frustrating')) {
      s += 2;
    }
    if (t.contains('help you')) s += 0.8;
    return s.clamp(3, 10);
  }

  static double _scoreListening(String t) {
    var s = 5.5;
    if (t.contains('just to confirm') ||
        t.contains('what i heard') ||
        t.contains('you mentioned')) {
      s += 2;
    }
    return s.clamp(3, 10);
  }

  static double _scoreProblem(String t, String problem) {
    var s = 5.5;
    final keys = problem
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((w) => w.length > 3)
        .take(6);
    var hits = 0;
    for (final k in keys) {
      if (t.contains(k)) hits++;
    }
    s += hits * 0.6;
    return s.clamp(3, 10);
  }

  static double _scoreSolution(String t, bool toolWorkDone) {
    var s = 5.0;
    if (t.contains('i will') ||
        t.contains('we can') ||
        t.contains('next step') ||
        t.contains('let me')) {
      s += 1.8;
    }
    if (toolWorkDone) s += 1.5;
    if (t.contains('escalate') || t.contains('transfer')) s += 0.8;
    return s.clamp(3, 10);
  }

  static double _scoreClosing(String t) {
    var s = 5.0;
    if (SimulationCoach.looksLikeClosing(t)) s += 2.5;
    if (t.contains('anything else')) s += 1;
    return s.clamp(3, 10);
  }
}
