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
    };
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
    );
  }

  Future<bool> insert(PlayedSession session) async {
    lastError = null;
    if (!SupabaseService.isReady) {
      lastError = 'Supabase is not ready';
      return false;
    }
    try {
      final evals = session.evaluations.map(_evalToMap).toList();
      await SupabaseService.client.from(_table).insert({
        'mode': session.mode.name,
        'sector': session.sector,
        'overall_score': session.overallScore,
        'multitasking_score': session.multitaskingScore,
        'completed_at': session.completedAt.toUtc().toIso8601String(),
        'evaluations': evals,
      });
      debugPrint('simulation_sessions insert ok');
      return true;
    } catch (e) {
      lastError = e.toString();
      debugPrint('simulation_sessions insert failed: $lastError');
      return false;
    }
  }

  Future<List<PlayedSession>> fetchAll() async {
    lastError = null;
    if (!SupabaseService.isReady) return [];
    try {
      final rows = await SupabaseService.client
          .from(_table)
          .select()
          .order('completed_at', ascending: false);
      final list = <PlayedSession>[];
      for (final row in rows as List) {
        final map = Map<String, dynamic>.from(row as Map);
        SimulationMode mode = SimulationMode.hybrid;
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
        list.add(
          PlayedSession(
            evaluations: evals,
            multitaskingScore: (map['multitasking_score'] as num?)?.toDouble(),
            completedAt: map['completed_at'] != null
                ? DateTime.tryParse(map['completed_at'] as String)?.toLocal() ??
                      DateTime.now()
                : DateTime.now(),
            mode: mode,
          ),
        );
      }
      debugPrint('simulation_sessions fetch count: ${list.length}');
      return list;
    } catch (e) {
      lastError = e.toString();
      debugPrint('simulation_sessions fetch failed: $lastError');
      return [];
    }
  }
}
