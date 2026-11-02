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
    try {
      await SupabaseService.client.from('app_notifications').upsert({
        'id': n.id,
        'user_id': user.id,
        'title': n.title,
        'body': n.body,
        'location_hint': n.locationHint,
        'type': n.type.name,
        'is_read': n.isRead,
        'created_at': n.createdAt.toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('notifications insert failed: $e');
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
