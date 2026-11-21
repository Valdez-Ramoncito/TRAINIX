import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:trainixprogram/models/training/speaking/speaking_prompt.dart';
import 'package:trainixprogram/models/training/speaking/speaking_result.dart';

class SpeakingEvaluation {
  final SpeakingResult result;
  final bool aiAvailable;
  final String? aiNote;

  const SpeakingEvaluation({
    required this.result,
    this.aiAvailable = true,
    this.aiNote,
  });
}

class SpeakingEvaluationApiService {
  static final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String _model = 'gemini-2.0-flash';
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';
  static const int _maxInlineAudioBytes = 15 * 1024 * 1024;

  static final RegExp _fillerPattern = RegExp(
    r'\b(um+|uh+|er+|ah+|like|you know|basically|actually|sort of|kind of)\b',
    caseSensitive: false,
  );

  Future<SpeakingEvaluation> scoreSpeaking({
    required SpeakingPrompt prompt,
    required String transcript,
    required int durationSeconds,
    String? audioPath,
  }) async {
    final cleaned = transcript.trim();
    final fillers = _countFillers(cleaned);
    final words = _wordCount(cleaned);
    final wpm = durationSeconds <= 0 ? 0.0 : words / (durationSeconds / 60.0);

    if (cleaned.isEmpty) {
      final empty = SpeakingResult(
        promptId: prompt.id,
        pack: prompt.pack,
        difficulty: prompt.difficulty,
        durationSeconds: durationSeconds.clamp(1, 999),
        transcript: '',
        finishedAt: DateTime.now(),
        fillerCount: 0,
        audioRetained: audioPath != null,
      );
      return SpeakingEvaluation(
        result: empty,
        aiAvailable: false,
        aiNote: 'Empty transcript. Nothing to score.',
      );
    }

    final audioParts = await _buildAudioParts(audioPath);
    final hasAudio = audioParts.isNotEmpty;

    if (_apiKey.isEmpty) {
      return SpeakingEvaluation(
        result: _deterministicOnly(
          prompt: prompt,
          transcript: cleaned,
          durationSeconds: durationSeconds,
          fillers: fillers,
          hasAudio: hasAudio,
          audioPath: audioPath,
        ),
        aiAvailable: false,
        aiNote: 'AI scores unavailable. Showing measured metrics only.',
      );
    }

    final promptText = _buildPrompt(
      prompt: prompt,
      transcript: cleaned,
      durationSeconds: durationSeconds,
      wordCount: words,
      wpm: wpm,
      fillerCount: fillers,
      hasAudio: hasAudio,
    );

    final content = await _sendRequest(
      promptText: promptText,
      audioParts: audioParts,
    );

    if (content == null) {
      return SpeakingEvaluation(
        result: _deterministicOnly(
          prompt: prompt,
          transcript: cleaned,
          durationSeconds: durationSeconds,
          fillers: fillers,
          hasAudio: hasAudio,
          audioPath: audioPath,
        ),
        aiAvailable: false,
        aiNote: 'AI scores unavailable. Showing measured metrics only.',
      );
    }

    final parsed = _parse(
      raw: content,
      prompt: prompt,
      transcript: cleaned,
      durationSeconds: durationSeconds,
      fillers: fillers,
      hasAudio: hasAudio,
      audioPath: audioPath,
    );
    return SpeakingEvaluation(result: parsed, aiAvailable: true);
  }

  SpeakingResult _deterministicOnly({
    required SpeakingPrompt prompt,
    required String transcript,
    required int durationSeconds,
    required int fillers,
    required bool hasAudio,
    String? audioPath,
  }) {
    final fillerScore = _fillerScoreFromCount(fillers, _wordCount(transcript));
    return SpeakingResult(
      promptId: prompt.id,
      pack: prompt.pack,
      difficulty: prompt.difficulty,
      durationSeconds: durationSeconds.clamp(1, 999),
      transcript: transcript,
      finishedAt: DateTime.now(),
      fillerCount: fillers,
      audioRetained: audioPath != null && hasAudio,
      fillerUsageScore: fillerScore,
      fluencyScore: _fluencyFromWpm(
        durationSeconds,
        _wordCount(transcript),
      ),
    );
  }

