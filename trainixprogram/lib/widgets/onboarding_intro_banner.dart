import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/models/training/training_categories.dart';

class OnboardingIntroBanner extends StatefulWidget {
  final String flagKey;
  final String title;
  final String body;

  const OnboardingIntroBanner({
    super.key,
    required this.flagKey,
    required this.title,
    required this.body,
  });

  @override
  State<OnboardingIntroBanner> createState() => _OnboardingIntroBannerState();
}

class _OnboardingIntroBannerState extends State<OnboardingIntroBanner> {
  bool _dismissed = false;

  bool get _shouldShow {
    if (_dismissed) return false;
    if (MiniTrainingProgress.preferMinimalGuidance) return false;
    switch (widget.flagKey) {
      case 'mini_intro':
        return !MiniTrainingProgress.seenMiniIntro;
      case 'scenario_intro':
        return !MiniTrainingProgress.seenScenarioIntro;
      case 'simulation_intro':
        return !MiniTrainingProgress.seenSimulationIntro;
      case 'typing_practice_intro':
        return !MiniTrainingProgress.seenTypingIntro;
      case 'speaking_practice_intro':
        return !MiniTrainingProgress.seenSpeakingIntro;
      default:
        return false;
    }
  }

  void _dismiss() {
    MiniTrainingProgress.markSeen(widget.flagKey);
    setState(() => _dismissed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.nextTint(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryText().withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: AppColors.primaryText(),
            size: 20,
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const Gap(4),
                Text(
                  widget.body,
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _dismiss,
            tooltip: 'Dismiss',
            icon: Icon(Icons.close,
                size: 18, color: AppColors.textMuted(context)),
          ),
        ],
      ),
    );
  }
}

class LockedPathBanner extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const LockedPathBanner({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.elevated(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary(context),
              height: 1.4,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const Gap(10),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.completeTint(context),
                foregroundColor: AppColors.textPrimary(context),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
