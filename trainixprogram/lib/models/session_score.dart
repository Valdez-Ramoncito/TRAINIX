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

  //per-category citation/justification text from the evaluator. Only
  //populated by the Gemini/TESDA chat and voice paths.
  final Map<String, String>? categoryNotes;

  //per-category verbatim excerpt from the trainee's own transcript that
  //the evaluator is citing as evidence
  //but this is the raw quoted line itself rather than the evaluator's
  //explanation of it.
  final Map<String, String>? categoryQuotes;

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

  /// Customer CSAT stars 1-5, derived from soft skills + overall score.
  final int? customerRating;

  /// Short customer-perspective comment paired with [customerRating].
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
    this.categoryNotes,
    this.categoryQuotes,
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
      categoryNotes: categoryNotes,
      categoryQuotes: categoryQuotes,
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
      categoryNotes: categoryNotes,
      categoryQuotes: categoryQuotes,
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
      categoryNotes: categoryNotes,
      categoryQuotes: categoryQuotes,
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
    final clarity = parse('COMMUNICATION_CLARITY');
    final sectorKnowledge = parse('SECTOR_KNOWLEDGE');
    final closing = parse('CLOSING_SPIEL');

    //chat has no vocal tone to score. Proxied from empathy + clarity,
    final toneProxy = (empathy + clarity) / 2;

    //overallScore
    final overall =
        [
          opening,
          positive,
          empathy,
          active,
          problemId,
          solution,
          clarity,
          toneProxy,
          sectorKnowledge,
          closing,
        ].reduce((a, b) => a + b) /
        10;

    //human-readable labels for the note map. Matches what Session
    //Report will display
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
      'COMMUNICATION_CLARITY': 'Communication Clarity',
      'SECTOR_KNOWLEDGE': 'Sector Knowledge',
      'CLOSING_SPIEL': 'Closing Spiel',
    };
    final notes = <String, String>{};
    final quotes = <String, String>{};
    noteKeys.forEach((key, label) {
      final note = fields['${key}_NOTE'];
      //skip empty notes and the "full marks" case. Only store notes
      //that actually explain a deduction
      if (note != null &&
          note.trim().isNotEmpty &&
          !note.toLowerCase().contains('full marks') &&
          note.trim() != 'N/A') {
        notes[label] = note.trim();
      }
      //verbatim transcript excerpt supporting the note above. Omitted
      //if the evaluator said "N/A" which means no specific line exists
      final quote = fields['${key}_QUOTE'];
      if (quote != null &&
          quote.trim().isNotEmpty &&
          quote.trim().toUpperCase() != 'N/A') {
        quotes[label] = quote.trim();
      }
    });

    return SessionEvaluation(
      sector: sector,
      openingSpielScore: opening,
      positiveScriptingScore: positive,
      empathyScore: empathy,
      activeListeningScore: active,
      problemIdentificationScore: problemId,
      solutionDeliveryScore: solution,
      communicationClarityScore: clarity,
      toneScore: toneProxy,
      sectorKnowledgeScore: sectorKnowledge,
      closingSpielScore: closing,
      overallScore: double.parse(overall.toStringAsFixed(1)),
      typingSpeedScore: typingSpeed,
      errorRateAccuracyScore: errorRate,
      responseConsistencyScore: consistency,
      categoryNotes: notes,
      categoryQuotes: quotes,
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
    final pronunciation = parse('PRONUNCIATION_AND_CLARITY');
    final fillerWords = parse('FILLER_WORD_USAGE');
    final tone = parse('TONE_AND_INFLECTION');
    final sectorKnowledge = parse('SECTOR_KNOWLEDGE');
    final closing = parse('CLOSING_SPIEL');

    //voice doesn't have a separate "communication clarity" category in
    //this rubric. Spoken clarity is pronunciation for voice.
    //proxied directly from pronunciation so the shared Dashboard
    //"Communication Clarity" category keeps a value across both channels
    final clarityProxy = pronunciation;

    //Overall Score
    final overall =
        [
          opening,
          positive,
          empathy,
          active,
          problemId,
          solution,
          clarityProxy,
          tone,
          sectorKnowledge,
          closing,
        ].reduce((a, b) => a + b) /
        10;

    const noteKeys = {
      'OPENING_SPIEL': 'Opening Spiel',
      'POSITIVE_SCRIPTING': 'Positive Scripting',
      'EMPATHY': 'Empathy',
      'ACTIVE_LISTENING': 'Active Listening',
      'PROBLEM_IDENTIFICATION': 'Problem Identification',
      'SOLUTION_DELIVERY': 'Solution Delivery',
      'PACE_AND_SPEED': 'Pace & Speed',
      'PRONUNCIATION_AND_CLARITY': 'Pronunciation & Clarity',
      'FILLER_WORD_USAGE': 'Filler Word Usage',
      'TONE_AND_INFLECTION': 'Tone & Inflection',
      'SECTOR_KNOWLEDGE': 'Sector Knowledge',
      'CLOSING_SPIEL': 'Closing Spiel',
    };
    final notes = <String, String>{};
    final quotes = <String, String>{};
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
    });

    return SessionEvaluation(
      sector: sector,
      openingSpielScore: opening,
      positiveScriptingScore: positive,
      empathyScore: empathy,
      activeListeningScore: active,
      problemIdentificationScore: problemId,
      solutionDeliveryScore: solution,
      communicationClarityScore: clarityProxy,
      toneScore: tone,
      sectorKnowledgeScore: sectorKnowledge,
      closingSpielScore: closing,
      overallScore: double.parse(overall.toStringAsFixed(1)),
      paceAndSpeedScore: pace,
      pronunciationClarityScore: pronunciation,
      fillerWordUsageScore: fillerWords,
      categoryNotes: notes,
      categoryQuotes: quotes,
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
