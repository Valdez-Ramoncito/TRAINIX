import 'package:flutter/foundation.dart';
import 'package:trainixprogram/components/class/trainee_activity_log.dart';
import 'package:trainixprogram/services/supabase_service.dart';

class ActivityLogRepository {
  ActivityLogRepository._();
  static final ActivityLogRepository instance = ActivityLogRepository._();

  static const _table = 'activity_logs';
  static String? lastError;

  Map<String, dynamic> _toRow(TraineeActivityLogEntry e) {
    return {
      'id': e.id,
      'at': e.at.toUtc().toIso8601String(),
      'actor_name': e.actorName,
      'actor_role': e.actorRole,
      'category': e.category.name,
      'action': e.action,
      'detail': e.detail,
      'room_id': e.roomId,
      'session_ref': e.sessionRef,
    };
  }

  TraineeActivityLogEntry _fromRow(Map<String, dynamic> row) {
    TraineeLogCategory category = TraineeLogCategory.system;
    for (final c in TraineeLogCategory.values) {
      if (c.name == (row['category'] as String? ?? '')) {
        category = c;
        break;
      }
    }
    return TraineeActivityLogEntry(
      id: row['id'] as String? ?? '',
      at: row['at'] != null
          ? DateTime.tryParse(row['at'] as String)?.toLocal() ?? DateTime.now()
          : DateTime.now(),
      actorName: row['actor_name'] as String? ?? '',
      actorRole: row['actor_role'] as String? ?? 'trainee',
      category: category,
      action: row['action'] as String? ?? '',
      detail: row['detail'] as String? ?? '',
      roomId: row['room_id'] as String?,
      sessionRef: row['session_ref'] as String?,
    );
  }

  Future<bool> insert(TraineeActivityLogEntry entry) async {
    lastError = null;
    if (!SupabaseService.isReady) {
      lastError = 'Supabase is not ready';
      return false;
    }
    try {
      await SupabaseService.client.from(_table).insert(_toRow(entry));
      debugPrint('activity_logs insert ok: ${entry.id}');
      return true;
    } catch (e) {
      lastError = e.toString();
      debugPrint('activity_logs insert failed: $lastError');
      return false;
    }
  }

  Future<List<TraineeActivityLogEntry>> fetchAll({int limit = 300}) async {
    lastError = null;
    if (!SupabaseService.isReady) return [];
    try {
      final rows = await SupabaseService.client
          .from(_table)
          .select()
          .order('at', ascending: false)
          .limit(limit);
      final list = <TraineeActivityLogEntry>[];
      for (final row in rows as List) {
        list.add(_fromRow(Map<String, dynamic>.from(row as Map)));
      }
      debugPrint('activity_logs fetch count: ${list.length}');
      return list;
    } catch (e) {
      lastError = e.toString();
      debugPrint('activity_logs fetch failed: $lastError');
      return [];
    }
  }
}
