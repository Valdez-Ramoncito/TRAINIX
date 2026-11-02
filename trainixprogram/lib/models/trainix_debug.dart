import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Hidden debug tools. Off by default for trainees.
/// Unlock from Settings by tapping the app version label 7 times.
class TrainixDebug extends ChangeNotifier {
  TrainixDebug._();
  static final TrainixDebug instance = TrainixDebug._();

  static bool unlocked = false;
  static int _versionTapCount = 0;
  static DateTime? _lastTap;

  static void onVersionTap() {
    final now = DateTime.now();
    if (_lastTap == null ||
        now.difference(_lastTap!) > const Duration(seconds: 3)) {
      _versionTapCount = 0;
    }
    _lastTap = now;
    _versionTapCount++;
    if (_versionTapCount >= 7) {
      unlocked = !unlocked;
      _versionTapCount = 0;
      instance.notifyListeners();
    }
  }

  static void resetForLogout() {
    if (!unlocked && _versionTapCount == 0) return;
    unlocked = false;
    _versionTapCount = 0;
    _lastTap = null;
    instance.notifyListeners();
  }
}

/// Rebuilds when developer tools are locked or unlocked.
class DebugOnly extends StatelessWidget {
  final Widget child;

  const DebugOnly({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: TrainixDebug.instance,
      builder: (context, _) {
        if (!TrainixDebug.unlocked) return const SizedBox.shrink();
        return child;
      },
    );
  }
}
