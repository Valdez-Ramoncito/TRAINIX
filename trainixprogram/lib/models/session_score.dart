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
  final List<String> strengths;
  final List<String> areasForImprovement;
  final String feedback;
  final DateTime evaluatedAt;

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
    required this.strengths,
    required this.areasForImprovement,
    required this.feedback,
    required this.evaluatedAt,
  });

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
