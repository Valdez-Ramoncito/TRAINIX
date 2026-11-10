import 'package:flutter/material.dart';
import 'package:trainixprogram/models/training/training_categories.dart';
import 'package:trainixprogram/screens/dashboard.dart';
import 'package:trainixprogram/screens/page/mini_training.dart';
import 'package:trainixprogram/screens/page/profile.dart';
import 'package:trainixprogram/screens/page/training.dart';
import 'package:trainixprogram/widgets/next_step_banner.dart';

enum TraineeNextStepTarget {
  profile,
  miniTraining,
  scenarioPractice,
  simulationHub,
  trainingSession,
  progressDashboard,
  none,
}

class TraineeNextStep {
  final String title;
  final String reason;
  final TraineeNextStepTarget target;
  final String actionLabel;
  final int? carouselCardId;
  final String? carouselHint;

  const TraineeNextStep({
    required this.title,
    required this.reason,
    required this.target,
    this.actionLabel = 'Go',
    this.carouselCardId,
    this.carouselHint,
  });

  static TraineeNextStep resolve() {
    if (!MiniTrainingProgress.isProfileComplete) {
      return const TraineeNextStep(
        title: 'Complete your profile',
        reason: 'Required before any training area opens.',
        target: TraineeNextStepTarget.profile,
        actionLabel: 'Open profile',
        carouselCardId: 1,
        carouselHint: 'Use the highlighted Account Profile card below.',
      );
    }

    if (!MiniTrainingProgress.allCategoriesCompleted) {
      return const TraineeNextStep(
        title: 'Continue Mini Training',
        reason: 'Finish lessons and category finals in order.',
        target: TraineeNextStepTarget.miniTraining,
        actionLabel: 'Continue',
        carouselCardId: 4,
        carouselHint: 'Use the highlighted Mini Training card below.',
      );
    }

    if (!MiniTrainingProgress.grandFinalPassed) {
      return const TraineeNextStep(
        title: 'Take the Grand Final',
        reason: 'Passing it unlocks Scenario Practice.',
        target: TraineeNextStepTarget.miniTraining,
        actionLabel: 'Open Mini Training',
        carouselCardId: 4,
        carouselHint: 'Use the highlighted Mini Training card below.',
      );
    }

    if (!MiniTrainingProgress.chatScenariosCleared) {
      return const TraineeNextStep(
        title: 'Practice Non-Voice scenarios',
        reason:
            'Clear Non-Voice scenarios to unlock Simulation non-voice mode.',
        target: TraineeNextStepTarget.scenarioPractice,
        actionLabel: 'Open scenarios',
        carouselCardId: 4,
        carouselHint: 'Open Mini Training, then the Scenario Practice tab.',
      );
    }

    if (!MiniTrainingProgress.voiceScenariosCleared) {
      return const TraineeNextStep(
        title: 'Practice Voice scenarios',
        reason: 'Clear Voice scenarios to unlock voice simulation.',
        target: TraineeNextStepTarget.scenarioPractice,
        actionLabel: 'Open scenarios',
        carouselCardId: 4,
        carouselHint: 'Open Mini Training, then the Scenario Practice tab.',
      );
    }

    if (MiniTrainingProgress.isSimulationTrainingUnlocked &&
        !MiniTrainingProgress.hasCompletedSimulationSession) {
      return const TraineeNextStep(
        title: 'Start a Simulation session',
        reason: 'Practice Non-Voice or Voice sessions on the full workstation.',
        target: TraineeNextStepTarget.trainingSession,
        actionLabel: 'Open Simulation',
        carouselCardId: 3,
        carouselHint: 'Use the highlighted Training Session card below.',
      );
    }

    if (MiniTrainingProgress.hasCompletedSimulationSession &&
        !MiniTrainingProgress.hasReviewedProgressDashboard) {
      return const TraineeNextStep(
        title: 'Review your progress',
        reason:
            'Your first simulation is saved. Open the dashboard to review it.',
        target: TraineeNextStepTarget.progressDashboard,
        actionLabel: 'Open dashboard',
        carouselCardId: 5,
        carouselHint: 'Use the highlighted Progress Dashboard card below.',
      );
    }

    if (MiniTrainingProgress.hasReviewedProgressDashboard) {
      return const TraineeNextStep(
        title: 'Guided path complete',
        reason:
            'You can keep practicing Simulation or reopen the Progress Dashboard anytime.',
        target: TraineeNextStepTarget.none,
        actionLabel: 'Dismiss guide',
        carouselCardId: null,
        carouselHint: null,
      );
    }

    return const TraineeNextStep(
      title: 'Continue training',
      reason:
          'Follow Mini Training and Scenario Practice to unlock more areas.',
      target: TraineeNextStepTarget.miniTraining,
      actionLabel: 'Open Mini Training',
      carouselCardId: 4,
    );
  }

