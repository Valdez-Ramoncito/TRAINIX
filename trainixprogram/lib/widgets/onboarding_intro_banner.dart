import 'package:flutter/material.dart';
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
        color: const Color(0xFF15261C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF70BD8A).withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: Color(0xFF70BD8A),
            size: 20,
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const Gap(4),
                Text(
                  widget.body,
                  style: const TextStyle(
                    color: Color(0xFFD1D5DB),
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
            icon: const Icon(Icons.close, size: 18, color: Color(0xFF9CA3AF)),
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
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const Gap(10),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF243447),
                foregroundColor: Colors.white,
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