  SpeakingResult _parse({
    required String raw,
    required SpeakingPrompt prompt,
    required String transcript,
    required int durationSeconds,
    required int fillers,
    required bool hasAudio,
    String? audioPath,
  }) {
    final cleaned = raw
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();
    final fields = <String, String>{};
    for (final line in cleaned.split('\n')) {
      final idx = line.indexOf(':');
      if (idx <= 0) continue;
      final key = line.substring(0, idx).trim().toUpperCase();
      final value = line.substring(idx + 1).trim();
      if (value.isNotEmpty) fields[key] = value;
    }

    double? score(String key) {
      final v = fields[key];
      if (v == null) return null;
      final upper = v.toUpperCase();
      if (upper == 'NOT_SCORED' || upper == 'N/A' || upper == 'NA') return null;
      return double.tryParse(v.replaceAll(RegExp(r'[^0-9.\-]'), ''));
    }

    String? note(String key) {
      final v = fields[key];
      if (v == null || v.isEmpty || v.toUpperCase() == 'N/A') return null;
      return v;
    }

    final issues = <SpeakingIssue>[];
    void addIssue(String kind, String? quote, String? suggest) {
      if (quote == null || quote.isEmpty || quote.toUpperCase() == 'N/A') {
        return;
      }
      issues.add(
        SpeakingIssue(
          quote: quote,
          kind: kind,
          suggestion: suggest ?? '',
        ),
      );
    }

    addIssue(
      'grammar',
      note('GRAMMAR_QUOTE'),
      note('GRAMMAR_SUGGEST'),
    );
    addIssue(
      'word_choice',
      note('WORD_CHOICE_QUOTE'),
      note('WORD_CHOICE_SUGGEST'),
    );
    addIssue(
      'fluency',
      note('FLUENCY_QUOTE'),
      note('FLUENCY_SUGGEST'),
    );
    addIssue(
      'pronunciation',
      note('PRONUNCIATION_QUOTE'),
      note('PRONUNCIATION_SUGGEST'),
    );
    addIssue(
      'filler',
      note('FILLER_QUOTE'),
      note('FILLER_SUGGEST'),
    );
    addIssue(
      'confidence',
      note('CONFIDENCE_QUOTE'),
      note('CONFIDENCE_SUGGEST'),
    );
    addIssue(
      'completeness',
      note('COMPLETENESS_QUOTE'),
      note('COMPLETENESS_SUGGEST'),
    );

    var pronunciation = score('PRONUNCIATION');
    var confidence = score('CONFIDENCE');
    if (!hasAudio) {
      pronunciation = null;
      confidence = null;
    }

    return SpeakingResult(
      promptId: prompt.id,
      pack: prompt.pack,
      difficulty: prompt.difficulty,
      durationSeconds: durationSeconds.clamp(1, 999),
      transcript: transcript,
      finishedAt: DateTime.now(),
      fillerCount: fillers,
      audioRetained: audioPath != null && hasAudio,
      issues: issues,
      grammarScore: score('GRAMMAR')?.clamp(0, 10),
      wordChoiceScore: score('WORD_CHOICE')?.clamp(0, 10),
      fluencyScore: score('FLUENCY')?.clamp(0, 10) ??
          _fluencyFromWpm(durationSeconds, _wordCount(transcript)),
      pronunciationClarityScore: pronunciation?.clamp(0, 10),
      fillerUsageScore: score('FILLER')?.clamp(0, 10) ??
          _fillerScoreFromCount(fillers, _wordCount(transcript)),
      confidenceScore: confidence?.clamp(0, 10),
      completenessScore: score('COMPLETENESS')?.clamp(0, 10),
    );
  }

