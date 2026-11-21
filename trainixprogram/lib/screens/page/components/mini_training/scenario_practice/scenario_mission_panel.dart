import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/models/training/scenarios/scenario_models.dart';

class ScenarioMissionPanel extends StatefulWidget {
  final List<ScenarioMissionStep> steps;
  final Set<String> completedStepIds;
  final String? currentStepId;

  const ScenarioMissionPanel({
    super.key,
    required this.steps,
    required this.completedStepIds,
    required this.currentStepId,
  });

  @override
  State<ScenarioMissionPanel> createState() => _ScenarioMissionPanelState();
}

class _ScenarioMissionPanelState extends State<ScenarioMissionPanel> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) return const SizedBox.shrink();

    final doneCount = widget.steps
        .where((s) => widget.completedStepIds.contains(s.id))
        .length;

    if (!_expanded) {
      return Material(
        color: AppColors.elevated(context),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _expanded = true),
          child: Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Column(
              children: [
                Icon(Icons.flag_rounded,
                    color: AppColors.successText(), size: 20),
                const Gap(8),
                RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    'MISSION  $doneCount/${widget.steps.length}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.successText(),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const Gap(8),
                Icon(Icons.chevron_right,
                    color: AppColors.textMuted(context), size: 18),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      width: 240,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.elevated(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_rounded,
                  size: 16, color: AppColors.successText()),
              const Gap(8),
              Expanded(
                child: Text(
                  'MISSION',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.1,
                    color: AppColors.successText(),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$doneCount/${widget.steps.length}',
                style: TextStyle(
                    fontSize: 11, color: AppColors.textMuted(context)),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () => setState(() => _expanded = false),
                icon: Icon(Icons.chevron_left,
                    color: AppColors.textMuted(context), size: 20),
              ),
            ],
          ),
          const Gap(8),
          Expanded(
            child: ListView(
              children: widget.steps.map((step) {
                final done = widget.completedStepIds.contains(step.id);
                final current = widget.currentStepId == step.id && !done;
                Color color;
                IconData icon;
                if (done) {
                  color = AppColors.successText();
                  icon = Icons.check_circle_rounded;
                } else if (current) {
                  color = AppColors.secondaryText();
                  icon = Icons.radio_button_checked;
                } else {
                  color = AppColors.textMuted(context);
                  icon = Icons.radio_button_unchecked;
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, size: 16, color: color),
                      const Gap(8),
                      Expanded(
                        child: Text(
                          step.label,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.3,
                            color: done
                                ? AppColors.textMuted(context)
                                : current
                                    ? AppColors.textPrimary(context)
                                    : AppColors.textMuted(context),
                            fontWeight:
                                current ? FontWeight.w600 : FontWeight.w400,
                            decoration:
                                done ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
