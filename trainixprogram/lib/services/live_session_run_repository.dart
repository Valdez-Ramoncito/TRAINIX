import 'package:flutter/foundation.dart';
import 'package:trainixprogram/components/class/live_training_session.dart';
import 'package:trainixprogram/services/supabase_service.dart';

class LiveSessionRunRepository {
  LiveSessionRunRepository._();
  static final LiveSessionRunRepository instance = LiveSessionRunRepository._();

  static const _table = 'live_session_runs';

  Map<String, dynamic> _toRow(
    LiveTrainingHistoryEntry e, {
    String? traineeUserId,
  }) {
    return {
      'room_id': e.roomId,
      'room_name': e.roomName,
      'trainer_name': e.trainerName,
      'trainee_name': e.traineeName,
      if (traineeUserId != null && traineeUserId.isNotEmpty)
        'trainee_user_id': traineeUserId,
      'mode': e.mode.name,
      'started_at': e.startedAt.toUtc().toIso8601String(),
      'ended_at': e.endedAt.toUtc().toIso8601String(),
      'rating': e.rating,
      'feedback': e.feedback,
      'takeaway': e.takeaway,
      'needs_follow_up': e.needsFollowUp,
      'checklist_done': e.checklistDone,
      'checklist_total': e.checklistTotal,
      'note_count': e.noteCount,
      'notes': e.notes
          .map(
            (n) => {
              'id': n.id,
              'title': n.title,
              'body': n.body,
              'updated_at': n.updatedAt.toUtc().toIso8601String(),
            },
          )
          .toList(),
      'checklist': e.checklist
          .map((c) => {'id': c.id, 'label': c.label, 'done': c.done})
          .toList(),
    };
  }

  LiveTrainingHistoryEntry _fromRow(Map<String, dynamic> row) {
    LiveSessionMode mode = LiveSessionMode.coaching;
    for (final m in LiveSessionMode.values) {
      if (m.name == (row['mode'] as String? ?? '')) {
        mode = m;
        break;
      }
    }

    final notesRaw = row['notes'];
    final notes = <SessionNote>[];
    if (notesRaw is List) {
      for (final n in notesRaw) {
        if (n is! Map) continue;
        final map = Map<String, dynamic>.from(n);
        notes.add(
          SessionNote(
            id: map['id'] as String? ?? '',
            title: map['title'] as String? ?? 'Note',
            body: map['body'] as String? ?? '',
            updatedAt: map['updated_at'] != null
                ? DateTime.tryParse(map['updated_at'] as String)?.toLocal() ??
                      DateTime.now()
                : DateTime.now(),
          ),
        );
      }
    }

    final checklistRaw = row['checklist'];
    final checklist = <SessionChecklistItem>[];
    if (checklistRaw is List) {
      for (final c in checklistRaw) {
        if (c is! Map) continue;
        final map = Map<String, dynamic>.from(c);
        checklist.add(
          SessionChecklistItem(
            id: map['id'] as String? ?? '',
            label: map['label'] as String? ?? '',
            done: map['done'] as bool? ?? false,
          ),
        );
      }
    }

    return LiveTrainingHistoryEntry(
      roomId: row['room_id'] as String? ?? '',
      roomName: row['room_name'] as String? ?? '',
      trainerName: row['trainer_name'] as String? ?? '',
      traineeName: row['trainee_name'] as String?,
      mode: mode,
      startedAt: row['started_at'] != null
          ? DateTime.tryParse(row['started_at'] as String)?.toLocal() ??
                DateTime.now()
          : DateTime.now(),
      endedAt: row['ended_at'] != null
          ? DateTime.tryParse(row['ended_at'] as String)?.toLocal() ??
                DateTime.now()
          : DateTime.now(),
      rating: row['rating'] as int?,
      feedback: row['feedback'] as String? ?? '',
      takeaway: row['takeaway'] as String? ?? '',
      needsFollowUp: row['needs_follow_up'] as bool? ?? false,
      checklistDone: row['checklist_done'] as int? ?? 0,
      checklistTotal: row['checklist_total'] as int? ?? 0,
      noteCount: row['note_count'] as int? ?? notes.length,
      notes: notes,
      checklist: checklist,
      roomClosed: true,
    );
  }

