import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/components/app_colors.dart';
import 'package:trainixprogram/components/class/live_training_session.dart';
import 'package:trainixprogram/components/class/trainee_activity_log.dart';
import 'package:trainixprogram/models/simulation_history.dart';
import 'package:trainixprogram/models/simulation_phase.dart';
import 'package:trainixprogram/services/simulation_session_repository.dart';
import 'package:trainixprogram/services/training_progress_repository.dart';

class TraineeStatisticsScreen extends StatefulWidget {
  final TraineeProgressSnapshot snapshot;

  const TraineeStatisticsScreen({super.key, required this.snapshot});

  @override
  State<TraineeStatisticsScreen> createState() =>
      _TraineeStatisticsScreenState();
}

class _TraineeStatisticsScreenState extends State<TraineeStatisticsScreen> {
  List<PlayedSession> _simSessions = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sessions = await SimulationSessionRepository.instance
          .fetchForUserId(widget.snapshot.userId);
      if (!mounted) return;
      setState(() {
        _simSessions = sessions;
        _loading = false;
        if (SimulationSessionRepository.lastError != null &&
            sessions.isEmpty) {
          _error = SimulationSessionRepository.lastError;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  List<LiveTrainingHistoryEntry> get _liveSessions {
    return LiveSessionStore.instance.historyForTrainee(
      widget.snapshot.displayName,
    );
  }

  List<TraineeActivityLogEntry> get _activity {
    final name = widget.snapshot.displayName.toLowerCase();
    return TraineeActivityLogStore.instance.entries
        .where((e) => e.actorName.toLowerCase() == name)
        .take(12)
        .toList();
  }

  Map<String, double> get _sectorAverages {
    final map = <String, List<double>>{};
    for (final s in _simSessions) {
      for (final e in s.evaluations) {
        final sector = e.sector.trim();
        if (sector.isEmpty) continue;
        map.putIfAbsent(sector, () => []).add(e.overallScore);
      }
    }
    return {
      for (final entry in map.entries)
        entry.key: entry.value.reduce((a, b) => a + b) / entry.value.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.snapshot;
    final sectors = _sectorAverages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final live = _liveSessions;
    final activity = _activity;

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const Gap(4),
                      Icon(
                        Icons.insights_rounded,
                        color: AppColors.secondaryText(),
                      ),
                      const Gap(8),
                      Expanded(
                        child: Text(
                          'Statistics · ${r.displayName}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Refresh',
                        onPressed: _load,
                        icon: Icon(
                          Icons.refresh_rounded,
                          color: AppColors.textMuted(context),
                        ),
                      ),
                    ],
                  ),
                  if (r.email.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 48, bottom: 8),
                      child: Text(
                        r.email,
                        style: TextStyle(
                          color: AppColors.textMuted(context),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView(
                            children: [
                              _sectionTitle(
                                context,
                                Icons.dashboard_outlined,
                                'Overview',
                              ),
                              const Gap(10),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _metric(
                                    context,
                                    'Knowledge',
                                    '${r.completedCategories}/${r.totalCategories}',
                                    Icons.menu_book_outlined,
                                  ),
                                  _metric(
                                    context,
                                    'Non-Voice scenarios',
                                    '${r.completedChatScenarios}',
                                    Icons.chat_bubble_outline_rounded,
                                  ),
                                  _metric(
                                    context,
                                    'Voice scenarios',
                                    '${r.completedVoiceScenarios}',
                                    Icons.mic_none_rounded,
                                  ),
                                  _metric(
                                    context,
                                    'Sim sessions',
                                    '${_simSessions.length}',
                                    Icons.computer_rounded,
                                  ),
                                  _metric(
                                    context,
                                    'Live sessions',
                                    '${live.length}',
                                    Icons.sensors_rounded,
                                  ),
                                  _metric(
                                    context,
                                    'Grand Final',
                                    r.grandFinalPassed ? 'Passed' : 'Open',
                                    Icons.emoji_events_outlined,
                                  ),
                                ],
                              ),
                              const Gap(20),
                              _sectionTitle(
                                context,
                                Icons.hub_outlined,
                                'Sector match (simulation)',
                              ),
                              const Gap(10),
                              if (sectors.isEmpty)
                                Text(
                                  _error != null
                                      ? 'Could not load simulation sessions. Run docs/sql/fix_training_progress_staff_read.sql so trainers can read trainee data.'
                                      : 'No scored simulation sessions for this trainee yet.',
                                  style: TextStyle(
                                    color: AppColors.textMuted(context),
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                )
                              else
                                ...sectors.map((e) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.card(context),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.borderIdle(context),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _sectorIcon(e.key),
                                          size: 18,
                                          color: AppColors.secondaryText(),
                                        ),
                                        const Gap(10),
                                        Expanded(
                                          child: Text(
                                            e.key,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          e.value.toStringAsFixed(1),
                                          style: TextStyle(
                                            color: AppColors.primaryText(),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              const Gap(20),
                              _sectionTitle(
                                context,
                                Icons.computer_rounded,
                                'Simulation session history',
                              ),
                              const Gap(10),
                              if (_simSessions.isEmpty)
                                Text(
                                  'No simulation runs found for this account.',
                                  style: TextStyle(
                                    color: AppColors.textMuted(context),
                                    fontSize: 13,
                                  ),
                                )
                              else
                                ..._simSessions.take(15).map((s) {
                                  final sector = s.evaluations.isEmpty
                                      ? 'Session'
                                      : s.evaluations.first.sector;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.card(context),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.borderIdle(context),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          s.mode == SimulationMode.voice
                                              ? Icons.mic_rounded
                                              : Icons.chat_bubble_outline_rounded,
                                          size: 18,
                                          color: AppColors.secondaryText(),
                                        ),
                                        const Gap(10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                sector.isEmpty
                                                    ? 'Simulation'
                                                    : sector,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              Text(
                                                '${s.mode == SimulationMode.voice ? 'Voice' : 'Non-Voice'} · ${s.evaluations.length} customer(s)',
                                                style: TextStyle(
                                                  color: AppColors.textMuted(
                                                    context,
                                                  ),
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          s.overallScore.toStringAsFixed(1),
                                          style: TextStyle(
                                            color: AppColors.primaryText(),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              const Gap(20),
                              _sectionTitle(
                                context,
                                Icons.sensors_rounded,
                                'Live coaching history',
                              ),
                              const Gap(10),
                              if (live.isEmpty)
                                Text(
                                  'No live rooms linked to this trainee name yet.',
                                  style: TextStyle(
                                    color: AppColors.textMuted(context),
                                    fontSize: 13,
                                  ),
                                )
                              else
                                ...live.take(10).map((e) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.card(context),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.borderIdle(context),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.video_camera_front_outlined,
                                          size: 18,
                                          color: AppColors.secondaryText(),
                                        ),
                                        const Gap(10),
                                        Expanded(
                                          child: Text(
                                            e.roomName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          'Checklist ${e.checklistDone}/${e.checklistTotal}',
                                          style: TextStyle(
                                            color: AppColors.textMuted(context),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              const Gap(20),
                              _sectionTitle(
                                context,
                                Icons.history_rounded,
                                'Recent activity',
                              ),
                              const Gap(10),
                              if (activity.isEmpty)
                                Text(
                                  'No activity log rows for this name.',
                                  style: TextStyle(
                                    color: AppColors.textMuted(context),
                                    fontSize: 13,
                                  ),
                                )
                              else
                                ...activity.map((e) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.circle,
                                          size: 8,
                                          color: AppColors.secondaryText(),
                                        ),
                                        const Gap(10),
                                        Expanded(
                                          child: Text(
                                            '${e.action} · ${e.detail}',
                                            style: TextStyle(
                                              color: AppColors.textSecondary(
                                                context,
                                              ),
                                              fontSize: 12,
                                              height: 1.35,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              const Gap(24),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.secondaryText()),
        const Gap(8),
        Text(
          title,
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _metric(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderIdle(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.secondaryText()),
          const Gap(8),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const Gap(2),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textMuted(context),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  IconData _sectorIcon(String sector) {
    final s = sector.toLowerCase();
    if (s.contains('telco') || s.contains('telecom')) {
      return Icons.cell_tower_rounded;
    }
    if (s.contains('finance') || s.contains('bank')) {
      return Icons.account_balance_rounded;
    }
    if (s.contains('health')) return Icons.local_hospital_outlined;
    if (s.contains('tech') || s.contains('support')) {
      return Icons.support_agent_rounded;
    }
    return Icons.business_center_outlined;
  }
}
