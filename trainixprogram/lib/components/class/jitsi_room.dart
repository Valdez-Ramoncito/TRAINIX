import 'package:flutter_dotenv/flutter_dotenv.dart';

class JitsiConfig {
  static String? get jaasAppId {
    final id = dotenv.env['JAAS_APP_ID']?.trim();
    if (id == null || id.isEmpty) return null;
    return id;
  }

  static String? get jaasKid {
    final kid = dotenv.env['JAAS_API_KEY_ID']?.trim();
    if (kid == null || kid.isEmpty) return null;
    return kid;
  }

  static bool get jaasConfigured => jaasAppId != null && jaasAppId!.isNotEmpty;

  static String get baseUrl {
    final fromEnv = dotenv.env['JITSI_BASE_URL']?.trim();
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    return 'https://meet.jit.si';
  }

  static bool get usesPublicMeet => baseUrl.contains('meet.jit.si');

  static const int publicSessionLimitMinutes = 95;

  static String roomNameFromCode(String roomCode) {
    final cleaned = roomCode.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (cleaned.isEmpty) return 'trainixroom';
    return 'trainix$cleaned';
  }

  static String meetingUrl({
    required String roomCode,
    String? displayName,
    bool asModerator = false,
    String? jwt,
  }) {
    final room = roomNameFromCode(roomCode);
    final appId = jaasAppId;
    final hasJwt = jwt != null && jwt.trim().isNotEmpty;

    final String origin;
    final String path;

    if (hasJwt && appId != null) {
      origin = 'https://8x8.vc';
      path = '$appId/$room';
    } else {
      origin = baseUrl.contains('8x8.vc') ? 'https://meet.jit.si' : baseUrl;
      path = room;
    }

    final parts = <String>[
      'config.prejoinPageEnabled=false',
      'config.prejoinConfig.enabled=false',
      'config.disableDeepLinking=true',
      'config.startWithAudioMuted=false',
      'config.startWithVideoMuted=false',
      'config.enableLobby=false',
      'config.requireDisplayName=false',
      'config.enableWelcomePage=false',
      'interfaceConfig.SHOW_CHROME_EXTENSION_BANNER=false',
    ];

    if (displayName != null && displayName.trim().isNotEmpty) {
      final name = Uri.encodeComponent(displayName.trim());
      parts.add('userInfo.displayName="$name"');
    }

    final hash = parts.join('&');
    if (hasJwt) {
      return '$origin/$path?jwt=${Uri.encodeComponent(jwt.trim())}#$hash';
    }
    return '$origin/$path#$hash';
  }

  static String statusHint({required bool hasJwt}) {
    if (jaasConfigured && hasJwt) {
      return 'JaaS meeting with signed token.';
    }
    if (jaasConfigured && !hasJwt) {
      return 'JaaS is set up, but no JWT yet. Using public meet.jit.si until the token service responds. Deploy the jaas-token Edge Function.';
    }
    return 'Public meet.jit.si. Host controls need JaaS + JWT.';
  }
}
