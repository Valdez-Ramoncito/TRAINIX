import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:trainixprogram/models/messages.dart';
import 'package:trainixprogram/models/session_score.dart';

//evaluates VOICE interactions against the TESDA Contact Center Services
//NC II standard, using Gemini 3.1 Flash Lite with the trainee's actual
//recorded audio attached not just the AssemblyAI text transcript.
class GeminiVoiceEvaluationApiService {
  static final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String _model = 'gemini-3.1-flash-lite';
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  //stay safely under Gemini's 20MB total inline-request cap, leaving
  //room for the text prompt or transcript alongside the audio
  static const int _maxInlineAudioBytes = 15 * 1024 * 1024;

  //TESDA rubric, grounded in TR_Contact_Center_Services_NC_II.docx
  //Unit codes:
  //ICT313365 (Communicate Effectively vocabulary/grammar/pronunciation, listening/comprehension),
  //ICT313366 (Customer Service Delivery Processes  inbound procedure explicitly lists opening spiel through closing spiel),
  //ICT313367 (Engage Customers  empathy, managing difficult conversations).
  //The WPM/dead-air/filler NUMBERS below are flagged to the model itself as general BPO-industry
  //convention, not TESDA-specified figures. The docx gives no numeric thresholds at all, only qualitative criteria.

