//this creates the evaluation for a session
class SessionEvaluation {
  final String sector;
  final double openingSpielScore;
  final double positiveScriptingScore;
  final double empathyScore;
  final double activeListeningScore;
  final double problemIdentificationScore;
  final double solutionDeliveryScore;
  final double communicationClarityScore;
  final double toneScore;
  final double sectorKnowledgeScore;
  final double closingSpielScore;
  final double overallScore;

  //TESDA Common Unit 2 (ICT311203) telemetry categories  chat-only.
  //Nullable and NOT folded into overallScore
  //voice evaluations leave these null
  final double? typingSpeedScore;
  final double? errorRateAccuracyScore;
  final double? responseConsistencyScore;

  //TESDA Core Unit 1 (ICT313365) acoustic categories. Voice-only, same
  //treatment as the chat fields above.
  //TONE_AND_INFLECTION reuses the existing shared toneScore field instead of a
  //new one, since that's exactly what toneScore always meant for voice.
  final double? paceAndSpeedScore;
  final double? pronunciationClarityScore;
  final double? fillerWordUsageScore;
  final double? confidenceScore;
  final double? dictionScore;
  final double? grammarScore;
  final double? wordChoiceScore;

  final Map<String, String>? categoryNotes;
  final Map<String, String>? categoryQuotes;
  final Map<String, String>? categorySuggestions;

  final List<String> strengths;
  final List<String> areasForImprovement;
  final String feedback;
  final DateTime evaluatedAt;
  final double? ahtHandleSeconds;
  final bool ahtOverLimit;
  final String customerName;
  final String channel;
  final String problem;
  final List<Map<String, String>> conversation;

  final int? customerRating;
  final String? customerComment;

  const SessionEvaluation({
    required this.sector,
    required this.openingSpielScore,
    required this.positiveScriptingScore,
    required this.empathyScore,
    required this.activeListeningScore,
    required this.problemIdentificationScore,
    required this.solutionDeliveryScore,
    required this.communicationClarityScore,
    required this.toneScore,
    required this.sectorKnowledgeScore,
    required this.closingSpielScore,
    required this.overallScore,
    this.typingSpeedScore,
    this.errorRateAccuracyScore,
    this.responseConsistencyScore,
    this.paceAndSpeedScore,
    this.pronunciationClarityScore,
    this.fillerWordUsageScore,
    this.confidenceScore,
    this.dictionScore,
    this.grammarScore,
    this.wordChoiceScore,
    this.categoryNotes,
    this.categoryQuotes,
    this.categorySuggestions,
    required this.strengths,
    required this.areasForImprovement,
    required this.feedback,
    required this.evaluatedAt,
    this.ahtHandleSeconds,
    this.ahtOverLimit = false,
    this.customerName = 'Customer',
    this.channel = 'chat',
    this.problem = '',
    this.conversation = const [],
    this.customerRating,
    this.customerComment,
  });

  static int deriveCustomerRating({
    required double overallScore,
    required double empathyScore,
    required double toneScore,
    bool ahtOverLimit = false,
  }) {
    final soft = (empathyScore + toneScore) / 2.0;
    final blend = overallScore * 0.55 + soft * 0.45;
    var stars = ((blend / 10.0) * 5.0).round().clamp(1, 5);
    if (ahtOverLimit && stars > 1) stars -= 1;
    return stars;
  }

  static String deriveCustomerComment(int rating) {
    switch (rating) {
      case 5:
        return 'Very satisfied. The agent resolved my concern clearly and professionally.';
      case 4:
        return 'Good support overall. A few moments could have been smoother.';
      case 3:
        return 'Okay experience. Some parts felt rushed or incomplete.';
      case 2:
        return 'Not fully resolved. Needed more care and clearer next steps.';
      default:
        return 'Poor experience. The issue still feels unclear or unresolved.';
    }
  }

