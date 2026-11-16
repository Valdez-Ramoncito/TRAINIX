import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/models/simulation_phase.dart';
import 'package:trainixprogram/models/trainix_debug.dart';
import 'package:trainixprogram/models/training/training_categories.dart';
import 'package:trainixprogram/providers/simulation_provider.dart';
import 'package:trainixprogram/screens/page/mini_training.dart';
import 'package:trainixprogram/widgets/onboarding_intro_banner.dart';

class SessionLobby extends StatefulWidget {
  final SimulationMode mode;
  final void Function(
    String? chosenSector,
    int? customerQuota,
    bool guidedMode,
  )
  onStart;
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
  bool _guidedMode = true;
  bool _starting = false;

  static const _accent = Color(0xFF70BD8A);
  static const _accentBlue = Color(0xFF3B82F6);
  static const _accentPurple = Color(0xFFA78BFA);
  static const _cardBg = Color(0xFF151515);
  static const _border = Color(0xFF2A2A2B);

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

  Color get _modeColor {
    switch (widget.mode) {
      case SimulationMode.chat:
        return _accentBlue;
      case SimulationMode.voice:
        return _accent;
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
    widget.onStart(sector, _selectedQuota, _guidedMode);
  }

  IconData _sectorIcon(String label) {
    switch (label.toLowerCase()) {
      case 'random':
        return Icons.shuffle_rounded;
      case 'finance':
        return Icons.account_balance_rounded;
      case 'healthcare':
        return Icons.local_hospital_outlined;
      case 'telco':
        return Icons.signal_cellular_alt_rounded;
      case 'tech support':
        return Icons.support_agent_rounded;
      default:
        return Icons.apartment_rounded;
    }
  }

  Widget _optionChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
    Color? selectedColor,
  }) {
    final color = selectedColor ?? _accent;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.16)
                : const Color(0xFF1C1C1C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color.withValues(alpha: 0.7) : _border,
              width: selected ? 1.2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: selected ? color : const Color(0xFF9CA3AF),
                ),
                const Gap(6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const Gap(10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = _unlocked;
    final canStart = unlocked && (_useRandom || _selectedSector != null);
    final modeColor = _modeColor;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: modeColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: modeColor.withValues(alpha: 0.4)),
                ),
                child: Icon(
                  _icon,
                  size: 22,
                  color: unlocked ? modeColor : const Color(0xFF9CA3AF),
                ),
              ),
              const Gap(14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: unlocked ? Colors.white : const Color(0xFF9CA3AF),
                      ),
                    ),
                    const Gap(4),
                    Text(
                      unlocked ? _description : _lockHint,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!unlocked) ...[
            const Gap(14),
            LockedPathBanner(
              message:
                  'This mode stays locked until the matching Scenario Practice stage is cleared in Mini Training.',
              actionLabel: 'Go to Scenario Practice',
              onAction: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MiniTraining()),
                );
              },
            ),
          ],
          const Gap(22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: unlocked
                    ? modeColor.withValues(alpha: 0.35)
                    : _border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!unlocked)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1C),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _border),
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
                _sectionHeader(
                  Icons.apartment_rounded,
                  'Sector',
                  modeColor,
                ),
                const Gap(12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _optionChip(
                      label: 'Random',
                      icon: Icons.shuffle_rounded,
                      selected: _useRandom,
                      selectedColor: modeColor,
                      onTap: () => setState(() {
                        _useRandom = true;
                        _selectedSector = null;
                      }),
                    ),
                    ...SimulationProvider.allSectors.map((s) {
                      return _optionChip(
                        label: s,
                        icon: _sectorIcon(s),
                        selected: !_useRandom && _selectedSector == s,
                        selectedColor: modeColor,
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
                    color: Color(0xFF94A3B8),
                    height: 1.35,
                  ),
                ),
                const Gap(22),
                _sectionHeader(
                  Icons.groups_outlined,
                  'Customer quota',
                  _accentPurple,
                ),
                const Gap(12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _optionChip(
                      label: 'Random (3-5)',
                      icon: Icons.casino_outlined,
                      selected: _selectedQuota == null,
                      selectedColor: _accentPurple,
                      onTap: () => setState(() => _selectedQuota = null),
                    ),
                    ...[1, 3, 4, 5].map(
                      (n) => _optionChip(
                        label: n == 1 ? '1 customer' : '$n customers',
                        icon: Icons.person_outline_rounded,
                        selected: _selectedQuota == n,
                        selectedColor: _accentPurple,
                        onTap: () => setState(() => _selectedQuota = n),
                      ),
                    ),
                  ],
                ),
                const Gap(8),
                Text(
                  _selectedQuota == null
                      ? 'This run will include a random number of customers between 3 and 5.'
                      : _selectedQuota == 1
                      ? 'This run will include exactly 1 customer.'
                      : 'This run will include exactly $_selectedQuota customers.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    height: 1.35,
                  ),
                ),
                const Gap(22),
                _sectionHeader(
                  Icons.menu_book_outlined,
                  'Guidance',
                  _accentBlue,
                ),
                const Gap(12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _optionChip(
                      label: 'Guided',
                      icon: Icons.menu_book_outlined,
                      selected: _guidedMode,
                      selectedColor: _accentBlue,
                      onTap: () => setState(() => _guidedMode = true),
                    ),
                    _optionChip(
                      label: 'Unguided',
                      icon: Icons.school_outlined,
                      selected: !_guidedMode,
                      selectedColor: _accentPurple,
                      onTap: () => setState(() => _guidedMode = false),
                    ),
                  ],
                ),
                const Gap(8),
                Text(
                  _guidedMode
                      ? 'Script Guide, tips, and step examples stay available. Best for practice and learning.'
                      : 'No Script Guide, tips, or step examples. Real call-center style assessment with scoring still on.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    height: 1.35,
                  ),
                ),
                const Gap(22),
                if (unlocked) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: modeColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: modeColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: modeColor,
                        ),
                        const Gap(10),
                        const Expanded(
                          child: Text(
                            'Pick a sector, customer quota, and guidance mode, then start. After the run you will see a score report. Modes unlock from Scenario Practice in Mini Training.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFCBD5E1),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(18),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: MouseRegion(
                      cursor: canStart && !_starting
                          ? SystemMouseCursors.click
                          : SystemMouseCursors.basic,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          mouseCursor: canStart && !_starting
                              ? SystemMouseCursors.click
                              : SystemMouseCursors.basic,
                          onTap: canStart && !_starting ? _start : null,
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 13,
                            ),
                            decoration: BoxDecoration(
                              color: canStart && !_starting
                                  ? modeColor
                                  : const Color(0xFF2A2A2B),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _starting
                                      ? Icons.hourglass_top_rounded
                                      : Icons.play_arrow_rounded,
                                  size: 20,
                                  color: canStart && !_starting
                                      ? const Color(0xFF0B1A12)
                                      : const Color(0xFF6B7280),
                                ),
                                const Gap(8),
                                Text(
                                  _starting ? 'Starting...' : 'Start Session',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: canStart && !_starting
                                        ? const Color(0xFF0B1A12)
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                if (TrainixDebug.unlocked && widget.onDebugUnlock != null) ...[
                  const Gap(16),
                  TextButton.icon(
                    onPressed: widget.onDebugUnlock,
                    icon: const Icon(Icons.lock_open_rounded, size: 16),
                    label: const Text('DEBUG: Unlock this mode'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
