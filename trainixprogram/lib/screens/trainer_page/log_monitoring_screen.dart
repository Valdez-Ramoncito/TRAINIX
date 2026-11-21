import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';
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
import 'package:trainixprogram/services/training_progress_repository.dart';
import 'package:trainixprogram/screens/trainer_page/trainee_statistics_screen.dart';
import 'package:trainixprogram/widgets/screen_help_button.dart';
import 'package:trainixprogram/widgets/user_facing_messages.dart';

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

    final body = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
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
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontSize: context.responsiveFont(6),
                                ),
                          ),
                      const Gap(4),
                      Text(
                        'Review practice sessions, live coaching rooms, and recent trainee activity.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted(context),
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
                CreateButton(
                  text: 'Refresh',
                  icon: Icons.refresh_rounded,
                  onTap: () => setState(() {}),
                ),
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
                  icon: Icons.event_available_outlined,
                  tone: AppColors.secondaryText(),
                ),
                _StatCard(
                  label: 'Follow-ups',
                  value: '$followUps',
                  icon: Icons.flag_outlined,
                  tone: AppColors.warningText(),
                ),
                _StatCard(
                  label: 'Avg rating',
                  value: history.isEmpty ? '-' : avgRating.toStringAsFixed(1),
                  icon: Icons.star_outline_rounded,
                  tone: AppColors.primaryText(),
                ),
                _StatCard(
                  label: 'Activity today',
                  value: '$traineeToday',
                  icon: Icons.today_outlined,
                  tone: AppColors.textSecondary(context),
                ),
                _StatCard(
                  label: widget.showAllRoles ? 'All logs' : 'Trainee logs',
                  value: '${scoped.length}',
                  icon: Icons.receipt_long_outlined,
                  tone: AppColors.textMuted(context),
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
                icon: Icons.dashboard_outlined,
                selected: _tab == 0,
                onTap: () => setState(() => _tab = 0),
              ),
              const Gap(8),
              _TabChip(
                label: 'Live sessions',
                icon: Icons.sensors_rounded,
                selected: _tab == 1,
                onTap: () => setState(() => _tab = 1),
              ),
              const Gap(8),
              _TabChip(
                label: widget.showAllRoles ? 'Activity logs' : 'Trainee logs',
                icon: Icons.history_rounded,
                selected: _tab == 2,
                onTap: () => setState(() => _tab = 2),
              ),
              const Gap(8),
              _TabChip(
                label: 'Trainee progress',
                icon: Icons.school_outlined,
                selected: _tab == 3,
                onTap: () => setState(() => _tab = 3),
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
                    : _tab == 2
                        ? _TraineeLogsTab(
                            logs: logs,
                            actors: actors,
                            actorFilter: _actorFilter,
                            categoryFilter: _logFilter,
                            roleFilter:
                                widget.showAllRoles ? _roleFilter : null,
                            onActor: (v) => setState(() => _actorFilter = v),
                            onCategory: (v) =>
                                setState(() => _logFilter = v),
                            onRole: widget.showAllRoles
                                ? (v) => setState(() => _roleFilter = v)
                                : null,
                          )
                        : const _TraineeProgressTab(),
          ),
              if (!widget.embedded) ...[
                const Gap(10),
                TrainingBackButton(
                  expand: false,
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
            ],
          ),
        ),
      ),
    );

    if (widget.embedded) return body;
    return Scaffold(body: SafeArea(child: body));
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.tone,
    this.icon,
  });

  final String label;
  final String value;
  final Color tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.panel(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderIdle(context)),
        boxShadow: AppColors.cardShadow(context, blur: 8),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: tone),
            ),
            const Gap(10),
          ],
          Expanded(
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
                const Gap(2),
                Text(
                  label,
                  style: TextStyle(
                      color: AppColors.textMuted(context), fontSize: 11),
                ),
              ],
            ),
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
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.secondaryText().withValues(alpha: 0.2)
              : AppColors.panel(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? AppColors.secondaryText()
                : AppColors.borderIdle(context),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected
                    ? AppColors.secondaryText()
                    : AppColors.textSecondary(context),
              ),
              const Gap(6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected
                    ? AppColors.textPrimary(context)
                    : AppColors.textSecondary(context),
              ),
            ),
          ],
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
              color: AppColors.panel(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderIdle(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 16,
                      color: AppColors.warningText(),
                    ),
                    const Gap(7),
                    Text(
                      'How to use this screen',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ],
                ),
                Gap(8),
                Text(
                  'See finished live coaching sessions, ratings, and notes. '
                  'Open Trainee logs for activity. Open Trainee progress for Knowledge Path and scenario stage. '
                  'Use this when you need proof of training or a quick activity timeline.',
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
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
            Text(
              'No ended live sessions yet. End a session from Session tools to populate this list.',
              style:
                  TextStyle(color: AppColors.textMuted(context), fontSize: 12),
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
            style: TextStyle(color: AppColors.textMuted(context), fontSize: 12),
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
      return Center(
        child: Text(
          'No ended live sessions yet.\nOpen a room, use Session tools, then End session.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted(context), fontSize: 13),
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

IconData _logActionIcon(String action, String category) {
  final a = action.toLowerCase();
  final c = category.toLowerCase();
  if (a.contains('enter') || a.contains('join')) return Icons.login_rounded;
  if (a.contains('left') || a.contains('leave')) return Icons.logout_rounded;
  if (a.contains('login') || a.contains('sign')) return Icons.badge_outlined;
  if (a.contains('complete') || a.contains('finish')) {
    return Icons.check_circle_outline_rounded;
  }
  if (a.contains('delete')) return Icons.delete_outline_rounded;
  if (c.contains('live')) return Icons.sensors_rounded;
  if (c.contains('sim')) return Icons.computer_rounded;
  if (c.contains('mini')) return Icons.school_outlined;
  return Icons.history_rounded;
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
              Text(
                'Role',
                style: TextStyle(
                    color: AppColors.textMuted(context), fontSize: 12),
              ),
              const Gap(8),
              DropdownButton<String>(
                value: roles.contains(roleFilter) ? roleFilter : 'All',
                dropdownColor: AppColors.elevated(context),
                style: TextStyle(
                    color: AppColors.textSecondary(context), fontSize: 12),
                items: roles
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onRole!(v);
                },
              ),
              const Gap(16),
            ],
            Text(
              'Actor',
              style:
                  TextStyle(color: AppColors.textMuted(context), fontSize: 12),
            ),
            const Gap(8),
            DropdownButton<String>(
              value: actors.contains(actorFilter) ? actorFilter : 'All',
              dropdownColor: AppColors.elevated(context),
              style: TextStyle(
                  color: AppColors.textSecondary(context), fontSize: 12),
              items: actors
                  .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                  .toList(),
              onChanged: (v) {
                if (v != null) onActor(v);
              },
            ),
            const Gap(16),
            Text(
              'Category',
              style:
                  TextStyle(color: AppColors.textMuted(context), fontSize: 12),
            ),
            const Gap(8),
            DropdownButton<String>(
              value:
                  categories.contains(categoryFilter) ? categoryFilter : 'All',
              dropdownColor: AppColors.elevated(context),
              style: TextStyle(
                  color: AppColors.textSecondary(context), fontSize: 12),
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
              ? Center(
                  child: Text(
                    'No activity logs yet.\nTrainee logins and completed sessions will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.textMuted(context), fontSize: 13),
                  ),
                )
              : ListView.separated(
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const Gap(8),
                  itemBuilder: (_, i) {
                    final e = logs[i];
                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => _LogDetailDialog(entry: e),
                        );
                      },
                      mouseCursor: SystemMouseCursors.click,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.panel(context),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.borderIdle(context),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryWash(context),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _logActionIcon(e.action, e.category.name),
                                    size: 16,
                                    color: AppColors.secondaryText(),
                                  ),
                                ),
                                const Gap(10),
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
                                  style: TextStyle(
                                    color: AppColors.textMuted(context),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const Gap(6),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline_rounded,
                                  size: 13,
                                  color: AppColors.textMuted(context),
                                ),
                                const Gap(4),
                                Expanded(
                                  child: Text(
                                    '${e.actorName}  ·  ${e.category.name}',
                                    style: TextStyle(
                                      color: AppColors.textMuted(context),
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const Gap(6),
                            Text(
                              e.detail,
                              style: TextStyle(
                                color: AppColors.textSecondary(context),
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
                              style: TextStyle(
                                color: AppColors.textMuted(context),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
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

class _TraineeProgressTab extends StatefulWidget {
  const _TraineeProgressTab();

  @override
  State<_TraineeProgressTab> createState() => _TraineeProgressTabState();
}

class _TraineeProgressTabState extends State<_TraineeProgressTab> {
  bool _loading = true;
  String? _error;
  List<TraineeProgressSnapshot> _rows = const [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload({bool force = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final list =
        await TrainingProgressRepository.instance.loadTraineeSnapshots(
      force: force,
    );
    if (!mounted) return;
    setState(() {
      _rows = list;
      _loading = false;
      _error = TrainingProgressRepository.lastError;
    });
  }

  List<TraineeProgressSnapshot> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _rows;
    return _rows
        .where(
          (r) =>
              r.displayName.toLowerCase().contains(q) ||
              r.email.toLowerCase().contains(q) ||
              r.stageLabel.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filtered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Mini Training progress by trainee',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            TextButton.icon(
              onPressed: _loading ? null : () => _reload(force: true),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary(context),
              ),
            ),
          ],
        ),
        const Gap(4),
        Text(
          'Knowledge Path categories, Grand Final, and Scenario Practice stage from saved training_progress.',
          style: TextStyle(
            color: AppColors.textMuted(context),
            fontSize: 12,
          ),
        ),
        const Gap(10),
        SizedBox(
          width: 320,
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Filter by name or email',
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.textMuted(context),
              ),
              isDense: true,
              filled: true,
              fillColor: AppColors.inputFill(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.borderIdle(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.borderIdle(context)),
              ),
            ),
          ),
        ),
        if (_error != null) ...[
          const Gap(8),
          Text(
            'Could not load every progress row. Check that trainers can read training_progress (RLS). $_error',
            style: TextStyle(
              color: AppColors.warningText(),
              fontSize: 12,
            ),
          ),
        ],
        const Gap(12),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : rows.isEmpty
                  ? Center(
                      child: Text(
                        _rows.isEmpty
                            ? 'No trainee profiles found yet.'
                            : 'No trainees match this filter.',
                        style: TextStyle(
                          color: AppColors.textMuted(context),
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const Gap(10),
                      itemBuilder: (context, index) {
                        final r = rows[index];
                        return _ProgressCard(snapshot: r);
                      },
                    ),
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.snapshot});

  final TraineeProgressSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final r = snapshot;
    final fraction = r.knowledgeFraction.clamp(0.0, 1.0);
    return Material(
      color: AppColors.card(context),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        mouseCursor: SystemMouseCursors.click,
        onTap: () => _showDetail(context, r),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderIdle(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 18,
                    color: AppColors.secondaryText(),
                  ),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      r.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryWash(context),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      r.stageLabel,
                      style: TextStyle(
                        color: AppColors.secondaryText(),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (r.email.isNotEmpty) ...[
                const Gap(4),
                Text(
                  r.email,
                  style: TextStyle(
                    color: AppColors.textMuted(context),
                    fontSize: 11,
                  ),
                ),
              ],
              const Gap(10),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 8,
                        backgroundColor: AppColors.chipBg(context),
                        color: AppColors.primaryText(),
                      ),
                    ),
                  ),
                  const Gap(10),
                  Text(
                    '${r.completedCategories}/${r.totalCategories} categories',
                    style: TextStyle(
                      color: AppColors.textSecondary(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Gap(8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _miniChip(
                    context,
                    Icons.badge_outlined,
                    r.profileComplete ? 'Profile complete' : 'Profile open',
                    r.profileComplete,
                  ),
                  _miniChip(
                    context,
                    Icons.emoji_events_outlined,
                    r.grandFinalPassed
                        ? 'Grand Final passed'
                        : (r.grandFinalUnlocked
                            ? 'Grand Final unlocked'
                            : 'Grand Final locked'),
                    r.grandFinalPassed,
                  ),
                  _miniChip(
                    context,
                    Icons.chat_bubble_outline_rounded,
                    'Non-Voice ${r.completedChatScenarios}',
                    r.completedChatScenarios > 0,
                  ),
                  _miniChip(
                    context,
                    Icons.mic_none_rounded,
                    'Voice ${r.completedVoiceScenarios}',
                    r.completedVoiceScenarios > 0,
                  ),
                ],
              ),
              if (r.updatedAt != null) ...[
                const Gap(6),
                Text(
                  'Updated ${_formatWhen(r.updatedAt!)}',
                  style: TextStyle(
                    color: AppColors.textMuted(context),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniChip(
    BuildContext context,
    IconData icon,
    String label,
    bool active,
  ) {
    final color =
        active ? AppColors.primaryText() : AppColors.textMuted(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? AppColors.primaryWash(context)
            : AppColors.chipBg(context),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const Gap(4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, TraineeProgressSnapshot r) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.elevated(context),
          title: Text(r.displayName),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    r.stageLabel,
                    style: TextStyle(
                      color: AppColors.secondaryText(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(12),
                  Row(
                    children: [
                      Icon(
                        Icons.menu_book_outlined,
                        size: 14,
                        color: AppColors.textMuted(context),
                      ),
                      const Gap(6),
                      Text(
                        'Knowledge Path',
                        style: TextStyle(
                          color: AppColors.textMuted(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Gap(8),
                  ...r.categoryDone.entries.map((e) {
                    final done = e.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(
                            done
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked,
                            size: 16,
                            color: done
                                ? AppColors.primaryText()
                                : AppColors.textMuted(context),
                          ),
                          const Gap(8),
                          Expanded(
                            child: Text(
                              e.key,
                              style: TextStyle(
                                color: done
                                    ? AppColors.textPrimary(context)
                                    : AppColors.textMuted(context),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Gap(14),
                  Row(
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 14,
                        color: AppColors.textMuted(context),
                      ),
                      const Gap(6),
                      Text(
                        'Recent activity for this trainee',
                        style: TextStyle(
                          color: AppColors.textMuted(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Gap(8),
                  ...() {
                    final logs = TraineeActivityLogStore.instance.entries
                        .where(
                          (e) =>
                              e.actorName.toLowerCase() ==
                              r.displayName.toLowerCase(),
                        )
                        .take(8)
                        .toList();
                    if (logs.isEmpty) {
                      return [
                        Text(
                          'No activity log rows for this name yet. Simulation session history requires trainer RLS access to training_progress and session tables.',
                          style: TextStyle(
                            color: AppColors.textMuted(context),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ];
                    }
                    return logs
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  _logActionIcon(e.action, e.category.name),
                                  size: 15,
                                  color: AppColors.secondaryText(),
                                ),
                                const Gap(8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        e.action,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        e.detail,
                                        style: TextStyle(
                                          color: AppColors.textMuted(context),
                                          fontSize: 11,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList();
                  }(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TraineeStatisticsScreen(snapshot: r),
                  ),
                );
              },
              icon: const Icon(Icons.insights_rounded, size: 16),
              label: const Text('Show statistics'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _formatWhen(DateTime at) {
    final m = at.month.toString().padLeft(2, '0');
    final d = at.day.toString().padLeft(2, '0');
    final h = at.hour > 12 ? at.hour - 12 : (at.hour == 0 ? 12 : at.hour);
    final mm = at.minute.toString().padLeft(2, '0');
    final am = at.hour >= 12 ? 'PM' : 'AM';
    return '$h:$mm $am $m/$d/${at.year}';
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry, this.compact = false});

  final LiveTrainingHistoryEntry entry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: compact ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: InkWell(
      onTap: compact
          ? null
          : () {
              showDialog(
                context: context,
                builder: (ctx) => _SessionDetailDialog(entry: entry),
              );
            },
      mouseCursor:
          compact ? SystemMouseCursors.basic : SystemMouseCursors.click,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(compact ? 12 : 16),
        decoration: BoxDecoration(
          color: AppColors.panel(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderIdle(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryText().withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.video_camera_front_outlined,
                    size: 13,
                    color: AppColors.secondaryText(),
                  ),
                ),
                const Gap(8),
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
                      color: AppColors.chipBg(context),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Closed',
                      style: TextStyle(
                          color: AppColors.textMuted(context), fontSize: 11),
                    ),
                  ),
                if (entry.needsFollowUp)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warningText().withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Follow-up',
                      style: TextStyle(
                          color: AppColors.warningText(), fontSize: 11),
                    ),
                  ),
              ],
            ),
            const Gap(6),
            Text(
              'Code ${entry.roomId}  ·  ${entry.mode.name}',
              style:
                  TextStyle(color: AppColors.textMuted(context), fontSize: 11),
            ),
            const Gap(6),
            Text(
              'Trainer: ${entry.trainerName}'
              '${entry.traineeName != null ? "  ·  Trainee: ${entry.traineeName}" : ""}',
              style: TextStyle(
                  color: AppColors.textSecondary(context), fontSize: 12),
            ),
            const Gap(6),
            Text(
              'Ended ${formatCreatedAt(entry.endedAt)}',
              style:
                  TextStyle(color: AppColors.textMuted(context), fontSize: 11),
            ),
            if (!compact) ...[
              const Gap(8),
              Row(
                children: [
                  if (entry.rating != null) ...[
                    ...List.generate(
                      entry.rating!,
                      (_) => Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: AppColors.warningText(),
                      ),
                    ),
                    const Gap(10),
                  ],
                  Text(
                    'Checklist ${entry.checklistDone}/${entry.checklistTotal}',
                    style: TextStyle(
                        color: AppColors.textMuted(context), fontSize: 11),
                  ),
                  const Gap(12),
                  Text(
                    '${entry.noteCount} note${entry.noteCount == 1 ? '' : 's'}',
                    style: TextStyle(
                        color: AppColors.textMuted(context), fontSize: 11),
                  ),
                  const Spacer(),
                  Text(
                    'Tap for notes and checklist',
                    style: TextStyle(
                        color: AppColors.textMuted(context), fontSize: 11),
                  ),
                ],
              ),
              if (entry.takeaway.trim().isNotEmpty) ...[
                const Gap(8),
                Text(
                  'Takeaway: ${entry.takeaway}',
                  style: TextStyle(
                      color: AppColors.textSecondary(context), fontSize: 12),
                ),
              ],
              if (entry.feedback.trim().isNotEmpty) ...[
                const Gap(6),
                Text(
                  entry.feedback,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: AppColors.textMuted(context), fontSize: 12),
                ),
              ],
            ],
          ],
        ),
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
      backgroundColor: AppColors.elevated(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.borderIdle(context)),
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
                    icon:
                        Icon(Icons.close, color: AppColors.textMuted(context)),
                  ),
                ],
              ),
              const Gap(6),
              Row(
                children: [
                  Icon(
                    Icons.videocam_outlined,
                    size: 14,
                    color: AppColors.secondaryText(),
                  ),
                  const Gap(4),
                  Icon(
                    Icons.tag_rounded,
                    size: 14,
                    color: AppColors.textMuted(context),
                  ),
                  const Gap(4),
                  Expanded(
                    child: Text(
                      'Code ${entry.roomId}  ·  Ended ${formatCreatedAt(entry.endedAt)}',
                      style: TextStyle(
                        color: AppColors.textMuted(context),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(14),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.sticky_note_2_outlined,
                            size: 16,
                            color: AppColors.secondaryText(),
                          ),
                          const Gap(6),
                          Text(
                            'Notes (${entry.notes.length})',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const Gap(8),
                      if (entry.notes.isEmpty)
                        Text(
                          'No notes saved.',
                          style: TextStyle(
                              color: AppColors.textMuted(context),
                              fontSize: 12),
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
                      Row(
                        children: [
                          Icon(
                            Icons.checklist_rounded,
                            size: 16,
                            color: AppColors.secondaryText(),
                          ),
                          const Gap(6),
                          const Text(
                            'Checklist',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const Gap(8),
                      if (entry.checklist.isEmpty)
                        Text(
                          'No checklist items.',
                          style: TextStyle(
                              color: AppColors.textMuted(context),
                              fontSize: 12),
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
                                      ? AppColors.primaryText()
                                      : AppColors.textMuted(context),
                                ),
                                const Gap(8),
                                Expanded(
                                  child: Text(
                                    c.label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: c.done
                                          ? AppColors.textMuted(context)
                                          : AppColors.textSecondary(context),
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
                          style: TextStyle(
                            color: AppColors.textSecondary(context),
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
                          style: TextStyle(
                            color: AppColors.textSecondary(context),
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
      backgroundColor: AppColors.elevated(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.borderIdle(context)),
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
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryWash(context),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _logActionIcon(entry.action, entry.category.name),
                      size: 18,
                      color: AppColors.secondaryText(),
                    ),
                  ),
                  const Gap(10),
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
                    icon:
                        Icon(Icons.close, color: AppColors.textMuted(context)),
                  ),
                ],
              ),
              const Gap(4),
              Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 14,
                    color: AppColors.textMuted(context),
                  ),
                  const Gap(4),
                  Expanded(
                    child: Text(
                      '${entry.actorName}  ·  ${formatCreatedAt(entry.at)}',
                      style: TextStyle(
                        color: AppColors.textMuted(context),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(14),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _kv(context, 'Type', entry.category.name),
                      _kv(context, 'What happened', entry.detail),
                      if (entry.roomId != null)
                        _kv(context, 'Room code', entry.roomId!),
                      if (entry.sessionRef != null)
                        _kv(context, 'Session', entry.sessionRef!),
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
                        _kv(context, 'Sector', linkedEval.sector),
                        _kv(context, 'Channel', linkedEval.channel),
                        _kv(
                          context,
                          'Overall score',
                          linkedEval.overallScore.toStringAsFixed(1),
                        ),
                        if (linkedEval.customerName.isNotEmpty)
                          _kv(
                            context,
                            'Customer',
                            friendlyCustomerName(linkedEval.customerName),
                          ),
                        if (friendlyProblemText(linkedEval.problem).isNotEmpty)
                          _kv(
                            context,
                            'Problem',
                            friendlyProblemText(linkedEval.problem),
                          ),
                        if (linkedEval.strengths
                            .map(friendlyEvalText)
                            .any((s) => s.isNotEmpty)) ...[
                          const Gap(8),
                          const Text(
                            'Strengths',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const Gap(4),
                          ...linkedEval.strengths.map((s) {
                            final text = friendlyEvalText(s);
                            if (text.isEmpty) return const SizedBox.shrink();
                            return Text(
                              '· $text',
                              style: TextStyle(
                                color: AppColors.textSecondary(context),
                                fontSize: 12,
                              ),
                            );
                          }),
                        ],
                        if (linkedEval.areasForImprovement
                            .map(friendlyEvalText)
                            .any((s) => s.isNotEmpty)) ...[
                          const Gap(8),
                          const Text(
                            'Areas for improvement',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const Gap(4),
                          ...linkedEval.areasForImprovement.map((s) {
                            final text = friendlyEvalText(s);
                            if (text.isEmpty) return const SizedBox.shrink();
                            return Text(
                              '· $text',
                              style: TextStyle(
                                color: AppColors.textSecondary(context),
                                fontSize: 12,
                              ),
                            );
                          }),
                        ],
                        if (friendlyEvalText(
                          linkedEval.feedback,
                        ).isNotEmpty) ...[
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
                            friendlyEvalText(linkedEval.feedback),
                            style: TextStyle(
                              color: AppColors.textSecondary(context),
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
                                style: TextStyle(
                                  color: AppColors.textSecondary(context),
                                  fontSize: 12,
                                  height: 1.3,
                                ),
                              ),
                            );
                          }),
                          if (linkedEval.conversation.length > 20)
                            Text(
                              '... ${linkedEval.conversation.length - 20} more message(s)',
                              style: TextStyle(
                                color: AppColors.textMuted(context),
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ] else if (entry.category ==
                              TraineeLogCategory.simulation ||
                          entry.category == TraineeLogCategory.scoring) ...[
                        const Gap(16),
                        Text(
                          'No matching simulation record in memory yet. '
                          'After a real simulation completes, scores and messages will show here when linked.',
                          style: TextStyle(
                            color: AppColors.textMuted(context),
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

  Widget _kv(BuildContext context, String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              k,
              style:
                  TextStyle(color: AppColors.textMuted(context), fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: TextStyle(
                  color: AppColors.textSecondary(context), fontSize: 12),
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
        color: AppColors.inputFill(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderIdle(context)),
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
                                  ? AppColors.textMuted(context)
                                  : AppColors.textMuted(context),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    _open ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textMuted(context),
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
                      color: body.isEmpty
                          ? AppColors.textMuted(context)
                          : AppColors.textSecondary(context),
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
