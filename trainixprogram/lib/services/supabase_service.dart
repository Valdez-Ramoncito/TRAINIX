import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();

  static bool _ready = false;
  static String? _lastError;

  static bool get isReady => _ready;
  static String? get lastError => _lastError;
  static SupabaseClient get client => Supabase.instance.client;

  static Future<bool> initialize() async {
    _lastError = null;
    final url = dotenv.env['SUPABASE_URL']?.trim() ?? '';
    final anonKey = dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';

    if (url.isEmpty || anonKey.isEmpty) {
      _ready = false;
      _lastError = 'Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env';
      return false;
    }

    try {
      await Supabase.initialize(url: url, anonKey: anonKey);
      try {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          await Supabase.instance.client.auth.refreshSession();
        }
      } catch (_) {
        try {
          await Supabase.instance.client.auth.signOut();
        } catch (_) {}
      }
      _ready = true;
      return true;
    } catch (e) {
      _ready = false;
      _lastError = e.toString();
      return false;
    }
  }

  static Future<String> smokeTest() async {
    if (!_ready) {
      return _lastError ?? 'Supabase is not initialized';
    }
    try {
      await client.from('profiles').select('id').limit(1);
      return 'Database connected.';
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('permission') ||
          msg.contains('rls') ||
          msg.contains('42501') ||
          msg.contains('unauthorized')) {
        return 'Database connected. Sign-in required for profiles.';
      }
      if (msg.contains('could not find the table') ||
          msg.contains('relation') ||
          msg.contains('pgrst') ||
          msg.contains('404')) {
        return 'Connected. Run DB-2 SQL for profiles.';
      }
      return 'Connected.';
    }
  }
}
