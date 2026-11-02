import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/components/button/back_button.dart';
import 'package:trainixprogram/components/button/create_button.dart';
import 'package:trainixprogram/components/button/menu_button_training.dart';
import 'package:trainixprogram/components/class/live_training_session.dart';
import 'package:trainixprogram/components/decoration/box_decoration.dart';
import 'package:trainixprogram/components/decoration/text_field.dart';
import 'package:trainixprogram/components/size.dart';
import 'package:trainixprogram/screens/home/homeScreen.dart';
import 'package:trainixprogram/screens/page/profile.dart';
import 'package:trainixprogram/components/class/trainee_activity_log.dart';
import 'package:trainixprogram/models/training/notifications/training_notification.dart';
import 'package:trainixprogram/screens/page/components/mini_training/training_notification_banner.dart';
import 'package:trainixprogram/screens/trainer_page/live_training_room.dart';

class TrainerSession extends StatefulWidget {
  final String? initialRoomCode;

  const TrainerSession({super.key, this.initialRoomCode});

  @override
  State<TrainerSession> createState() => _TrainerSessionState();
}

class _TrainerSessionState extends State<TrainerSession> {
  final TextEditingController _codeCtrl = TextEditingController();
  String? _joinError;

  @override
  void initState() {
    super.initState();
    final code = widget.initialRoomCode?.trim() ?? '';
    if (code.isNotEmpty) {
      _codeCtrl.text = code;
    }
  }

  List<LiveTrainingSession> get _rooms => LiveSessionStore.instance
      .joinableForTrainee(traineeName: ProfileData.displayName);

  List<LiveTrainingSession> get _upcoming => LiveSessionStore.instance
      .upcomingSessions(traineeName: ProfileData.displayName);

  void _refresh() => setState(() {});

  void _checkReminders() {
    for (final s in LiveSessionStore.instance.roomsNeedingReminder()) {
      LiveSessionStore.instance.markReminded(s.id);
      TrainingNotificationCenter.notifyLiveRoomReminder(
        roomName: s.name,
        whenLabel: formatCreatedAt(s.scheduledAt!),
      );
    }
  }