  String _buildPrompt({
    required SpeakingPrompt prompt,
    required String transcript,
    required int durationSeconds,
    required int wordCount,
    required double wpm,
    required int fillerCount,
    required bool hasAudio,
  }) {
    final required = prompt.requiredPoints.isEmpty
        ? 'None listed.'
        : prompt.requiredPoints.map((p) => '- $p').join('\n');
    final focus = prompt.focus.isEmpty
        ? 'general delivery'
        : prompt.focus.join(', ');

    return '''
You are scoring a contact-center Speaking Practice take for TRAINIX.
Score only the trainee transcript (and audio when provided). Do not invent customer dialogue.

PROMPT LABEL: ${prompt.label}
PACK: ${prompt.pack.label}
DIFFICULTY: ${prompt.difficulty.label}
TARGET SECONDS: ${prompt.targetSeconds}
FOCUS: $focus
PROMPT TEXT:
${prompt.text}

REQUIRED POINTS (for Completeness):
$required

MEASURED:
- duration_seconds: $durationSeconds
- word_count: $wordCount
- words_per_minute: ${wpm.toStringAsFixed(1)}
- filler_count_local: $fillerCount
- audio_attached: $hasAudio

DIMENSIONS (start each at 10, continuous deductions, floor at 0, one decimal):
1. GRAMMAR - sentence structure, agreement, tense, articles
2. WORD_CHOICE - precise professional vocabulary
3. FLUENCY - smooth delivery; use WPM 110-160 as a practice band
4. PRONUNCIATION - intelligibility from audio only. If audio_attached is false, output NOT_SCORED
5. FILLER - um, uh, like, you know, repeated so
6. CONFIDENCE - steady delivery from audio. If audio_attached is false, output NOT_SCORED
7. COMPLETENESS - covers required points / prompt intent

RULES:
- Deduct only with a concrete quote from the transcript or a clear audio moment.
- No evidence means leave the score at 10 and NOTE = Full marks.
- Suggestions must be one stronger line the trainee could say.
- Never mention TESDA, ICT codes, or Core Units in notes.

OUTPUT FORMAT (one field per line, exact keys):
GRAMMAR: <0-10 or NOT_SCORED>
GRAMMAR_NOTE: <text>
GRAMMAR_QUOTE: <quote or N/A>
GRAMMAR_SUGGEST: <line or N/A>
WORD_CHOICE: ...
WORD_CHOICE_NOTE: ...
WORD_CHOICE_QUOTE: ...
WORD_CHOICE_SUGGEST: ...
FLUENCY: ...
FLUENCY_NOTE: ...
FLUENCY_QUOTE: ...
FLUENCY_SUGGEST: ...
PRONUNCIATION: ...
PRONUNCIATION_NOTE: ...
PRONUNCIATION_QUOTE: ...
PRONUNCIATION_SUGGEST: ...
FILLER: ...
FILLER_NOTE: ...
FILLER_QUOTE: ...
FILLER_SUGGEST: ...
CONFIDENCE: ...
CONFIDENCE_NOTE: ...
CONFIDENCE_QUOTE: ...
CONFIDENCE_SUGGEST: ...
COMPLETENESS: ...
COMPLETENESS_NOTE: ...
COMPLETENESS_QUOTE: ...
COMPLETENESS_SUGGEST: ...

TRANSCRIPT:
$transcript
''';
  }

  Future<List<Map<String, dynamic>>> _buildAudioParts(String? path) async {
    if (path == null || path.isEmpty) return const [];
    try {
      final file = File(path);
      if (!await file.exists()) return const [];
      final bytes = await file.readAsBytes();
      if (bytes.length > _maxInlineAudioBytes) {
        print(
          '[SPEAKING EVAL] audio ${bytes.length} bytes exceeds '
          '$_maxInlineAudioBytes, scoring transcript only',
        );
        return const [];
      }
      print('[SPEAKING EVAL] attaching audio bytes=${bytes.length}');
      return [
        {
          'inlineData': {
            'mimeType': 'audio/wav',
            'data': base64Encode(bytes),
          },
        },
      ];
    } catch (e, stack) {
      print('Speaking eval audio read failed: $e');
      print(stack);
      return const [];
    }
  }

  Future<String?> _sendRequest({
    required String promptText,
    required List<Map<String, dynamic>> audioParts,
  }) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final response = await http.post(
          Uri.parse('$_endpoint?key=$_apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {'text': promptText},
                  ...audioParts,
                ],
              },
            ],
            'generationConfig': {
              'temperature': 0.3,
              'maxOutputTokens': 2500,
            },
          }),
        );
        if (response.statusCode != 200) {
          print(
            'Speaking eval HTTP ${response.statusCode}: ${response.body}',
          );
          continue;
        }
        final data = jsonDecode(response.body);
        final content =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (content is! String || content.trim().isEmpty) {
          print('Speaking eval empty content attempt ${attempt + 1}/3');
          continue;
        }
        return content;
      } catch (e, stack) {
        print('Speaking eval request failed: $e');
        print(stack);
      }
    }
    return null;
  }

  int _wordCount(String text) {
    final parts = text.trim().split(RegExp(r'\s+'));
    if (parts.length == 1 && parts.first.isEmpty) return 0;
    return parts.length;
  }

  int _countFillers(String text) => _fillerPattern.allMatches(text).length;

  double _fillerScoreFromCount(int fillers, int words) {
    if (fillers <= 0) return 10;
    if (words <= 0) return 7;
    final ratio = fillers / words;
    if (ratio >= 0.2) return 3;
    if (ratio >= 0.12) return 5;
    if (ratio >= 0.06) return 7;
    if (fillers >= 3) return 8;
    return 9;
  }

  double _fluencyFromWpm(int durationSeconds, int words) {
    if (durationSeconds <= 0 || words <= 0) return 7;
    final wpm = words / (durationSeconds / 60.0);
    if (wpm >= 110 && wpm <= 160) return 10;
    if (wpm >= 90 && wpm <= 180) return 8;
    if (wpm >= 70 && wpm <= 200) return 6;
    return 4;
  }
}
