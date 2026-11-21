import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/components/button/back_button.dart';
import 'package:trainixprogram/components/button/create_button.dart';
import 'package:trainixprogram/components/class/live_training_session.dart';
import 'package:trainixprogram/components/size.dart';

class LiveTrainingHistoryScreen extends StatefulWidget {
  const LiveTrainingHistoryScreen({super.key});

  @override
  State<LiveTrainingHistoryScreen> createState() =>
      _LiveTrainingHistoryScreenState();
}

class _LiveTrainingHistoryScreenState extends State<LiveTrainingHistoryScreen> {
  List<LiveTrainingHistoryEntry> get _entries =>
      LiveSessionStore.instance.historyEntries();

  @override
  Widget build(BuildContext context) {
    final entries = _entries;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Live training history',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontSize: context.responsiveFont(6),
                          ),
                    ),
                  ),
                  CreateButton(
                    text: 'Refresh',
                    icon: Icons.refresh_rounded,
                    onTap: () => setState(() {}),
                  ),
                ],
              ),
              const Gap(6),
              Text(
                'Ended one-on-one sessions with notes, checklist progress, and feedback.',
                style: TextStyle(
                    color: AppColors.textMuted(context), fontSize: 12),
              ),
              const Gap(18),
              Expanded(
                child: entries.isEmpty
                    ? Center(
                        child: Text(
                          'No ended live sessions yet.\nOpen a room, use Session tools, then End session.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.textMuted(context),
                              fontSize: 13),
                        ),
                      )
                    : ListView.separated(
                        itemCount: entries.length,
                        separatorBuilder: (_, __) => const Gap(12),
                        itemBuilder: (_, i) => _HistoryCard(entry: entries[i]),
                      ),
              ),
              const Gap(12),
              Align(
                alignment: Alignment.centerLeft,
                child: TrainingBackButton(
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry});

  final LiveTrainingHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Expanded(
                child: Text(
                  entry.roomName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
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
                    style:
                        TextStyle(color: AppColors.warningText(), fontSize: 11),
                  ),
                ),
            ],
          ),
          const Gap(6),
          Text(
            'Code ${entry.roomId}  ·  ${entry.mode.name}',
            style: TextStyle(color: AppColors.textMuted(context), fontSize: 11),
          ),
          const Gap(8),
          Text(
            'Trainer: ${entry.trainerName}',
            style: TextStyle(
                color: AppColors.textSecondary(context), fontSize: 12),
          ),
          if (entry.traineeName != null) ...[
            const Gap(4),
            Text(
              'Trainee: ${entry.traineeName}',
              style:
                  TextStyle(color: AppColors.textMuted(context), fontSize: 12),
            ),
          ],
          const Gap(8),
          Text(
            'Ended ${formatCreatedAt(entry.endedAt)}',
            style: TextStyle(color: AppColors.textMuted(context), fontSize: 11),
          ),
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
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style:
                  TextStyle(color: AppColors.textMuted(context), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