  void _joinByCode() {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _joinError = 'Enter a room code');
      return;
    }
    final session = LiveSessionStore.instance.findByCode(code);
    if (session == null) {
      setState(() => _joinError = 'No room found for that code');
      return;
    }
    setState(() => _joinError = null);
    _tryEnter(session);
  }

  void _onRoomTap(LiveTrainingSession session) {
    final info = computeRoomStatus(session);
    if (info.status == RoomDisplayStatus.full ||
        info.status == RoomDisplayStatus.inSession) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Room is full (1 trainer + 1 trainee only).'),
        ),
      );
      return;
    }

    if (!canJoinBySchedule(session)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Opens 15 minutes before ${formatCreatedAt(session.scheduledAt!)}',
          ),
        ),
      );
      return;
    }

    if (session.isPrivate) {
      _showPrivateCodeDialog(session);
      return;
    }

    _tryEnter(session);
  }

  void _showPrivateCodeDialog(LiveTrainingSession session) {
    final ctrl = TextEditingController();
    String? error;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return Dialog(
              child: Container(
                width: 380,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 22,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color.fromARGB(240, 21, 21, 21),
                  border: Border.all(
                    color: const Color.fromARGB(255, 49, 48, 48),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Private room',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: context.responsiveFont(5),
                      ),
                    ),
                    const Gap(8),
                    Text(
                      'Enter the room code shared by your trainer to join "${session.name}".',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                    const Gap(16),
                    AppTextField(label: 'Room code', controller: ctrl),
                    if (error != null) ...[
                      const Gap(8),
                      Text(
                        error!,
                        style: const TextStyle(
                          color: Color(0xFFFF8A80),
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const Gap(20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CreateButton(
                          text: 'Exit',
                          onTap: () => Navigator.pop(dialogCtx),
                        ),
                        const Gap(10),
                        CreateButton(
                          text: 'Join',
                          onTap: () {
                            final entered = ctrl.text.trim();
                            if (entered != session.id) {
                              setLocal(() => error = 'Incorrect room code');
                              return;
                            }
                            Navigator.pop(dialogCtx);
                            _tryEnter(session);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _tryEnter(LiveTrainingSession session) {
    var firstEntry = false;
    final err = LiveSessionStore.instance.tryJoin(
      roomId: session.id,
      asTrainer: false,
      traineeDisplayName: ProfileData.displayName,
      onJoined: (first) => firstEntry = first,
    );
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      _refresh();
      return;
    }
    final updated = LiveSessionStore.instance.findByCode(session.id)!;
    if (updated.isPrivate && firstEntry) {
      TrainingNotificationCenter.notifyPrivateRoomTraineeEntered(
        traineeName: ProfileData.displayName,
        roomName: updated.name,
      );
    }
    TraineeActivityLogStore.instance.log(
      actorName: ProfileData.displayName,
      actorRole: 'trainee',
      category: TraineeLogCategory.liveTraining,
      action: 'Entered room',
      detail: 'Trainee entered "${updated.name}"',
      roomId: updated.id,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveTrainingRoom(session: updated, isTrainer: false),
      ),
    ).then((_) {
      LiveSessionStore.instance.leave(roomId: session.id, asTrainer: false);
      TraineeActivityLogStore.instance.log(
        actorName: ProfileData.displayName,
        actorRole: 'trainee',
        category: TraineeLogCategory.liveTraining,
        action: 'Left room',
        detail: 'Trainee left "${session.name}"',
        roomId: session.id,
      );
      _refresh();
    });
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkReminders());
    return TrainingNotificationHost(
      child: Scaffold(
        body: Row(
          children: [
            SizedBox(
              width: 260,
              height: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 30,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Text(
                          'TRAINIX',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontSize: context.responsiveFont(7)),
                        ),
                        const Gap(40),
                        MenuButton(
                          icon: Icons.person_outline_rounded,
                          label: 'Profile',
                        ),
                        MenuButton(
                          icon: Icons.school_outlined,
                          label: 'Trainer Session',
                          onTap: () {},
                        ),
                        MenuButton(
                          icon: Icons.settings_outlined,
                          label: 'Settings',
                        ),
                      ],
                    ),
                    TrainingBackButton(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const VerticalDivider(
              width: .5,
              thickness: .3,
              color: Color.fromARGB(255, 105, 106, 106),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trainer Session',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: context.responsiveFont(7),
                      ),
                    ),
                    const Gap(8),
                    Text(
                      'Join a real 1:1 coaching room with your trainer. Private rooms need a code; public rooms show theirs.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                    const Gap(28),
                    Text(
                      'Join by room code',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: context.responsiveFont(4.5),
                      ),
                    ),
                    const Gap(12),
                    Row(
                      children: [
                        SizedBox(
                          width: 280,
                          child: AppTextField(
                            label: 'Room code',
                            controller: _codeCtrl,
                          ),
                        ),
                        const Gap(16),
                        CreateButton(text: 'Join', onTap: _joinByCode),
                      ],
                    ),
                    if (_joinError != null) ...[
                      const Gap(10),
                      Text(
                        _joinError!,
                        style: const TextStyle(
                          color: Color(0xFFFF8A80),
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const Gap(32),
                    if (_upcoming.isNotEmpty) ...[
                      Text(
                        'Upcoming',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontSize: context.responsiveFont(4),
                        ),
                      ),
                      const Gap(10),
                      SizedBox(
                        height: 88,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _upcoming.length,
                          separatorBuilder: (_, __) => const Gap(12),
                          itemBuilder: (_, i) {
                            final s = _upcoming[i];
                            final open = canJoinBySchedule(s);
                            return GestureDetector(
                              onTap: () => _onRoomTap(s),
                              child: Container(
                                width: 220,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(180, 21, 21, 21),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: open
                                        ? const Color(0xFF0D82FE)
                                        : const Color.fromARGB(255, 49, 48, 48),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Gap(6),
                                    Text(
                                      scheduleLabel(s),
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const Gap(4),
                                    Text(
                                      open ? 'Join open' : 'Not open yet',
                                      style: TextStyle(
                                        color: open
                                            ? const Color(0xFF8AFB09)
                                            : Colors.white38,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const Gap(20),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Available rooms',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontSize: context.responsiveFont(4.5)),
                        ),
                        TextButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Refresh'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const Gap(12),
                    Expanded(
                      child: _rooms.isEmpty
                          ? const _EmptyInvites()
                          : GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    mainAxisSpacing: 15,
                                    crossAxisSpacing: 15,
                                    childAspectRatio: 1.05,
                                  ),
                              itemCount: _rooms.length,
                              itemBuilder: (_, index) {
                                final session = _rooms[index];
                                final forMe = session.isDesignatedFor(
                                  ProfileData.displayName,
                                );
                                return _RoomCard(
                                  session: session,
                                  highlighted: forMe,
                                  onTap: () => _onRoomTap(session),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyInvites extends StatelessWidget {
  const _EmptyInvites();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.meeting_room_outlined,
            size: 48,
            color: Colors.white.withValues(alpha: 0.25),
          ),
          const Gap(16),
          Text(
            'No rooms available yet',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: Colors.white54),
          ),
          const Gap(8),
          Text(
            'Ask your trainer for a room code, or wait for an invite.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white38),
          ),
        ],
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.session,
    required this.highlighted,
    required this.onTap,
  });

  final LiveTrainingSession session;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final info = computeRoomStatus(session);
    final tone = _toneColor(info.tone);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: highlighted
                ? const Color(0xFF0D82FE)
                : const Color.fromARGB(255, 49, 48, 48),
            width: highlighted ? 1.5 : 0.3,
          ),
          boxShadow: highlighted
              ? [
                  BoxShadow(
                    color: const Color(0xFF0D82FE).withValues(alpha: 0.25),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: ListContainer(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: tone.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: tone.withValues(alpha: 0.45)),
                      ),
                      child: Text(
                        info.label,
                        style: TextStyle(
                          color: tone,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Gap(6),
                    if (highlighted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D82FE).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'For you',
                          style: TextStyle(
                            color: Color(0xFF0D82FE),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const Spacer(),
                    Icon(
                      session.isPrivate ? Icons.lock_outline : Icons.public,
                      size: 14,
                      color: Colors.white38,
                    ),
                  ],
                ),
                const Gap(10),
                Text(
                  session.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(4),
                Text(
                  'Trainer: ${session.trainerName}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (session.isPublic) ...[
                  const Gap(4),
                  Text(
                    'Code: ${session.id}',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ] else ...[
                  const Gap(4),
                  const Text(
                    'Code: •••••• (enter to join)',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
                if (session.description != null &&
                    session.description!.isNotEmpty) ...[
                  const Gap(6),
                  Text(
                    session.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
                const Gap(6),
                Text(
                  info.detail,
                  style: TextStyle(
                    color: tone.withValues(alpha: 0.9),
                    fontSize: 11,
                  ),
                ),
                const Gap(4),
                Text(
                  'Created ${formatCreatedAt(session.createdAt)}',
                  style: const TextStyle(color: Colors.white24, fontSize: 10),
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    session.isPrivate ? 'Tap · enter code' : 'Tap to join',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _toneColor(ColorTone tone) {
    switch (tone) {
      case ColorTone.green:
        return const Color(0xFF8AFB09);
      case ColorTone.blue:
        return const Color(0xFF0D82FE);
      case ColorTone.amber:
        return const Color(0xFFFFB74D);
      case ColorTone.red:
        return const Color(0xFFFF8A80);
      case ColorTone.neutral:
        return Colors.white54;
    }
  }
}