  SessionEvaluation withDerivedCustomerRating() {
    if (customerRating != null) return this;
    final rating = deriveCustomerRating(
      overallScore: overallScore,
      empathyScore: empathyScore,
      toneScore: toneScore,
      ahtOverLimit: ahtOverLimit,
    );
    return SessionEvaluation(
      sector: sector,
      openingSpielScore: openingSpielScore,
      positiveScriptingScore: positiveScriptingScore,
      empathyScore: empathyScore,
      activeListeningScore: activeListeningScore,
      problemIdentificationScore: problemIdentificationScore,
      solutionDeliveryScore: solutionDeliveryScore,
      communicationClarityScore: communicationClarityScore,
      toneScore: toneScore,
      sectorKnowledgeScore: sectorKnowledgeScore,
      closingSpielScore: closingSpielScore,
      overallScore: overallScore,
      typingSpeedScore: typingSpeedScore,
      errorRateAccuracyScore: errorRateAccuracyScore,
      responseConsistencyScore: responseConsistencyScore,
      paceAndSpeedScore: paceAndSpeedScore,
      pronunciationClarityScore: pronunciationClarityScore,
      fillerWordUsageScore: fillerWordUsageScore,
      confidenceScore: confidenceScore,
      dictionScore: dictionScore,
      grammarScore: grammarScore,
      wordChoiceScore: wordChoiceScore,
      categoryNotes: categoryNotes,
      categoryQuotes: categoryQuotes,
      categorySuggestions: categorySuggestions,
      strengths: strengths,
      areasForImprovement: areasForImprovement,
      feedback: feedback,
      evaluatedAt: evaluatedAt,
      ahtHandleSeconds: ahtHandleSeconds,
      ahtOverLimit: ahtOverLimit,
      customerName: customerName,
      channel: channel,
      problem: problem,
      conversation: conversation,
      customerRating: rating,
      customerComment: deriveCustomerComment(rating),
    );
  }

  //from a parsed json, make it into a session evaluation object
  factory SessionEvaluation.fromParsed({
    required String sector,
    required Map<String, String> fields,
  }) {
    //return the value for that specific key, if it doesn't exist
    //return 0. Since the 0 is a string, we parse it into a double
    //if it cannot be parsed, we return 0
    double parse(String key) => double.tryParse(fields[key] ?? '0') ?? 0;

    //set a list of double of scores
    final scores = [
      parse('OPENING_SPIEL'),
      parse('POSITIVE_SCRIPTING'),
      parse('EMPATHY'),
      parse('ACTIVE_LISTENING'),
      parse('PROBLEM_IDENTIFICATION'),
      parse('SOLUTION_DELIVERY'),
      parse('COMMUNICATION_CLARITY'),
      parse('TONE'),
      parse('SECTOR_KNOWLEDGE'),
      parse('CLOSING_SPIEL'),
    ];

    //for every element in the score, we add them altogether and
    //get the average
    final overall = scores.reduce((a, b) => a + b) / scores.length;

    //since everything in the score list is in order, we just set
    //the values of the keys accordingly
    return SessionEvaluation(
      sector: sector,
      openingSpielScore: scores[0],
      positiveScriptingScore: scores[1],
      empathyScore: scores[2],
      activeListeningScore: scores[3],
      problemIdentificationScore: scores[4],
      solutionDeliveryScore: scores[5],
      communicationClarityScore: scores[6],
      toneScore: scores[7],
      sectorKnowledgeScore: scores[8],
      closingSpielScore: scores[9],
      overallScore: double.parse(overall.toStringAsFixed(1)),
      strengths: [
        fields['STRENGTH_1'] ?? '',
        fields['STRENGTH_2'] ?? '',
        fields['STRENGTH_3'] ?? '',
      ].where((s) => s.isNotEmpty).toList(),
      areasForImprovement: [
        fields['IMPROVEMENT_1'] ?? '',
        fields['IMPROVEMENT_2'] ?? '',
        fields['IMPROVEMENT_3'] ?? '',
      ].where((s) => s.isNotEmpty).toList(),
      feedback: fields['FEEDBACK'] ?? '',
      evaluatedAt: DateTime.now(),
      customerName: 'Customer',
      channel: 'chat',
      problem: '',
      conversation: const [],
    );
  }

