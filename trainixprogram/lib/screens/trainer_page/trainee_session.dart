import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/components/button/add_button.dart';
import 'package:trainixprogram/components/button/back_button.dart';
import 'package:trainixprogram/components/button/create_button.dart';
import 'package:trainixprogram/components/button/menu_button_training.dart';
import 'package:trainixprogram/components/class/live_training_session.dart';
import 'package:trainixprogram/services/live_room_repository.dart';
import 'package:trainixprogram/services/profile_directory_service.dart';
import 'package:trainixprogram/components/class/room_generate.dart';
import 'package:trainixprogram/components/decoration/box_decoration.dart';
import 'package:trainixprogram/components/decoration/text_field.dart';
import 'package:trainixprogram/components/layout/content_bounds.dart';
import 'package:trainixprogram/components/size.dart';
import 'package:trainixprogram/screens/home/trainer/home_screen.dart';
import 'package:trainixprogram/screens/page/profile.dart';
import 'package:trainixprogram/screens/settings_screen.dart';
import 'package:trainixprogram/components/class/trainee_activity_log.dart';
import 'package:trainixprogram/models/training/notifications/training_notification.dart';
import 'package:trainixprogram/services/notification_inbox_service.dart';
import 'package:trainixprogram/screens/page/components/mini_training/training_notification_banner.dart';
import 'package:trainixprogram/screens/trainer_page/components/header.dart';
import 'package:trainixprogram/screens/trainer_page/live_training_room.dart';
import 'package:trainixprogram/screens/trainer_page/log_monitoring_screen.dart';
import 'package:trainixprogram/widgets/screen_help_button.dart';

class TraineeSession extends StatefulWidget {
  const TraineeSession({super.key});

  @override
  State<TraineeSession> createState() => _TraineeSessionState();
}

class _TraineeSessionState extends State<TraineeSession> {
  List<LiveTrainingSession> get _rooms =>
      LiveSessionStore.instance.roomsForTrainer(ProfileData.displayName);

  List<LiveTrainingSession> get _upcoming => LiveSessionStore.instance
      .upcomingSessions(trainerName: ProfileData.displayName);

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _onStoreChanged() => _refresh();

