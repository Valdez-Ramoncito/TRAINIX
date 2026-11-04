import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:trainixprogram/models/messages.dart';
import 'package:trainixprogram/models/session_score.dart';

//TESDA rubric, grounded in TR_Contact_Center_Services_NC_II.docx

//Sourcing of the SCORING MECHANISM specifically TR_Contact_Center_Services_NC_II.docx,
//Section 4, states plainly: "There is no National Assessment for this
//TR. The industry association concerned shall develop non-branded/
//non-proprietary assessment tools for the qualification..."  i.e.
//TESDA itself defines no numeric instrument and explicitly defers
//that to industry. The category-based, start-at-maximum,
//deduct-per-observed-violation method used below is not this team's
//own invention filling that gap  it follows the documented,
//converging convention across independent BPO industry QA-scorecard
//sources for scoring the exact same category types TESDA names
//(opening, issue identification/discovery, communication, empathy,
//resolution, closing):
//  - Balto (2025). "Call Center Quality Monitoring Scorecard Best
//    Practices." https://www.balto.ai/blog/call-center-quality-monitoring-scorecard/
//  - Calabrio (2026). "Call Center QA Scorecards: 7 Tips for Quality
//    Assurance and CX Excellence."
//    https://www.calabrio.com/blog/quality-assurance-qa-scorecard/
//  - Five9 (2026). "How to Create High-Quality Scorecards for Your
//    Contact Center." https://www.five9.com/blog/how-create-contact-center-scorecard
//These sources independently describe the same start-at-max,
//deduct-for-a-miss mechanism used in this rubric. TESDA supplies
//what to measure, these sources support how that gets made
//measurable, for the same kind of interaction TESDA is written for.
class GeminiEvaluationApiService {
  static final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String _model = 'gemini-3.1-flash-lite';
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  //TESDA rubric
  static const String _tesdaRubricInstructions =
      'You are an experienced BPO QA Evaluator applying the TESDA Contact '
      'Center Services NC II Training Regulation to a CHAT-based customer '
      'interaction. IMPORTANT CONTEXT: TESDA\'s own assessment methodology '
      'is a binary Competent / Not Yet Competent judgment made from a '
      'Satisfactory / Not Satisfactory checklist  it defines no numeric '
      'score, point scale, or percentage threshold of any kind. The 0-10 '
      'scale below, every deduction amount, and every numeric threshold '
      '(WPM baselines, accuracy percentages, second counts, etc.) is this '
      'application\'s own scoring instrument, built to operationalize '
      'TESDA\'s qualitative competency elements into measurable feedback  '
      'none of those numbers are themselves sourced from the TR document. '
      'Score each of the 12 categories below from 0 to 10, starting every '
      'category at 10 and applying deductions only where the transcript '
      'or telemetry actually shows a violation  do not deduct on '
      'assumption. This start-at-maximum, deduct-per-violation method '
      'follows documented BPO industry QA-scorecard convention (see the '
      'sourcing note above this constant in the source file) for scoring '
      'the same category types named below  it is not an unsourced '
      'scoring scheme.\n\n'
      '1. OPENING_SPIEL (Core Unit 2, ICT313366  Perform Customer Service '
      'Delivery Processes; the enterprise inbound procedure explicitly '
      'requires an opening spiel before identifying the customer\'s need): '
      'greeting, agent identification, offer of assistance. -3 if missing '
      'agent identification, -4 for a generic/unprofessional greeting.\n'
      '2. POSITIVE_SCRIPTING (Core Unit 3, ICT313367  Engage Customers): '
      'constructive reframing instead of flat refusals. -3 for phrases '
      'like "I can\'t do that" / "that\'s policy" used without an '
      'alternative offered in the same breath; -2 for a blunt rejection '
      'with no alternative at all.\n'
      '3. EMPATHY (Core Unit 3, ICT313367): explicit written acknowledgment '
      'of the customer\'s stated emotion before troubleshooting starts. -5 '
      'if the customer\'s emotional state is never acknowledged; -3 if the '
      'acknowledgment feels canned/copy-pasted rather than specific to '
      'what the customer said.\n'
      '4. ACTIVE_LISTENING (Core Unit 1, ICT313365): confirming/restating '
      'the issue instead of re-asking for information already given. -5 '
      'if the agent asks for information the customer already provided '
      'in their opening message.\n'
      '5. PROBLEM_IDENTIFICATION (Core Unit 2, ICT313366  Customer '
      'Service Delivery Processes): correct root-cause isolation for the '
      'sector. -5 for misdiagnosis; -3 for unnecessary troubleshooting '
      'steps not relevant to the stated problem.\n'
      '6. SOLUTION_DELIVERY (Core Unit 2, ICT313366): accuracy and '
      'completeness of the fix/steps given. -10 for incorrect policy or '
      'factual information; -5 for an incomplete set of instructions.\n'
      '7. TYPING_SPEED_WPM (Common Unit 2, ICT311203  Perform Computer '
      'Operations; the docx requires accurate, procedure-compliant data '
      'entry but names no numeric speed standard at all). 30-35+ WPM is '
      'general BPO-industry convention, NOT a TESDA-specified number  '
      'apply it as a reasonable baseline, not a cited requirement. -2 if '
      'WPM is 25-29, -5 if WPM is below 25. The measured WPM for this '
      'interaction is given to you below  do not estimate it yourself '
      'from the transcript.\n'
      '8. ERROR_RATE_AND_ACCURACY (Common Unit 2, ICT311203  the docx '
      'requires that "accuracy of information is checked" but names no '
      'numeric threshold): keystroke precision plus spelling/grammar in '
      'the actual messages. The keystroke-accuracy percentage is given to '
      'you below (derived from backspace count)  use it as your primary '
      'signal. The 95% threshold below is general BPO-industry '
      'convention, NOT TESDA-specified. Deduct -2 per clear spelling/'
      'grammar error you see in the transcript itself, -3 additional if '
      'accuracy drops under 95%.\n'
      '9. RESPONSE_CONSISTENCY_AND_PACE (no single named TESDA element  '
      'this category operationalizes the general expectation of prompt, '
      'consistent service implied across Core Unit 2/ICT313366 and '
      'Common Unit 2/ICT311203, but the specific reply-latency numbers '
      'below are our own convention, not TESDA-specified): reply latency '
      'and pacing. A reply-latency log is given to you below. -3 for any '
      'single reply taking longer than 60 seconds with no explanation '
      'visible in the transcript; -3 for erratic/uneven intervals '
      'between replies.\n'
      '10. COMMUNICATION_CLARITY (Core Unit 1, ICT313365  the 3 C\'s of '
      'communication: clarity, conciseness, coherence): short, digestible '
      'chat messages instead of dense walls of text. Note: the docx '
      'doesn\'t name "wall of text" or slang avoidance specifically  '
      'this category is our own operationalization of "clarity/'
      'conciseness" for a text channel. -3 for any single message that '
      'reads as an unformatted wall of text; -2 for informal chat slang/'
      'abbreviations ("u", "r", "plss").\n'
      '11. SECTOR_KNOWLEDGE (Core Unit 2, ICT313366): correct terminology '
      'and process for the given sector. -5 for failing an identity/'
      'security check where one was clearly warranted; -3 for incorrect '
      'sector-specific terminology.\n'
      '12. CLOSING_SPIEL (Core Unit 2, ICT313366  the same inbound '
      'procedure explicitly requires a closing spiel): confirmation the '
      'issue is resolved, offer of further help, sign-off. -3 if missing '
      'the offer of further help; -3 if missing a sign-off entirely.\n\n'
      'CRITICAL: for every category scoring below 10, the paired _NOTE '
      'field MUST quote or cite the exact transcript line or telemetry '
      'value that justified the deduction  no vague reasoning. For a '
      'category that scores a full 10, its _NOTE field must say exactly: '
      'Full marks.\n'
      'USER-FACING LANGUAGE: strength lists, improvement lists, notes, and '
      'FEEDBACK must be plain coaching language. Never mention Core Unit, '
      'Common Unit, ICT codes, Basic Competency numbers, TESDA, or NC II '
      'in those fields. Name the skill in everyday words (greeting, empathy, '
      'problem solving, closing).';

