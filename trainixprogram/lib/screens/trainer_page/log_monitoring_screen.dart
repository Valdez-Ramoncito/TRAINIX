import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/components/button/back_button.dart';
import 'package:trainixprogram/components/button/create_button.dart';
import 'package:trainixprogram/components/class/live_training_session.dart';
import 'package:trainixprogram/components/class/trainee_activity_log.dart';
import 'package:trainixprogram/components/size.dart';
import 'package:trainixprogram/screens/home/trainer/home_screen.dart';
import 'package:trainixprogram/screens/page/profile.dart';
import 'package:provider/provider.dart';
import 'package:trainixprogram/models/simulation_history.dart';
import 'package:trainixprogram/models/session_score.dart';
import 'package:trainixprogram/widgets/screen_help_button.dart';

class LogMonitoringScreen extends StatefulWidget {
  const LogMonitoringScreen({
    super.key,
    this.showAllRoles = false,
    this.embedded = false,
  });

  /// When true, show trainee + trainer + admin activity (admin view).
  final bool showAllRoles;

  /// When true, hide the outer Scaffold chrome for embedding in Admin.
  final bool embedded;

  @override
  State<LogMonitoringScreen> createState() => _LogMonitoringScreenState();
}

class _LogMonitoringScreenState extends State<LogMonitoringScreen> {
  int _tab = 0;
  String _logFilter = 'All';
  String _actorFilter = 'All';
  String _roleFilter = 'All';

  List<LiveTrainingHistoryEntry> get _history =>
      LiveSessionStore.instance.historyEntries();

  List<TraineeActivityLogEntry> get _baseLogs {
    final all = TraineeActivityLogStore.instance.entries;
    if (widget.showAllRoles) return all;
    return all.where((e) => e.actorRole.toLowerCase() == 'trainee').toList();
  }

