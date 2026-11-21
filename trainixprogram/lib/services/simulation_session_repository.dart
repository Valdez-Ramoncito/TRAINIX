import 'package:flutter/foundation.dart';
import 'package:trainixprogram/models/session_score.dart';
import 'package:trainixprogram/models/simulation_history.dart';
import 'package:trainixprogram/models/simulation_phase.dart';
import 'package:trainixprogram/services/supabase_service.dart';

class SimulationSessionRepository {
  SimulationSessionRepository._();
  static final SimulationSessionRepository instance =
      SimulationSessionRepository._();

  static const _table = 'simulation_sessions';
  static String? lastError;

  Map<String, dynamic> _evalToMap(SessionEvaluation e) {
    return {
      'sector': e.sector,
      'openingSpielScore': e.openingSpielScore,
      'positiveScriptingScore': e.positiveScriptingScore,
      'empathyScore': e.empathyScore,
      'activeListeningScore': e.activeListeningScore,
      'problemIdentificationScore': e.problemIdentificationScore,
      'solutionDeliveryScore': e.solutionDeliveryScore,
      'communicationClarityScore': e.communicationClarityScore,
      'toneScore': e.toneScore,
      'sectorKnowledgeScore': e.sectorKnowledgeScore,
      'closingSpielScore': e.closingSpielScore,
      'overallScore': e.overallScore,
      'typingSpeedScore': e.typingSpeedScore,
      'errorRateAccuracyScore': e.errorRateAccuracyScore,
      'responseConsistencyScore': e.responseConsistencyScore,
      'paceAndSpeedScore': e.paceAndSpeedScore,
      'pronunciationClarityScore': e.pronunciationClarityScore,
      'fillerWordUsageScore': e.fillerWordUsageScore,
      'confidenceScore': e.confidenceScore,
      'dictionScore': e.dictionScore,
      'grammarScore': e.grammarScore,
      'wordChoiceScore': e.wordChoiceScore,
      'strengths': e.strengths,
      'areasForImprovement': e.areasForImprovement,
      'feedback': e.feedback,
      'evaluatedAt': e.evaluatedAt.toUtc().toIso8601String(),
      'ahtHandleSeconds': e.ahtHandleSeconds,
      'ahtOverLimit': e.ahtOverLimit,
      'customerName': e.customerName,
      'channel': e.channel,
      'problem': e.problem,
      'conversation': e.conversation,
      'customerRating': e.customerRating,
      'customerComment': e.customerComment,
      'categoryNotes': e.categoryNotes,
      'categoryQuotes': e.categoryQuotes,
      'categorySuggestions': e.categorySuggestions,
    };
  }

  Map<String, String>? _stringMap(dynamic raw) {
    if (raw is! Map) return null;
    final out = <String, String>{};
    raw.forEach((k, v) {
      if (v == null) return;
      final s = '$v'.trim();
      if (s.isEmpty) return;
      out['$k'] = s;
    });
    return out.isEmpty ? null : out;
  }

  SessionEvaluation _evalFromMap(Map<String, dynamic> m) {
    double d(String k) => (m[k] as num?)?.toDouble() ?? 0;
    double? dn(String k) => (m[k] as num?)?.toDouble();
    return SessionEvaluation(
      sector: m['sector'] as String? ?? '',
      openingSpielScore: d('openingSpielScore'),
      positiveScriptingScore: d('positiveScriptingScore'),
      empathyScore: d('empathyScore'),
      activeListeningScore: d('activeListeningScore'),
      problemIdentificationScore: d('problemIdentificationScore'),
      solutionDeliveryScore: d('solutionDeliveryScore'),
      communicationClarityScore: d('communicationClarityScore'),
      toneScore: d('toneScore'),
      sectorKnowledgeScore: d('sectorKnowledgeScore'),
      closingSpielScore: d('closingSpielScore'),
      overallScore: d('overallScore'),
      typingSpeedScore: dn('typingSpeedScore'),
      errorRateAccuracyScore: dn('errorRateAccuracyScore'),
      responseConsistencyScore: dn('responseConsistencyScore'),
      paceAndSpeedScore: dn('paceAndSpeedScore'),
      pronunciationClarityScore: dn('pronunciationClarityScore'),
      fillerWordUsageScore: dn('fillerWordUsageScore'),
      confidenceScore: dn('confidenceScore'),
      dictionScore: dn('dictionScore'),
      grammarScore: dn('grammarScore'),
      wordChoiceScore: dn('wordChoiceScore'),
      categoryNotes: _stringMap(m['categoryNotes']),
      categoryQuotes: _stringMap(m['categoryQuotes']),
      categorySuggestions: _stringMap(m['categorySuggestions']),
      strengths: (m['strengths'] as List?)?.map((e) => '$e').toList() ?? [],
      areasForImprovement:
          (m['areasForImprovement'] as List?)?.map((e) => '$e').toList() ?? [],
      feedback: m['feedback'] as String? ?? '',
      evaluatedAt: m['evaluatedAt'] != null
          ? DateTime.tryParse(m['evaluatedAt'] as String)?.toLocal() ??
                DateTime.now()
          : DateTime.now(),
      ahtHandleSeconds: dn('ahtHandleSeconds'),
      ahtOverLimit: m['ahtOverLimit'] as bool? ?? false,
      customerName: m['customerName'] as String? ?? 'Customer',
      channel: m['channel'] as String? ?? 'chat',
      problem: m['problem'] as String? ?? '',
      conversation:
          (m['conversation'] as List?)?.map((e) {
            if (e is Map) {
              return Map<String, String>.from(
                e.map((k, v) => MapEntry('$k', '$v')),
              );
            }
            return <String, String>{};
          }).toList() ??
          const [],
      customerRating: (m['customerRating'] as num?)?.toInt(),
      customerComment: m['customerComment'] as String?,
    );
  }

