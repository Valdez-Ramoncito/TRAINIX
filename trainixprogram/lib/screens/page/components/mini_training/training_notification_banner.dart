import 'package:flutter/material.dart';
import 'package:trainixprogram/models/training/notifications/training_notification.dart';

class TrainingNotificationHost extends StatefulWidget {
  final Widget child;

  const TrainingNotificationHost({super.key, required this.child});

  @override
  State<TrainingNotificationHost> createState() =>
      _TrainingNotificationHostState();
}

class _TrainingNotificationHostState extends State<TrainingNotificationHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _attach());
  }

  void _attach() {
    if (!mounted) return;
    final navigator = Navigator.maybeOf(context, rootNavigator: true);
    final overlay =
        navigator?.overlay ?? Overlay.maybeOf(context, rootOverlay: true);
    if (overlay != null) {
      TrainingNotificationCenter.attachOverlay(overlay);
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _attach());
    return widget.child;
  }
}
