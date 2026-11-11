import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:trainixprogram/screens/page/profile.dart';
import 'package:trainixprogram/screens/page/trainer_session.dart';
import 'package:trainixprogram/screens/page/mini_training.dart';
import 'package:trainixprogram/screens/settings_screen.dart';
import 'package:trainixprogram/screens/simulation_hub_screen.dart';
import 'package:trainixprogram/services/app_navigator.dart';
import 'package:trainixprogram/services/notification_inbox_service.dart';
import 'package:trainixprogram/services/supabase_service.dart';

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
    _pump();
  }

  static OverlayState? _resolveOverlay() {
    return _overlay ?? AppNavigator.key.currentState?.overlay;
  }

  static void push({
    required String title,
    required String body,
    String? locationHint,
    TrainingNotificationType type = TrainingNotificationType.info,
    String? actionType,
    String? actionPayload,
    bool addToInbox = true,
    String? id,
  }) {
    final signedIn =
        SupabaseService.isReady &&
        SupabaseService.client.auth.currentUser != null;
    if (!signedIn) return;
    if (!AppSettings.notificationsEnabled) return;
    final note = TrainingNotification(
      id: id ?? 'n_${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      body: body,
      locationHint: locationHint,
      type: type,
      actionType: actionType,
      actionPayload: actionPayload,
    );
    _queue.add(note);
    if (addToInbox) {
      NotificationInboxService.instance.addFromToast(note);
    }
    _pump();
  }

  static void clearToasts() {
    _queue.clear();
    dismissCurrent();
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
    final overlay = _resolveOverlay();
    if (overlay == null) {
      _showing = false;
      _queue.insert(0, note);
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!_showing) _pump();
      });
      return;
    }
    _overlay = overlay;

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

  static void notifyScenarioCompleted(String scenarioTitle) {
    final label = scenarioTitle.trim().isEmpty
        ? 'Scenario'
        : scenarioTitle.trim();
    push(
      title: 'Scenario complete',
      body: 'You finished "$label". Keep going when you are ready.',
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
      actionType: 'open_simulation',
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

  static Future<bool> notifyLiveRoomInvite({
    required String trainerName,
    required String roomName,
    required bool isPrivate,
    String? designatedTraineeName,
    String? designatedTraineeUserId,
    String? roomCode,
  }) async {
    final code = roomCode?.trim() ?? '';
    final title = isPrivate
        ? 'Private training invite'
        : 'Training room available';
    final codeLine = code.isEmpty ? '' : ' Room code: $code.';
    final body = isPrivate
        ? '$trainerName invited you to "$roomName".$codeLine Open Trainer Session to join.'
        : '$trainerName opened "$roomName".$codeLine Open Trainer Session to join.';
    final noteId = 'n_${DateTime.now().microsecondsSinceEpoch}';
    final actionType = code.isEmpty ? 'open_trainer_session' : 'join_room';
    final actionPayload = code.isEmpty ? null : code;

    if (isPrivate) {
      final targetId = designatedTraineeUserId?.trim() ?? '';
      if (targetId.isEmpty) {
        debugPrint('private invite skipped: no designated trainee user id');
        return false;
      }
      final ok = await NotificationInboxService.instance.insertForUser(
        userId: targetId,
        id: noteId,
        title: title,
        body: body,
        locationHint: 'Home > Trainer Session',
        type: TrainingNotificationType.info,
        actionType: actionType,
        actionPayload: actionPayload,
      );
      if (!ok) {
        debugPrint('private invite insert failed for $targetId');
      }
      if (ProfileData.role == AppRole.trainee) {
        final meId = SupabaseService.isReady
            ? SupabaseService.client.auth.currentUser?.id
            : null;
        if (meId != null && meId == targetId) {
          push(
            id: noteId,
            title: title,
            body: body,
            locationHint: 'Home > Trainer Session',
            type: TrainingNotificationType.info,
            actionType: actionType,
            actionPayload: actionPayload,
            addToInbox: false,
          );
        }
      }
      return ok;
    }

    if (ProfileData.role == AppRole.trainee) {
      push(
        title: title,
        body: body,
        locationHint: 'Home > Trainer Session',
        type: TrainingNotificationType.info,
        actionType: actionType,
        actionPayload: actionPayload,
      );
    }
    return true;
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
    String? roomCode,
  }) {
    final code = roomCode?.trim() ?? '';
    final codeLine = code.isEmpty ? '' : ' Room code: $code.';
    push(
      title: 'Session starting soon',
      body: '"$roomName" starts at $whenLabel.$codeLine You can join now.',
      locationHint: 'Home > Trainer Session',
      type: TrainingNotificationType.progress,
      actionType: code.isEmpty ? 'open_trainer_session' : 'join_room',
      actionPayload: code.isEmpty ? null : code,
    );
  }

  static Future<bool> notifyLiveRoomCancelled({
    required String roomName,
    String? designatedTraineeName,
    String? designatedTraineeUserId,
    bool isPrivate = false,
    String? roomCode,
  }) async {
    final code = roomCode?.trim() ?? '';
    final title = 'Training room deleted';
    final body = code.isEmpty
        ? '"$roomName" was deleted by the trainer and is no longer available.'
        : '"$roomName" ($code) was deleted by the trainer and is no longer available.';
    final noteId = 'n_${DateTime.now().microsecondsSinceEpoch}';

    if (isPrivate) {
      final targetId = designatedTraineeUserId?.trim() ?? '';
      if (targetId.isEmpty) return false;
      final ok = await NotificationInboxService.instance.insertForUser(
        userId: targetId,
        id: noteId,
        title: title,
        body: body,
        locationHint: 'Home > Trainer Session',
        type: TrainingNotificationType.info,
        actionType: 'open_trainer_session',
      );
      if (ProfileData.role == AppRole.trainee) {
        final meId = SupabaseService.isReady
            ? SupabaseService.client.auth.currentUser?.id
            : null;
        if (meId != null && meId == targetId) {
          push(
            id: noteId,
            title: title,
            body: body,
            locationHint: 'Home > Trainer Session',
            type: TrainingNotificationType.info,
            actionType: 'open_trainer_session',
            addToInbox: false,
          );
        }
      }
      return ok;
    }
    return false;
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

  bool get _navigable {
    final action = note.actionType?.trim() ?? '';
    final hint = (note.locationHint ?? '').toLowerCase();
    if (action.isNotEmpty) return true;
    return hint.contains('trainer session') ||
        hint.contains('mini training') ||
        hint.contains('scenario practice') ||
        hint.contains('categories') ||
        hint.contains('simulation') ||
        hint.contains('create room');
  }

  void _openTarget(BuildContext context) {
    NotificationInboxService.instance.markRead(note.id);
    final action = note.actionType?.trim();
    final payload = note.actionPayload?.trim() ?? '';
    final hint = (note.locationHint ?? '').toLowerCase();
    final nav = AppNavigator.context;
    if (nav == null) return;
    final isTrainee = ProfileData.role == AppRole.trainee;

    void go(Widget page) {
      onClose();
      Navigator.of(nav).push(MaterialPageRoute(builder: (_) => page));
    }

    if (action == 'join_room') {
      if (isTrainee) {
        go(TrainerSession(initialRoomCode: payload.isEmpty ? null : payload));
      }
      return;
    }
    if (action == 'open_trainer_session') {
      if (isTrainee) go(const TrainerSession());
      return;
    }
    if (action == 'open_mini_training' ||
        hint.contains('mini training') ||
        hint.contains('scenario practice') ||
        hint.contains('categories')) {
      if (isTrainee) go(const MiniTraining());
      return;
    }
    if (action == 'open_simulation' ||
        hint.contains('training simulation') ||
        hint.contains('simulation')) {
      if (isTrainee) go(const SimulationHubScreen());
      return;
    }
    if (hint.contains('create room')) {
      return;
    }
    if (hint.contains('trainer session')) {
      if (isTrainee) go(const TrainerSession());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _navigable ? () => _openTarget(context) : null,
        mouseCursor: _navigable
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _accent, width: 1.4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
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
                    if (_navigable) ...[
                      const SizedBox(height: 6),
                      Text(
                        note.actionType == 'join_room'
                            ? 'Click to open the room'
                            : 'Click to open',
                        style: const TextStyle(
                          color: Color(0xFF70BD8A),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
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
                mouseCursor: SystemMouseCursors.click,
                icon: const Icon(Icons.close, size: 18, color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
