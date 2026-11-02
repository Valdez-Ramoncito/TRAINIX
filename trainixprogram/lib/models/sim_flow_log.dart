import 'package:flutter/foundation.dart';

class SimFlowLog {
  static const enabled = true;

  static void line(String message) {
    if (!enabled) return;
    debugPrint('[TRAINIX_SIM] $message');
  }

  static void block(String title, Map<String, Object?> fields) {
    if (!enabled) return;
    final buf = StringBuffer('[TRAINIX_SIM] --- $title ---');
    debugPrint(buf.toString());
    for (final e in fields.entries) {
      var v = e.value;
      if (v is String && v.length > 160) {
        v = '${v.substring(0, 160)}...';
      }
      debugPrint('[TRAINIX_SIM]   ${e.key}: $v');
    }
  }
}