  SessionEvaluation withMeta({
    String? customerName,
    String? channel,
    String? problem,
    List<Map<String, String>>? conversation,
  }) {
    return SessionEvaluation(
      sector: sector,
      openingSpielScore: openingSpielScore,
      positiveScriptingScore: positiveScriptingScore,
      empathyScore: empathyScore,
      activeListeningScore: activeListeningScore,
      problemIdentificationScore: problemIdentificationScore,
      solutionDeliveryScore: solutionDeliveryScore,
      communicationClarityScore: communicationClarityScore,
      toneScore: toneScore,
      sectorKnowledgeScore: sectorKnowledgeScore,
      closingSpielScore: closingSpielScore,
      overallScore: overallScore,
      typingSpeedScore: typingSpeedScore,
      errorRateAccuracyScore: errorRateAccuracyScore,
      responseConsistencyScore: responseConsistencyScore,
      paceAndSpeedScore: paceAndSpeedScore,
      pronunciationClarityScore: pronunciationClarityScore,
      fillerWordUsageScore: fillerWordUsageScore,
      confidenceScore: confidenceScore,
      dictionScore: dictionScore,
      grammarScore: grammarScore,
      wordChoiceScore: wordChoiceScore,
      categoryNotes: categoryNotes,
      categoryQuotes: categoryQuotes,
      categorySuggestions: categorySuggestions,
      strengths: strengths,
      areasForImprovement: areasForImprovement,
      feedback: feedback,
      evaluatedAt: evaluatedAt,
      ahtHandleSeconds: ahtHandleSeconds,
      ahtOverLimit: ahtOverLimit,
      customerName: customerName ?? this.customerName,
      channel: channel ?? this.channel,
      problem: problem ?? this.problem,
      conversation: conversation ?? this.conversation,
      customerRating: customerRating,
      customerComment: customerComment,
    );
  }

  SessionEvaluation withAht({
    required double handleSeconds,
    int limitSeconds = 600,
  }) {
    final over = handleSeconds > limitSeconds;
    final improvements = List<String>.from(areasForImprovement);
    if (over &&
        !improvements.any((s) => s.toLowerCase().contains('handle time'))) {
      improvements.add('Average Handle Time');
    }
    return SessionEvaluation(
      sector: sector,
      openingSpielScore: openingSpielScore,
      positiveScriptingScore: positiveScriptingScore,
      empathyScore: empathyScore,
      activeListeningScore: activeListeningScore,
      problemIdentificationScore: problemIdentificationScore,
      solutionDeliveryScore: solutionDeliveryScore,
      communicationClarityScore: communicationClarityScore,
      toneScore: toneScore,
      sectorKnowledgeScore: sectorKnowledgeScore,
      closingSpielScore: closingSpielScore,
      overallScore: overallScore,
      typingSpeedScore: typingSpeedScore,
      errorRateAccuracyScore: errorRateAccuracyScore,
      responseConsistencyScore: responseConsistencyScore,
      paceAndSpeedScore: paceAndSpeedScore,
      pronunciationClarityScore: pronunciationClarityScore,
      fillerWordUsageScore: fillerWordUsageScore,
      confidenceScore: confidenceScore,
      dictionScore: dictionScore,
      grammarScore: grammarScore,
      wordChoiceScore: wordChoiceScore,
      categoryNotes: categoryNotes,
      categoryQuotes: categoryQuotes,
      categorySuggestions: categorySuggestions,
      strengths: strengths,
      areasForImprovement: improvements,
      feedback: over
          ? '$feedback\nHandle time ${handleSeconds.toStringAsFixed(0)}s exceeded the ${limitSeconds}s AHT target.'
          : feedback,
      evaluatedAt: evaluatedAt,
      ahtHandleSeconds: handleSeconds,
      ahtOverLimit: over,
      customerName: customerName,
      channel: channel,
      problem: problem,
      conversation: conversation,
      customerRating: customerRating,
      customerComment: customerComment,
    );
  }

