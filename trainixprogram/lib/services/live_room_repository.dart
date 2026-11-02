import 'package:flutter/foundation.dart';
import 'package:trainixprogram/components/class/live_training_session.dart';
import 'package:trainixprogram/services/supabase_service.dart';

class LiveRoomRepository {
  LiveRoomRepository._();
  static final LiveRoomRepository instance = LiveRoomRepository._();

  static const _table = 'live_rooms';
  static String? lastError;

  Map<String, dynamic> _toRow(LiveTrainingSession s) {
    final uid = SupabaseService.isReady
        ? SupabaseService.client.auth.currentUser?.id
        : null;
    return {
      'id': s.id,
      'name': s.name,
      if (uid != null) 'trainer_id': uid,
      'trainer_name': s.trainerName,
      'mode': s.mode.name,
      'visibility': s.visibility.name,
      'designated_trainee_name': s.designatedTraineeName,
      'description': s.description,
      'focus_area': s.focusArea,
      'scheduled_at': s.scheduledAt?.toUtc().toIso8601String(),
      'closed': s.closed,
      'created_at': s.createdAt.toUtc().toIso8601String(),
      'updated_at': (s.updatedAt ?? DateTime.now()).toUtc().toIso8601String(),
    };
  }

  LiveTrainingSession _fromRow(Map<String, dynamic> row) {
    LiveSessionMode mode = LiveSessionMode.coaching;
    for (final m in LiveSessionMode.values) {
      if (m.name == (row['mode'] as String? ?? '')) {
        mode = m;
        break;
      }
    }
    LiveSessionVisibility visibility = LiveSessionVisibility.public;
    for (final v in LiveSessionVisibility.values) {
      if (v.name == (row['visibility'] as String? ?? '')) {
        visibility = v;
        break;
      }
    }
    return LiveTrainingSession(
      id: row['id'] as String,
      name: row['name'] as String? ?? 'Training room',
      trainerName: row['trainer_name'] as String? ?? '',
      mode: mode,
      visibility: visibility,
      designatedTraineeName: row['designated_trainee_name'] as String?,
      description: row['description'] as String?,
      focusArea: row['focus_area'] as String?,
      scheduledAt: row['scheduled_at'] != null
          ? DateTime.tryParse(row['scheduled_at'] as String)?.toLocal()
          : null,
      createdAt: row['created_at'] != null
          ? DateTime.tryParse(row['created_at'] as String)?.toLocal() ??
                DateTime.now()
          : DateTime.now(),
      updatedAt: row['updated_at'] != null
          ? DateTime.tryParse(row['updated_at'] as String)?.toLocal()
          : null,
      closed: row['closed'] as bool? ?? false,
    );
  }

  Future<bool> upsert(LiveTrainingSession session) async {
    lastError = null;
    if (!SupabaseService.isReady) {
      lastError = 'Supabase is not ready';
      debugPrint('live_rooms upsert skipped: $lastError');
      return false;
    }
    try {
      await SupabaseService.client
          .from(_table)
          .upsert(_toRow(session), onConflict: 'id');
      debugPrint('live_rooms upsert ok: ${session.id}');
      return true;
    } catch (e) {
      lastError = e.toString();
      debugPrint('live_rooms upsert failed: $lastError');
      return false;
    }
  }

  Future<bool> delete(String roomId) async {
    lastError = null;
    if (!SupabaseService.isReady) {
      lastError = 'Supabase is not ready';
      return false;
    }
    try {
      await SupabaseService.client.from(_table).delete().eq('id', roomId);
      debugPrint('live_rooms delete ok: $roomId');
      return true;
    } catch (e) {
      lastError = e.toString();
      debugPrint('live_rooms delete failed: $lastError');
      return false;
    }
  }

  Future<List<LiveTrainingSession>> fetchAll() async {
    lastError = null;
    if (!SupabaseService.isReady) return [];
    try {
      final rows = await SupabaseService.client
          .from(_table)
          .select()
          .order('created_at', ascending: false);
      final list = <LiveTrainingSession>[];
      for (final row in rows as List) {
        list.add(_fromRow(Map<String, dynamic>.from(row as Map)));
      }
      debugPrint('live_rooms fetch count: ${list.length}');
      return list;
    } catch (e) {
      lastError = e.toString();
      debugPrint('live_rooms fetch failed: $lastError');
      return [];
    }
  }
}
