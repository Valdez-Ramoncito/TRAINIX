import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/components/decoration/box_decoration.dart';
import 'package:trainixprogram/models/simulation_phase.dart';
import 'package:trainixprogram/models/trainix_debug.dart';
import 'package:trainixprogram/models/training/training_categories.dart';
import 'package:trainixprogram/providers/simulation_provider.dart';
import 'package:trainixprogram/screens/page/mini_training.dart';
import 'package:trainixprogram/widgets/onboarding_intro_banner.dart';

class SessionLobby extends StatefulWidget {
  final SimulationMode mode;
  final void Function(String? chosenSector, int? customerQuota) onStart;
  final VoidCallback? onDebugUnlock;

  const SessionLobby({
    super.key,
    required this.mode,
    required this.onStart,
    this.onDebugUnlock,
  });

  @override
  State<SessionLobby> createState() => _SessionLobbyState();
}

class _SessionLobbyState extends State<SessionLobby> {
  bool _useRandom = true;
  String? _selectedSector;
  int? _selectedQuota;
  bool _starting = false;

  @override
  void activate() {
    super.activate();
    if (_starting) {
      setState(() => _starting = false);
    }
  }

  String get _title {
    switch (widget.mode) {
      case SimulationMode.chat:
        return 'Non-Voice Session';
      case SimulationMode.voice:
        return 'Voice Session';
    }
  }

  String get _description {
    switch (widget.mode) {
      case SimulationMode.chat:
        return 'Practice text customer handling with AI customers.';
      case SimulationMode.voice:
        return 'Practice live voice calls with AI customers.';
    }
  }

  IconData get _icon {
    switch (widget.mode) {
      case SimulationMode.chat:
        return Icons.chat_bubble_outline_rounded;
      case SimulationMode.voice:
        return Icons.phone_in_talk_outlined;
    }
  }

  bool get _unlocked {
    switch (widget.mode) {
      case SimulationMode.chat:
        return MiniTrainingProgress.isChatSessionUnlocked;
      case SimulationMode.voice:
        return MiniTrainingProgress.isVoiceSessionUnlocked;
    }
  }

  String get _lockHint {
    switch (widget.mode) {
      case SimulationMode.chat:
        return 'Clear Chat Scenario Practice first.';
      case SimulationMode.voice:
        return 'Clear Voice Scenario Practice first.';
    }
  }

  void _start() {
    if (!_unlocked || _starting) return;
    final sector = _useRandom ? null : _selectedSector;
    if (!_useRandom && sector == null) return;
    setState(() => _starting = true);
    widget.onStart(sector, _selectedQuota);
  }

  Widget _sectorChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? const Color.fromARGB(255, 12, 67, 30)
                : const Color.fromARGB(180, 21, 21, 21),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? const Color.fromARGB(255, 112, 189, 138)
                  : const Color.fromARGB(255, 49, 48, 48),
              width: 0.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : const Color(0xFF9CA3AF),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = _unlocked;
    final canStart = unlocked && (_useRandom || _selectedSector != null);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _icon,
                size: 26,
                color: unlocked ? Colors.white : const Color(0xFF9CA3AF),
              ),
              const Gap(12),
              Text(
                _title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: unlocked ? Colors.white : const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          const Gap(8),
          Text(
            unlocked ? _description : _lockHint,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          if (!unlocked) ...[
            const Gap(12),
            LockedPathBanner(
              message:
                  'This mode stays locked until the matching Scenario Practice stage is cleared in Mini Training.',
              actionLabel: 'Go to Scenario Practice',
              onAction: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const MiniTraining()));
              },
            ),
          ],
          const Gap(22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: boxDecoration(false, unlocked),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!unlocked)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF333333)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.lock_rounded,
                          size: 16,
                          color: Color(0xFF9CA3AF),
                        ),
                        Gap(8),
                        Expanded(
                          child: Text(
                            'Locked until the matching Scenario Practice stage is cleared.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF9CA3AF),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const Text(
                  'Sector',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                const Gap(10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _sectorChip(
                      label: 'Random',
                      selected: _useRandom,
                      onTap: () => setState(() {
                        _useRandom = true;
                        _selectedSector = null;
                      }),
                    ),
                    ...SimulationProvider.allSectors.map((s) {
                      return _sectorChip(
                        label: s,
                        selected: !_useRandom && _selectedSector == s,
                        onTap: () => setState(() {
                          _useRandom = false;
                          _selectedSector = s;
                        }),
                      );
                    }),
                  ],
                ),
                const Gap(8),
                Text(
                  _useRandom
                      ? 'A sector will be chosen for you. Specific picks still update the random cycle so repeats stay uncommon.'
                      : 'This sector will be used. You can switch back to Random anytime.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                    height: 1.35,
                  ),
                ),
                const Gap(22),
                const Text(
                  'Customer quota',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const Gap(10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _sectorChip(
                      label: 'Random (3-5)',
                      selected: _selectedQuota == null,
                      onTap: () => setState(() => _selectedQuota = null),
                    ),
                    ...[3, 4, 5].map(
                      (n) => _sectorChip(
                        label: '$n customers',
                        selected: _selectedQuota == n,
                        onTap: () => setState(() => _selectedQuota = n),
                      ),
                    ),
                  ],
                ),
                const Gap(8),
                Text(
                  _selectedQuota == null
                      ? 'This run will include a random number of customers between 3 and 5.'
                      : 'This run will include exactly $_selectedQuota customers.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                    height: 1.35,
                  ),
                ),
                const Gap(22),
                if (unlocked) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1F26),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF70BD8A).withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Text(
                      'Pick a sector and how many customers, then start. After the run you will see a score report. Modes unlock from Scenario Practice in Mini Training.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                        height: 1.35,
                      ),
                    ),
                  ),
                  const Gap(16),
                ],
                Row(
                  children: [
                    MouseRegion(
                      cursor: canStart && !_starting
                          ? SystemMouseCursors.click
                          : SystemMouseCursors.basic,
                      child: ElevatedButton.icon(
                        onPressed: canStart && !_starting ? _start : null,
                        icon: _starting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white70,
                                ),
                              )
                            : const Icon(Icons.play_arrow_rounded, size: 20),
                        label: Text(
                          _starting ? 'Starting...' : 'Start Session',
                        ),
                        style:
                            ElevatedButton.styleFrom(
                              backgroundColor: canStart
                                  ? const Color.fromARGB(255, 12, 67, 30)
                                  : null,
                              foregroundColor: Colors.white,
                              disabledForegroundColor: const Color(0xFF6B7280),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                            ).copyWith(
                              mouseCursor: WidgetStatePropertyAll(
                                canStart && !_starting
                                    ? SystemMouseCursors.click
                                    : SystemMouseCursors.basic,
                              ),
                            ),
                      ),
                    ),
                    if (TrainixDebug.unlocked &&
                        widget.onDebugUnlock != null) ...[
                      const Gap(12),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: OutlinedButton(
                          onPressed: widget.onDebugUnlock,
                          child: const Text('DEBUG: Unlock'),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
