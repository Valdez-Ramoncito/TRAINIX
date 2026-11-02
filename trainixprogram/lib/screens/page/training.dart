import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainixprogram/models/simulation_phase.dart';
import 'package:trainixprogram/models/training/training_categories.dart';
import 'package:trainixprogram/providers/simulation_provider.dart';
import 'package:trainixprogram/screens/mock_call_screen.dart';
import 'package:trainixprogram/screens/session_report_screen.dart';
import 'package:trainixprogram/screens/page/components/mini_training/training_notification_banner.dart';
import 'package:trainixprogram/screens/page/components/training/content/history/session_history_list.dart';
import 'package:trainixprogram/screens/page/components/training/content/session/session_lobby.dart';
import 'package:trainixprogram/screens/page/components/training/header.dart';
import 'package:trainixprogram/screens/page/components/training/left_menu.dart';
import 'package:trainixprogram/screens/page/components/training/right_toolbar.dart';
import 'package:trainixprogram/widgets/next_step_banner.dart';

class TrainingSession extends StatefulWidget {
  const TrainingSession({super.key});

  @override
  State<TrainingSession> createState() => _TrainingSessionState();
}

class _TrainingSessionState extends State<TrainingSession> {
  int _selectedMenuIndex = 0;

  bool _isUnlocked(SimulationMode mode) {
    switch (mode) {
      case SimulationMode.chat:
        return MiniTrainingProgress.isChatSessionUnlocked;
      case SimulationMode.voice:
        return MiniTrainingProgress.isVoiceSessionUnlocked;
      case SimulationMode.hybrid:
        return MiniTrainingProgress.isHybridSessionUnlocked;
    }
  }

  int _lobbyEpoch = 0;

  Future<void> _startSession(
    SimulationMode mode, {
    String? chosenSector,
    int? customerQuota,
  }) async {
    if (!_isUnlocked(mode)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This session type is still locked.')),
      );
      return;
    }

    final provider = Provider.of<SimulationProvider>(context, listen: false);
    final sector = chosenSector != null
        ? provider.selectSector(chosenSector)
        : provider.pickNextSector();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MockCallScreen(
          sector: sector,
          mode: mode,
          customerQuota: customerQuota,
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _lobbyEpoch++);
  }

  void _onSelectFromPlus(int index) {
    final mode = switch (index) {
      0 => SimulationMode.voice,
      1 => SimulationMode.chat,
      _ => SimulationMode.chat,
    };
    _startSession(mode);
  }

  void _debugUnlock(SimulationMode mode) {
    switch (mode) {
      case SimulationMode.chat:
        MiniTrainingProgress.debugUnlockChatSession();
      case SimulationMode.voice:
        MiniTrainingProgress.debugUnlockVoiceSession();
      case SimulationMode.hybrid:
        MiniTrainingProgress.debugUnlockHybridSession();
    }
    setState(() {});
  }

  Widget _buildMainContent() {
    switch (_selectedMenuIndex) {
      case 0:
        return SessionLobby(
          key: ValueKey('lobby_chat_$_lobbyEpoch'),
          mode: SimulationMode.chat,
          onStart: (sector, quota) => _startSession(
            SimulationMode.chat,
            chosenSector: sector,
            customerQuota: quota,
          ),
          onDebugUnlock: () => _debugUnlock(SimulationMode.chat),
        );
      case 1:
        return SessionLobby(
          key: ValueKey('lobby_voice_$_lobbyEpoch'),
          mode: SimulationMode.voice,
          onStart: (sector, quota) => _startSession(
            SimulationMode.voice,
            chosenSector: sector,
            customerQuota: quota,
          ),
          onDebugUnlock: () => _debugUnlock(SimulationMode.voice),
        );
      case 2:
        return const SessionHistoryList(modeFilter: SimulationMode.chat);
      case 3:
        return const SessionHistoryList(modeFilter: SimulationMode.voice);
      case 4:
        return const SessionHistoryList();
      case 5:
        return const MessagesArchiveList();
      default:
        return SessionLobby(
          key: ValueKey('lobby_default_$_lobbyEpoch'),
          mode: SimulationMode.chat,
          onStart: (sector, quota) => _startSession(
            SimulationMode.chat,
            chosenSector: sector,
            customerQuota: quota,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TrainingNotificationHost(
      child: Scaffold(
        body: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 14),
              child: Header(),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(30, 0, 30, 10),
              child: NextStepBanner(
                screen: TraineeNextStepScreen.trainingSession,
                showSkipGuide: true,
              ),
            ),
            const Divider(
              height: .5,
              thickness: .3,
              color: Color.fromARGB(255, 105, 106, 106),
            ),
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                    width: 230,
                    child: LeftMenu(
                      selectedIndex: _selectedMenuIndex,
                      onMenuSelected: (index) {
                        setState(() => _selectedMenuIndex = index);
                      },
                    ),
                  ),
                  const VerticalDivider(
                    width: .5,
                    thickness: .3,
                    color: Color.fromARGB(255, 105, 106, 106),
                  ),
                  Expanded(
                    child: KeyedSubtree(
                      key: ValueKey(_selectedMenuIndex),
                      child: _buildMainContent(),
                    ),
                  ),
                  const VerticalDivider(
                    width: .5,
                    thickness: .3,
                    color: Color.fromARGB(255, 105, 106, 106),
                  ),
                  SizedBox(
                    width: 100,
                    child: RightToolbar(onSelectSessionType: _onSelectFromPlus),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