  String? contextHintFor(TraineeNextStepScreen screen) {
    switch (screen) {
      case TraineeNextStepScreen.home:
        return null;
      case TraineeNextStepScreen.profile:
        if (target == TraineeNextStepTarget.profile) {
          return 'Fill required fields, then save to unlock Mini Training.';
        }
        return 'Profile is complete. Use the guide when it is on to continue.';
      case TraineeNextStepScreen.miniTraining:
        if (target == TraineeNextStepTarget.miniTraining ||
            target == TraineeNextStepTarget.scenarioPractice) {
          return target == TraineeNextStepTarget.scenarioPractice
              ? 'Open the Scenario Practice tab and clear the current stage.'
              : 'Work the Knowledge Path in order, then the Grand Final.';
        }
        return 'You can train here. Other areas open when their prerequisites are done.';
      case TraineeNextStepScreen.trainingSession:
        if (target == TraineeNextStepTarget.trainingSession ||
            target == TraineeNextStepTarget.simulationHub) {
          return 'Pick an unlocked mode from the left menu, then start a session.';
        }
        return 'Modes stay locked until matching Scenario Practice stages are cleared.';
      case TraineeNextStepScreen.progressDashboard:
        if (target == TraineeNextStepTarget.progressDashboard) {
          return 'Review Overview, Session History, and Sector Fit tabs.';
        }
        return 'Dashboard opens after Simulation Training is unlocked.';
      case TraineeNextStepScreen.other:
        return null;
    }
  }

  static bool canAccessArea(int cardId) {
    if (!MiniTrainingProgress.isProfileComplete) {
      return cardId == 1;
    }
    switch (cardId) {
      case 1:
        return true;
      case 2:
        return true;
      case 3:
        return MiniTrainingProgress.isSimulationTrainingUnlocked;
      case 4:
        return true;
      case 5:
        return MiniTrainingProgress.isProgressDashboardUnlocked;
      default:
        return true;
    }
  }

  static bool canOpenCarouselCard(int cardId) {
    if (!canAccessArea(cardId)) return false;
    if (!MiniTrainingProgress.isGuideActive) return true;
    final next = resolve();
    if (next.carouselCardId == null) return true;
    if (cardId == next.carouselCardId) return true;
    if (cardId == 1) return true;
    return false;
  }

  static String lockReasonForCarouselCard(int cardId) {
    if (!MiniTrainingProgress.isProfileComplete && cardId != 1) {
      return 'Complete your profile first. Other areas stay closed until then.';
    }
    if (!canAccessArea(cardId)) {
      return switch (cardId) {
        3 =>
          'Training Session unlocks after you clear Non-Voice Scenario Practice in Mini Training.',
        5 =>
          'Progress Dashboard unlocks after you complete your first Simulation session.',
        _ => 'This area is still locked. Finish earlier training first.',
      };
    }
    if (MiniTrainingProgress.isGuideActive) {
      final next = resolve();
      final name = switch (cardId) {
        1 => 'Account Profile',
        2 => 'Trainer Session',
        3 => 'Training Session',
        4 => 'Mini Training',
        5 => 'Progress Dashboard',
        _ => 'This area',
      };
      return '$name is guide-locked. Finish "${next.title}" first, or skip the guide in Help.';
    }
    return 'This area is locked.';
  }

  void open(BuildContext context) {
    switch (target) {
      case TraineeNextStepTarget.profile:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const Profile(requireCompletion: true),
          ),
        );
      case TraineeNextStepTarget.miniTraining:
      case TraineeNextStepTarget.scenarioPractice:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MiniTraining()),
        );
      case TraineeNextStepTarget.simulationHub:
      case TraineeNextStepTarget.trainingSession:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TrainingSession()),
        );
      case TraineeNextStepTarget.progressDashboard:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      case TraineeNextStepTarget.none:
        MiniTrainingProgress.setPreferMinimalGuidance(true);
        break;
    }
  }
}