  Future<bool> insert(PlayedSession session) async {
    lastError = null;
    if (!SupabaseService.isReady) {
      lastError = 'Supabase is not ready';
      return false;
    }
    final uid = SupabaseService.client.auth.currentUser?.id;
    final evals = session.evaluations.map(_evalToMap).toList();
    try {
      final row = <String, dynamic>{
        'mode': session.mode.name,
        'sector': session.sector,
        'overall_score': session.overallScore,
        'multitasking_score': session.multitaskingScore,
        'typing_wpm': session.averageTypingWpm,
        'speaking_wpm': session.averageSpeakingWpm,
        'filler_count': session.fillerWordCount,
        'guided_mode': session.guidedMode,
        'completed_at': session.completedAt.toUtc().toIso8601String(),
        'evaluations': evals,
      };
      if (uid != null) row['user_id'] = uid;
      await SupabaseService.client.from(_table).insert(row);
      debugPrint('simulation_sessions insert ok');
      return true;
    } catch (e) {
      lastError = e.toString();
      debugPrint('simulation_sessions insert failed: $lastError');
      if (lastError!.contains('typing_wpm') ||
          lastError!.contains('speaking_wpm') ||
          lastError!.contains('filler_count') ||
          lastError!.contains('guided_mode') ||
          lastError!.contains('user_id')) {
        try {
          final fallback = <String, dynamic>{
            'mode': session.mode.name,
            'sector': session.sector,
            'overall_score': session.overallScore,
            'multitasking_score': session.multitaskingScore,
            'completed_at': session.completedAt.toUtc().toIso8601String(),
            'evaluations': evals,
          };
          if (uid != null && !lastError!.contains('user_id')) {
            fallback['user_id'] = uid;
          }
          if (!lastError!.contains('guided_mode')) {
            fallback['guided_mode'] = session.guidedMode;
          }
          if (!lastError!.contains('typing_wpm')) {
            fallback['typing_wpm'] = session.averageTypingWpm;
          }
          if (!lastError!.contains('speaking_wpm')) {
            fallback['speaking_wpm'] = session.averageSpeakingWpm;
          }
          if (!lastError!.contains('filler_count')) {
            fallback['filler_count'] = session.fillerWordCount;
          }
          await SupabaseService.client.from(_table).insert(fallback);
          debugPrint('simulation_sessions insert ok (legacy columns)');
          return true;
        } catch (e2) {
          lastError = e2.toString();
          debugPrint('simulation_sessions insert failed: $lastError');
        }
      }
      return false;
    }
  }

  Future<List<PlayedSession>> fetchAll() async {
    final uid = SupabaseService.client.auth.currentUser?.id;
    return fetchForUserId(uid);
  }

  /// Staff-facing fetch for a specific trainee. Requires
  /// simulation_sessions_select_staff RLS policy.
  Future<List<PlayedSession>> fetchForUserId(String? userId) async {
    lastError = null;
    if (!SupabaseService.isReady) return [];
    try {
      var query = SupabaseService.client.from(_table).select();
      if (userId != null && userId.isNotEmpty) {
        query = query.eq('user_id', userId);
      }
      final rows = await query.order('completed_at', ascending: false);
      final list = <PlayedSession>[];
      for (final row in rows as List) {
        final map = Map<String, dynamic>.from(row as Map);
        list.add(_sessionFromMap(map));
      }
      debugPrint(
        'simulation_sessions fetch count: ${list.length} user=$userId',
      );
      return list;
    } catch (e) {
      lastError = e.toString();
      debugPrint('simulation_sessions fetch failed: $lastError');
      return [];
    }
  }

  PlayedSession _sessionFromMap(Map<String, dynamic> map) {
    SimulationMode mode = SimulationMode.chat;
    for (final m in SimulationMode.values) {
      if (m.name == (map['mode'] as String? ?? '')) {
        mode = m;
        break;
      }
    }
    final evalsRaw = map['evaluations'];
    final evals = <SessionEvaluation>[];
    if (evalsRaw is List) {
      for (final e in evalsRaw) {
        if (e is Map) {
          evals.add(_evalFromMap(Map<String, dynamic>.from(e)));
        }
      }
    }
    return PlayedSession(
      evaluations: evals,
      multitaskingScore: (map['multitasking_score'] as num?)?.toDouble(),
      completedAt: map['completed_at'] != null
          ? DateTime.tryParse(map['completed_at'] as String)?.toLocal() ??
                DateTime.now()
          : DateTime.now(),
      mode: mode,
      averageTypingWpm: (map['typing_wpm'] as num?)?.toDouble(),
      averageSpeakingWpm: (map['speaking_wpm'] as num?)?.toDouble(),
      fillerWordCount: (map['filler_count'] as num?)?.toInt(),
      guidedMode: map['guided_mode'] as bool? ?? true,
    );
  }
}
