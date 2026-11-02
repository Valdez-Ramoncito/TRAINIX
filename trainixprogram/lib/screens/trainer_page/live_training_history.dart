import 'package:flutter/material.dart';
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
                  CreateButton(text: 'Refresh', onTap: () => setState(() {})),
                ],
              ),
              const Gap(6),
              const Text(
                'Ended one-on-one sessions with notes, checklist progress, and feedback.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const Gap(18),
              Expanded(
                child: entries.isEmpty
                    ? const Center(
                        child: Text(
                          'No ended live sessions yet.\nOpen a room, use Session tools, then End session.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white38, fontSize: 13),
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
          const Gap(8),
          Text(
            'Trainer: ${entry.trainerName}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          if (entry.traineeName != null) ...[
            const Gap(4),
            Text(
              'Trainee: ${entry.traineeName}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
          const Gap(8),
          Text(
            'Ended ${formatCreatedAt(entry.endedAt)}',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
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
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