  //build the transcript
  String _buildTranscript(List<Message> messages) {
    final buffer = StringBuffer();
    for (final msg in messages) {
      if (msg.role == 'user') {
        final content = msg.message.replaceFirst('[AGENT]: ', '');
        buffer.writeln('AGENT: $content');
      } else if (msg.role == 'assistant') {
        buffer.writeln('CUSTOMER: ${msg.message}');
      }
    }
    return buffer.toString().trim();
  }

  //builds a reply-latency log from real message timestamps
  //this is what feeds RESPONSE_CONSISTENCY_AND_PACE
  String _buildTimestampLog(List<Message> messages) {
    final lines = <String>[];
    for (int i = 0; i < messages.length - 1; i++) {
      final current = messages[i];
      final next = messages[i + 1];
      if (current.role == 'assistant' && next.role == 'user') {
        final latency = next.timestamp.difference(current.timestamp).inSeconds;
        lines.add('Customer message -> agent reply took ${latency}s');
      }
    }
    if (lines.isEmpty) return 'No timed turns recorded for this interaction.';
    return lines.join('\n');
  }

  //assembles the full prompt
  String _buildEvaluationPrompt({
    required String transcript,
    required String sector,
    required String customerEmotion,
    required String customerProblem,
    required double typingWpm,
    required double typingAccuracy,
    required int backspaceCount,
    required String timestampLog,
  }) {
    return '$_tesdaRubricInstructions\n\n'
        'SECTOR: $sector\n'
        'CUSTOMER EMOTION: $customerEmotion\n'
        'CUSTOMER PROBLEM: $customerProblem\n\n'
        'TRANSCRIPT:\n$transcript\n\n'
        'TYPING METRICS FOR THIS INTERACTION:\n'
        'Average typing speed: ${typingWpm.toStringAsFixed(0)} WPM\n'
        'Keystroke accuracy: ${typingAccuracy.toStringAsFixed(0)}% '
        '(derived from $backspaceCount backspace keystrokes across the '
        'interaction)\n\n'
        'REPLY-LATENCY LOG:\n$timestampLog\n\n'
        'For every category below, in addition to its NOTE, also '
        'provide a QUOTE field: the exact, verbatim line the AGENT (not '
        'the customer) actually typed in the transcript above that best '
        'demonstrates the deduction. Copy it exactly as written  do '
        'not paraphrase it. If the violation is about something the '
        'agent never said (e.g. a missing opening spiel, a missing '
        'sign-off) rather than something they said incorrectly, there '
        'is no line to quote  respond with exactly "N/A" for that '
        'QUOTE field instead of inventing one. If the category scored '
        'full marks, respond with exactly "N/A" for its QUOTE field '
        'too.\n\n'
        'Respond in EXACTLY this format with no extra text before or '
        'after, no markdown, no commentary:\n'
        'OPENING_SPIEL: <0-10>\n'
        'OPENING_SPIEL_NOTE: <citation or "Full marks">\n'
        'OPENING_SPIEL_QUOTE: <verbatim agent line or "N/A">\n'
        'POSITIVE_SCRIPTING: <0-10>\n'
        'POSITIVE_SCRIPTING_NOTE: <citation or "Full marks">\n'
        'POSITIVE_SCRIPTING_QUOTE: <verbatim agent line or "N/A">\n'
        'EMPATHY: <0-10>\n'
        'EMPATHY_NOTE: <citation or "Full marks">\n'
        'EMPATHY_QUOTE: <verbatim agent line or "N/A">\n'
        'ACTIVE_LISTENING: <0-10>\n'
        'ACTIVE_LISTENING_NOTE: <citation or "Full marks">\n'
        'ACTIVE_LISTENING_QUOTE: <verbatim agent line or "N/A">\n'
        'PROBLEM_IDENTIFICATION: <0-10>\n'
        'PROBLEM_IDENTIFICATION_NOTE: <citation or "Full marks">\n'
        'PROBLEM_IDENTIFICATION_QUOTE: <verbatim agent line or "N/A">\n'
        'SOLUTION_DELIVERY: <0-10>\n'
        'SOLUTION_DELIVERY_NOTE: <citation or "Full marks">\n'
        'SOLUTION_DELIVERY_QUOTE: <verbatim agent line or "N/A">\n'
        'TYPING_SPEED_WPM: <0-10>\n'
        'TYPING_SPEED_WPM_NOTE: <citation or "Full marks">\n'
        'TYPING_SPEED_WPM_QUOTE: <verbatim agent line or "N/A">\n'
        'ERROR_RATE_AND_ACCURACY: <0-10>\n'
        'ERROR_RATE_AND_ACCURACY_NOTE: <citation or "Full marks">\n'
        'ERROR_RATE_AND_ACCURACY_QUOTE: <verbatim agent line or "N/A">\n'
        'RESPONSE_CONSISTENCY_AND_PACE: <0-10>\n'
        'RESPONSE_CONSISTENCY_AND_PACE_NOTE: <citation or "Full marks">\n'
        'RESPONSE_CONSISTENCY_AND_PACE_QUOTE: <verbatim agent line or "N/A">\n'
        'COMMUNICATION_CLARITY: <0-10>\n'
        'COMMUNICATION_CLARITY_NOTE: <citation or "Full marks">\n'
        'COMMUNICATION_CLARITY_QUOTE: <verbatim agent line or "N/A">\n'
        'SECTOR_KNOWLEDGE: <0-10>\n'
        'SECTOR_KNOWLEDGE_NOTE: <citation or "Full marks">\n'
        'SECTOR_KNOWLEDGE_QUOTE: <verbatim agent line or "N/A">\n'
        'CLOSING_SPIEL: <0-10>\n'
        'CLOSING_SPIEL_NOTE: <citation or "Full marks">\n'
        'CLOSING_SPIEL_QUOTE: <verbatim agent line or "N/A">\n'
        'STRENGTH_1: <demonstrated competency with evidence>\n'
        'STRENGTH_2: <demonstrated competency with evidence>\n'
        'STRENGTH_3: <demonstrated competency with evidence>\n'
        'IMPROVEMENT_1: <specific rule broken with exact quote/metric>\n'
        'IMPROVEMENT_2: <specific rule broken with exact quote/metric>\n'
        'IMPROVEMENT_3: <specific rule broken with exact quote/metric>\n'
        'FEEDBACK: <coaching summary tied back to the TESDA units above>';
  }

