import 'package:flutter/foundation.dart';
import 'package:trainixprogram/services/supabase_service.dart';

class RegisteredTrainee {
  final String id;
  final String displayName;
  final String email;

  const RegisteredTrainee({
    required this.id,
    required this.displayName,
    required this.email,
  });
}

class ProfileDirectoryService {
  ProfileDirectoryService._();
  static final ProfileDirectoryService instance = ProfileDirectoryService._();

  List<RegisteredTrainee> _cache = [];
  DateTime? _loadedAt;

  Future<List<RegisteredTrainee>> loadTrainees({bool force = false}) async {
    if (!force &&
        _cache.isNotEmpty &&
        _loadedAt != null &&
        DateTime.now().difference(_loadedAt!) < const Duration(minutes: 2)) {
      return _cache;
    }
    if (!SupabaseService.isReady) return _cache;
    try {
      final rows = await SupabaseService.client
          .from('profiles')
          .select('id, display_name, email, role')
          .eq('role', 'trainee')
          .order('display_name');
      final list = <RegisteredTrainee>[];
      for (final row in rows as List) {
        final m = Map<String, dynamic>.from(row as Map);
        list.add(
          RegisteredTrainee(
            id: m['id'] as String? ?? '',
            displayName: m['display_name'] as String? ?? '',
            email: m['email'] as String? ?? '',
          ),
        );
      }
      _cache = list;
      _loadedAt = DateTime.now();
      return list;
    } catch (e) {
      debugPrint('load trainees failed: $e');
      return _cache;
    }
  }

  Future<RegisteredTrainee?> resolveTrainee(String input) async {
    final q = input.trim().toLowerCase();
    if (q.isEmpty) return null;
    final list = await loadTrainees();
    for (final t in list) {
      if (t.displayName.trim().toLowerCase() == q) return t;
      if (t.email.trim().toLowerCase() == q) return t;
    }
    final matches = list.where((t) {
      final n = t.displayName.trim().toLowerCase();
      final e = t.email.trim().toLowerCase();
      return n.contains(q) || e.contains(q);
    }).toList();
    if (matches.length == 1) return matches.first;
    return null;
  }

  Future<List<RegisteredTrainee>> suggestions(String input) async {
    final q = input.trim().toLowerCase();
    final list = await loadTrainees();
    if (q.isEmpty) return list.take(8).toList();
    return list
        .where((t) {
          final n = t.displayName.trim().toLowerCase();
          final e = t.email.trim().toLowerCase();
          return n.contains(q) || e.contains(q);
        })
        .take(8)
        .toList();
  }
}
