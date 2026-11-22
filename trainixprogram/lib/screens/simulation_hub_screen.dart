import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:trainixprogram/components/background.dart';
import 'package:trainixprogram/components/decoration/box_decoration.dart';
import 'package:trainixprogram/components/size.dart';
import 'package:trainixprogram/models/simulation_history.dart';
import 'package:trainixprogram/models/simulation_phase.dart';
import 'package:trainixprogram/models/training/training_categories.dart';
import 'package:trainixprogram/providers/simulation_provider.dart';
import 'package:trainixprogram/screens/mock_call_screen.dart';
import 'package:trainixprogram/screens/session_report_screen.dart';
import 'package:trainixprogram/screens/page/components/mini_training/training_notification_banner.dart';
import 'package:trainixprogram/screens/home/homeScreen.dart';
import 'package:trainixprogram/screens/page/mini_training.dart';
import 'package:trainixprogram/widgets/onboarding_intro_banner.dart';
import 'package:trainixprogram/widgets/screen_help_button.dart';
import 'package:trainixprogram/models/trainix_debug.dart';
import 'package:trainixprogram/widgets/user_facing_messages.dart';

class SimulationHubScreen extends StatefulWidget {
  const SimulationHubScreen({super.key});

  @override
  State<SimulationHubScreen> createState() => _SimulationHubScreenState();
}

class _SimulationHubScreenState extends State<SimulationHubScreen> {
  bool _pickingMode = false;

  @override
  void initState() {
    super.initState();
    TrainixDebug.instance.addListener(_onDebugChanged);
  }