  //Sourcing of the SCORING MECHANISM specifically TR_Contact_Center_Services_NC_II.docx,
  //Section 4, states plainly: "There is no National Assessment for this
  //TR. The industry association concerned shall develop non-branded/
  //non-proprietary assessment tools for the qualification..."  i.e.
  //TESDA itself defines no numeric instrument and explicitly defers
  //that to industry. The category-based, start-at-maximum,
  //deduct-per-observed-violation method used below follows the
  //documented, converging convention across independent BPO industry
  //QA-scorecard sources for scoring this same kind of interaction:
  //  - Balto (2025). "Call Center Quality Monitoring Scorecard Best
  //    Practices." https://www.balto.ai/blog/call-center-quality-monitoring-scorecard/
  //  - Calabrio (2026). "Call Center QA Scorecards: 7 Tips for Quality
  //    Assurance and CX Excellence."
  //    https://www.calabrio.com/blog/quality-assurance-qa-scorecard/
  //  - Five9 (2026). "How to Create High-Quality Scorecards for Your
  //    Contact Center." https://www.five9.com/blog/how-create-contact-center-scorecard
  //TESDA supplies what to measure; these sources support how that gets
  //made measurable for the same kind of interaction TESDA is written
  //for, this is not an unsourced scoring scheme invented from nothing.
  static const String _tesdaRubricInstructions =
      'You are an experienced BPO QA Evaluator applying the TESDA Contact '
      'Center Services NC II Training Regulation to a VOICE-based customer '
      'call. You have been given the actual recorded audio of the AGENT\'s '
      'turns, in order, alongside a text transcript. Base your scoring on '
      'the AUDIO primarily for anything about how something was said '
      '(pace, pronunciation, fillers, tone)  use the transcript primarily '
      'for what was said (content, accuracy, structure). IMPORTANT '
      'CONTEXT: TESDA\'s own assessment methodology is a binary Competent '
      '/ Not Yet Competent judgment made from a Satisfactory / Not '
      'Satisfactory checklist  it defines no numeric score, point '
      'scale, or percentage threshold of any kind. The 0-10 scale below, '
      'every deduction amount, and every numeric threshold (WPM '
      'baselines, second counts, etc.) is this application\'s own '
      'scoring instrument, built to operationalize TESDA\'s qualitative '
      'competency elements into measurable feedback  none of those '
      'numbers are themselves sourced from the TR document. Score each of the'
      '12 categories below from 0 to 10, starting'
      'every category at 10 and applying deductions only where the '
      'audio or transcript actually shows a violation  do not deduct '
      'on assumption. This start-at-maximum, deduct-per-violation '
      'method follows documented BPO industry QA-scorecard convention '
      '(see the sourcing note above this constant in the source file) '
      'for scoring the same category types named below  it is not an '
      'unsourced scoring scheme.\n\n'
      '1. OPENING_SPIEL (Core Unit 2, ICT313366  enterprise inbound '
      'procedure explicitly requires an opening spiel before identifying '
      'the customer\'s need): greeting, agent identification, offer of '
      'help. -3 if missing agent identification, -4 for a generic/'
      'unprofessional greeting.\n'
      '2. POSITIVE_SCRIPTING (Core Unit 3, ICT313367  managing difficult '
      'conversations via constructive communication): constructive '
      'reframing instead of flat refusals. -3 for phrases like "I can\'t '
      'do that" used without an alternative in the same breath; -2 for a '
      'blunt rejection with no alternative at all.\n'
      '3. EMPATHY (Core Unit 3, ICT313367  "ability to sense feelings of '
      'customer and respond accordingly"): verbal acknowledgment of the '
      'customer\'s stated emotion before troubleshooting starts. -5 if '
      'never acknowledged; -3 if it sounds flat/insincere in the audio.\n'
      '4. ACTIVE_LISTENING (Core Unit 1, ICT313365  "ability to listen '
      'and comprehend effectively"): confirming/restating the issue '
      'instead of re-asking for information already given. -5 if the '
      'agent asks for information the customer already provided.\n'
      '5. PROBLEM_IDENTIFICATION (Core Unit 2, ICT313366  "identify/'
      'clarify customer need" in the inbound procedure): correct '
      'root-cause isolation for the sector. -5 for misdiagnosis; -3 for '
      'unnecessary troubleshooting steps.\n'
      '6. SOLUTION_DELIVERY (Core Unit 2, ICT313366  "resolve or address '
      'need/offer solution"): accuracy and completeness of the fix. -10 '
      'for incorrect policy/information; -5 for incomplete instructions.\n'
      '7. PACE_AND_SPEED (Core Unit 1, ICT313365  communication '
      'proficiency): speech rate. General BPO-industry convention (NOT a '
      'TESDA-specified number) treats 130-160 WPM as a healthy baseline. '
      '-3 for rushing noticeably past that, -3 for speaking noticeably '
      'slower, -5 for unannounced dead air/silence you can hear exceeding '
      'roughly 10 seconds.\n'
      '8. PRONUNCIATION_AND_CLARITY (Core Unit 1, ICT313365  '
      '"communication proficiency includes accurate and appropriate use '
      'of vocabulary, grammar, pronunciation"): clear enunciation, '
      'absence of mumbling or accent interference that impairs '
      'understanding. -2 per severe mispronunciation or mumbled '
      'sentence you can actually hear.\n'
      '9. FILLER_WORD_USAGE (Core Unit 1, ICT313365  part of the 3 C\'s: '
      'clarity, conciseness, coherence): minimizing verbal fillers '
      '("uhm", "ah", "you know", "like"). General convention (not '
      'TESDA-specified): -2 per noticeable cluster of fillers.\n'
      '10. TONE_AND_INFLECTION (Core Unit 3, ICT313367  "avoids '
      'manifestations of stress in conversations"): professional, warm, '
      'modulated delivery. -5 for flat/monotone/robotic delivery or '
      'sounding defensive/argumentative in the audio.\n'
      '11. SECTOR_KNOWLEDGE (Core Unit 2, ICT313366): accurate '
      'terminology and compliance for the sector. -5 for failing an '
      'identity/security check where clearly warranted; -3 for incorrect '
      'sector-specific terminology.\n'
      '12. CLOSING_SPIEL (Core Unit 2, ICT313366  inbound procedure '
      'explicitly requires a closing spiel): confirmation of resolution, '
      'offer of further help, sign-off. -3 if missing the offer of '
      'further help; -3 if missing a sign-off entirely.\n\n'
      'CRITICAL: for every category scoring below 10, the paired _NOTE '
      'field MUST cite the exact transcript quote or an approximate '
      'audio timestamp/description justifying the deduction  no vague '
      'reasoning. For a category scoring a full 10, its _NOTE field must '
      'say exactly: Full marks.';

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

