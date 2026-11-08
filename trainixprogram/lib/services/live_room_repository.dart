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
      'trainer_inside': s.presence.trainerInside,
      'trainee_inside': s.presence.traineeInside,
      'trainee_display_name': s.presence.traineeDisplayName,
      'created_at': s.createdAt.toUtc().toIso8601String(),
      'updated_at': (s.updatedAt ?? DateTime.now()).toUtc().toIso8601String(),
    };
  }

  LiveTrainingSession fromRowPublic(Map<String, dynamic> row) => _fromRow(row);

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
    final presence = RoomPresence(
      trainerInside: row['trainer_inside'] as bool? ?? false,
      traineeInside: row['trainee_inside'] as bool? ?? false,
      traineeDisplayName: row['trainee_display_name'] as String?,
    );
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
      presence: presence,
    );
  }

  Map<String, dynamic> _toRowLite(LiveTrainingSession s) {
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
    };
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
      debugPrint('live_rooms upsert full failed: $e');
      try {
        await SupabaseService.client
            .from(_table)
            .upsert(_toRowLite(session), onConflict: 'id');
        debugPrint('live_rooms upsert lite ok: ${session.id}');
        await updatePresence(session);
        return true;
      } catch (e2) {
        lastError = e2.toString();
        debugPrint('live_rooms upsert failed: $lastError');
        return false;
      }
    }
  }

  Future<bool> updatePresence(LiveTrainingSession session) async {
    return patchPresence(
      roomId: session.id,
      trainerInside: session.presence.trainerInside,
      traineeInside: session.presence.traineeInside,
      traineeDisplayName: session.presence.traineeDisplayName,
    );
  }

  Future<bool> patchPresence({
    required String roomId,
    bool? trainerInside,
    bool? traineeInside,
    String? traineeDisplayName,
    bool clearTraineeName = false,
  }) async {
    lastError = null;
    if (!SupabaseService.isReady) return false;
    if (trainerInside == null &&
        traineeInside == null &&
        traineeDisplayName == null &&
        !clearTraineeName) {
      return true;
    }

    // RPC bypasses owner-only RLS so trainees can set trainee_inside.
    try {
      final row = await SupabaseService.client.rpc(
        'set_live_room_presence',
        params: {
          'p_room_id': roomId,
          'p_trainer_inside': trainerInside,
          'p_trainee_inside': traineeInside,
          'p_trainee_display_name': traineeDisplayName,
          'p_clear_trainee_name': clearTraineeName,
        },
      );
      debugPrint('live_rooms presence rpc ok: $roomId row=$row');
      return true;
    } catch (e) {
      debugPrint('live_rooms presence rpc failed: $e');
    }

    // Fallback: direct update (works for room owner / trainer only).
    final patch = <String, dynamic>{
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (trainerInside != null) patch['trainer_inside'] = trainerInside;
    if (traineeInside != null) patch['trainee_inside'] = traineeInside;
    if (clearTraineeName) {
      patch['trainee_display_name'] = null;
    } else if (traineeDisplayName != null) {
      patch['trainee_display_name'] = traineeDisplayName;
    }
    try {
      final rows = await SupabaseService.client
          .from(_table)
          .update(patch)
          .eq('id', roomId)
          .select('id, trainer_inside, trainee_inside');
      final list = rows as List? ?? const [];
      if (list.isEmpty) {
        lastError = 'presence update matched 0 rows (RLS or missing room)';
        debugPrint('live_rooms presence patch empty: $roomId');
        return false;
      }
      debugPrint('live_rooms presence patch ok: $roomId ${list.first}');
      return true;
    } catch (e2) {
      lastError = e2.toString();
      debugPrint('live_rooms presence patch failed: $lastError');
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
      debugPrint('live_rooms hard delete failed: $e');
      try {
        await SupabaseService.client
            .from(_table)
            .update({
              'closed': true,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', roomId);
        debugPrint('live_rooms soft-close ok: $roomId');
        return true;
      } catch (e2) {
        try {
          await SupabaseService.client
              .from(_table)
              .update({'closed': true})
              .eq('id', roomId);
          debugPrint('live_rooms soft-close lite ok: $roomId');
          return true;
        } catch (e3) {
          lastError = e3.toString();
          debugPrint('live_rooms delete failed: $lastError');
          return false;
        }
      }
    }
  }

  Future<List<LiveTrainingSession>?> fetchAll() async {
    lastError = null;
    if (!SupabaseService.isReady) {
      lastError = 'Supabase is not ready';
      return null;
    }
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
      return null;
    }
  }
}
