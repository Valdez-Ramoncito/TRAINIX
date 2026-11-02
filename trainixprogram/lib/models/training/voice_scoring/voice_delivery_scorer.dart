import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:trainixprogram/models/training/voice_scoring/voice_score_result.dart';
import 'package:trainixprogram/models/training/voice_scoring/voice_script_scorer.dart';

class VoiceDeliveryScorer {
  static final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  static Future<VoiceScoreResult> score({
    required String transcript,
    required String targetScript,
    String? audioPath,
  }) async {
    final contentResult = VoiceScriptScorer.scoreScriptOnly(
      transcript: transcript,
      targetScript: targetScript,
    );

    if (transcript.trim().isEmpty) {
      return contentResult;
    }

    int clarity = 10;
    int pace = 7;
    int tone = 10;
    int confidence = 7;
    final deliveryNotes = <String>[];

    try {
      final delivery = await _evaluateDelivery(
        transcript: transcript,
        targetScript: targetScript,
        audioPath: audioPath,
      );
      if (delivery != null) {
        clarity = delivery['clarity'] ?? clarity;
        pace = delivery['pace'] ?? pace;
        tone = delivery['tone'] ?? tone;
        confidence = delivery['confidence'] ?? confidence;
        final notes = delivery['notes'];
        if (notes is List) {
          for (final n in notes) {
            if (n is String && n.trim().isNotEmpty) {
              deliveryNotes.add(n.trim());
            }
          }
        }
      } else {
        deliveryNotes.add(
          'Delivery evaluation unavailable. Neutral delivery points applied.',
        );
      }
    } catch (e) {
      print('VoiceDeliveryScorer error: $e');
      deliveryNotes.add(
        'Delivery evaluation failed. Neutral delivery points applied.',
      );
    }

    clarity = clarity.clamp(0, 15);
    pace = pace.clamp(0, 10);
    tone = tone.clamp(0, 15);
    confidence = confidence.clamp(0, 10);

    final deliveryScore = clarity + pace + tone + confidence;
    final totalScore = contentResult.contentScore + deliveryScore;

    final contentGate = contentResult.contentScore >= 30;
    final deliveryGate = deliveryScore >= 28;
    final totalGate = totalScore >= 75;
    final passed =
        !contentResult.criticalFail && contentGate && deliveryGate && totalGate;

    return VoiceScoreResult(
      transcript: transcript,
      contentScore: contentResult.contentScore,
      deliveryScore: deliveryScore,
      totalScore: totalScore,
      passed: passed,
      criticalFail: contentResult.criticalFail,
      criticalFailReason: contentResult.criticalFailReason,
      contentNotes: contentResult.contentNotes,
      deliveryNotes: deliveryNotes,
      deliveryEvaluated: true,
    );
  }

  static Future<Map<String, dynamic>?> _evaluateDelivery({
    required String transcript,
    required String targetScript,
    String? audioPath,
  }) async {
    if (_apiKey.isEmpty) return null;

    final parts = <Map<String, dynamic>>[
      {
        "text":
            '''You are scoring a trainee contact-center voice practice line.

Score ONLY delivery quality using this fixed rubric:
- CLARITY max 15 (words easy to understand)
- PACE max 10 (calm and steady)
- TONE max 15 (warm, professional)
- CONFIDENCE max 10 (steady, few fillers)

Use mild deductions for small issues and major deductions for severe issues.
Do not award content accuracy here.

TARGET SCRIPT:
$targetScript

TRANSCRIPT:
$transcript

Respond in EXACTLY this format with no extra text:
CLARITY: <0-15>
PACE: <0-10>
TONE: <0-15>
CONFIDENCE: <0-10>
NOTE1: <short coaching note or N/A>
NOTE2: <short coaching note or N/A>
''',
      },
    ];

    if (audioPath != null) {
      try {
        final file = File(audioPath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          if (bytes.length < 12 * 1024 * 1024) {
            parts.add({
              "inlineData": {
                "mimeType": "audio/wav",
                "data": base64Encode(bytes),
              },
            });
          }
        }
      } catch (e) {
        print('VoiceDeliveryScorer audio read error: $e');
      }
    }

    final response = await http.post(
      Uri.parse('$_endpoint?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {"role": "user", "parts": parts},
        ],
        "generationConfig": {"temperature": 0.2, "maxOutputTokens": 500},
      }),
    );

    if (response.statusCode != 200) {
      print(
        'VoiceDeliveryScorer HTTP ${response.statusCode}: ${response.body}',
      );
      return null;
    }

    final data = jsonDecode(response.body);
    final content = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
    if (content is! String || content.trim().isEmpty) return null;

    return _parse(content);
  }

  static Map<String, dynamic> _parse(String raw) {
    int readInt(String key, int fallback) {
      final match = RegExp(
        '$key:\\s*(\\d+)',
        caseSensitive: false,
      ).firstMatch(raw);
      if (match == null) return fallback;
      return int.tryParse(match.group(1)!) ?? fallback;
    }

    final notes = <String>[];
    for (final key in ['NOTE1', 'NOTE2']) {
      final match = RegExp(
        '$key:\\s*(.+)',
        caseSensitive: false,
      ).firstMatch(raw);
      if (match != null) {
        final value = match.group(1)!.trim();
        if (value.isNotEmpty && value.toUpperCase() != 'N/A') {
          notes.add(value);
        }
      }
    }

    return {
      'clarity': readInt('CLARITY', 10),
      'pace': readInt('PACE', 7),
      'tone': readInt('TONE', 10),
      'confidence': readInt('CONFIDENCE', 7),
      'notes': notes,
    };
  }
}