  //reads retained turn recordings into base64 inlineData parts, capped
  //at _maxInlineAudioBytes total so a long call can't blow past
  //Gemini's 20MB request limit
  Future<List<Map<String, dynamic>>> _buildAudioParts(
    List<String> audioFilePaths,
  ) async {
    final parts = <Map<String, dynamic>>[];
    int totalBytes = 0;
    for (final path in audioFilePaths) {
      try {
        final file = File(path);
        if (!await file.exists()) continue;
        final bytes = await file.readAsBytes();
        if (totalBytes + bytes.length > _maxInlineAudioBytes) {
          print(
            '[GEMINI VOICE EVAL] audio budget reached  skipping '
            'remaining turns for this request',
          );
          break;
        }
        totalBytes += bytes.length;
        parts.add({
          "inlineData": {"mimeType": "audio/wav", "data": base64Encode(bytes)},
        });
      } catch (e, stack) {
        print("Exception reading retained audio file $path: $e");
        print(stack);
      }
    }
    return parts;
  }

  String _buildPromptText({
    required String transcript,
    required String sector,
    required String customerEmotion,
    required String customerProblem,
    required bool hasAudio,
  }) {
    final audioNote = hasAudio
        ? 'Audio recordings of the AGENT\'s turns are attached below as '
              'separate audio clips, in chronological order matching the '
              'transcript. Use them as your PRIMARY evidence for '
              'PACE_AND_SPEED, PRONUNCIATION_AND_CLARITY, FILLER_WORD_USAGE, '
              'and TONE_AND_INFLECTION.'
        : 'No audio was available for this evaluation (recording or '
              'retrieval failed). Score PACE_AND_SPEED, PRONUNCIATION_AND_'
              'CLARITY, FILLER_WORD_USAGE, and TONE_AND_INFLECTION at a '
              'neutral 7, and set each of their _NOTE fields to exactly: '
              'Audio unavailable for this interaction. Do not guess at '
              'acoustic qualities from text alone.';

    return '$_tesdaRubricInstructions\n\n'
        'SECTOR: $sector\n'
        'CUSTOMER EMOTION: $customerEmotion\n'
        'CUSTOMER PROBLEM: $customerProblem\n\n'
        '$audioNote\n\n'
        'TRANSCRIPT:\n$transcript\n\n'
        'For every category below, in addition to its NOTE, also '
        'provide a QUOTE field: the exact, verbatim line the AGENT (not '
        'the customer) actually said, per the transcript above, that '
        'best demonstrates the deduction. Copy it exactly as '
        'transcribed  do not paraphrase it. If the violation is about '
        'something the agent never said (e.g. a missing opening spiel, '
        'a missing sign-off) rather than something they said '
        'incorrectly, there is no line to quote  respond with exactly '
        '"N/A" for that QUOTE field instead of inventing one. If the '
        'category scored full marks, respond with exactly "N/A" for '
        'its QUOTE field too.\n\n'
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
        'PACE_AND_SPEED: <0-10>\n'
        'PACE_AND_SPEED_NOTE: <citation or "Full marks">\n'
        'PACE_AND_SPEED_QUOTE: <verbatim agent line or "N/A">\n'
        'PRONUNCIATION_AND_CLARITY: <0-10>\n'
        'PRONUNCIATION_AND_CLARITY_NOTE: <citation or "Full marks">\n'
        'PRONUNCIATION_AND_CLARITY_QUOTE: <verbatim agent line or "N/A">\n'
        'FILLER_WORD_USAGE: <0-10>\n'
        'FILLER_WORD_USAGE_NOTE: <citation or "Full marks">\n'
        'FILLER_WORD_USAGE_QUOTE: <verbatim agent line or "N/A">\n'
        'TONE_AND_INFLECTION: <0-10>\n'
        'TONE_AND_INFLECTION_NOTE: <citation or "Full marks">\n'
        'TONE_AND_INFLECTION_QUOTE: <verbatim agent line or "N/A">\n'
        'SECTOR_KNOWLEDGE: <0-10>\n'
        'SECTOR_KNOWLEDGE_NOTE: <citation or "Full marks">\n'
        'SECTOR_KNOWLEDGE_QUOTE: <verbatim agent line or "N/A">\n'
        'CLOSING_SPIEL: <0-10>\n'
        'CLOSING_SPIEL_NOTE: <citation or "Full marks">\n'
        'CLOSING_SPIEL_QUOTE: <verbatim agent line or "N/A">\n'
        'STRENGTH_1: <demonstrated competency with evidence>\n'
        'STRENGTH_2: <demonstrated competency with evidence>\n'
        'STRENGTH_3: <demonstrated competency with evidence>\n'
        'IMPROVEMENT_1: <specific rule broken with exact quote/timestamp>\n'
        'IMPROVEMENT_2: <specific rule broken with exact quote/timestamp>\n'
        'IMPROVEMENT_3: <specific rule broken with exact quote/timestamp>\n'
        'FEEDBACK: <coaching summary tied back to the TESDA units above>';
  }

