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

    if (cleaned.isEmpty || words < 3) {
      final empty = SpeakingResult(
        promptId: prompt.id,
        pack: prompt.pack,
        difficulty: prompt.difficulty,
        durationSeconds: durationSeconds.clamp(1, 999),
        transcript: cleaned,
        finishedAt: DateTime.now(),
        fillerCount: 0,
        audioRetained: false,
      );
      return SpeakingEvaluation(
        result: empty,
        aiAvailable: false,
        aiNote: 'Empty or too short transcript. Nothing to score.',
      );
    }

    final audioParts = await _buildAudioParts(audioPath);
    final hasAudio = audioParts.isNotEmpty;

    if (_apiKey.isEmpty) {
      return SpeakingEvaluation(
        result: _buildResult(
          prompt: prompt,
          transcript: cleaned,
          durationSeconds: durationSeconds,
          fillers: fillers,
          hasAudio: hasAudio,
          audioPath: audioPath,
          fields: const {},
          issues: const [],
        ),
        aiAvailable: false,
        aiNote: 'AI scores unavailable. Measured dimensions still saved.',
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
        result: _buildResult(
          prompt: prompt,
          transcript: cleaned,
          durationSeconds: durationSeconds,
          fillers: fillers,
          hasAudio: hasAudio,
          audioPath: audioPath,
          fields: const {},
          issues: const [],
        ),
        aiAvailable: false,
        aiNote: 'AI scores unavailable. Measured dimensions still saved.',
      );
    }

    final fields = _extractFields(content);
    final issues = _extractIssues(fields);
    final result = _buildResult(
      prompt: prompt,
      transcript: cleaned,
      durationSeconds: durationSeconds,
      fillers: fillers,
      hasAudio: hasAudio,
      audioPath: audioPath,
      fields: fields,
      issues: issues,
    );
    print(
      '[SPEAKING EVAL] saved dims '
      'grammar=${result.grammarScore} '
      'word=${result.wordChoiceScore} '
      'fluency=${result.fluencyScore} '
      'pron=${result.pronunciationClarityScore} '
      'filler=${result.fillerUsageScore} '
      'conf=${result.confidenceScore} '
      'complete=${result.completenessScore}',
    );
    return SpeakingEvaluation(result: result, aiAvailable: true);
  }

  /// Builds a result where every transcript-measurable dimension is non-null.
  /// Pronunciation stays null only when no usable audio was attached.
  SpeakingResult _buildResult({
    required SpeakingPrompt prompt,
    required String transcript,
    required int durationSeconds,
    required int fillers,
    required bool hasAudio,
    String? audioPath,
    required Map<String, String> fields,
    required List<SpeakingIssue> issues,
  }) {
    final words = _wordCount(transcript);
    final secs = durationSeconds.clamp(1, 999);

    double? fromAi(String key) {
      for (final candidate in _keysFor(key)) {
        final v = fields[candidate];
        if (v == null) continue;
        final upper = v.toUpperCase().trim();
        if (upper == 'NOT_SCORED' ||
            upper == 'N/A' ||
            upper == 'NA' ||
            upper == 'NONE' ||
            upper == '-') {
          continue;
        }
        final match = RegExp(r'-?\d+(\.\d+)?').firstMatch(v);
        if (match == null) continue;
        final parsed = double.tryParse(match.group(0)!);
        if (parsed == null) continue;
        return parsed.clamp(0, 10).toDouble();
      }
      return null;
    }

    final grammar =
        fromAi('GRAMMAR') ?? _grammarHeuristic(transcript);
    final wordChoice =
        fromAi('WORD_CHOICE') ?? _wordChoiceHeuristic(transcript, prompt);
    final fluency =
        fromAi('FLUENCY') ?? _fluencyFromWpm(secs, words);
    final fillerUsage =
        fromAi('FILLER') ?? _fillerScoreFromCount(fillers, words);
    final completeness =
        fromAi('COMPLETENESS') ?? _completenessHeuristic(transcript, prompt);

    // Confidence always recorded: AI when present, else pace/length heuristic.
    final confidence =
        fromAi('CONFIDENCE') ?? _confidenceHeuristic(secs, words);

    // Pronunciation only when audio existed for the take.
    double? pronunciation;
    if (hasAudio) {
      pronunciation = fromAi('PRONUNCIATION') ??
          _pronunciationBaseline(secs, words);
    }

    return SpeakingResult(
      promptId: prompt.id,
      pack: prompt.pack,
      difficulty: prompt.difficulty,
      durationSeconds: secs,
      transcript: transcript,
      finishedAt: DateTime.now(),
      fillerCount: fillers,
      audioRetained: audioPath != null && hasAudio,
      issues: issues,
      grammarScore: grammar,
      wordChoiceScore: wordChoice,
      fluencyScore: fluency,
      pronunciationClarityScore: pronunciation,
      fillerUsageScore: fillerUsage,
      confidenceScore: confidence,
      completenessScore: completeness,
    );
  }

  List<String> _keysFor(String canonical) {
    switch (canonical) {
      case 'GRAMMAR':
        return const ['GRAMMAR', 'GRAMMAR_ACCURACY', 'GRAMMAR_SCORE'];
      case 'WORD_CHOICE':
        return const [
          'WORD_CHOICE',
          'WORDCHOICE',
          'WORD_CHOICE_SCORE',
          'VOCABULARY',
        ];
      case 'FLUENCY':
        return const [
          'FLUENCY',
          'FLUENCY_SCORE',
          'PACE',
          'SPEAKING_RATE',
          'FLOW',
        ];
      case 'PRONUNCIATION':
        return const [
          'PRONUNCIATION',
          'PRONUNCIATION_CLARITY',
          'PRONUNCIATION_SCORE',
          'CLARITY',
        ];
      case 'FILLER':
        return const [
          'FILLER',
          'FILLER_USAGE',
          'FILLERS',
          'FILLER_SCORE',
        ];
      case 'CONFIDENCE':
        return const [
          'CONFIDENCE',
          'SPEAKING_CONFIDENCE',
          'CONFIDENCE_SCORE',
        ];
      case 'COMPLETENESS':
        return const [
          'COMPLETENESS',
          'COMPLETE',
          'COMPLETENESS_SCORE',
          'COVERAGE',
        ];
      default:
        return [canonical];
    }
  }

  List<SpeakingIssue> _extractIssues(Map<String, String> fields) {
    final issues = <SpeakingIssue>[];
    void addIssue(String kind, String quoteKey, String suggestKey) {
      final quote = fields[quoteKey]?.trim();
      if (quote == null ||
          quote.isEmpty ||
          quote.toUpperCase() == 'N/A' ||
          quote.toUpperCase() == 'NA') {
        return;
      }
      final suggest = fields[suggestKey]?.trim() ?? '';
      issues.add(
        SpeakingIssue(
          quote: quote,
          kind: kind,
          suggestion: suggest.toUpperCase() == 'N/A' ? '' : suggest,
        ),
      );
    }

    addIssue('grammar', 'GRAMMAR_QUOTE', 'GRAMMAR_SUGGEST');
    addIssue('word_choice', 'WORD_CHOICE_QUOTE', 'WORD_CHOICE_SUGGEST');
    addIssue('fluency', 'FLUENCY_QUOTE', 'FLUENCY_SUGGEST');
    addIssue('pronunciation', 'PRONUNCIATION_QUOTE', 'PRONUNCIATION_SUGGEST');
    addIssue('filler', 'FILLER_QUOTE', 'FILLER_SUGGEST');
    addIssue('confidence', 'CONFIDENCE_QUOTE', 'CONFIDENCE_SUGGEST');
    addIssue('completeness', 'COMPLETENESS_QUOTE', 'COMPLETENESS_SUGGEST');
    return issues;
  }

  Map<String, String> _extractFields(String raw) {
    final fields = <String, String>{};
    var cleaned = raw
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    void put(String key, String value) {
      final k = key.trim().toUpperCase().replaceAll(RegExp(r'[\s\-]+'), '_');
      final v = value.trim();
      if (k.isEmpty || v.isEmpty) return;
      fields.putIfAbsent(k, () => v);
    }

    void flatten(dynamic node, [String prefix = '']) {
      if (node is Map) {
        node.forEach((k, v) {
          final key = prefix.isEmpty
              ? k.toString()
              : '${prefix}_${k.toString()}';
          if (v is Map || v is List) {
            flatten(v, key);
          } else if (v != null) {
            put(key, v.toString());
            put(k.toString(), v.toString());
          }
        });
      } else if (node is List) {
        for (final item in node) {
          flatten(item, prefix);
        }
      }
    }

    // JSON object response (whole body or embedded)
    final jsonStart = cleaned.indexOf('{');
    final jsonEnd = cleaned.lastIndexOf('}');
    if (jsonStart >= 0 && jsonEnd > jsonStart) {
      try {
        final decoded = jsonDecode(cleaned.substring(jsonStart, jsonEnd + 1));
        flatten(decoded);
      } catch (_) {}
    }

    for (final line in cleaned.split('\n')) {
      final idx = line.indexOf(':');
      if (idx <= 0) continue;
      put(line.substring(0, idx), line.substring(idx + 1));
    }

    // Fallback: KEY <number> without colon
    final loose = RegExp(
      r'\b(GRAMMAR|WORD[_\s]?CHOICE|FLUENCY|PRONUNCIATION|FILLER|CONFIDENCE|COMPLETENESS)\b[^\d]{0,20}(\d+(\.\d+)?)',
      caseSensitive: false,
    );
    for (final m in loose.allMatches(cleaned)) {
      put(m.group(1)!, m.group(2)!);
    }

    return fields;
  }

  double _grammarHeuristic(String transcript) {
    final t = transcript.trim();
    if (t.isEmpty) return 5;
    var score = 9.0;
    if (!RegExp(r'[.!?]$').hasMatch(t) && t.split(' ').length > 8) {
      score -= 0.5;
    }
    final lower = t.toLowerCase();
    if (RegExp(r'\bi is\b|\bi are\b|\bthey is\b|\bhe are\b').hasMatch(lower)) {
      score -= 2;
    }
    if (RegExp(r'\b(dont|cant|wont|im)\b').hasMatch(lower)) {
      score -= 0.5;
    }
    return score.clamp(0, 10).toDouble();
  }

  double _wordChoiceHeuristic(String transcript, SpeakingPrompt prompt) {
    final t = transcript.toLowerCase();
    if (t.isEmpty) return 5;
    var score = 8.5;
    final focusHits = prompt.focus
        .where((f) => f.trim().isNotEmpty && t.contains(f.toLowerCase()))
        .length;
    if (focusHits > 0) score += 0.5;
    if (RegExp(r'\b(um+|uh+|like|you know)\b').hasMatch(t)) score -= 0.5;
    if (t.split(RegExp(r'\s+')).length < 6) score -= 1;
    return score.clamp(0, 10).toDouble();
  }

  double _completenessHeuristic(String transcript, SpeakingPrompt prompt) {
    final t = transcript.toLowerCase();
    if (t.isEmpty) return 0;
    final points = prompt.requiredPoints
        .map((p) => p.trim().toLowerCase())
        .where((p) => p.isNotEmpty)
        .toList();
    if (points.isEmpty) {
      final promptWords = prompt.text
          .toLowerCase()
          .split(RegExp(r'[^a-z0-9]+'))
          .where((w) => w.length > 4)
          .toSet();
      if (promptWords.isEmpty) return 8;
      final hits = promptWords.where((w) => t.contains(w)).length;
      final ratio = hits / promptWords.length;
      if (ratio >= 0.35) return 9;
      if (ratio >= 0.2) return 7;
      if (ratio >= 0.1) return 5;
      return 4;
    }
    var hits = 0;
    for (final p in points) {
      final tokens = p
          .split(RegExp(r'[^a-z0-9]+'))
          .where((w) => w.length > 3)
          .toList();
      if (tokens.isEmpty) continue;
      final matched = tokens.where((w) => t.contains(w)).length;
      if (matched >= (tokens.length / 2).ceil()) hits++;
    }
    final ratio = hits / points.length;
    if (ratio >= 0.85) return 10;
    if (ratio >= 0.6) return 8;
    if (ratio >= 0.35) return 6;
    if (ratio > 0) return 4;
    return 3;
  }

  double _confidenceHeuristic(int durationSeconds, int words) {
    if (words < 5) return 5;
    if (durationSeconds <= 0) return 6;
    final wpm = words / (durationSeconds / 60.0);
    if (wpm >= 100 && wpm <= 170) return 8;
    if (wpm >= 80 && wpm <= 190) return 7;
    return 6;
  }

  /// Neutral baseline when audio exists but the model omits pronunciation.
  double _pronunciationBaseline(int durationSeconds, int words) {
    if (words < 5) return 6;
    final fluency = _fluencyFromWpm(durationSeconds, words);
    // Stay conservative: never claim full marks without an AI audio read.
    return ((fluency + 7) / 2).clamp(6, 8).toDouble();
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
        final parts = data['candidates']?[0]?['content']?['parts'];
        final buf = StringBuffer();
        if (parts is List) {
          for (final part in parts) {
            if (part is Map && part['text'] is String) {
              buf.writeln(part['text'] as String);
            }
          }
        }
        final content = buf.toString().trim();
        if (content.isEmpty) {
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
