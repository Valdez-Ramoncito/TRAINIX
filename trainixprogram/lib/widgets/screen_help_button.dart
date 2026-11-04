import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/models/training/training_categories.dart';
import 'package:trainixprogram/models/training/trainee_next_step.dart';
import 'package:trainixprogram/screens/page/profile.dart';

class ScreenHelpContent {
  final String title;
  final List<String> bullets;
  final String? footer;

  const ScreenHelpContent({
    required this.title,
    required this.bullets,
    this.footer,
  });
}

class ScreenHelpCatalog {
  static const home = ScreenHelpContent(
    title: 'Home',
    bullets: [
      'The Guide / Next strip tells you the current step.',
      'While the guide is on, only the highlighted carousel card opens. Other cards show Guide locked.',
      'Skip guide unlocks free browsing of available screens.',
      'Open Help on any screen for local tips and the full path overview.',
    ],
    footer:
        'Path: Profile → Mini Training → Scenario Practice → Simulation → Dashboard. Practice scores are a 0-10 training tool. TESDA panel criteria are a separate competency checklist (greeting, listening, problem solving, close).',
  );

  static const miniTraining = ScreenHelpContent(
    title: 'Mini Training',
    bullets: [
      'Knowledge Path: lessons unlock in order inside each category.',
      'Finish a category final to open the next category.',
      'After all categories, take the Grand Final.',
      'Scenario Practice tab unlocks after the Grand Final (Chat, Voice, Hybrid).',
    ],
    footer: 'Use the Scenario Practice tab after the Grand Final.',
  );

  static const knowledgePath = ScreenHelpContent(
    title: 'Knowledge Path',
    bullets: [
      'Lessons unlock in order inside each category.',
      'Finish every lesson, then pass the category final to open the next category.',
      'After all categories are complete, take the Grand Final.',
      'Passing the Grand Final unlocks the Scenario Practice tab.',
    ],
    footer: 'Work top to bottom. Completed categories show a check.',
  );

  static const progressDashboard = ScreenHelpContent(
    title: 'Progress Dashboard',
    bullets: [
      'Overview: averages and trends from practice sessions.',
      'Session History: past simulation runs with detail.',
      'Sector Fit: how results line up by sector.',
      'Scores use a 0 to 10 practice scale unless a screen says otherwise.',
      'These numbers support training. TESDA panel checklists stay separate.',
    ],
    footer:
        'Data builds as you complete Simulation and scored practice. Practice scores are a training tool, not the official panel grade.',
  );

  static const simulationHub = ScreenHelpContent(
    title: 'Simulation Training',
    bullets: [
      'Left menu switches Non-Voice, Voice, and history views.',
      'Modes unlock after matching Scenario Practice stages.',
      'Start a session from an unlocked lobby after choosing sector and quota.',
      'Back in the sidebar returns to Home when the stack cannot pop.',
    ],
  );

  static const scenarioPractice = ScreenHelpContent(
    title: 'Scenario Practice',
    bullets: [
      'Order is Non-Voice, then Voice.',
      'Early scenarios are guided. Follow prompts and scripts.',
      'Clearing a stage unlocks the next stage and matching Simulation modes.',
      'If this tab is locked, finish Knowledge Path and the Grand Final first.',
    ],
  );

  static const profile = ScreenHelpContent(
    title: 'Account Profile',
    bullets: [
      'Complete required profile fields to unlock training modes.',
      'Save when finished. The guide will move to Mini Training next.',
      'You can reopen Profile later to update details.',
    ],
  );

  static const trainerHome = ScreenHelpContent(
    title: 'Trainer home',
    bullets: [
      'Open Trainee Session to create or manage live coaching rooms.',
      'Open Log Monitoring to review trainee activity and ended sessions.',
      'Share the room code with trainees if they cannot find the invite.',
    ],
    footer:
        'Live rooms use video for coaching. Session tools hold notes and checklists.',
  );

  static const logMonitoring = ScreenHelpContent(
    title: 'Log Monitoring',
    bullets: [
      'Overview shows recent ended live sessions and activity counts.',
      'Live sessions lists rooms that are still open.',
      'Trainee logs is a timeline of sign-in, room join, and practice events.',
      'Tap a log row for more detail.',
    ],
  );