  //parsed from Gemini's TESDA-grounded chat evaluation
  factory SessionEvaluation.fromGeminiTesda({
    required String sector,
    required Map<String, String> fields,
  }) {
    double parse(String key) => double.tryParse(fields[key] ?? '0') ?? 0;

    final opening = parse('OPENING_SPIEL');
    final positive = parse('POSITIVE_SCRIPTING');
    final empathy = parse('EMPATHY');
    final active = parse('ACTIVE_LISTENING');
    final problemId = parse('PROBLEM_IDENTIFICATION');
    final solution = parse('SOLUTION_DELIVERY');
    final typingSpeed = parse('TYPING_SPEED_WPM');
    final errorRate = parse('ERROR_RATE_AND_ACCURACY');
    final consistency = parse('RESPONSE_CONSISTENCY_AND_PACE');
    final grammar = parse('GRAMMAR');
    final wordChoice = parse('CORRECT_WORD_USE');
    final clarity = parse('COMMUNICATION_CLARITY');
    final sectorKnowledge = parse('SECTOR_KNOWLEDGE');
    final closing = parse('CLOSING_SPIEL');

    // Chat has no vocal tone field. Tone is the average of empathy + clarity.
    final toneProxy =
        double.parse(((empathy + clarity) / 2).toStringAsFixed(1));

    const noteKeys = {
      'OPENING_SPIEL': 'Opening Spiel',
      'POSITIVE_SCRIPTING': 'Positive Scripting',
      'EMPATHY': 'Empathy',
      'ACTIVE_LISTENING': 'Active Listening',
      'PROBLEM_IDENTIFICATION': 'Problem Identification',
      'SOLUTION_DELIVERY': 'Solution Delivery',
      'TYPING_SPEED_WPM': 'Typing Speed',
      'ERROR_RATE_AND_ACCURACY': 'Error Rate & Accuracy',
      'RESPONSE_CONSISTENCY_AND_PACE': 'Response Consistency & Pace',
      'GRAMMAR': 'Grammar',
      'CORRECT_WORD_USE': 'Correct Word Use',
      'COMMUNICATION_CLARITY': 'Communication Clarity',
      'SECTOR_KNOWLEDGE': 'Sector Knowledge',
      'CLOSING_SPIEL': 'Closing Spiel',
    };
    final notes = <String, String>{};
    final quotes = <String, String>{};
    final suggestions = <String, String>{};
    noteKeys.forEach((key, label) {
      final note = fields['${key}_NOTE'];
      if (note != null &&
          note.trim().isNotEmpty &&
          !note.toLowerCase().contains('full marks') &&
          note.trim() != 'N/A') {
        notes[label] = note.trim();
      }
      final quote = fields['${key}_QUOTE'];
      if (quote != null &&
          quote.trim().isNotEmpty &&
          quote.trim().toUpperCase() != 'N/A') {
        quotes[label] = quote.trim();
      }
      final suggest = fields['${key}_SUGGEST'];
      if (suggest != null &&
          suggest.trim().isNotEmpty &&
          suggest.trim().toUpperCase() != 'N/A' &&
          !suggest.toLowerCase().contains('full marks')) {
        suggestions[label] = suggest.trim();
      }
    });

    if (toneProxy < 9.95) {
      final parts = <String>[
        'Chat tone is derived as (Empathy ${empathy.toStringAsFixed(1)} + Communication Clarity ${clarity.toStringAsFixed(1)}) / 2 = ${toneProxy.toStringAsFixed(1)}.',
      ];
      final empNote = notes['Empathy'];
      final clrNote = notes['Communication Clarity'];
      if (empNote != null && empNote.isNotEmpty) {
        parts.add('Empathy gap: $empNote');
      }
      if (clrNote != null && clrNote.isNotEmpty) {
        parts.add('Clarity gap: $clrNote');
      }
      if (empNote == null && clrNote == null) {
        if (empathy < clarity) {
          parts.add(
            'Empathy pulled tone down. Acknowledge the customer emotion more specifically before process talk.',
          );
        } else if (clarity < empathy) {
          parts.add(
            'Clarity pulled tone down. Use shorter, warmer phrasing that still sounds professional.',
          );
        } else {
          parts.add(
            'Both empathy and clarity were below full marks, which lowered the combined tone score.',
          );
        }
      }
      notes['Tone'] = parts.join(' ');
      final empSuggest = suggestions['Empathy'];
      final clrSuggest = suggestions['Communication Clarity'];
      if (empSuggest != null && empSuggest.isNotEmpty) {
        suggestions['Tone'] = empSuggest;
      } else if (clrSuggest != null && clrSuggest.isNotEmpty) {
        suggestions['Tone'] = clrSuggest;
      } else {
        suggestions['Tone'] =
            'I can hear how frustrating this has been. Let me walk you through the next step clearly so we can get you unblocked.';
      }
    }

    double keepIfEvidenced(String label, double score) {
      if (score >= 9.95) return score;
      final n = notes[label];
      if (n == null || n.trim().isEmpty) return 10.0;
      return score;
    }

    final openingE = keepIfEvidenced('Opening Spiel', opening);
    final positiveE = keepIfEvidenced('Positive Scripting', positive);
    final empathyE = keepIfEvidenced('Empathy', empathy);
    final activeE = keepIfEvidenced('Active Listening', active);
    final problemE = keepIfEvidenced('Problem Identification', problemId);
    final solutionE = keepIfEvidenced('Solution Delivery', solution);
    final clarityE = keepIfEvidenced('Communication Clarity', clarity);
    final toneE = keepIfEvidenced('Tone', toneProxy);
    final sectorE = keepIfEvidenced('Sector Knowledge', sectorKnowledge);
    final closingE = keepIfEvidenced('Closing Spiel', closing);
    final overallE =
        (openingE +
            positiveE +
            empathyE +
            activeE +
            problemE +
            solutionE +
            clarityE +
            toneE +
            sectorE +
            closingE) /
        10;

    return SessionEvaluation(
      sector: sector,
      openingSpielScore: openingE,
      positiveScriptingScore: positiveE,
      empathyScore: empathyE,
      activeListeningScore: activeE,
      problemIdentificationScore: problemE,
      solutionDeliveryScore: solutionE,
      communicationClarityScore: clarityE,
      toneScore: toneE,
      sectorKnowledgeScore: sectorE,
      closingSpielScore: closingE,
      overallScore: double.parse(overallE.toStringAsFixed(1)),
      typingSpeedScore: typingSpeed,
      errorRateAccuracyScore: errorRate,
      responseConsistencyScore: consistency,
      grammarScore: grammar,
      wordChoiceScore: wordChoice,
      categoryNotes: notes,
      categoryQuotes: quotes,
      categorySuggestions: suggestions,
      strengths: [
        fields['STRENGTH_1'] ?? '',
        fields['STRENGTH_2'] ?? '',
        fields['STRENGTH_3'] ?? '',
      ].where((s) => s.isNotEmpty).toList(),
      areasForImprovement: [
        fields['IMPROVEMENT_1'] ?? '',
        fields['IMPROVEMENT_2'] ?? '',
        fields['IMPROVEMENT_3'] ?? '',
      ].where((s) => s.isNotEmpty).toList(),
      feedback: fields['FEEDBACK'] ?? '',
      evaluatedAt: DateTime.now(),
    );
  }

