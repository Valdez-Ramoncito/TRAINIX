import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:trainixprogram/screens/page/profile.dart';
import 'package:trainixprogram/services/notification_inbox_service.dart';

enum TrainingNotificationType { unlock, progress, success, info }

class TrainingNotification {
  final String id;
  final String title;
  final String body;
  final String? locationHint;
  final TrainingNotificationType type;
  final String? actionType;
  final String? actionPayload;

  const TrainingNotification({
    required this.id,
    required this.title,
    required this.body,
    this.locationHint,
    this.type = TrainingNotificationType.info,
    this.actionType,
    this.actionPayload,
  });
}

class TrainingNotificationCenter {
  static final ValueNotifier<TrainingNotification?> current =
      ValueNotifier<TrainingNotification?>(null);

  static final List<TrainingNotification> _queue = [];
  static bool _showing = false;
  static OverlayState? _overlay;
  static OverlayEntry? _entry;

  static void attachOverlay(OverlayState overlay) {
    _overlay = overlay;
  }

  static void push({
    required String title,
    required String body,
    String? locationHint,
    TrainingNotificationType type = TrainingNotificationType.info,
    String? actionType,
    String? actionPayload,
  }) {
    final note = TrainingNotification(
      id: 'n_${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      body: body,
      locationHint: locationHint,
      type: type,
      actionType: actionType,
      actionPayload: actionPayload,
    );
    _queue.add(note);
    NotificationInboxService.instance.addFromToast(note);
    _pump();
  }

  static void dismissCurrent() {
    current.value = null;
    _entry?.remove();
    _entry = null;
    _showing = false;
    _pump();
  }

  static void _pump() {
    if (_showing || _queue.isEmpty) return;
    _showing = true;
    final note = _queue.removeAt(0);
    current.value = note;
    _showOverlay(note);
  }

