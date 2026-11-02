import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/models/training/trainee_next_step.dart';
import 'package:trainixprogram/models/training/training_categories.dart';

class NextStepBanner extends StatelessWidget {
  final TraineeNextStepScreen screen;
  final bool showSkipGuide;
  final EdgeInsetsGeometry margin;

  const NextStepBanner({
    super.key,
    this.screen = TraineeNextStepScreen.home,
    this.showSkipGuide = true,
    this.margin = EdgeInsets.zero,
  });

  bool _isOnTargetScreen(TraineeNextStep next) {
    switch (screen) {
      case TraineeNextStepScreen.profile:
        return next.target == TraineeNextStepTarget.profile;
      case TraineeNextStepScreen.miniTraining:
        return next.target == TraineeNextStepTarget.miniTraining ||
            next.target == TraineeNextStepTarget.scenarioPractice;
      case TraineeNextStepScreen.trainingSession:
        return next.target == TraineeNextStepTarget.trainingSession ||
            next.target == TraineeNextStepTarget.simulationHub;
      case TraineeNextStepScreen.progressDashboard:
        return next.target == TraineeNextStepTarget.progressDashboard;
      case TraineeNextStepScreen.home:
      case TraineeNextStepScreen.other:
        return false;
    }
  }

  String _onScreenHint(TraineeNextStep next) {
    switch (screen) {
      case TraineeNextStepScreen.profile:
        return 'You are here. Fill required fields, then save.';
      case TraineeNextStepScreen.miniTraining:
        return next.target == TraineeNextStepTarget.scenarioPractice
            ? 'You are here. Open the Scenario Practice tab and clear the current stage.'
            : 'You are here. Work the Knowledge Path in order, then the Grand Final.';
      case TraineeNextStepScreen.trainingSession:
        return 'You are here. Pick an unlocked mode, then start a session.';
      case TraineeNextStepScreen.progressDashboard:
        return 'You are here. Review Overview, Session History, and Sector Fit.';
      default:
        return 'You are already on this step.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: MiniTrainingProgress.guidanceRevision,
      builder: (context, _, __) {
        if (!MiniTrainingProgress.isGuideActive) {
          return const SizedBox.shrink();
        }

        final next = TraineeNextStep.resolve();
        final contextLine = next.contextHintFor(screen);
        final onTarget = _isOnTargetScreen(next);

        return Container(
          width: double.infinity,
          margin: margin,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F26),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF70BD8A).withValues(alpha: 0.55),
              width: 1.2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF70BD8A),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Guide: ${next.title}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      next.reason,
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 13,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      onTarget ? _onScreenHint(next) : (contextLine ?? ''),
                      style: const TextStyle(
                        color: Color(0xFF70BD8A),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!onTarget &&
                        next.carouselHint != null &&
                        screen == TraineeNextStepScreen.home) ...[
                      const Gap(4),
                      Text(
                        next.carouselHint!,
                        style: const TextStyle(
                          color: Color(0xFF70BD8A),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Gap(10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (next.target == TraineeNextStepTarget.none)
                    TextButton(
                      onPressed: () {
                        MiniTrainingProgress.setPreferMinimalGuidance(true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Guide dismissed. Progress locks still apply. Turn the guide on again from Help.',
                            ),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF70BD8A),
                        foregroundColor: const Color(0xFF0F1419),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        next.actionLabel,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    )
                  else if (!onTarget)
                    TextButton(
                      onPressed: () {
                        if (!MiniTrainingProgress.seenHomePath) {
                          MiniTrainingProgress.markSeen('home_path');
                        }
                        next.open(context);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF70BD8A),
                        foregroundColor: const Color(0xFF0F1419),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        next.actionLabel,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  if (showSkipGuide &&
                      next.target != TraineeNextStepTarget.none) ...[
                    if (!onTarget) const Gap(4),
                    TextButton(
                      onPressed: () {
                        MiniTrainingProgress.setPreferMinimalGuidance(true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Guide hidden. Progress locks still apply. Turn the guide on again from Help.',
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Skip guide',
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

enum TraineeNextStepScreen {
  home,
  miniTraining,
  trainingSession,
  progressDashboard,
  profile,
  other,
}
