import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';
import 'package:trainixprogram/components/layout/content_bounds.dart';
import 'package:trainixprogram/components/decoration/box_decoration.dart';
import 'package:trainixprogram/components/decoration/check.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/models/training/scenarios/chat_scenarios.dart';
import 'package:trainixprogram/models/training/scenarios/scenario_models.dart';
import 'package:trainixprogram/models/training/scenarios/voice_scenarios.dart';
import 'package:trainixprogram/models/trainix_debug.dart';
import 'package:trainixprogram/models/training/training_categories.dart';
import 'package:trainixprogram/screens/page/components/mini_training/scenario_practice/chat_scenario_player.dart';
import 'package:trainixprogram/screens/page/components/mini_training/scenario_practice/voice_scenario_player.dart';

class ScenarioPracticeScreen extends StatefulWidget {
  final String stageName;

  const ScenarioPracticeScreen({super.key, required this.stageName});

  @override
  State<ScenarioPracticeScreen> createState() => _ScenarioPracticeScreenState();
}

class _ScenarioPracticeScreenState extends State<ScenarioPracticeScreen> {
  bool get _isChat => widget.stageName == 'Chat';
  bool get _isVoice => widget.stageName == 'Voice';

  List<ScenarioDefinition> get _scenarios {
    if (_isVoice) return voiceScenarios;
    return chatScenarios;
  }

  Set<String> get _completed {
    if (_isVoice) return MiniTrainingProgress.completedVoiceScenarios;
    return MiniTrainingProgress.completedChatScenarios;
  }

  bool _isUnlocked(int index) {
    if (index == 0) return true;
    final prev = _scenarios[index - 1];
    return _completed.contains(prev.id);
  }

  Future<void> _openScenario(ScenarioDefinition scenario) async {
    final Widget page;
    if (_isVoice) {
      page = VoiceScenarioPlayer(scenario: scenario);
    } else {
      page = ChatScenarioPlayer(scenario: scenario);
    }
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => page));
    if (result == true && mounted) {
      setState(() {});
    }
  }

  void _debugClearStage() {
    if (_isChat) {
      for (final id in requiredChatScenarioIds) {
        MiniTrainingProgress.completedChatScenarios.add(id);
      }
      MiniTrainingProgress.markChatScenariosCleared();
    } else if (_isVoice) {
      for (final id in requiredVoiceScenarioIds) {
        MiniTrainingProgress.completedVoiceScenarios.add(id);
      }
      MiniTrainingProgress.markVoiceScenariosCleared();
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('DEBUG: ${widget.stageName} stage cleared')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scenarios = _scenarios;

    return Scaffold(
      backgroundColor: AppColors.inputFill(context),
      appBar: AppBar(
        centerTitle: true,
        title: Text('${widget.stageName} Scenario Practice'),
        backgroundColor: AppColors.elevated(context),
      ),
      body: ContentBounds(
        maxWidth: 1100,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.stageName} Scenario Practice',
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const Gap(8),
              Text(
                _isChat
                    ? 'Predefined non-voice scenarios by sector. Difficulty increases as you go.'
                    : 'Voice scenarios including Account Lookup, no-lookup, and already-resolved cases.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary(context),
                  height: 1.4,
                ),
              ),
              if (TrainixDebug.unlocked) ...[
                const Gap(12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _debugClearStage,
                    child: Text('DEBUG: Clear ${widget.stageName} stage'),
                  ),
                ),
              ],
              const Gap(8),
              Expanded(
                child: scenarios.isEmpty
                    ? Text(
                        'No scenarios added for this stage yet.',
                        style: TextStyle(color: AppColors.textMuted(context)),
                      )
                    : ListView.separated(
                        itemCount: scenarios.length,
                        separatorBuilder: (_, __) => const Gap(12),
                        itemBuilder: (context, index) {
                          final s = scenarios[index];
                          final done = _completed.contains(s.id);
                          final unlocked = _isUnlocked(index);
                          return MouseRegion(
                            cursor: unlocked
                                ? SystemMouseCursors.click
                                : SystemMouseCursors.basic,
                            child: GestureDetector(
                              onTap: unlocked ? () => _openScenario(s) : null,
                              child: Container(
                                width: double.infinity,
                                height: 92,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                decoration: themedBoxDecoration(
                                  context,
                                  isComplete: done,
                                  isNext: unlocked && !done,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      margin: const EdgeInsets.only(right: 14),
                                      decoration: BoxDecoration(
                                        color: AppColors.card(context),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: AppColors.borderIdle(context),
                                        ),
                                      ),
                                      child: Icon(
                                        done
                                            ? Icons.check_rounded
                                            : unlocked
                                                ? (_isChat
                                                    ? Icons.forum_outlined
                                                    : Icons.graphic_eq_rounded)
                                                : Icons.lock_outline_rounded,
                                        size: 18,
                                        color: done
                                            ? AppColors.primaryText()
                                            : unlocked
                                                ? AppColors.secondaryText()
                                                : AppColors.textMuted(context),
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            s.title,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: unlocked || done
                                                  ? AppColors.textPrimary(
                                                      context)
                                                  : AppColors.textMuted(
                                                      context),
                                            ),
                                          ),
                                          const Gap(8),
                                          Text(
                                            done
                                                ? 'Completed'
                                                : unlocked
                                                    ? '${s.sector} • ${s.emotion} • ${s.isGuided ? "Guided" : "Practice"}'
                                                    : 'Locked — finish the previous scenario first',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: unlocked || done
                                                  ? AppColors.textSecondary(
                                                      context)
                                                  : AppColors.textMuted(
                                                      context),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (done)
                                      const CheckProgress()
                                    else if (!unlocked)
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.border(context),
                                        ),
                                        child: Icon(
                                          Icons.lock_rounded,
                                          size: 14,
                                          color: AppColors.textMuted(context),
                                        ),
                                      )
                                    else
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        color: AppColors.textMuted(context),
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
          ),
        ),
      ),
    );
  }
}