  //parses Gemini's response
  SessionEvaluation _parseEvaluation(String raw, String sector) {
    String cleaned = raw.trim();
    if (cleaned.contains('```')) {
      cleaned = cleaned.replaceAll(RegExp(r'```json|```'), '').trim();
    }

    final lastBlockIdx = cleaned.lastIndexOf('\nOPENING_SPIEL:');
    if (lastBlockIdx >= 0) {
      cleaned = cleaned.substring(lastBlockIdx).trim();
    } else {
      final startIdx = cleaned.indexOf('OPENING_SPIEL:');
      if (startIdx >= 0) cleaned = cleaned.substring(startIdx);
    }

    String feedback = '';
    final feedbackIdx = cleaned.indexOf('FEEDBACK:');
    if (feedbackIdx >= 0) {
      feedback = cleaned.substring(feedbackIdx + 9).trim();
      cleaned = cleaned.substring(0, feedbackIdx);
    }

    const validKeys = {
      'OPENING_SPIEL',
      'OPENING_SPIEL_NOTE',
      'OPENING_SPIEL_QUOTE',
      'POSITIVE_SCRIPTING',
      'POSITIVE_SCRIPTING_NOTE',
      'POSITIVE_SCRIPTING_QUOTE',
      'EMPATHY',
      'EMPATHY_NOTE',
      'EMPATHY_QUOTE',
      'ACTIVE_LISTENING',
      'ACTIVE_LISTENING_NOTE',
      'ACTIVE_LISTENING_QUOTE',
      'PROBLEM_IDENTIFICATION',
      'PROBLEM_IDENTIFICATION_NOTE',
      'PROBLEM_IDENTIFICATION_QUOTE',
      'SOLUTION_DELIVERY',
      'SOLUTION_DELIVERY_NOTE',
      'SOLUTION_DELIVERY_QUOTE',
      'TYPING_SPEED_WPM',
      'TYPING_SPEED_WPM_NOTE',
      'TYPING_SPEED_WPM_QUOTE',
      'ERROR_RATE_AND_ACCURACY',
      'ERROR_RATE_AND_ACCURACY_NOTE',
      'ERROR_RATE_AND_ACCURACY_QUOTE',
      'RESPONSE_CONSISTENCY_AND_PACE',
      'RESPONSE_CONSISTENCY_AND_PACE_NOTE',
      'RESPONSE_CONSISTENCY_AND_PACE_QUOTE',
      'COMMUNICATION_CLARITY',
      'COMMUNICATION_CLARITY_NOTE',
      'COMMUNICATION_CLARITY_QUOTE',
      'SECTOR_KNOWLEDGE',
      'SECTOR_KNOWLEDGE_NOTE',
      'SECTOR_KNOWLEDGE_QUOTE',
      'CLOSING_SPIEL',
      'CLOSING_SPIEL_NOTE',
      'CLOSING_SPIEL_QUOTE',
      'STRENGTH_1',
      'STRENGTH_2',
      'STRENGTH_3',
      'IMPROVEMENT_1',
      'IMPROVEMENT_2',
      'IMPROVEMENT_3',
    };

    final fields = <String, String>{};
    for (final line in cleaned.split('\n')) {
      final idx = line.indexOf(':');
      if (idx > 0) {
        final key = line.substring(0, idx).trim().toUpperCase();
        final value = line.substring(idx + 1).trim();
        if (validKeys.contains(key)) fields[key] = value;
      }
    }
    fields['FEEDBACK'] = feedback;

    if (fields.containsKey('OPENING_SPIEL')) {
      return SessionEvaluation.fromGeminiTesda(sector: sector, fields: fields);
    }
    return SessionEvaluation.fallback(sector);
  }