  static void _showOverlay(TrainingNotification note) {
    final overlay = _overlay;
    if (overlay == null) return;

    _entry?.remove();
    _entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: 24,
          right: 24,
          child: Material(
            color: Colors.transparent,
            child: _NotificationCard(note: note, onClose: dismissCurrent),
          ),
        );
      },
    );
    overlay.insert(_entry!);

    Future.delayed(const Duration(seconds: 5), () {
      if (current.value?.id == note.id) {
        dismissCurrent();
      }
    });
  }

  static void notifyLessonUnlocked({
    required String categoryName,
    required String lessonTitle,
  }) {
    push(
      title: 'Lesson unlocked',
      body: '$lessonTitle is now available in $categoryName.',
      locationHint: 'Mini Training > Categories > $categoryName',
      type: TrainingNotificationType.unlock,
    );
  }

  static void notifyCategoryFinalUnlocked(String categoryName) {
    push(
      title: 'Category final unlocked',
      body:
          'All lessons in $categoryName are done. Take the category final assessment.',
      locationHint:
          'Mini Training > Categories > $categoryName > Final Assessment',
      type: TrainingNotificationType.unlock,
    );
  }

  static void notifyCategoryCleared(String categoryName) {
    push(
      title: 'Category completed',
      body: '$categoryName is fully cleared.',
      locationHint: 'Mini Training > Categories tab',
      type: TrainingNotificationType.success,
    );
  }

  static void notifyNextCategory(String categoryName) {
    push(
      title: 'Next category ready',
      body: '$categoryName is now unlocked on the category timeline.',
      locationHint: 'Mini Training > Categories tab',
      type: TrainingNotificationType.unlock,
    );
  }

  static void notifyGrandFinalUnlocked() {
    push(
      title: 'Grand Final unlocked',
      body:
          'All categories are complete. You can take the Grand Final assessment.',
      locationHint: 'Mini Training > Categories tab > Grand Final',
      type: TrainingNotificationType.unlock,
    );
  }

  static void notifyScenarioPracticeUnlocked() {
    push(
      title: 'Scenario Practice unlocked',
      body: 'Non-Voice Scenario Practice is now available.',
      locationHint: 'Mini Training > Scenario Practice tab > Non-Voice',
      type: TrainingNotificationType.unlock,
    );
  }

  static void notifyVoiceScenariosUnlocked() {
    push(
      title: 'Voice scenarios unlocked',
      body:
          'Non-Voice scenarios are complete. Voice Scenario Practice is open.',
      locationHint: 'Mini Training > Scenario Practice tab > Voice',
      type: TrainingNotificationType.unlock,
    );
  }

  static void notifyHybridScenariosUnlocked() {
    // Hybrid mode retired.
  }

  static void notifyScenarioCompleted(String scenarioTitle) {
    push(
      title: 'Scenario completed',
      body: '$scenarioTitle is marked complete.',
      locationHint: 'Mini Training > Scenario Practice',
      type: TrainingNotificationType.success,
    );
  }

  static void notifyDebugUnlock() {
    push(
      title: 'Scenario Practice unlocked',
      body:
          'Debug unlock applied. Non-Voice Scenario Practice is available now.',
      locationHint: 'Mini Training > Scenario Practice tab > Non-Voice',
      type: TrainingNotificationType.unlock,
    );
  }

  static void notifySimulationTrainingUnlocked() {
    push(
      title: 'Simulation Training unlocked',
      body:
          'Non-Voice scenarios are complete. Simulation Training is open from the main menu.',
      locationHint: 'Main Menu > Training Simulation',
      type: TrainingNotificationType.unlock,
    );
  }

  static void notifyChatSessionUnlocked() {
    push(
      title: 'Non-Voice Session unlocked',
      body: 'You can start a Non-Voice simulation session.',
      locationHint: 'Training Simulation > New Session > Non-Voice Session',
      type: TrainingNotificationType.unlock,
    );
  }

  static void notifyVoiceSessionUnlocked() {
    push(
      title: 'Voice Session unlocked',
      body: 'You can start a Voice simulation session.',
      locationHint: 'Training Simulation > New Session > Voice Session',
      type: TrainingNotificationType.unlock,
    );
  }

  static void notifyHybridSessionUnlocked() {
    // Hybrid mode retired. No-op for older call sites.
  }

  static void notifyLiveRoomInvite({
    required String trainerName,
    required String roomName,
    required bool isPrivate,
    String? designatedTraineeName,
    String? roomCode,
  }) {
    if (ProfileData.role != AppRole.trainee) return;
    if (isPrivate) {
      final target = designatedTraineeName?.trim().toLowerCase() ?? '';
      final me = ProfileData.displayName.trim().toLowerCase();
      if (target.isEmpty || me.isEmpty || target != me) {
        final t0 = target.split(RegExp(r'\s+')).first;
        final m0 = me.split(RegExp(r'\s+')).first;
        if (t0.isEmpty || m0.isEmpty || t0 != m0) return;
      }
    }
    final code = roomCode?.trim() ?? '';
    push(
      title: isPrivate ? 'Private training invite' : 'Training room available',
      body: isPrivate
          ? '$trainerName invited you to "$roomName".${code.isEmpty ? '' : ' Room code: $code'} Tap to open Trainer Session.'
          : '$trainerName opened "$roomName".${code.isEmpty ? '' : ' Room code: $code'} Tap to open Trainer Session.',
      locationHint: 'Home > Trainer Session',
      type: TrainingNotificationType.info,
      actionType: code.isEmpty ? 'open_trainer_session' : 'join_room',
      actionPayload: code.isEmpty ? null : code,
    );
  }

  static void notifyLiveRoomStarted({
    required String trainerName,
    required String roomName,
  }) {
    push(
      title: 'Training session started',
      body: '$trainerName started "$roomName". Join now from Trainer Session.',
      locationHint: 'Home > Trainer Session',
      type: TrainingNotificationType.progress,
    );
  }

  static void notifyPrivateRoomTrainerEntered({
    required String trainerName,
    required String roomName,
  }) {
    if (ProfileData.role != AppRole.trainee) return;
    push(
      title: 'Trainer is in the room',
      body:
          '$trainerName entered "$roomName". Join from Trainer Session when ready.',
      locationHint: 'Home > Trainer Session',
      type: TrainingNotificationType.progress,
    );
  }

  static void notifyPrivateRoomTraineeEntered({
    required String traineeName,
    required String roomName,
  }) {
    if (ProfileData.role != AppRole.trainer) return;
    push(
      title: 'Trainee joined',
      body: '$traineeName entered "$roomName".',
      locationHint: 'Create Room > your room list',
      type: TrainingNotificationType.success,
    );
  }

  static void notifyLiveRoomReminder({
    required String roomName,
    required String whenLabel,
  }) {
    push(
      title: 'Session starting soon',
      body: '"$roomName" starts at $whenLabel. You can join now.',
      locationHint: 'Trainer Session or Create Room',
      type: TrainingNotificationType.progress,
    );
  }

  static void notifyLiveRoomCancelled({required String roomName}) {
    push(
      title: 'Training room closed',
      body: '"$roomName" was removed by the trainer.',
      locationHint: 'Home > Trainer Session',
      type: TrainingNotificationType.info,
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final TrainingNotification note;
  final VoidCallback onClose;

  const _NotificationCard({required this.note, required this.onClose});

  Color get _accent {
    switch (note.type) {
      case TrainingNotificationType.unlock:
        return const Color(0xFF34D399);
      case TrainingNotificationType.success:
        return const Color(0xFF60A5FA);
      case TrainingNotificationType.progress:
        return const Color(0xFFFBBF24);
      case TrainingNotificationType.info:
        return const Color(0xFF94A3B8);
    }
  }

  IconData get _icon {
    switch (note.type) {
      case TrainingNotificationType.unlock:
        return Icons.lock_open_rounded;
      case TrainingNotificationType.success:
        return Icons.check_circle_rounded;
      case TrainingNotificationType.progress:
        return Icons.flag_rounded;
      case TrainingNotificationType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, color: _accent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title,
                  style: TextStyle(
                    color: _accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  note.body,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                if (note.locationHint != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Where: ${note.locationHint}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: onClose,
            icon: const Icon(Icons.close, size: 18, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