  void _onDebugChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    TrainixDebug.instance.removeListener(_onDebugChanged);
    super.dispose();
  }

  void _goBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  Future<void> _startSession(SimulationMode mode) async {
    final setup = await _pickSessionSetup();
    if (!mounted || setup == null) return;
    final sim = Provider.of<SimulationProvider>(context, listen: false);
    final sector = setup['sector'] == 'random'
        ? sim.pickNextSector()
        : sim.selectSector(setup['sector'] as String);
    final quota = setup['quota'] as int;
    final resolved = quota == 0 ? null : quota;
    final guidedMode = setup['guided'] as bool? ?? true;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MockCallScreen(
          sector: sector,
          mode: mode,
          customerQuota: resolved,
          guidedMode: guidedMode,
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _pickSessionSetup() async {
    String selectedSector = 'random';
    int selectedQuota = 0;
    bool guidedMode = true;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              backgroundColor: AppColors.elevated(context),
              title: Text(
                'Session setup',
                style: TextStyle(color: AppColors.textPrimary(context)),
              ),
              content: SizedBox(
                width: 360,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sector',
                        style: TextStyle(
                          color: AppColors.textPrimary(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _setupChip(
                            label: 'Random sector',
                            selected: selectedSector == 'random',
                            onTap: () =>
                                setLocal(() => selectedSector = 'random'),
                          ),
                          ...SimulationProvider.allSectors.map(
                            (s) => _setupChip(
                              label: s,
                              selected: selectedSector == s,
                              onTap: () => setLocal(() => selectedSector = s),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Customer quota',
                        style: TextStyle(
                          color: AppColors.textPrimary(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...[1, 3, 4, 5].map(
                            (n) => _setupChip(
                              label: n == 1 ? '1 customer' : '$n customers',
                              selected: selectedQuota == n,
                              onTap: () => setLocal(() => selectedQuota = n),
                            ),
                          ),
                          _setupChip(
                            label: 'Random (3-5)',
                            selected: selectedQuota == 0,
                            onTap: () => setLocal(() => selectedQuota = 0),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Guidance',
                        style: TextStyle(
                          color: AppColors.textPrimary(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _setupChip(
                            label: 'Guided',
                            selected: guidedMode,
                            onTap: () => setLocal(() => guidedMode = true),
                          ),
                          _setupChip(
                            label: 'Unguided',
                            selected: !guidedMode,
                            onTap: () => setLocal(() => guidedMode = false),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        guidedMode
                            ? 'Script Guide and tips available.'
                            : 'No guides or scripts. Real call-center style.',
                        style: TextStyle(
                          color: AppColors.textMuted(context),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, {
                    'sector': selectedSector,
                    'quota': selectedQuota,
                    'guided': guidedMode,
                  }),
                  child: const Text('Start session'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _setupChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.nextTint(context)
                : AppColors.elevated(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.primaryText()
                  : AppColors.borderStrong(context),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? AppColors.primaryText()
                  : AppColors.textSecondary(context),
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _hubCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: double.infinity,
          height: 110,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: themedBoxDecoration(
            context,
            isComplete: false,
            isNext: enabled,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: enabled
                      ? AppColors.textPrimary(context)
                      : AppColors.textMuted(context),
                ),
                const Gap(18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: enabled
                              ? AppColors.textPrimary(context)
                              : AppColors.textMuted(context),
                        ),
                      ),
                      const Gap(6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: enabled
                              ? AppColors.textSecondary(context)
                              : AppColors.textMuted(context),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!enabled)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.border(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.borderStrong(context),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_rounded,
                          size: 14,
                          color: AppColors.textMuted(context),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Locked',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted(context),
                          ),
                        ),
                      ],
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
      ),
    );
  }

  Widget _modeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isUnlocked,
    required VoidCallback? onTap,
  }) {
    return MouseRegion(
      cursor: isUnlocked ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: isUnlocked ? onTap : null,
        child: Container(
          width: double.infinity,
          height: 100,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: themedBoxDecoration(
            context,
            isComplete: false,
            isNext: isUnlocked,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 26,
                  color: isUnlocked
                      ? AppColors.textPrimary(context)
                      : AppColors.textMuted(context),
                ),
                const Gap(18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isUnlocked
                              ? AppColors.textPrimary(context)
                              : AppColors.textMuted(context),
                        ),
                      ),
                      const Gap(6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isUnlocked
                              ? AppColors.textSecondary(context)
                              : AppColors.textMuted(context),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isUnlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.border(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.borderStrong(context),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_rounded,
                          size: 14,
                          color: AppColors.textMuted(context),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Locked',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted(context),
                          ),
                        ),
                      ],
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
      ),
    );
  }

  Widget _debugButton(String label, VoidCallback onPressed) {
    return DebugOnly(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SizedBox(
          width: double.infinity,
          height: 40,
          child: OutlinedButton(
            onPressed: () {
              onPressed();
              setState(() {});
            },
            child: Text(label),
          ),
        ),
      ),
    );
  }

  Widget _buildModePicker() {
    final chatUnlocked = MiniTrainingProgress.isChatSessionUnlocked;
    final voiceUnlocked = MiniTrainingProgress.isVoiceSessionUnlocked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() => _pickingMode = false),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            ),
            Text(
              'Choose Session Type',
              style: TextStyle(
                fontSize: context.responsiveFont(5.5),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const Gap(8),
        Text(
          'Pick a channel mode. Next you will choose sector and customer quota (1, 3-5, or random). Locked modes clear after Scenario Practice.',
          style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary(context),
              height: 1.4),
        ),
        const Gap(20),
        _modeCard(
          title: 'Non-Voice Session',
          subtitle: chatUnlocked
              ? 'Text channel. Practice written customer handling.'
              : 'Clear Non-Voice Scenario Practice first',
          icon: Icons.chat_bubble_outline_rounded,
          isUnlocked: chatUnlocked,
          onTap: () => _startSession(SimulationMode.chat),
        ),
        _modeCard(
          title: 'Voice Session',
          subtitle: voiceUnlocked
              ? 'Voice channel. Practice live call handling.'
              : 'Clear Voice Scenario Practice first',
          icon: Icons.phone_in_talk_outlined,
          isUnlocked: voiceUnlocked,
          onTap: () => _startSession(SimulationMode.voice),
        ),
        const Gap(12),
        _debugButton('DEBUG: Unlock Non-Voice Session', () {
          MiniTrainingProgress.debugUnlockChatSession();
          _snack('DEBUG: Non-Voice Session unlocked');
        }),
        _debugButton('DEBUG: Unlock Voice Session', () {
          MiniTrainingProgress.debugUnlockVoiceSession();
          _snack('DEBUG: Voice Session unlocked');
        }),
      ],
    );
  }

  Widget _buildHubHome() {
    final unlocked = MiniTrainingProgress.isSimulationTrainingUnlocked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => _goBack(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              tooltip: 'Back',
            ),
            TextButton(
              onPressed: () => _goBack(context),
              child: const Text('Back'),
            ),
            const Gap(4),
            Expanded(
              child: Text(
                'Simulation Training',
                style: TextStyle(
                  fontSize: context.responsiveFont(5.5),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const ScreenHelpButton(content: ScreenHelpCatalog.simulationHub),
          ],
        ),
        const Gap(8),
        Text(
          unlocked
              ? 'Start a new practice session or review past runs.'
              : 'Simulation Training unlocks after you clear Non-Voice Scenario Practice.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary(context),
            height: 1.4,
          ),
        ),
        const Gap(12),
        const OnboardingIntroBanner(
          flagKey: 'simulation_intro',
          title: 'About Simulation Training',
          body:
              'New Session starts practice in non-voice or voice. Modes unlock after you clear the matching Scenario Practice stage in Mini Training.',
        ),
        if (!unlocked)
          LockedPathBanner(
            message:
                'Simulation Training is locked. Clear all Non-Voice scenarios in Scenario Practice first.',
            actionLabel: 'Go to Scenario Practice',
            onAction: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const MiniTraining()));
            },
          ),
        _hubCard(
          title: 'New Session',
          subtitle: unlocked
              ? 'Choose Non-Voice or Voice and start practicing.'
              : 'Locked until Non-Voice Scenario Practice is cleared',
          icon: Icons.play_circle_outline_rounded,
          enabled: unlocked,
          onTap: () => setState(() => _pickingMode = true),
        ),
        _hubCard(
          title: 'Session History',
          subtitle: 'Review scores and past simulation runs.',
          icon: Icons.history_rounded,
          enabled: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SimulationSessionHistoryScreen(),
              ),
            );
          },
        ),
        const Gap(12),
        _debugButton('DEBUG: Unlock Simulation Training', () {
          MiniTrainingProgress.debugUnlockSimulationTraining();
          _snack('DEBUG: Simulation Training unlocked');
        }),
        _debugButton('DEBUG: Unlock All Simulation Modes', () {
          MiniTrainingProgress.debugUnlockVoiceSession();
          _snack('DEBUG: Non-Voice and Voice simulation unlocked');
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return TrainingNotificationHost(
      child: Scaffold(
        body: AppBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: SingleChildScrollView(
                child: _pickingMode ? _buildModePicker() : _buildHubHome(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SimulationSessionHistoryScreen extends StatelessWidget {
  const SimulationSessionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                      ),
                    ),
                    Text(
                      'Session History',
                      style: TextStyle(
                        fontSize: context.responsiveFont(5.5),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const Gap(12),
                Expanded(
                  child: Consumer<SimulationHistoryProvider>(
                    builder: (context, history, _) {
                      final visible = history.sessions
                          .where((s) => !isDebugSession(s))
                          .toList();
                      if (visible.isEmpty) {
                        return Center(
                          child: Text(
                            'No sessions yet.\nComplete a simulation to see your history.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary(context),
                              height: 1.4,
                            ),
                          ),
                        );
                      }

                      final reversed = visible.reversed.toList();
                      return ListView.builder(
                        itemCount: reversed.length,
                        itemBuilder: (_, index) {
                          final session = reversed[index];
                          final number = reversed.length - index;
                          final customerLabel = session.evaluations
                              .map((e) => friendlyCustomerName(e.customerName))
                              .where((n) => n.isNotEmpty)
                              .toSet()
                              .take(3)
                              .join(', ');
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SessionReportScreen(
                                    evaluations: session.evaluations,
                                    multitaskingScore:
                                        session.multitaskingScore,
                                    guidedMode: session.guidedMode,
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              decoration: themedBoxDecoration(
                                context,
                                isComplete: false,
                                isNext: true,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.secondaryWash(context),
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: Icon(
                                      session.mode == SimulationMode.voice
                                          ? Icons.mic_rounded
                                          : Icons.chat_bubble_outline_rounded,
                                      size: 18,
                                      color: AppColors.secondaryText(),
                                    ),
                                  ),
                                  const Gap(12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          session.sector.isEmpty
                                              ? 'Session #$number'
                                              : '${session.sector} · #$number',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const Gap(4),
                                        Text(
                                          '${session.mode == SimulationMode.voice ? 'VOICE' : 'NON-VOICE'} · ${session.evaluations.length} customer(s)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textMuted(context),
                                          ),
                                        ),
                                        if (customerLabel.isNotEmpty) ...[
                                          const Gap(4),
                                          Text(
                                            customerLabel,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color:
                                                  AppColors.textMuted(context),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        session.overallScore.toStringAsFixed(1),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: AppColors.primaryText(),
                                        ),
                                      ),
                                      Text(
                                        'View report',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textMuted(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: AppColors.textMuted(context),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
