import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/models/training/typing/typing_passage.dart';
import 'package:trainixprogram/models/training/typing/typing_practice_store.dart';
import 'package:trainixprogram/models/training/typing/typing_result.dart';
import 'package:trainixprogram/screens/page/components/mini_training/typing_practice/typing_test_screen.dart';
import 'package:trainixprogram/widgets/onboarding_intro_banner.dart';
import 'package:trainixprogram/widgets/screen_help_button.dart';

class TypingPracticeTab extends StatefulWidget {
  const TypingPracticeTab({super.key});

  @override
  State<TypingPracticeTab> createState() => _TypingPracticeTabState();
}

class _TypingPracticeTabState extends State<TypingPracticeTab> {
  static const _green = Color(0xFF70BD8A);
  static const _card = Color(0xFF151515);
  static const _border = Color(0xFF2F2F2F);
  static const _muted = Color(0xFF9CA3AF);

  int _durationSeconds = 60;
  TypingPack _pack = TypingPack.scripts;
  bool _noBackspace = false;

  Future<void> _start() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TypingTestScreen(
          durationSeconds: _durationSeconds,
          pack: _pack,
          noBackspace: _noBackspace,
        ),
      ),
    );
    if (changed == true && mounted) setState(() {});
  }

  String _packLabel(TypingPack pack) {
    switch (pack) {
      case TypingPack.general:
        return 'General';
      case TypingPack.scripts:
        return 'Scripts';
      case TypingPack.chat:
        return 'Chat';
    }
  }

  String _packHint(TypingPack pack) {
    switch (pack) {
      case TypingPack.general:
        return 'Neutral warm-up lines for pure speed and accuracy.';
      case TypingPack.scripts:
        return 'Agent openings, empathy, verification, and closings.';
      case TypingPack.chat:
        return 'Short customer and agent chat turns.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final overall = TypingPracticeStore.overallBest;
    final modeBest = TypingPracticeStore.bestFor(
      durationSeconds: _durationSeconds,
      pack: _pack,
    );
    final history = TypingPracticeStore.history;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: OnboardingIntroBanner(
                flagKey: 'typing_practice_intro',
                title: 'Typing Practice',
                body:
                    'Optional speed drills for chat work. Timer starts on your first key. Scores stay on this device for now and do not gate Mini Training.',
              ),
            ),
            const ScreenHelpButton(content: ScreenHelpCatalog.typingPractice),
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
                      const Text(
                        'Duration',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _muted,
                        ),
                      ),
                      const Gap(10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _ChoiceChip(
                            label: '30 sec',
                            selected: _durationSeconds == 30,
                            onTap: () => setState(() => _durationSeconds = 30),
                          ),
                          _ChoiceChip(
                            label: '60 sec',
                            selected: _durationSeconds == 60,
                            onTap: () => setState(() => _durationSeconds = 60),
                          ),
                          _ChoiceChip(
                            label: '2 min',
                            selected: _durationSeconds == 120,
                            onTap: () =>
                                setState(() => _durationSeconds = 120),
                          ),
                        ],
                      ),
                      const Gap(22),
                      const Text(
                        'Passage pack',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _muted,
                        ),
                      ),
                      const Gap(10),
                      ...TypingPack.values.map((pack) {
                        final selected = _pack == pack;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PackCard(
                            title: _packLabel(pack),
                            subtitle: _packHint(pack),
                            selected: selected,
                            onTap: () => setState(() => _pack = pack),
                          ),
                        );
                      }),
                      const Gap(8),
                      InkWell(
                        onTap: () =>
                            setState(() => _noBackspace = !_noBackspace),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _card,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _noBackspace ? _green : _border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _noBackspace
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank,
                                size: 20,
                                color: _noBackspace ? _green : _muted,
                              ),
                              const Gap(10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'No backspace mode',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Gap(2),
                                    Text(
                                      'Blocks delete and backspace. Builds clean first-pass typing.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Gap(24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _start,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Start ${_durationSeconds}s · ${_packLabel(_pack)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const Gap(12),
                      const Text(
                        'Chat agents often aim for 40 to 60+ net WPM with high accuracy. Use Scripts and Chat packs to mirror real replies.',
                        style: TextStyle(fontSize: 12, color: _muted, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(24),
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BestCard(
                        title: 'Best for this setup',
                        result: modeBest,
                        emptyLabel: 'No run yet for this duration and pack.',
                      ),
                      const Gap(12),
                      _BestCard(
                        title: 'Overall best',
                        result: overall,
                        emptyLabel: 'Complete a run to see your best net WPM.',
                      ),
                      const Gap(18),
                      const Text(
                        'Recent runs',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _muted,
                        ),
                      ),
                      const Gap(10),
                      if (history.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _border),
                          ),
                          child: const Text(
                            'Your last 20 runs will appear here for this session.',
                            style: TextStyle(fontSize: 13, color: _muted),
                          ),
                        )
                      else
                        ...history.take(8).map((r) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _HistoryRow(result: r),
                          );
                        }),
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
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF70BD8A).withValues(alpha: 0.16)
                : const Color(0xFF151515),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? const Color(0xFF70BD8A) : const Color(0xFF2F2F2F),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? const Color(0xFF70BD8A) : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PackCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF141C18)
                : const Color(0xFF151515),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? const Color(0xFF70BD8A) : const Color(0xFF2F2F2F),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color:
                          const Color(0xFF70BD8A).withValues(alpha: 0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
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
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 20,
                color: selected
                    ? const Color(0xFF70BD8A)
                    : const Color(0xFF6B7280),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BestCard extends StatelessWidget {
  final String title;
  final TypingResult? result;
  final String emptyLabel;

  const _BestCard({
    required this.title,
    required this.result,
    required this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2F2F2F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const Gap(10),
          if (result == null)
            Text(
              emptyLabel,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            )
          else
            Row(
              children: [
                Text(
                  '${result!.roundedNetWpm}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF70BD8A),
                  ),
                ),
                const Gap(8),
                const Text(
                  'WPM',
                  style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                ),
                const Spacer(),
                Text(
                  '${result!.roundedAccuracy}% · ${result!.durationSeconds}s',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final TypingResult result;

  const _HistoryRow({required this.result});

  String get _pack {
    switch (result.pack) {
      case TypingPack.general:
        return 'General';
      case TypingPack.scripts:
        return 'Scripts';
      case TypingPack.chat:
        return 'Chat';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2F2F2F)),
      ),
      child: Row(
        children: [
          Text(
            '${result.roundedNetWpm} WPM',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(10),
          Text(
            '${result.roundedAccuracy}%',
            style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          ),
          const Spacer(),
          Text(
            '$_pack · ${result.durationSeconds}s'
            '${result.noBackspace ? ' · NB' : ''}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}