  List<TraineeActivityLogEntry> get _logs {
    var list = List<TraineeActivityLogEntry>.from(_baseLogs);
    if (_roleFilter != 'All') {
      list = list
          .where((e) => e.actorRole.toLowerCase() == _roleFilter.toLowerCase())
          .toList();
    }
    if (_actorFilter != 'All') {
      list = list.where((e) => e.actorName == _actorFilter).toList();
    }
    if (_logFilter != 'All') {
      final cat = TraineeLogCategory.values.firstWhere(
        (c) => c.name == _logFilter,
        orElse: () => TraineeLogCategory.system,
      );
      list = list.where((e) => e.category == cat).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final history = _history;
    final logs = _logs;
    final scoped = _baseLogs;
    final actors = ['All', ...scoped.map((e) => e.actorName).toSet()];
    final traineeToday = scoped.where((e) {
      final now = DateTime.now();
      return e.at.year == now.year &&
          e.at.month == now.month &&
          e.at.day == now.day;
    }).length;
    final endedCount = history.length;
    final followUps = history.where((e) => e.needsFollowUp).length;
    final avgRating = history.isEmpty
        ? 0.0
        : history
                  .where((e) => e.rating != null)
                  .map((e) => e.rating!)
                  .fold<int>(0, (a, b) => a + b) /
              (history.where((e) => e.rating != null).isEmpty
                  ? 1
                  : history.where((e) => e.rating != null).length);

    final body = Padding(
      padding: EdgeInsets.fromLTRB(
        widget.embedded ? 20 : 24,
        widget.embedded ? 8 : 18,
        widget.embedded ? 20 : 24,
        widget.embedded ? 8 : 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.embedded) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Log Monitoring',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontSize: context.responsiveFont(6),
                        ),
                      ),
                      const Gap(4),
                      Text(
                        'Review practice sessions, live coaching rooms, and recent trainee activity.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const ScreenHelpButton(
                  content: ScreenHelpCatalog.logMonitoring,
                ),
                const Gap(8),
                CreateButton(text: 'Refresh', onTap: () => setState(() {})),
              ],
            ),
            const Gap(16),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final maxW = constraints.maxWidth;
              final gap = 12.0;
              final cols = maxW >= 1100
                  ? 5
                  : maxW >= 800
                  ? 4
                  : maxW >= 560
                  ? 3
                  : 2;
              final cardW = (maxW - gap * (cols - 1)) / cols;
              final cards = [
                _StatCard(
                  label: 'Ended sessions',
                  value: '$endedCount',
                  tone: const Color(0xFF0D82FE),
                ),
                _StatCard(
                  label: 'Follow-ups',
                  value: '$followUps',
                  tone: const Color(0xFFFFB74D),
                ),
                _StatCard(
                  label: 'Avg rating',
                  value: history.isEmpty ? '-' : avgRating.toStringAsFixed(1),
                  tone: const Color(0xFF8AFB09),
                ),
                _StatCard(
                  label: 'Activity today',
                  value: '$traineeToday',
                  tone: Colors.white70,
                ),
                _StatCard(
                  label: widget.showAllRoles ? 'All logs' : 'Trainee logs',
                  value: '${scoped.length}',
                  tone: Colors.white54,
                ),
              ];
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: cards
                    .map(
                      (c) => SizedBox(width: cardW.clamp(140, 280), child: c),
                    )
                    .toList(),
              );
            },
          ),
          const Gap(16),
          Row(
            children: [
              _TabChip(
                label: 'Overview',
                selected: _tab == 0,
                onTap: () => setState(() => _tab = 0),
              ),
              const Gap(8),
              _TabChip(
                label: 'Live sessions',
                selected: _tab == 1,
                onTap: () => setState(() => _tab = 1),
              ),
              const Gap(8),
              _TabChip(
                label: widget.showAllRoles ? 'Activity logs' : 'Trainee logs',
                selected: _tab == 2,
                onTap: () => setState(() => _tab = 2),
              ),
            ],
          ),
          const Gap(14),
          Expanded(
            child: _tab == 0
                ? _OverviewTab(
                    history: history,
                    logCount: scoped.length,
                    actors: actors.length - 1,
                  )
                : _tab == 1
                ? _LiveSessionsTab(entries: history)
                : _TraineeLogsTab(
                    logs: logs,
                    actors: actors,
                    actorFilter: _actorFilter,
                    categoryFilter: _logFilter,
                    roleFilter: widget.showAllRoles ? _roleFilter : null,
                    onActor: (v) => setState(() => _actorFilter = v),
                    onCategory: (v) => setState(() => _logFilter = v),
                    onRole: widget.showAllRoles
                        ? (v) => setState(() => _roleFilter = v)
                        : null,
                  ),
          ),
          if (!widget.embedded) ...[
            const Gap(10),
            TrainingBackButton(
              expand: false,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreenTrainer()),
                );
              },
            ),
          ],
        ],
      ),
    );

    if (widget.embedded) return body;
    return Scaffold(body: SafeArea(child: body));
  }

  void _seedDemoLogs() {
    final store = TraineeActivityLogStore.instance;
    store.log(
      actorName: 'Demo Trainee',
      actorRole: 'trainee',
      category: TraineeLogCategory.auth,
      action: 'Login',
      detail: 'Trainee signed in',
    );
    store.log(
      actorName: 'Demo Trainee',
      actorRole: 'trainee',
      category: TraineeLogCategory.navigation,
      action: 'Opened Trainer Session',
      detail: 'Viewed available live rooms',
    );
    store.log(
      actorName: 'Demo Trainee',
      actorRole: 'trainee',
      category: TraineeLogCategory.liveTraining,
      action: 'Joined room',
      detail: 'Entered live room for coaching',
      roomId: 'demo-room',
    );
    store.log(
      actorName: 'Demo Trainee',
      actorRole: 'trainee',
      category: TraineeLogCategory.simulation,
      action: 'Completed simulation',
      detail: 'Non-Voice simulation finished with overall score 7.8',
      sessionRef: 'sim-demo-1',
    );
    store.log(
      actorName: 'Sample Trainee',
      actorRole: 'trainee',
      category: TraineeLogCategory.scoring,
      action: 'Viewed session report',
      detail: 'Opened score report after simulation',
      sessionRef: 'sim-demo-2',
    );
    store.log(
      actorName: 'Sample Trainee',
      actorRole: 'trainee',
      category: TraineeLogCategory.simulation,
      action: 'Completed simulation',
      detail: 'Voice simulation finished with overall score 6.4',
      sessionRef: 'sim-demo-2',
    );
    setState(() {});
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(180, 21, 21, 21),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color.fromARGB(255, 49, 48, 48)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: tone,
            ),
          ),
          const Gap(4),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF0D82FE).withValues(alpha: 0.2)
              : const Color.fromARGB(180, 21, 21, 21),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? const Color(0xFF0D82FE)
                : const Color.fromARGB(255, 49, 48, 48),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.history,
    required this.logCount,
    required this.actors,
  });

  final List<LiveTrainingHistoryEntry> history;
  final int logCount;
  final int actors;

  @override
  Widget build(BuildContext context) {
    final recent = history.take(3).toList();
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color.fromARGB(180, 21, 21, 21),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color.fromARGB(255, 49, 48, 48)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How to use this screen',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Gap(8),
                Text(
                  'See finished live coaching sessions, ratings, and notes. '
                  'Open Trainee logs to check who signed in, joined a room, or finished practice. '
                  'Use this when you need proof of training or a quick activity timeline.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const Gap(14),
          Text(
            'Recent ended sessions',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontSize: 14),
          ),
          const Gap(8),
          if (recent.isEmpty)
            const Text(
              'No ended live sessions yet. End a session from Session tools to populate this list.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            )
          else
            ...recent.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _HistoryCard(entry: e, compact: true),
              ),
            ),
          const Gap(8),
          Text(
            'Activity snapshot',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontSize: 14),
          ),
          const Gap(8),
          Text(
            '$logCount log event(s) stored  ·  $actors unique actor(s)',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _LiveSessionsTab extends StatelessWidget {
  const _LiveSessionsTab({required this.entries});

  final List<LiveTrainingHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(
        child: Text(
          'No ended live sessions yet.\nOpen a room, use Session tools, then End session.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38, fontSize: 13),
        ),
      );
    }
    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, __) => const Gap(12),
      itemBuilder: (_, i) => _HistoryCard(entry: entries[i]),
    );
  }
}

