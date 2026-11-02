import 'package:flutter/foundation.dart';
import 'package:trainixprogram/components/class/jitsi_room.dart';
import 'package:trainixprogram/screens/page/profile.dart';
import 'package:trainixprogram/services/supabase_service.dart';

class JaasTokenService {
  JaasTokenService._();
  static final JaasTokenService instance = JaasTokenService._();

  static String? lastError;

  Future<String?> fetchToken({
    required String roomCode,
    required bool asModerator,
  }) async {
    lastError = null;
    if (!JitsiConfig.jaasConfigured) {
      lastError = 'JAAS_APP_ID is not set';
      return null;
    }
    if (!SupabaseService.isReady) {
      lastError = 'Supabase is not ready';
      return null;
    }
    if (SupabaseService.client.auth.currentUser == null) {
      lastError = 'Sign in required for JaaS tokens';
      return null;
    }

    final room = JitsiConfig.roomNameFromCode(roomCode);
    try {
      final res = await SupabaseService.client.functions.invoke(
        'jaas-token',
        body: {
          'room': room,
          'moderator': asModerator,
          'name': ProfileData.displayName,
          'email': ProfileData.email,
          'userId': ProfileData.current.id,
        },
      );
      final data = res.data;
      if (data is Map && data['token'] is String) {
        return data['token'] as String;
      }
      lastError = 'Token response missing token field: $data';
      debugPrint(lastError);
      return null;
    } catch (e) {
      lastError = e.toString();
      debugPrint('jaas-token failed: $lastError');
      return null;
    }
  }
}
