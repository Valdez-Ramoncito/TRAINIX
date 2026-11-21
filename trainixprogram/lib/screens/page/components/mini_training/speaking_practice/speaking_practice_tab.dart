import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/components/app_colors.dart';
import 'package:trainixprogram/models/training/speaking/speaking_practice_store.dart';
import 'package:trainixprogram/models/training/speaking/speaking_prompt.dart';
import 'package:trainixprogram/models/training/speaking/speaking_prompt_catalog.dart';
import 'package:trainixprogram/models/training/speaking/speaking_result.dart';
import 'package:trainixprogram/screens/page/components/mini_training/speaking_practice/speaking_test_screen.dart';
import 'package:trainixprogram/widgets/onboarding_intro_banner.dart';
import 'package:trainixprogram/widgets/screen_help_button.dart';

class SpeakingPracticeTab extends StatefulWidget {
  const SpeakingPracticeTab({super.key});

  @override
  State<SpeakingPracticeTab> createState() => _SpeakingPracticeTabState();
}

class _SpeakingPracticeTabState extends State<SpeakingPracticeTab> {
  SpeakingPack _pack = SpeakingPack.readAloud;
  SpeakingPromptDifficulty _difficulty = SpeakingPromptDifficulty.short;

  Future<void> _start() async {
    final prompts = SpeakingPromptCatalog.forSetup(_pack, _difficulty);
    if (prompts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No prompts for this setup yet.')),
      );
      return;
    }
    final prompt = prompts[math.Random().nextInt(prompts.length)];
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SpeakingTestScreen(prompt: prompt),
      ),
    );
    if (changed == true && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final best = SpeakingPracticeStore.bestFor(
      pack: _pack,
      difficulty: _difficulty,
    );
    final overall = SpeakingPracticeStore.overallBest;
    final history = SpeakingPracticeStore.history;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: OnboardingIntroBanner(
                flagKey: 'speaking_practice_intro',
                title: 'Speaking Practice',
                body:
                    'Optional speech drills for delivery and language. Scores stay in memory for this session only and clear when the app restarts. They never gate Mini Training.',
              ),
            ),
            const ScreenHelpButton(
              content: ScreenHelpCatalog.speakingPractice,
            ),
          ],
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 16,
                            color: AppColors.textMuted(context),
                          ),
                          const Gap(6),
                          Text(
                            'Difficulty',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted(context),
                            ),
                          ),
                        ],
                      ),
                      const Gap(10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: SpeakingPromptDifficulty.values.map((d) {
                          return _ChoiceChip(
                            label: d.label,
                            selected: _difficulty == d,
                            onTap: () => setState(() => _difficulty = d),
                          );
                        }).toList(),
                      ),
                      const Gap(22),
                      Row(
                        children: [
                          Icon(
                            Icons.record_voice_over_outlined,
                            size: 16,
                            color: AppColors.textMuted(context),
                          ),
                          const Gap(6),
                          Text(
                            'Prompt pack',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted(context),
                            ),
                          ),
                        ],
                      ),
                      const Gap(10),
                      ...SpeakingPack.values.map((pack) {
                        final selected = _pack == pack;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PackCard(
                            title: pack.label,
                            subtitle: pack.hint,
                            selected: selected,
                            onTap: () => setState(() => _pack = pack),
                          ),
                        );
                      }),
                      const Gap(16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _start,
                          icon: const Icon(Icons.mic_rounded, size: 18),
                          label: Text(
                            'Start · ${_pack.label} · ${_difficulty.label}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryText(),
                            foregroundColor: AppColors.onPrimary(context),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const Gap(12),
                      Text(
                        'Mic permission is requested only when you press Start.',
                        style: TextStyle(
                          color: AppColors.textMuted(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(16),
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoCard(
                        title: 'Best for this setup',
                        body: best == null
                            ? 'No run yet for this pack and difficulty.'
                            : 'Overall ${best.overallScore.toStringAsFixed(1)} · ${best.bandLabel} · ${best.roundedWordsPerMinute} WPM',
                      ),
                      const Gap(10),
                      _InfoCard(
                        title: 'Overall best',
                        body: overall == null
                            ? 'Complete a run to see your best score.'
                            : 'Overall ${overall.overallScore.toStringAsFixed(1)} · ${overall.pack.label}',
                      ),
                      const Gap(16),
                      Text(
                        'Recent runs',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted(context),
                        ),
                      ),
                      const Gap(8),
                      if (history.isEmpty)
                        _InfoCard(
                          title: 'This session',
                          body:
                              'Your last 20 runs appear here. History clears when the app restarts.',
                        )
                      else
                        ...history.take(20).map((r) => _HistoryRow(result: r)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.stageSelected(context)
              : AppColors.card(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primaryText()
                : AppColors.borderIdle(context),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: selected
                ? AppColors.primaryText()
                : AppColors.textSecondary(context),
          ),
        ),
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  const _PackCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.stageSelected(context)
              : AppColors.card(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.primaryText()
                : AppColors.borderIdle(context),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: selected
                  ? AppColors.primaryText()
                  : AppColors.borderStrong(context),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderIdle(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textSecondary(context),
            ),
          ),
          const Gap(6),
          Text(
            body,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted(context),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.result});

  final SpeakingResult result;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderIdle(context)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.mic_none_rounded,
              size: 16,
              color: AppColors.secondaryText(),
            ),
            const Gap(8),
            Expanded(
              child: Text(
                '${result.pack.label} · ${result.difficulty.label}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              result.scoredScores.isEmpty
                  ? '${result.roundedWordsPerMinute} WPM'
                  : result.overallScore.toStringAsFixed(1),
              style: TextStyle(
                color: AppColors.primaryText(),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