  void _checkReminders() {
    for (final s in LiveSessionStore.instance.roomsNeedingReminder()) {
      final at = s.scheduledAt;
      if (at == null) continue;
      LiveSessionStore.instance.markReminded(s.id);
      TrainingNotificationCenter.notifyLiveRoomReminder(
        roomName: s.name,
        whenLabel: formatCreatedAt(at),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    LiveSessionStore.instance.addListener(_onStoreChanged);
    LiveSessionStore.instance.startRealtime();
    NotificationInboxService.instance.startRealtime();
    LiveSessionStore.instance.loadFromRemote().then((_) {
      if (mounted) _refresh();
    });
  }

  @override
  void dispose() {
    LiveSessionStore.instance.removeListener(_onStoreChanged);
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
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontSize: context.responsiveFont(7)),
                        ),
                        const Gap(40),
                        MenuButton(
                          icon: Icons.person_outline_rounded,
                          label: 'Profile',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const Profile(),
                              ),
                            );
                          },
                        ),
                        MenuButton(
                          icon: Icons.computer_rounded,
                          label: 'Log Monitoring',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LogMonitoringScreen(),
                              ),
                            );
                          },
                        ),
                        MenuButton(
                          icon: Icons.settings_outlined,
                          label: 'Settings',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SettingsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    TrainingBackButton(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HomeScreenTrainer(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            VerticalDivider(
              width: .5,
              thickness: .3,
              color: AppColors.textMuted(context),
            ),
            Expanded(
              child: ContentBounds(
                maxWidth: 1100,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const TrainerHeader(),
                      const Gap(28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const ScreenHelpButton(
                                content: ScreenHelpCatalog.trainerSession,
                              ),
                              const Gap(10),
                              CreateButton(
                                text: 'Logs',
                                icon: Icons.receipt_long_outlined,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const LogMonitoringScreen(),
                                    ),
                                  );
                                },
                              ),
                              const Gap(10),
                              AddButton(onTap: () => _openEditor()),
                            ],
                          ),
                        ],
                      ),
                      const Gap(20),
                      if (_upcoming.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.event_available_outlined,
                              size: 16,
                              color: AppColors.secondaryText(),
                            ),
                            const Gap(7),
                            Text(
                              'Upcoming',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontSize: context.responsiveFont(4),
                                  ),
                            ),
                          ],
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
                              final scheduledAt = s.scheduledAt;
                              return GestureDetector(
                                onTap: () {
                                  if (!open) {
                                    final when = scheduledAt == null
                                        ? 'the scheduled time'
                                        : formatCreatedAt(scheduledAt);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Opens 15 minutes before $when',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  _enterAsTrainer(s);
                                },
                                child: Container(
                                  width: 200,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.panel(context),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: open
                                          ? AppColors.secondaryText()
                                          : AppColors.borderIdle(context),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.schedule_rounded,
                                            size: 12,
                                            color: AppColors.textMuted(context),
                                          ),
                                          const Gap(5),
                                          Expanded(
                                            child: Text(
                                              scheduledAt == null
                                                  ? 'Scheduled'
                                                  : 'Starts ${compactScheduleTime(scheduledAt)}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: AppColors.textMuted(
                                                    context),
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Gap(4),
                                      Row(
                                        children: [
                                          Icon(
                                            open
                                                ? Icons.lock_open_rounded
                                                : Icons.lock_clock_outlined,
                                            size: 12,
                                            color: open
                                                ? AppColors.primaryText()
                                                : AppColors.textMuted(context),
                                          ),
                                          const Gap(5),
                                          Expanded(
                                            child: Text(
                                              open
                                                  ? 'Join open'
                                                  : 'Not open yet',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: open
                                                    ? AppColors.primaryText()
                                                    : AppColors.textMuted(
                                                        context),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
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
                      Expanded(
                        child: _rooms.isEmpty
                            ? const _EmptyRooms()
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  final maxW = constraints.maxWidth;
                                  final extent = maxW >= 1400
                                      ? 320.0
                                      : maxW >= 1100
                                          ? 360.0
                                          : maxW >= 800
                                              ? 400.0
                                              : maxW;
                                  return GridView.builder(
                                    gridDelegate:
                                        SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: extent,
                                      mainAxisSpacing: 14,
                                      crossAxisSpacing: 14,
                                      mainAxisExtent: 296,
                                    ),
                                    itemCount: _rooms.length,
                                    itemBuilder: (_, index) {
                                      final session = _rooms[index];
                                      return _TrainerRoomCard(
                                        session: session,
                                        onStartNow: () =>
                                            _enterAsTrainer(session),
                                        onEdit: () =>
                                            _openEditor(existing: session),
                                        onDelete: () =>
                                            _confirmDelete(session),
                                        onReopen: () {
                                          final ok = LiveSessionStore.instance
                                              .reopenRoom(
                                            session.id,
                                            byTrainerName:
                                                ProfileData.displayName,
                                          );
                                          if (ok == null) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'You can only reopen rooms you created.',
                                                ),
                                              ),
                                            );
                                            return;
                                          }
                                          _refresh();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Room reopened. You can enter again.',
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isTrainerIdentity(String name) {
    final n = name.trim().toLowerCase();
    final me = ProfileData.displayName.trim().toLowerCase();
    final meShort = ProfileData.shortName.trim().toLowerCase();
    if (n == me || n == meShort) return true;
    if (n.contains('trainer')) return true;
    return false;
  }

  void _openEditor({LiveTrainingSession? existing}) {
    ProfileDirectoryService.instance.loadTrainees();
    final isEdit = existing != null;
    final codeCtrl = TextEditingController(
      text: existing?.id ?? roomGenerate(),
    );
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final focusCtrl = TextEditingController(text: existing?.focusArea ?? '');
    final traineeCtrl = TextEditingController(
      text: existing?.designatedTraineeName ?? '',
    );
    var visibility = existing?.visibility ?? LiveSessionVisibility.public;
    var mode = existing?.mode ?? LiveSessionMode.coaching;
    DateTime? scheduledAt = existing?.scheduledAt;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return Dialog(
              child: Container(
                width: 480,
                constraints: const BoxConstraints(maxHeight: 620),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.panel(context),
                  border: Border.all(
                    color: AppColors.borderIdle(context),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 22,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isEdit
                                ? Icons.edit_note_rounded
                                : Icons.add_home_work_outlined,
                            size: 20,
                            color: AppColors.secondaryText(),
                          ),
                          const Gap(8),
                          Text(
                            isEdit ? 'Edit room' : 'Create room',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontSize: context.responsiveFont(6),
                                ),
                          ),
                        ],
                      ),
                      const Gap(20),
                      Text(
                        'Room code (auto-generated)',
                        style: Theme.of(
                          context,
                        )
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textMuted(context)),
                      ),
                      const Gap(6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.inputFill(context),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.borderIdle(context),
                          ),
                        ),
                        child: SelectableText(
                          codeCtrl.text,
                          style: TextStyle(
                            color: AppColors.secondaryText(),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const Gap(12),
                      AppTextField(label: 'Room name', controller: nameCtrl),
                      const Gap(12),
                      AppTextField(
                        label: 'Agenda / description (optional)',
                        controller: descCtrl,
                      ),
                      const Gap(12),
                      AppTextField(
                        label: 'Focus area (optional)',
                        controller: focusCtrl,
                      ),
                      const Gap(16),
                      Row(
                        children: [
                          Icon(
                            Icons.visibility_outlined,
                            size: 14,
                            color: AppColors.textMuted(context),
                          ),
                          const Gap(6),
                          Text(
                            'Visibility',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textMuted(context),
                                    ),
                          ),
                        ],
                      ),
                      const Gap(8),
                      Row(
                        children: [
                          _ChoiceChip(
                            label: 'Public',
                            selected:
                                visibility == LiveSessionVisibility.public,
                            onTap: () => setLocal(
                              () => visibility = LiveSessionVisibility.public,
                            ),
                          ),
                          const Gap(10),
                          _ChoiceChip(
                            label: 'Private',
                            selected:
                                visibility == LiveSessionVisibility.private,
                            onTap: () => setLocal(
                              () => visibility = LiveSessionVisibility.private,
                            ),
                          ),
                        ],
                      ),
                      if (visibility == LiveSessionVisibility.private) ...[
                        const Gap(12),
                        Text(
                          'Designated trainee',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textMuted(context)),
                        ),
                        const Gap(6),
                        Autocomplete<RegisteredTrainee>(
                          initialValue: TextEditingValue(
                            text: traineeCtrl.text,
                          ),
                          optionsBuilder: (value) async {
                            return ProfileDirectoryService.instance.suggestions(
                              value.text,
                            );
                          },
                          displayStringForOption: (t) => t.displayName,
                          onSelected: (t) {
                            traineeCtrl.text = t.displayName;
                          },
                          fieldViewBuilder:
                              (context, controller, focusNode, onSubmit) {
                            if (traineeCtrl.text.isNotEmpty &&
                                controller.text.isEmpty) {
                              controller.text = traineeCtrl.text;
                            }
                            controller.addListener(() {
                              traineeCtrl.text = controller.text;
                            });
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              style: TextStyle(
                                  color: AppColors.textPrimary(context)),
                              decoration: InputDecoration(
                                hintText: 'Type a registered trainee name',
                                hintStyle: TextStyle(
                                  color: AppColors.textMuted(context),
                                ),
                                filled: true,
                                fillColor: AppColors.inputFill(context),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onSubmitted: (_) => onSubmit(),
                            );
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            final list = options.toList();
                            if (list.isEmpty) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  color: AppColors.elevated(context),
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Text(
                                      'No registered trainee matches.',
                                      style: TextStyle(
                                          color: AppColors.textMuted(context)),
                                    ),
                                  ),
                                ),
                              );
                            }
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                color: AppColors.elevated(context),
                                elevation: 4,
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  width: 360,
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: list.length,
                                    itemBuilder: (_, i) {
                                      final t = list[i];
                                      return ListTile(
                                        dense: true,
                                        title: Text(t.displayName),
                                        subtitle: Text(
                                          t.email,
                                          style: TextStyle(
                                            color: AppColors.textMuted(context),
                                            fontSize: 11,
                                          ),
                                        ),
                                        onTap: () => onSelected(t),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const Gap(6),
                        Text(
                          'Must match a registered trainee account. Only that trainee should know the code.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: AppColors.textMuted(context),
                                  fontSize: 11),
                        ),
                      ],
                      const Gap(16),
                      Row(
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 14,
                            color: AppColors.textMuted(context),
                          ),
                          const Gap(6),
                          Text(
                            'Session type',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textMuted(context),
                                    ),
                          ),
                        ],
                      ),
                      const Gap(8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: LiveSessionMode.values.map((m) {
                          final label = m.name.isEmpty
                              ? m.name
                              : '${m.name[0].toUpperCase()}${m.name.substring(1)}';
                          return _ChoiceChip(
                            label: label,
                            selected: mode == m,
                            onTap: () => setLocal(() => mode = m),
                          );
                        }).toList(),
                      ),
                      const Gap(16),
                      Row(
                        children: [
                          Text(
                            'Schedule (optional)',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textMuted(context)),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: ctx,
                                initialDate: scheduledAt ?? DateTime.now(),
                                firstDate: DateTime.now().subtract(
                                  const Duration(days: 1),
                                ),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (date == null) return;
                              if (!ctx.mounted) return;
                              final time = await showTimePicker(
                                context: ctx,
                                initialTime: TimeOfDay.fromDateTime(
                                  scheduledAt ?? DateTime.now(),
                                ),
                              );
                              if (time == null) return;
                              setLocal(() {
                                scheduledAt = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                              });
                            },
                            child: Text(() {
                              final at = scheduledAt;
                              return at == null
                                  ? 'Pick date & time'
                                  : formatCreatedAt(at);
                            }()),
                          ),
                          if (scheduledAt != null)
                            IconButton(
                              tooltip: 'Clear schedule',
                              onPressed: () =>
                                  setLocal(() => scheduledAt = null),
                              icon: const Icon(Icons.clear, size: 18),
                            ),
                        ],
                      ),
                      const Gap(24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          CreateButton(
                            text: 'Exit',
                            onTap: () => Navigator.of(dialogCtx).pop(),
                          ),
                          const Gap(10),
                          CreateButton(
                            text: isEdit ? 'Save' : 'Create',
                            onTap: () async {
                              final code = codeCtrl.text.trim();
                              if (code.isEmpty) return;
                              final name = nameCtrl.text.trim().isEmpty
                                  ? 'Training room'
                                  : nameCtrl.text.trim();
                              String? designated;
                              String? designatedUserId;
                              if (visibility == LiveSessionVisibility.private) {
                                final typed = traineeCtrl.text.trim();
                                if (typed.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Private rooms need a registered trainee.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (_isTrainerIdentity(typed)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'You can only invite trainees, not yourself or another trainer.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                final match = await ProfileDirectoryService
                                    .instance
                                    .resolveTrainee(typed);
                                if (match == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'No registered trainee matches that name. Pick one from the suggestions.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                designated = match.displayName;
                                designatedUserId = match.id;
                                traineeCtrl.text = match.displayName;
                              }
                              final now = DateTime.now();
                              final session = LiveTrainingSession(
                                id: code,
                                name: name,
                                trainerName: ProfileData.displayName,
                                mode: mode,
                                visibility: visibility,
                                designatedTraineeName: designated,
                                description: descCtrl.text.trim().isEmpty
                                    ? null
                                    : descCtrl.text.trim(),
                                focusArea: focusCtrl.text.trim().isEmpty
                                    ? null
                                    : focusCtrl.text.trim(),
                                scheduledAt: scheduledAt,
                                createdAt: existing?.createdAt ?? now,
                                updatedAt: isEdit ? now : null,
                                presence:
                                    existing?.presence ?? const RoomPresence(),
                                closed: existing?.closed ?? false,
                              );
                              final editing = existing;
                              if (editing != null) {
                                if (!LiveSessionStore.instance.isOwnedBy(
                                  editing.id,
                                  ProfileData.displayName,
                                )) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'You can only edit rooms you created.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                LiveSessionStore.instance.update(session);
                              } else {
                                LiveSessionStore.instance.add(session);
                                TrainingNotificationCenter.notifyLiveRoomInvite(
                                  trainerName: session.trainerName,
                                  roomName: session.name,
                                  isPrivate: session.isPrivate,
                                  designatedTraineeName:
                                      session.designatedTraineeName,
                                  designatedTraineeUserId: designatedUserId,
                                  roomCode: session.id,
                                );
                              }
                              Navigator.of(dialogCtx).pop();
                              _refresh();
                              final ok = await LiveRoomRepository.instance
                                  .upsert(session);
                              if (!context.mounted) return;
                              if (!ok) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      LiveRoomRepository.lastError ??
                                          'Room saved locally but not to database.',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(LiveTrainingSession session) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(context),
        title: const Text('Delete room?'),
        content: Text('Remove "${session.name}" (${session.id}) permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final designatedName = session.designatedTraineeName;
              String? designatedUserId;
              if (session.isPrivate &&
                  designatedName != null &&
                  designatedName.trim().isNotEmpty) {
                final match = await ProfileDirectoryService.instance
                    .resolveTrainee(designatedName);
                designatedUserId = match?.id;
              }
              LiveSessionStore.instance.remove(session.id);
              TrainingNotificationCenter.notifyLiveRoomCancelled(
                roomName: session.name,
                designatedTraineeName: designatedName,
                designatedTraineeUserId: designatedUserId,
                isPrivate: session.isPrivate,
              );
              if (ctx.mounted) Navigator.pop(ctx);
              _refresh();
            },
            child: Text(
              'Delete',
              style: TextStyle(color: AppColors.errorText()),
            ),
          ),
        ],
      ),
    );
  }

  void _enterAsTrainer(LiveTrainingSession session) {
    var firstEntry = false;
    final err = LiveSessionStore.instance.tryJoin(
      roomId: session.id,
      asTrainer: true,
      onJoined: (first) => firstEntry = first,
    );
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      _refresh();
      return;
    }
    final updated = LiveSessionStore.instance.findByCode(session.id)!;
    if (updated.isPrivate && firstEntry) {
      TrainingNotificationCenter.notifyPrivateRoomTrainerEntered(
        trainerName: updated.trainerName,
        roomName: updated.name,
      );
    }
    TraineeActivityLogStore.instance.log(
      actorName: ProfileData.displayName,
      actorRole: 'trainer',
      category: TraineeLogCategory.liveTraining,
      action: 'Entered room',
      detail: 'Trainer entered "${updated.name}"',
      roomId: updated.id,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveTrainingRoom(session: updated, isTrainer: true),
      ),
    ).then((_) {
      LiveSessionStore.instance.leave(roomId: session.id, asTrainer: true);
      TraineeActivityLogStore.instance.log(
        actorName: ProfileData.displayName,
        actorRole: 'trainer',
        category: TraineeLogCategory.liveTraining,
        action: 'Left room',
        detail: 'Trainer left "${session.name}"',
        roomId: session.id,
      );
      _refresh();
    });
  }
}