  Future<String?> _sendRequest(String prompt) async {
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await http
            .post(
              Uri.parse('$_endpoint?key=$_apiKey'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                "contents": [
                  {
                    "role": "user",
                    "parts": [
                      {"text": prompt},
                    ],
                  },
                ],
                "generationConfig": {
                  "temperature": 0.3,
                  "maxOutputTokens": 3000,
                  "thinkingConfig": {"thinkingLevel": "low"},
                },
              }),
            )
            .timeout(const Duration(seconds: 12));

        if (response.statusCode != 200) {
          print(
            "Gemini evaluation error ${response.statusCode}: ${response.body}",
          );
          if (response.statusCode == 503 || response.statusCode == 429) {
            return null;
          }
          continue;
        }

        final data = jsonDecode(response.body);
        final content =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'];

        print("Gemini Evaluation Status: ${response.statusCode}");
        print("Gemini Evaluation Response: $content");

        if (content == null || content is! String || content.trim().isEmpty) {
          print(
            "Null Gemini evaluation content  retrying (attempt ${attempt + 1}/3)",
          );
          continue;
        }

        return content;
      } catch (e, stack) {
        print("Exception in Gemini evaluation _sendRequest: $e");
        print(stack);
      }
    }
    return null;
  }

  //evaluates a resolved chat interaction against the TESDA rubric
  Future<SessionEvaluation> evaluateChatTesda({
    required List<Message> messages,
    required String sector,
    required String customerEmotion,
    required String customerProblem,
    required double typingWpm,
    required double typingAccuracy,
    required int backspaceCount,
  }) async {
    final transcript = _buildTranscript(messages);
    if (transcript.isEmpty) return SessionEvaluation.fallback(sector);

    final timestampLog = _buildTimestampLog(messages);

    final prompt = _buildEvaluationPrompt(
      transcript: transcript,
      sector: sector,
      customerEmotion: customerEmotion,
      customerProblem: customerProblem,
      typingWpm: typingWpm,
      typingAccuracy: typingAccuracy,
      backspaceCount: backspaceCount,
      timestampLog: timestampLog,
    );

    final content = await _sendRequest(prompt);
    if (content == null) return SessionEvaluation.fallback(sector);

    return _parseEvaluation(content, sector);
  }
}