  static const trainerSession = ScreenHelpContent(
    title: 'Trainee Session',
    bullets: [
      'Create a room to coach a trainee live.',
      'Room codes are generated for you. Share the code if needed.',
      'Public rooms appear in the trainee list. Private rooms need the code.',
      'Use Session tools inside the room for notes and checklists.',
    ],
  );

  static const allScreens = [
    ScreenHelpContent(
      title: 'Home',
      bullets: [
        'Hub for all trainee areas.',
        'Follow Guide / Next, or Skip guide for free navigation.',
      ],
    ),
    ScreenHelpContent(
      title: 'Account Profile',
      bullets: ['Personal details required before training unlocks.'],
    ),
    ScreenHelpContent(
      title: 'Mini Training',
      bullets: ['Knowledge Path lessons and finals, then Scenario Practice.'],
    ),
    ScreenHelpContent(
      title: 'Training Session (Simulation)',
      bullets: ['Full practice sessions in non-voice or voice.'],
    ),
    ScreenHelpContent(
      title: 'Progress Dashboard',
      bullets: ['Scores, history, and sector fit after practice.'],
    ),
    ScreenHelpContent(
      title: 'Trainer Session',
      bullets: ['Join live rooms with a human trainer when scheduled.'],
    ),
  ];

  static const trainerAllScreens = [
    ScreenHelpContent(
      title: 'Trainer Home',
      bullets: [
        'Hub for coaching tools.',
        'Open Trainee Session or Log Monitoring from the cards.',
      ],
    ),
    ScreenHelpContent(
      title: 'Account Profile',
      bullets: ['Update your display name and preferences used across tools.'],
    ),
    ScreenHelpContent(
      title: 'Trainee Session',
      bullets: [
        'Create or manage live coaching rooms.',
        'Share room codes when trainees cannot find the invite.',
      ],
    ),
    ScreenHelpContent(
      title: 'Log Monitoring',
      bullets: [
        'Review trainee activity, open rooms, and ended coaching sessions.',
      ],
    ),
    ScreenHelpContent(
      title: 'Live room tools',
      bullets: ['Notes and checklists stay with the session while coaching.'],
    ),
  ];
}

class ScreenHelpButton extends StatelessWidget {
  final ScreenHelpContent content;
  final bool showSkipTips;
  final bool showPathOverview;

  const ScreenHelpButton({
    super.key,
    required this.content,
    this.showSkipTips = false,
    this.showPathOverview = true,
  });

  void _open(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) =>
          _HelpPanel(content: content, showPathOverview: showPathOverview),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Help',
      onPressed: () => _open(context),
      icon: const Icon(Icons.help_outline_rounded, color: Color(0xFF9CA3AF)),
    );
  }
}

class _HelpPanel extends StatefulWidget {
  final ScreenHelpContent content;
  final bool showPathOverview;

  const _HelpPanel({required this.content, required this.showPathOverview});

  @override
  State<_HelpPanel> createState() => _HelpPanelState();
}

