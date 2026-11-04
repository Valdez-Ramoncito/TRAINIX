import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:trainixprogram/services/supabase_service.dart';
import 'package:trainixprogram/models/training/notifications/training_notification.dart';

class InboxNotification {
  final String id;
  final String title;
  final String body;
  final String? locationHint;
  final TrainingNotificationType type;
  final DateTime createdAt;
  final String? actionType;
  final String? actionPayload;
  bool isRead;

  InboxNotification({
    required this.id,
    required this.title,
    required this.body,
    this.locationHint,
    required this.type,
    required this.createdAt,
    this.actionType,
    this.actionPayload,
    this.isRead = false,
  });
}

class NotificationInboxService extends ChangeNotifier {
  NotificationInboxService._();
  static final NotificationInboxService instance = NotificationInboxService._();

  final List<InboxNotification> _items = [];

  List<InboxNotification> get items => List.unmodifiable(_items);

  int get unreadCount => _items.where((e) => !e.isRead).length;

  void addFromToast(TrainingNotification note) {
    if (_items.any((e) => e.id == note.id)) return;
    _items.insert(
      0,
      InboxNotification(
        id: note.id,
        title: note.title,
        body: note.body,
        locationHint: note.locationHint,
        type: note.type,
        createdAt: DateTime.now(),
        actionType: note.actionType,
        actionPayload: note.actionPayload,
        isRead: false,
      ),
    );
    if (_items.length > 100) {
      _items.removeRange(100, _items.length);
    }
    notifyListeners();
    _persistInsert(_items.first);
  }

  void markRead(String id) {
    final i = _items.indexWhere((e) => e.id == id);
    if (i < 0) return;
    if (_items[i].isRead) return;
    _items[i].isRead = true;
    notifyListeners();
    _persistRead(id, true);
  }

  void markAllRead() {
    for (final e in _items) {
      e.isRead = true;
    }
    notifyListeners();
    _persistMarkAllRead();
  }

  void deleteOne(String id) {
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
    _persistDelete(id);
  }

  void clearAll() {
    _items.clear();
    notifyListeners();
    _persistClear();
  }

  void clearLocalOnly() {
    _items.clear();
    notifyListeners();
  }

  Future<void> loadFromRemote() async {
    if (!SupabaseService.isReady) return;
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return;
    try {
      final rows = await SupabaseService.client
          .from('app_notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(80);
      _items.clear();
      for (final row in rows as List) {
        final m = Map<String, dynamic>.from(row as Map);
        TrainingNotificationType type = TrainingNotificationType.info;
        for (final t in TrainingNotificationType.values) {
          if (t.name == (m['type'] as String? ?? '')) {
            type = t;
            break;
          }
        }
        _items.add(
          InboxNotification(
            id: m['id'] as String? ?? '',
            title: m['title'] as String? ?? '',
            body: m['body'] as String? ?? '',
            locationHint: m['location_hint'] as String?,
            type: type,
            createdAt: m['created_at'] != null
                ? DateTime.tryParse(m['created_at'] as String)?.toLocal() ??
                      DateTime.now()
                : DateTime.now(),
            isRead: m['is_read'] as bool? ?? false,
            actionType: m['action_type'] as String?,
            actionPayload: m['action_payload'] as String?,
          ),
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('notifications load failed: $e');
    }
  }

  Future<void> _persistInsert(InboxNotification n) async {
    if (!SupabaseService.isReady) return;
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return;
    await insertForUser(
      userId: user.id,
      id: n.id,
      title: n.title,
      body: n.body,
      locationHint: n.locationHint,
      type: n.type,
      isRead: n.isRead,
      createdAt: n.createdAt,
      actionType: n.actionType,
      actionPayload: n.actionPayload,
    );
  }

  Future<bool> insertForUser({
    required String userId,
    required String id,
    required String title,
    required String body,
    String? locationHint,
    TrainingNotificationType type = TrainingNotificationType.info,
    bool isRead = false,
    DateTime? createdAt,
    String? actionType,
    String? actionPayload,
  }) async {
    if (!SupabaseService.isReady) return false;
    if (userId.trim().isEmpty) return false;
    final at = createdAt ?? DateTime.now();
    final row = <String, dynamic>{
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'location_hint': locationHint,
      'type': type.name,
      'is_read': isRead,
      'created_at': at.toUtc().toIso8601String(),
      if (actionType != null && actionType.trim().isNotEmpty)
        'action_type': actionType.trim(),
      if (actionPayload != null && actionPayload.trim().isNotEmpty)
        'action_payload': actionPayload.trim(),
    };
    var ok = false;
    try {
      await SupabaseService.client.from('app_notifications').upsert(row);
      ok = true;
    } catch (e) {
      debugPrint('notifications direct insert failed: $e');
      ok = await _insertViaEdgeFunction(row);
    }
    if (!ok) return false;
    final me = SupabaseService.client.auth.currentUser?.id;
    if (me != null && me == userId) {
      if (_items.any((e) => e.id == id)) return true;
      _items.insert(
        0,
        InboxNotification(
          id: id,
          title: title,
          body: body,
          locationHint: locationHint,
          type: type,
          createdAt: at,
          actionType: actionType,
          actionPayload: actionPayload,
          isRead: isRead,
        ),
      );
      if (_items.length > 100) {
        _items.removeRange(100, _items.length);
      }
      notifyListeners();
    }
    return true;
  }

  Future<bool> _insertViaEdgeFunction(Map<String, dynamic> row) async {
    try {
      final res = await SupabaseService.client.functions.invoke(
        'notify-user',
        body: row,
      );
      final data = res.data;
      if (data is Map && (data['ok'] == true || data['id'] != null)) {
        return true;
      }
      debugPrint('notify-user response: $data');
      return false;
    } catch (e) {
      debugPrint('notify-user edge failed: $e');
      return false;
    }
  }

  Future<void> _persistRead(String id, bool isRead) async {
    if (!SupabaseService.isReady) return;
    try {
      await SupabaseService.client
          .from('app_notifications')
          .update({'is_read': isRead})
          .eq('id', id);
    } catch (_) {}
  }

  Future<void> _persistMarkAllRead() async {
    if (!SupabaseService.isReady) return;
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return;
    try {
      await SupabaseService.client
          .from('app_notifications')
          .update({'is_read': true})
          .eq('user_id', user.id);
    } catch (_) {}
  }

  Future<void> _persistDelete(String id) async {
    if (!SupabaseService.isReady) return;
    try {
      await SupabaseService.client
          .from('app_notifications')
          .delete()
          .eq('id', id);
    } catch (_) {}
  }

  Future<void> _persistClear() async {
    if (!SupabaseService.isReady) return;
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return;
    try {
      await SupabaseService.client
          .from('app_notifications')
          .delete()
          .eq('user_id', user.id);
    } catch (_) {}
  }
}