class _TraineeLogsTab extends StatelessWidget {
  const _TraineeLogsTab({
    required this.logs,
    required this.actors,
    required this.actorFilter,
    required this.categoryFilter,
    required this.onActor,
    required this.onCategory,
    this.roleFilter,
    this.onRole,
  });

  final List<TraineeActivityLogEntry> logs;
  final List<String> actors;
  final String actorFilter;
  final String categoryFilter;
  final ValueChanged<String> onActor;
  final ValueChanged<String> onCategory;
  final String? roleFilter;
  final ValueChanged<String>? onRole;

  @override
  Widget build(BuildContext context) {
    final categories = ['All', ...TraineeLogCategory.values.map((c) => c.name)];
    final roles = const ['All', 'trainee', 'trainer', 'admin'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (onRole != null && roleFilter != null) ...[
              const Text(
                'Role',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const Gap(8),
              DropdownButton<String>(
                value: roles.contains(roleFilter) ? roleFilter : 'All',
                dropdownColor: const Color(0xFF1A1A1A),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                items: roles
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onRole!(v);
                },
              ),
              const Gap(16),
            ],
            const Text(
              'Actor',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const Gap(8),
            DropdownButton<String>(
              value: actors.contains(actorFilter) ? actorFilter : 'All',
              dropdownColor: const Color(0xFF1A1A1A),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              items: actors
                  .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                  .toList(),
              onChanged: (v) {
                if (v != null) onActor(v);
              },
            ),
            const Gap(16),
            const Text(
              'Category',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const Gap(8),
            DropdownButton<String>(
              value: categories.contains(categoryFilter)
                  ? categoryFilter
                  : 'All',
              dropdownColor: const Color(0xFF1A1A1A),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              items: categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {
                if (v != null) onCategory(v);
              },
            ),
          ],
        ),
        const Gap(10),
        Expanded(
          child: logs.isEmpty
              ? const Center(
                  child: Text(
                    'No activity logs yet.\nTrainee logins and completed sessions will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                )
              : ListView.separated(
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const Gap(8),
                  itemBuilder: (_, i) {
                    final e = logs[i];
                    return InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => _LogDetailDialog(entry: e),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(180, 21, 21, 21),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color.fromARGB(255, 49, 48, 48),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    e.action,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Text(
                                  formatCreatedAt(e.at),
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const Gap(4),
                            Text(
                              '${e.actorName}  ·  ${e.category.name}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                            const Gap(6),
                            Text(
                              e.detail,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const Gap(4),
                            Text(
                              [
                                if (e.roomId != null) 'Room ${e.roomId}',
                                if (e.sessionRef != null) 'Ref ${e.sessionRef}',
                                'Tap for details',
                              ].join('  ·  '),
                              style: const TextStyle(
                                color: Colors.white30,
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
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry, this.compact = false});

  final LiveTrainingHistoryEntry entry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: compact
          ? null
          : () {
              showDialog(
                context: context,
                builder: (ctx) => _SessionDetailDialog(entry: entry),
              );
            },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(compact ? 12 : 16),
        decoration: BoxDecoration(
          color: const Color.fromARGB(180, 21, 21, 21),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color.fromARGB(255, 49, 48, 48)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.roomName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: compact ? 13 : 15,
                    ),
                  ),
                ),
                if (entry.roomClosed)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Closed',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ),
                if (entry.needsFollowUp)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB74D).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Follow-up',
                      style: TextStyle(color: Color(0xFFFFB74D), fontSize: 11),
                    ),
                  ),
              ],
            ),
            const Gap(6),
            Text(
              'Code ${entry.roomId}  ·  ${entry.mode.name}',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
            const Gap(6),
            Text(
              'Trainer: ${entry.trainerName}'
              '${entry.traineeName != null ? "  ·  Trainee: ${entry.traineeName}" : ""}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const Gap(6),
            Text(
              'Ended ${formatCreatedAt(entry.endedAt)}',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
            if (!compact) ...[
              const Gap(8),
              Row(
                children: [
                  if (entry.rating != null) ...[
                    ...List.generate(
                      entry.rating!,
                      (_) => const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: Color(0xFFFFB74D),
                      ),
                    ),
                    const Gap(10),
                  ],
                  Text(
                    'Checklist ${entry.checklistDone}/${entry.checklistTotal}',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  const Gap(12),
                  Text(
                    '${entry.noteCount} note${entry.noteCount == 1 ? '' : 's'}',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  const Spacer(),
                  const Text(
                    'Tap for notes and checklist',
                    style: TextStyle(color: Colors.white30, fontSize: 11),
                  ),
                ],
              ),
              if (entry.takeaway.trim().isNotEmpty) ...[
                const Gap(8),
                Text(
                  'Takeaway: ${entry.takeaway}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
              if (entry.feedback.trim().isNotEmpty) ...[
                const Gap(6),
                Text(
                  entry.feedback,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _SessionDetailDialog extends StatelessWidget {
  const _SessionDetailDialog({required this.entry});

  final LiveTrainingHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color.fromARGB(255, 49, 48, 48)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.roomName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
                ],
              ),
              Text(
                'Code ${entry.roomId}  ·  Ended ${formatCreatedAt(entry.endedAt)}',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const Gap(14),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notes (${entry.notes.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const Gap(8),
                      if (entry.notes.isEmpty)
                        const Text(
                          'No notes saved.',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        )
                      else
                        ...entry.notes.asMap().entries.map((e) {
                          final n = e.value;
                          return _CollapsibleNoteTile(
                            title: n.title,
                            body: n.body,
                            initiallyExpanded: e.key == 0,
                          );
                        }),
                      const Gap(12),
                      const Text(
                        'Checklist',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const Gap(8),
                      if (entry.checklist.isEmpty)
                        const Text(
                          'No checklist items.',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        )
                      else
                        ...entry.checklist.map((c) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(
                                  c.done
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                  size: 18,
                                  color: c.done
                                      ? const Color(0xFF8AFB09)
                                      : Colors.white38,
                                ),
                                const Gap(8),
                                Expanded(
                                  child: Text(
                                    c.label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: c.done
                                          ? Colors.white54
                                          : Colors.white70,
                                      decoration: c.done
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      if (entry.takeaway.trim().isNotEmpty) ...[
                        const Gap(14),
                        const Text(
                          'Takeaway',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const Gap(6),
                        Text(
                          entry.takeaway,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (entry.feedback.trim().isNotEmpty) ...[
                        const Gap(14),
                        const Text(
                          'Feedback',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const Gap(6),
                        Text(
                          entry.feedback,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Gap(12),
              Row(
                children: [
                  Expanded(
                    child: CreateButton(
                      text: 'Close',
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  if (entry.roomClosed) ...[
                    const Gap(10),
                    Expanded(
                      child: CreateButton(
                        text: 'Reopen room',
                        onTap: () {
                          final ok = LiveSessionStore.instance.reopenRoom(
                            entry.roomId,
                            byTrainerName: ProfileData.displayName,
                          );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok == null
                                    ? 'You can only reopen rooms you created.'
                                    : 'Room reopened with a fresh session. Past history is kept.',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogDetailDialog extends StatelessWidget {
  const _LogDetailDialog({required this.entry});

  final TraineeActivityLogEntry entry;

  @override
  Widget build(BuildContext context) {
    PlayedSession? linkedSession;
    SessionEvaluation? linkedEval;
    try {
      final history = Provider.of<SimulationHistoryProvider>(
        context,
        listen: false,
      );
      // Match by sessionRef timestamp when possible, else by detail score + sector.
      if (entry.sessionRef != null && history.sessions.isNotEmpty) {
        final refParts = entry.sessionRef!.split('_');
        final ms = int.tryParse(refParts.isNotEmpty ? refParts.last : '');
        if (ms != null) {
          final target = DateTime.fromMillisecondsSinceEpoch(ms);
          for (final s in history.sessions) {
            final diff = s.completedAt.difference(target).inSeconds.abs();
            if (diff <= 2) {
              linkedSession = s;
              break;
            }
          }
        }
      }
      if (linkedSession == null &&
          entry.category == TraineeLogCategory.simulation &&
          history.sessions.isNotEmpty) {
        final detail = entry.detail.toLowerCase();
        for (final s in history.sessions.reversed) {
          final sector = s.sector.toLowerCase();
          final score = s.overallScore.toStringAsFixed(1);
          if (detail.contains(sector) && detail.contains(score)) {
            linkedSession = s;
            break;
          }
        }
      }
      if (linkedSession != null && linkedSession.evaluations.isNotEmpty) {
        linkedEval = linkedSession.evaluations.first;
      } else if (entry.category == TraineeLogCategory.scoring &&
          history.evaluations.isNotEmpty) {
        linkedEval = history.evaluations.last;
      }
    } catch (_) {}

    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color.fromARGB(255, 49, 48, 48)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.action,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
                ],
              ),
              Text(
                '${entry.actorName}  ·  ${formatCreatedAt(entry.at)}',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const Gap(14),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _kv('Type', entry.category.name),
                      _kv('What happened', entry.detail),
                      if (entry.roomId != null) _kv('Room code', entry.roomId!),
                      if (entry.sessionRef != null)
                        _kv('Session', entry.sessionRef!),
                      if (linkedEval != null) ...[
                        const Gap(16),
                        const Text(
                          'Related practice score',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const Gap(8),
                        _kv('Sector', linkedEval.sector),
                        _kv('Channel', linkedEval.channel),
                        _kv(
                          'Overall score',
                          linkedEval.overallScore.toStringAsFixed(1),
                        ),
                        if (linkedEval.customerName.isNotEmpty)
                          _kv('Customer', linkedEval.customerName),
                        if (linkedEval.problem.isNotEmpty)
                          _kv('Problem', linkedEval.problem),
                        if (linkedEval.strengths.isNotEmpty) ...[
                          const Gap(8),
                          const Text(
                            'Strengths',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const Gap(4),
                          ...linkedEval.strengths.map(
                            (s) => Text(
                              '· $s',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        if (linkedEval.areasForImprovement.isNotEmpty) ...[
                          const Gap(8),
                          const Text(
                            'Areas for improvement',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const Gap(4),
                          ...linkedEval.areasForImprovement.map(
                            (s) => Text(
                              '· $s',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        if (linkedEval.feedback.isNotEmpty) ...[
                          const Gap(8),
                          const Text(
                            'Feedback',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const Gap(4),
                          Text(
                            linkedEval.feedback,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                        if (linkedEval.conversation.isNotEmpty) ...[
                          const Gap(12),
                          const Text(
                            'Messages',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const Gap(6),
                          ...linkedEval.conversation.take(20).map((m) {
                            final role = m['role'] ?? 'unknown';
                            final msg = m['text'] ?? '';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                '$role: $msg',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  height: 1.3,
                                ),
                              ),
                            );
                          }),
                          if (linkedEval.conversation.length > 20)
                            Text(
                              '... ${linkedEval.conversation.length - 20} more message(s)',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ] else if (entry.category ==
                              TraineeLogCategory.simulation ||
                          entry.category == TraineeLogCategory.scoring) ...[
                        const Gap(16),
                        const Text(
                          'No matching simulation record in memory yet. '
                          'After a real simulation completes, scores and messages will show here when linked.',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Gap(12),
              CreateButton(text: 'Close', onTap: () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              k,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollapsibleNoteTile extends StatefulWidget {
  const _CollapsibleNoteTile({
    required this.title,
    required this.body,
    this.initiallyExpanded = false,
  });

  final String title;
  final String body;
  final bool initiallyExpanded;

  @override
  State<_CollapsibleNoteTile> createState() => _CollapsibleNoteTileState();
}

class _CollapsibleNoteTileState extends State<_CollapsibleNoteTile> {
  late bool _open;

  @override
  void initState() {
    super.initState();
    _open = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final body = widget.body.trim();
    final preview = body.isEmpty
        ? '(empty)'
        : (body.length > 80 ? '${body.substring(0, 80)}...' : body);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color.fromARGB(255, 49, 48, 48)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        if (!_open) ...[
                          const Gap(4),
                          Text(
                            preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: body.isEmpty
                                  ? Colors.white30
                                  : Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    _open ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white38,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: SingleChildScrollView(
                  child: Text(
                    body.isEmpty ? '(empty)' : widget.body,
                    style: TextStyle(
                      color: body.isEmpty ? Colors.white30 : Colors.white70,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