  //parsed from Gemini's TESDA-grounded VOICE evaluation
  factory SessionEvaluation.fromGeminiVoiceTesda({
    required String sector,
    required Map<String, String> fields,
  }) {
    double parse(String key) => double.tryParse(fields[key] ?? '0') ?? 0;

    final opening = parse('OPENING_SPIEL');
    final positive = parse('POSITIVE_SCRIPTING');
    final empathy = parse('EMPATHY');
    final active = parse('ACTIVE_LISTENING');
    final problemId = parse('PROBLEM_IDENTIFICATION');
    final solution = parse('SOLUTION_DELIVERY');
    final pace = parse('PACE_AND_SPEED');
    final pronunciation = fields.containsKey('PRONUNCIATION')
        ? parse('PRONUNCIATION')
        : parse('PRONUNCIATION_AND_CLARITY');
    final diction = fields.containsKey('DICTION')
        ? parse('DICTION')
        : pronunciation;
    final spokenClarity = fields.containsKey('SPOKEN_CLARITY')
        ? parse('SPOKEN_CLARITY')
        : pronunciation;
    final fillerWords = parse('FILLER_WORD_USAGE');
    final tone = parse('TONE_AND_INFLECTION');
    final confidence =
        fields.containsKey('CONFIDENCE') ? parse('CONFIDENCE') : tone;
    final sectorKnowledge = parse('SECTOR_KNOWLEDGE');
    final closing = parse('CLOSING_SPIEL');

    // Overall uses spoken clarity as Communication Clarity, not pronunciation.
    // Delivery categories stay separate on the report. Final overall is overallE
    // after evidence gating below.

    const noteKeys = {
      'OPENING_SPIEL': 'Opening Spiel',
      'POSITIVE_SCRIPTING': 'Positive Scripting',
      'EMPATHY': 'Empathy',
      'ACTIVE_LISTENING': 'Active Listening',
      'PROBLEM_IDENTIFICATION': 'Problem Identification',
      'SOLUTION_DELIVERY': 'Solution Delivery',
      'PACE_AND_SPEED': 'Pace & Speed',
      'PRONUNCIATION': 'Pronunciation',
      'PRONUNCIATION_AND_CLARITY': 'Pronunciation',
      'DICTION': 'Diction',
      'SPOKEN_CLARITY': 'Spoken Clarity',
      'CONFIDENCE': 'Confidence',
      'FILLER_WORD_USAGE': 'Filler Word Usage',
      'TONE_AND_INFLECTION': 'Tone',
      'SECTOR_KNOWLEDGE': 'Sector Knowledge',
      'CLOSING_SPIEL': 'Closing Spiel',
    };
    final notes = <String, String>{};
    final quotes = <String, String>{};
    final suggestions = <String, String>{};
    noteKeys.forEach((key, label) {
      final note = fields['${key}_NOTE'];
      if (note != null &&
          note.trim().isNotEmpty &&
          !note.toLowerCase().contains('full marks') &&
          note.trim() != 'N/A') {
        notes[label] = note.trim();
      }
      final quote = fields['${key}_QUOTE'];
      if (quote != null &&
          quote.trim().isNotEmpty &&
          quote.trim().toUpperCase() != 'N/A') {
        quotes[label] = quote.trim();
      }
      final suggest = fields['${key}_SUGGEST'];
      if (suggest != null &&
          suggest.trim().isNotEmpty &&
          suggest.trim().toUpperCase() != 'N/A' &&
          !suggest.toLowerCase().contains('full marks')) {
        suggestions[label] = suggest.trim();
      }
    });

    double keepIfEvidenced(String label, double score) {
      if (score >= 9.95) return score;
      final n = notes[label];
      if (n == null || n.trim().isEmpty) return 10.0;
      return score;
    }

    final openingE = keepIfEvidenced('Opening Spiel', opening);
    final positiveE = keepIfEvidenced('Positive Scripting', positive);
    final empathyE = keepIfEvidenced('Empathy', empathy);
    final activeE = keepIfEvidenced('Active Listening', active);
    final problemE = keepIfEvidenced('Problem Identification', problemId);
    final solutionE = keepIfEvidenced('Solution Delivery', solution);
    final clarityE = keepIfEvidenced('Spoken Clarity', spokenClarity);
    final toneE = keepIfEvidenced('Tone', tone);
    final sectorE = keepIfEvidenced('Sector Knowledge', sectorKnowledge);
    final closingE = keepIfEvidenced('Closing Spiel', closing);
    final overallE =
        (openingE +
            positiveE +
            empathyE +
            activeE +
            problemE +
            solutionE +
            clarityE +
            toneE +
            sectorE +
            closingE) /
        10;

    return SessionEvaluation(
      sector: sector,
      openingSpielScore: openingE,
      positiveScriptingScore: positiveE,
      empathyScore: empathyE,
      activeListeningScore: activeE,
      problemIdentificationScore: problemE,
      solutionDeliveryScore: solutionE,
      communicationClarityScore: clarityE,
      toneScore: toneE,
      sectorKnowledgeScore: sectorE,
      closingSpielScore: closingE,
      overallScore: double.parse(overallE.toStringAsFixed(1)),
      paceAndSpeedScore: pace,
      pronunciationClarityScore: pronunciation,
      fillerWordUsageScore: fillerWords,
      confidenceScore: confidence,
      dictionScore: diction,
      categoryNotes: notes,
      categoryQuotes: quotes,
      categorySuggestions: suggestions,
      strengths: [
        fields['STRENGTH_1'] ?? '',
        fields['STRENGTH_2'] ?? '',
        fields['STRENGTH_3'] ?? '',
      ].where((s) => s.isNotEmpty).toList(),
      areasForImprovement: [
        fields['IMPROVEMENT_1'] ?? '',
        fields['IMPROVEMENT_2'] ?? '',
        fields['IMPROVEMENT_3'] ?? '',
      ].where((s) => s.isNotEmpty).toList(),
      feedback: fields['FEEDBACK'] ?? '',
      evaluatedAt: DateTime.now(),
    );
  }

  //if the evaluation somehow fails, we return a fallback
  factory SessionEvaluation.fallback(String sector) {
    return SessionEvaluation(
      sector: sector,
      openingSpielScore: 0,
      positiveScriptingScore: 0,
      empathyScore: 0,
      activeListeningScore: 0,
      problemIdentificationScore: 0,
      solutionDeliveryScore: 0,
      communicationClarityScore: 0,
      toneScore: 0,
      sectorKnowledgeScore: 0,
      closingSpielScore: 0,
      overallScore: 0,
      strengths: [],
      areasForImprovement: [],
      feedback: 'Evaluation could not be completed.',
      evaluatedAt: DateTime.now(),
    );
  }
}