  static String? lastError;

  Future<bool> insert(LiveTrainingHistoryEntry entry) async {
    return insertForTrainee(entry, null);
  }

  Future<bool> insertForTrainee(
    LiveTrainingHistoryEntry entry,
    String? traineeUserId,
  ) async {
    lastError = null;
    if (!SupabaseService.isReady) {
      lastError = 'Supabase is not ready';
      debugPrint('live_session_runs insert skipped: $lastError');
      return false;
    }
    try {
      await SupabaseService.client
          .from(_table)
          .insert(_toRow(entry, traineeUserId: traineeUserId));
      debugPrint('live_session_runs insert ok: ${entry.roomId}');
      return true;
    } catch (e) {
      lastError = e.toString();
      debugPrint('live_session_runs insert failed: $lastError');
      if (lastError!.contains('trainee_user_id')) {
        try {
          await SupabaseService.client
              .from(_table)
              .insert(_toRow(entry, traineeUserId: null));
          debugPrint('live_session_runs insert ok (no trainee_user_id)');
          return true;
        } catch (e2) {
          lastError = e2.toString();
          debugPrint('live_session_runs insert failed: $lastError');
        }
      }
      return false;
    }
  }

  Future<List<LiveTrainingHistoryEntry>> fetchAll({
    String? traineeUserId,
    String? traineeName,
    bool scopeToCurrentUser = false,
  }) async {
    if (!SupabaseService.isReady) return [];
    try {
      final uid = traineeUserId ??
          (scopeToCurrentUser
              ? SupabaseService.client.auth.currentUser?.id
              : null);
      List<LiveTrainingHistoryEntry> list = [];
      if (uid != null) {
        try {
          final rows = await SupabaseService.client
              .from(_table)
              .select()
              .eq('trainee_user_id', uid)
              .order('ended_at', ascending: false);
          for (final row in rows as List) {
            list.add(_fromRow(Map<String, dynamic>.from(row as Map)));
          }
        } catch (e) {
          debugPrint('live_session_runs uid filter failed: $e');
        }
      }
      if (list.isEmpty) {
        final rows = await SupabaseService.client
            .from(_table)
            .select()
            .order('ended_at', ascending: false);
        for (final row in rows as List) {
          list.add(_fromRow(Map<String, dynamic>.from(row as Map)));
        }
      }
      if (scopeToCurrentUser ||
          (traineeName != null && traineeName.trim().isNotEmpty)) {
        list = list.where((e) {
          return LiveTrainingSession.sameTraineeIdentity(
            e.traineeName,
            traineeName,
          );
        }).toList();
      }
      return list;
    } catch (e) {
      lastError = e.toString();
      debugPrint('live_session_runs fetch failed: $lastError');
      if (lastError!.contains('trainee_user_id')) {
        try {
          final rows = await SupabaseService.client
              .from(_table)
              .select()
              .order('ended_at', ascending: false);
          var list = <LiveTrainingHistoryEntry>[];
          for (final row in rows as List) {
            list.add(_fromRow(Map<String, dynamic>.from(row as Map)));
          }
          if (scopeToCurrentUser ||
              (traineeName != null && traineeName.trim().isNotEmpty)) {
            list = list.where((e) {
              return LiveTrainingSession.sameTraineeIdentity(
                e.traineeName,
                traineeName,
              );
            }).toList();
          }
          return list;
        } catch (e2) {
          lastError = e2.toString();
          debugPrint('live_session_runs fetch fallback failed: $lastError');
        }
      }
      return [];
    }
  }
}