class _HelpPanelState extends State<_HelpPanel> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final next = TraineeNextStep.resolve();
    final guided = MiniTrainingProgress.isGuideActive;
    final size = MediaQuery.of(context).size;
    final wide = size.width >= 900;

    return Dialog(
      backgroundColor: const Color(0xFF141A22),
      insetPadding: EdgeInsets.symmetric(
        horizontal: wide ? size.width * 0.18 : 24,
        vertical: wide ? 48 : 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 720,
          maxHeight: size.height * 0.82,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  const Icon(Icons.menu_book_rounded, color: Color(0xFF70BD8A)),
                  const Gap(10),
                  const Expanded(
                    child: Text(
                      'Help and guidance',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _tabChip(0, 'This screen'),
                  const Gap(8),
                  _tabChip(1, 'All screens'),
                  if (ProfileData.role != AppRole.trainer) ...[
                    const Gap(8),
                    _tabChip(2, 'Guide settings'),
                  ],
                ],
              ),
            ),
            const Gap(8),
            const Divider(height: 1, color: Color(0xFF2A2A2A)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: _tab == 0
                    ? _thisScreen(next, guided)
                    : _tab == 1
                    ? _allScreens()
                    : ProfileData.role == AppRole.trainer
                    ? _allScreens()
                    : _settings(context, guided),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabChip(int index, String label) {
    final selected = _tab == index;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _tab = index),
      selectedColor: const Color(0xFF243447),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF70BD8A) : const Color(0xFF9CA3AF),
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      backgroundColor: const Color(0xFF1A1F26),
      side: BorderSide(
        color: selected ? const Color(0xFF70BD8A) : const Color(0xFF333333),
      ),
    );
  }

  Widget _thisScreen(TraineeNextStep next, bool guided) {
    final isTrainer = ProfileData.role == AppRole.trainer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.content.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Gap(10),
        for (final line in widget.content.bullets) ...[
          _bullet(line),
          const Gap(8),
        ],
        if (widget.content.footer != null) ...[
          const Gap(4),
          Text(
            widget.content.footer!,
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
          ),
        ],
        if (!isTrainer) ...[
          const Gap(16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F26),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2A3441)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guided ? 'Current guide step' : 'Suggested next step',
                  style: const TextStyle(
                    color: Color(0xFF70BD8A),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const Gap(6),
                Text(
                  next.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
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
              ],
            ),
          ),
        ],
        if (widget.showPathOverview && !isTrainer) ...[
          const Gap(16),
          const Text(
            'Training path',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const Gap(8),
          _bullet('1. Complete your profile'),
          _bullet('2. Mini Training lessons and category finals'),
          _bullet('3. Grand Final, then Scenario Practice (Non-Voice → Voice)'),
          _bullet('4. Simulation Training for fuller practice'),
          _bullet('5. Progress Dashboard for scores and history'),
        ],
        if (isTrainer) ...[
          const Gap(16),
          const Text(
            'Trainer workflow',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const Gap(8),
          _bullet('1. Complete your profile'),
          _bullet('2. Open Trainee Session to create a live room'),
          _bullet('3. Share the room code with the trainee'),
          _bullet('4. Use session tools for notes while coaching'),
          _bullet('5. Review activity in Log Monitoring after the session'),
        ],
      ],
    );
  }

  Widget _allScreens() {
    final isTrainer = ProfileData.role == AppRole.trainer;
    final items = isTrainer
        ? ScreenHelpCatalog.trainerAllScreens
        : ScreenHelpCatalog.allScreens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What each area is for',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Gap(12),
        for (final item in items) ...[
          Text(
            item.title,
            style: const TextStyle(
              color: Color(0xFF70BD8A),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const Gap(6),
          for (final line in item.bullets) ...[_bullet(line), const Gap(4)],
          const Gap(12),
        ],
      ],
    );
  }

  Widget _settings(BuildContext context, bool guided) {
    if (ProfileData.role == AppRole.trainer) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Guide settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          Gap(8),
          Text(
            'The step-by-step training guide and intro tips apply to trainee accounts only. Trainer tools stay open without guide locks.',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Guide and tips',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Gap(8),
        const Text(
          'Guide mode highlights the next step and locks unrelated Home cards until you finish that step or skip the guide.',
          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, height: 1.4),
        ),
        const Gap(8),
        const Text(
          'Intro tips are short banners on first visit. Dismissing them only hides those banners. Help always stays available.',
          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, height: 1.4),
        ),
        const Gap(16),
        if (guided)
          _actionButton(
            label: 'Skip guide (free navigation)',
            subtitle:
                'Unlocks browsing. You can turn the guide back on anytime.',
            onTap: () {
              MiniTrainingProgress.setPreferMinimalGuidance(true);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Guide skipped. Home cards are no longer guide-locked.',
                  ),
                ),
              );
            },
          )
        else
          _actionButton(
            label: MiniTrainingProgress.hasReviewedProgressDashboard
                ? 'Quick walkthrough'
                : 'Turn guide back on',
            subtitle: MiniTrainingProgress.hasReviewedProgressDashboard
                ? 'A short refresher of Home cards and what to do in each area.'
                : 'Shows the guide banner again and focuses the current step.',
            onTap: () {
              Navigator.pop(context);
              if (MiniTrainingProgress.hasReviewedProgressDashboard) {
                _showQuickWalkthrough(context);
              } else {
                MiniTrainingProgress.setPreferMinimalGuidance(false);
                final next = TraineeNextStep.resolve();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Guide on: ${next.title}')),
                );
                next.open(context);
              }
            },
          ),
        const Gap(10),
        _actionButton(
          label: 'Show intro tips again',
          subtitle:
              'Only re-shows short reminder banners. Does not reset progress or re-lock anything you already unlocked.',
          onTap: () {
            MiniTrainingProgress.clearSeenIntros();
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Intro tips will show again on those screens.'),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showQuickWalkthrough(BuildContext context) {
    const steps = <(String, String, IconData)>[
      (
        'Account Profile',
        'Set your display name and preferred sector. Email stays linked to your login.',
        Icons.person_outline,
      ),
      (
        'Mini Training',
        'Learn by category, pass at 75% or higher, then practice Non-Voice and Voice scenarios.',
        Icons.school_outlined,
      ),
      (
        'Training Session',
        'Run full customer practice in non-voice or voice after Scenario Practice unlocks each mode.',
        Icons.computer_outlined,
      ),
      (
        'Progress Dashboard',
        'Review scores and session history after your first simulation run.',
        Icons.bar_chart_rounded,
      ),
      (
        'Help anytime',
        'Open Help on any screen for tips. Use this walkthrough whenever you need a short refresher.',
        Icons.help_outline,
      ),
    ];

    var index = 0;
    final pageController = PageController();

    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return Dialog(
              backgroundColor: const Color(0xFF14181E),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 36,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: const Color(0xFF70BD8A).withValues(alpha: 0.45),
                ),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 640,
                  maxHeight: 520,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Quick walkthrough',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 56,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: steps.length,
                        separatorBuilder: (_, __) => const Gap(8),
                        itemBuilder: (_, i) {
                          final active = i == index;
                          return GestureDetector(
                            onTap: () {
                              setLocal(() => index = i);
                              pageController.animateToPage(
                                i,
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOut,
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? const Color(0xFF1F3A2A)
                                    : const Color(0xFF1A1F26),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: active
                                      ? const Color(0xFF70BD8A)
                                      : const Color(0xFF2A313A),
                                  width: active ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    steps[i].$3,
                                    size: 16,
                                    color: active
                                        ? const Color(0xFF70BD8A)
                                        : Colors.white54,
                                  ),
                                  const Gap(6),
                                  Text(
                                    steps[i].$1,
                                    style: TextStyle(
                                      color: active
                                          ? Colors.white
                                          : Colors.white70,
                                      fontWeight: active
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const Gap(8),
                    Expanded(
                      child: PageView.builder(
                        controller: pageController,
                        itemCount: steps.length,
                        onPageChanged: (i) => setLocal(() => index = i),
                        itemBuilder: (_, i) {
                          final step = steps[i];
                          return SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1F26),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(
                                    0xFF70BD8A,
                                  ).withValues(alpha: 0.35),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1F3A2A),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Icon(
                                          step.$3,
                                          color: const Color(0xFF70BD8A),
                                        ),
                                      ),
                                      const Gap(12),
                                      Expanded(
                                        child: Text(
                                          step.$1,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Gap(14),
                                  Text(
                                    step.$2,
                                    style: const TextStyle(
                                      color: Color(0xFFB7C0CB),
                                      fontSize: 15,
                                      height: 1.45,
                                    ),
                                  ),
                                  const Gap(16),
                                  Text(
                                    'Step ${i + 1} of ${steps.length}',
                                    style: const TextStyle(
                                      color: Color(0xFF70BD8A),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: Row(
                        children: [
                          TextButton(
                            onPressed: index == 0
                                ? null
                                : () {
                                    final next = index - 1;
                                    setLocal(() => index = next);
                                    pageController.animateToPage(
                                      next,
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      curve: Curves.easeOut,
                                    );
                                  },
                            child: const Text('Back'),
                          ),
                          const Spacer(),
                          ...List.generate(steps.length, (i) {
                            final active = i == index;
                            return Container(
                              width: active ? 16 : 7,
                              height: 7,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: active
                                    ? const Color(0xFF70BD8A)
                                    : const Color(0xFF3A4450),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            );
                          }),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              if (index >= steps.length - 1) {
                                Navigator.pop(ctx);
                                return;
                              }
                              final next = index + 1;
                              setLocal(() => index = next);
                              pageController.animateToPage(
                                next,
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOut,
                              );
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFF70BD8A),
                              foregroundColor: const Color(0xFF0F1419),
                            ),
                            child: Text(
                              index >= steps.length - 1 ? 'Done' : 'Next',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _actionButton({
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF1A1F26),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const Gap(4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bullet(String line) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '•  ',
          style: TextStyle(color: Color(0xFF70BD8A), height: 1.4),
        ),
        Expanded(
          child: Text(
            line,
            style: const TextStyle(
              color: Color(0xFFE5E7EB),
              height: 1.4,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
