import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/components/decoration/box_decoration.dart';
import 'package:trainixprogram/components/decoration/check.dart';
import 'package:trainixprogram/models/training/scenarios/chat_scenarios.dart';
import 'package:trainixprogram/models/training/scenarios/voice_scenarios.dart';
import 'package:trainixprogram/models/trainix_debug.dart';
import 'package:trainixprogram/models/training/training_categories.dart';
import 'package:trainixprogram/screens/page/components/mini_training/scenario_practice_screen.dart';
import 'package:trainixprogram/widgets/onboarding_intro_banner.dart';
import 'package:trainixprogram/widgets/screen_help_button.dart';

class ScenarioPracticeTab extends StatefulWidget {
  final VoidCallback? onOpenKnowledgePath;

  const ScenarioPracticeTab({super.key, this.onOpenKnowledgePath});

  @override
  State<ScenarioPracticeTab> createState() => _ScenarioPracticeTabState();
}

class _ScenarioPracticeTabState extends State<ScenarioPracticeTab> {
  void _debugUnlockScenarioPractice() {
    MiniTrainingProgress.debugUnlockScenarioPractice();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('DEBUG: Scenario Practice unlocked (Chat stage)'),
      ),
    );
  }

  void _debugUnlockAllMiniTraining() {
    MiniTrainingProgress.debugUnlockAllMiniTraining();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'DEBUG: Knowledge Path, Grand Final, and all Scenario stages cleared',
        ),
      ),
    );
  }

  int _doneCount(Set<String> completed, List<String> required) {
    return required.where(completed.contains).length;
  }

  Widget _stageCard({
    required String title,
    required String subtitle,
    required bool isUnlocked,
    required bool isCompleted,
    required int done,
    required int total,
    required VoidCallback? onTap,
  }) {
    final percent = total == 0 ? 0 : ((done / total) * 100).round();

    return MouseRegion(
      cursor: isUnlocked
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: isUnlocked ? onTap : null,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 14),
          height: 100,
          decoration: boxDecoration(isCompleted, isUnlocked && !isCompleted),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isUnlocked || isCompleted
                              ? Colors.white
                              : Colors.white54,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Gap(8),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: isUnlocked || isCompleted
                              ? const Color.fromARGB(255, 210, 210, 210)
                              : Colors.white38,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCompleted)
                const CheckProgress()
              else if (!isUnlocked)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF4A4A4A),
                          width: 0.8,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_rounded,
                            size: 14,
                            color: Color(0xFF9CA3AF),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Locked',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$percent%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(6),
                    Text(
                      '$done / $total scenarios',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pathLocked =
        !MiniTrainingProgress.grandFinalPassed &&
        MiniTrainingProgress.scenarioStage == ScenarioStage.locked;

    final chatUnlocked = MiniTrainingProgress.isChatScenariosUnlocked;
    final voiceUnlocked = MiniTrainingProgress.isVoiceScenariosUnlocked;

    final chatDone = requiredChatScenarioIds.every(
      MiniTrainingProgress.completedChatScenarios.contains,
    );
    final voiceDone = requiredVoiceScenarioIds.every(
      MiniTrainingProgress.completedVoiceScenarios.contains,
    );

    final chatProgress = _doneCount(
      MiniTrainingProgress.completedChatScenarios,
      requiredChatScenarioIds,
    );
    final voiceProgress = _doneCount(
      MiniTrainingProgress.completedVoiceScenarios,
      requiredVoiceScenarioIds,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Scenario Practice',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
              const ScreenHelpButton(
                content: ScreenHelpCatalog.scenarioPractice,
                showPathOverview: false,
              ),
            ],
          ),
          const Gap(8),
          const Text(
            'Apply what you learned in guided non-voice and voice scenarios.',
            style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.4),
          ),
          const Gap(12),
          const OnboardingIntroBanner(
            flagKey: 'scenario_intro',
            title: 'Scenario path order',
            body:
                'Work Non-Voice first, then Voice. Early scenarios are guided. Clearing a stage unlocks the next one and matching Simulation modes.',
          ),
          if (pathLocked)
            LockedPathBanner(
              message:
                  'Scenario Practice is locked. Finish all categories and pass the Grand Final Assessment first.',
              actionLabel: 'Go to Knowledge Path',
              onAction: widget.onOpenKnowledgePath,
            ),
          _stageCard(
            title: 'Non-Voice Scenario Practice',
            subtitle: chatDone
                ? 'All non-voice scenarios cleared'
                : chatUnlocked
                ? 'Practice applying skills in non-voice scenarios'
                : 'Finish Grand Final to unlock',
            isUnlocked: chatUnlocked,
            isCompleted: chatDone,
            done: chatProgress,
            total: requiredChatScenarioIds.length,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      const ScenarioPracticeScreen(stageName: 'Chat'),
                ),
              );
              setState(() {});
            },
          ),
          _stageCard(
            title: 'Voice Scenario Practice',
            subtitle: voiceDone
                ? 'All voice scenarios cleared'
                : voiceUnlocked
                ? 'Practice applying skills in voice scenarios'
                : 'Clear Non-Voice Scenario Practice first',
            isUnlocked: voiceUnlocked,
            isCompleted: voiceDone,
            done: voiceProgress,
            total: requiredVoiceScenarioIds.length,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      const ScenarioPracticeScreen(stageName: 'Voice'),
                ),
              );
              setState(() {});
            },
          ),
          if (TrainixDebug.unlocked) ...[
            const Gap(8),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton(
                onPressed: _debugUnlockScenarioPractice,
                child: const Text('DEBUG: Unlock Scenario Practice'),
              ),
            ),
            const Gap(8),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton(
                onPressed: _debugUnlockAllMiniTraining,
                child: const Text('DEBUG: Complete all Mini Training'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