class _EmptyRooms extends StatelessWidget {
  const _EmptyRooms();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add_home_work_outlined,
            size: 48,
            color: AppColors.textMuted(context),
          ),
          const Gap(16),
          Text(
            'No rooms yet',
            style: Theme.of(
              context,
            )
                .textTheme
                .titleSmall
                ?.copyWith(color: AppColors.textMuted(context)),
          ),
          const Gap(8),
          Text(
            'Tap + to create a coaching room for a trainee.',
            style: Theme.of(
              context,
            )
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textMuted(context)),
          ),
        ],
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.secondaryText().withValues(alpha: 0.25)
              : AppColors.cardHover(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? AppColors.secondaryText()
                : AppColors.borderStrong(context),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected
                ? AppColors.textPrimary(context)
                : AppColors.textSecondary(context),
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _TrainerRoomCard extends StatelessWidget {
  const _TrainerRoomCard({
    required this.session,
    required this.onStartNow,
    required this.onEdit,
    required this.onDelete,
    required this.onReopen,
  });

  final LiveTrainingSession session;
  final VoidCallback onStartNow;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReopen;

  @override
  Widget build(BuildContext context) {
    final info = computeRoomStatus(session);
    final tone = _toneColor(context, info.tone);

    return ListContainer(
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: session.isPrivate
                        ? AppColors.warningText().withValues(alpha: 0.12)
                        : AppColors.chipBg(context),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    session.isPrivate ? 'Private' : 'Public',
                    style: TextStyle(
                      fontSize: 10,
                      color: session.isPrivate
                          ? AppColors.warningText()
                          : AppColors.textMuted(context),
                    ),
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 18,
                    color: AppColors.textMuted(context),
                  ),
                  color: AppColors.elevated(context),
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const Gap(8),
            Text(
              session.name,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Gap(4),
            _MetaRow(
              icon: Icons.person_outline_rounded,
              text: 'Trainer: ${session.trainerName}',
              color: AppColors.textSecondary(context),
            ),
            const Gap(4),
            _MetaRow(
              icon: Icons.vpn_key_outlined,
              text: session.id,
              color: AppColors.secondaryText(context),
              mono: true,
            ),
            if (session.designatedTraineeName != null) ...[
              const Gap(4),
              _MetaRow(
                icon: Icons.school_outlined,
                text: 'Trainee: ${session.designatedTraineeName}',
              ),
            ],
            if (session.description case final description?
                when description.isNotEmpty) ...[
              const Gap(6),
              _MetaRow(
                icon: Icons.notes_rounded,
                text: description,
                maxLines: 2,
              ),
            ],
            const Gap(6),
            _MetaRow(
              icon: Icons.info_outline_rounded,
              text: info.detail,
              color: tone.withValues(alpha: 0.85),
            ),
            const Gap(4),
            _MetaRow(
              icon: Icons.history_rounded,
              text: 'Created ${formatCreatedAt(session.createdAt)}',
              fontSize: 10,
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerLeft,
              child: session.closed
                  ? _SmallAction(
                      label: 'Reopen room',
                      icon: Icons.lock_open_rounded,
                      primary: true,
                      onTap: onReopen,
                    )
                  : _SmallAction(
                      label: 'Enter room',
                      icon: Icons.login_rounded,
                      primary: true,
                      onTap: onStartNow,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Color _toneColor(BuildContext context, ColorTone tone) {
    switch (tone) {
      case ColorTone.green:
        return AppColors.primaryText();
      case ColorTone.blue:
        return AppColors.secondaryText();
      case ColorTone.amber:
        return AppColors.warningText();
      case ColorTone.red:
        return AppColors.errorText();
      case ColorTone.neutral:
        return AppColors.textMuted(context);
    }
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.text,
    this.color,
    this.mono = false,
    this.maxLines = 1,
    this.fontSize = 11,
  });

  final IconData icon;
  final String text;
  final Color? color;
  final bool mono;
  final int maxLines;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final tone = color ?? AppColors.textMuted(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 13, color: tone),
        ),
        const Gap(6),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: tone,
              fontSize: fontSize,
              fontFamily: mono ? 'monospace' : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _SmallAction extends StatefulWidget {
  const _SmallAction({
    required this.label,
    required this.primary,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool primary;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  State<_SmallAction> createState() => _SmallActionState();
}

class _SmallActionState extends State<_SmallAction> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final icon = widget.icon;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: widget.primary
                ? (_hover
                    ? AppColors.secondaryText()
                    : AppColors.secondaryText())
                : (_hover
                    ? AppColors.cardHover(context)
                    : AppColors.cardHover(context)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.primary
                  ? Colors.transparent
                  : AppColors.borderStrong(context),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: widget.primary
                      ? AppColors.onSecondary(context)
                      : AppColors.textSecondary(context),
                ),
                const Gap(6),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: widget.primary
                      ? AppColors.onSecondary(context)
                      : AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