  //same key:value parsing approach as the chat evaluator, extended for
  //voice's category set
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
      'PACE_AND_SPEED',
      'PACE_AND_SPEED_NOTE',
      'PACE_AND_SPEED_QUOTE',
      'PRONUNCIATION_AND_CLARITY',
      'PRONUNCIATION_AND_CLARITY_NOTE',
      'PRONUNCIATION_AND_CLARITY_QUOTE',
      'FILLER_WORD_USAGE',
      'FILLER_WORD_USAGE_NOTE',
      'FILLER_WORD_USAGE_QUOTE',
      'TONE_AND_INFLECTION',
      'TONE_AND_INFLECTION_NOTE',
      'TONE_AND_INFLECTION_QUOTE',
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
      return SessionEvaluation.fromGeminiVoiceTesda(
        sector: sector,
        fields: fields,
      );
    }
    return SessionEvaluation.fallback(sector);
  }

  //sends the prompt + audio parts to Gemini, retrying up to 3 times on
  //failure/empty content
  Future<String?> _sendRequest({
    required String promptText,
    required List<Map<String, dynamic>> audioParts,
  }) async {
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final response = await http.post(
          Uri.parse('$_endpoint?key=$_apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "contents": [
              {
                "role": "user",
                "parts": [
                  {"text": promptText},
                  ...audioParts,
                ],
              },
            ],
            "generationConfig": {
              "temperature": 0.3,
              "maxOutputTokens": 3000,
              "thinkingConfig": {"thinkingLevel": "low"},
            },
          }),
        );

        if (response.statusCode != 200) {
          print(
            "Gemini voice evaluation error ${response.statusCode}: "
            "${response.body}",
          );
          continue;
        }

        final data = jsonDecode(response.body);
        final content =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'];

        print("Gemini Voice Evaluation Status: ${response.statusCode}");
        print("Gemini Voice Evaluation Response: $content");

        if (content == null || content is! String || content.trim().isEmpty) {
          print(
            "Null Gemini voice evaluation content  retrying "
            "(attempt ${attempt + 1}/3)",
          );
          continue;
        }

        return content;
      } catch (e, stack) {
        print("Exception in Gemini voice evaluation _sendRequest: $e");
        print(stack);
      }
    }
    return null;
  }

  //evaluates a resolved voice interaction against the TESDA rubric,
  //with the trainee's actual recorded audio attached where available
  Future<SessionEvaluation> evaluateVoiceTesda({
    required List<Message> messages,
    required String sector,
    required String customerEmotion,
    required String customerProblem,
    required List<String> audioFilePaths,
  }) async {
    final transcript = _buildTranscript(messages);
    if (transcript.isEmpty) return SessionEvaluation.fallback(sector);

    final audioParts = await _buildAudioParts(audioFilePaths);

    final promptText = _buildPromptText(
      transcript: transcript,
      sector: sector,
      customerEmotion: customerEmotion,
      customerProblem: customerProblem,
      hasAudio: audioParts.isNotEmpty,
    );

    final content = await _sendRequest(
      promptText: promptText,
      audioParts: audioParts,
    );
    if (content == null) return SessionEvaluation.fallback(sector);

    return _parseEvaluation(content, sector);
  }
}
