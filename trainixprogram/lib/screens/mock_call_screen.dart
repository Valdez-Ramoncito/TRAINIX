import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainixprogram/models/session_score.dart';
import 'package:trainixprogram/models/customer_account.dart';
import 'package:trainixprogram/models/messages.dart';
import 'package:trainixprogram/models/simulation_history.dart';
import 'package:trainixprogram/models/simulation_phase.dart';
import 'package:trainixprogram/models/training/training_categories.dart';
import 'package:trainixprogram/screens/session_report_screen.dart';
import 'package:trainixprogram/screens/mock_call_ui/header.dart';
import 'package:trainixprogram/widgets/chat_panel.dart';
import 'package:trainixprogram/widgets/voice_panel.dart';
import 'package:trainixprogram/widgets/agent_notepad.dart';
import 'package:trainixprogram/models/trainix_debug.dart';
import 'package:trainixprogram/screens/settings_screen.dart';

//simulates a call-center workstation with two simultaneous channels
//Voice and Call channels
//both channels receive the same sector
class MockCallScreen extends StatefulWidget {
  final String sector;
  final SimulationMode mode;
  final int? customerQuota;

  const MockCallScreen({
    super.key,
    required this.sector,
    this.mode = SimulationMode.chat,
    this.customerQuota,
  });

  @override
  State<MockCallScreen> createState() => _MockCallScreenState();
}

class _MockCallScreenState extends State<MockCallScreen> {
  //set the simulation phase to be incoming at the start
  SimulationPhase _phase = SimulationPhase.incoming;

  //how many full calls were done
  int _completedInteractions = 0;

  //the quota to reach
  late final int _requiredInteractions;

  // Scoped once per screen so rebuilds do not recreate ChatPanel/VoicePanel
  // state or re-run mission.start.
  late final MessageProvider _chatMessages;
  late final AccountProvider _chatAccounts;
  late final MessageProvider _voiceMessages;
  late final AccountProvider _voiceAccounts;

  //the call timer (isolated notifier so ticks do not rebuild the full screen)
  final ValueNotifier<int> _elapsedSeconds = ValueNotifier<int>(0);

  //the time ticker for call timer
  Timer? _callTimer;

  //list of all session evaluations
  final List<SessionEvaluation> _sessionEvaluations = [];

  //list of all words per minute in voice calls
  final List<double> _voiceWpmSamples = [];

  //list of all words per minute in chat conversations
  final List<double> _chatWpmSamples = [];

  //how many fillers were used in a voice call
  int _voiceFillerCount = 0;

  //how long did it take for each customer in each channel got
  //their problems resolved

  //check if the session ended
  bool _sessionEnding = false;
  bool _sessionFinished = false;

  //whether each channel currently has a customer whose resolution
  //hasn't been counted into _completedInteractions yet
  bool _voiceHasActiveCustomer = false;
  bool _chatHasActiveCustomer = false;

  //whether chat is currently in its own after-work-report or grace-period
  //flow. Mirrors _voiceCallInProgress below, so the session can't kick
  //the trainee away from chat's own manual reporting step either
  bool _chatInProgress = false;

  // Session attentiveness: tools, guides, notes, and follow-through.
  double? get _multitaskingScore {
    if (_completedInteractions <= 0 &&
        !_chatInProgress &&
        !_voiceCallInProgress) {
      return null;
    }
    var points = 0.0;
    var maxPoints = 0.0;

    void add(bool hit, [double weight = 1]) {
      maxPoints += weight;
      if (hit) points += weight;
    }

    final chatId = _chatAccounts.identityVerified;
    final chatTool = _chatAccounts.toolWorkDone;
    final voiceId = _voiceAccounts.identityVerified;
    final voiceTool = _voiceAccounts.toolWorkDone;
    final notesUsed = SessionNotesStore.notes.any(
      (n) => n.body.trim().isNotEmpty,
    );

    if (widget.mode == SimulationMode.chat) {
      add(chatId, 1.5);
      add(chatTool, 2);
    }
    if (widget.mode == SimulationMode.voice) {
      add(voiceId, 1.5);
      add(voiceTool, 2);
    }
    if (_completedInteractions > 0) {
      add(true, 1);
    }
    // Notes are a small bonus only.
    if (notesUsed) {
      points += 0.5;
      maxPoints += 0.5;
    }

    if (maxPoints <= 0) return null;
    return ((points / maxPoints) * 100).clamp(0, 100);
  }

  //at the start, set the required calls to a minimum of 3
  //with a set maximum of random
  @override
  void initState() {
    super.initState();
    SessionNotesStore.resetForSession();
    _requiredInteractions = widget.customerQuota ?? (Random().nextInt(3) + 3);
    _chatMessages = MessageProvider();
    _chatAccounts = AccountProvider();
    _voiceMessages = MessageProvider();
    _voiceAccounts = AccountProvider();
    TrainixDebug.instance.addListener(_onDebugChanged);
  }

  void _onDebugChanged() {
    if (mounted) setState(() {});
  }

  Widget _constrainWide(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth > 1680
            ? 1680.0
            : constraints.maxWidth;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: maxW, child: child),
        );
      },
    );
  }

  @override
  void dispose() {
    TrainixDebug.instance.removeListener(_onDebugChanged);
    _callTimer?.cancel();
    _postCallBreakTimer?.cancel();
    _elapsedSeconds.dispose();
    _chatMessages.dispose();
    _chatAccounts.dispose();
    _voiceMessages.dispose();
    _voiceAccounts.dispose();
    SessionNotesStore.resetForSession();
    super.dispose();
  }

  //try to start a new interaction on the given channel
  //a channel may start a new customer only if doing
  //so, on top of whatever's already completed AND whatever the OTHER
  //channel is already actively serving, wouldn't push the total past
  //the required quota.
  bool _tryStartNewInteraction(String channel) {
    if (_sessionEnding) return false;

    final otherChannelOccupied = channel == 'voice'
        ? _chatHasActiveCustomer
        : _voiceHasActiveCustomer;
    final otherOccupiedCount = otherChannelOccupied ? 1 : 0;

    //completed so far, plus the other channel's in-flight customer, if there's
    //any, plus the one this channel is about to start. Does that
    //exceed the quota?
    if (_completedInteractions + otherOccupiedCount + 1 >
        _requiredInteractions) {
      return false;
    }

    //claim this channel's slot
    if (channel == 'voice') {
      _voiceHasActiveCustomer = true;
    } else {
      _chatHasActiveCustomer = true;
    }
    return true;
  }

  //handle the evaluation
  void _handleEvaluation(String channel, SessionEvaluation e) {
    setState(() {
      final rated = e.withDerivedCustomerRating();
      _sessionEvaluations.add(rated);
      //increase the completed interactions
      _completedInteractions++;
      //this channel's customer is now counted  free its occupancy
      //slot so the other channel's quota check sees accurate state
      if (channel == 'voice') {
        _voiceHasActiveCustomer = false;
      } else {
        _chatHasActiveCustomer = false;
      }
      //if it has reached the required interactions
      //set the session ending to true
      if (_completedInteractions >= _requiredInteractions) {
        _sessionEnding = true;
      }
    });
    //if the session is ending but neither channel is still actively
    //wrapping up its own call or chat, then finish the session
    if (_sessionEnding && !_voiceCallInProgress && !_chatInProgress) {
      _finishSession();
    }
  }

  //tells the parent chat has started serving a customer
  void _handleChatCustomerStarted() {
    setState(() => _chatHasActiveCustomer = true);
  }

  //called whenever chat enters or leaves its own after-work-report or
  //grace-period flow. Re-checks whether the session can finish now
  //that chat just became idle, the same way voice's postCallBreak does
  void _handleChatBusyChanged(bool busy) {
    setState(() => _chatInProgress = busy);
    if (!busy && _sessionEnding && !_voiceCallInProgress) {
      if (_phase != SimulationPhase.wrappingUp) {
        setState(() => _phase = SimulationPhase.wrappingUp);
      }
      // Chat already delayed onBusyChanged for last-customer wrap-up dwell.
      _finishSession();
    }
  }

  //finishes the session
  void _finishSession() {
    //do nothing if its already finished
    if (_sessionFinished) return;
    //set it to true if its not
    _sessionFinished = true;

    //then initialize the history provider
    final historyProvider = Provider.of<SimulationHistoryProvider>(
      context,
      listen: false,
    );

    //get the multitasking score
    final finalMultitaskingScore = _multitaskingScore;

    //if the multitasking score is not null
    //then save the multitasking score
    if (finalMultitaskingScore != null) {
      historyProvider.saveMultitaskingScore(finalMultitaskingScore);
    }

    //record this whole play-through as one grouped session
    //this is what Session History / Score Trend / Total Sessions read from, so
    //a session with 3 resolved customers shows as 1 session there, not 3
    historyProvider.saveSession(
      evaluations: List.from(_sessionEvaluations),
      multitaskingScore: finalMultitaskingScore,
      mode: widget.mode,
    );
    MiniTrainingProgress.markSimulationSessionCompleted();

    //send the needed data then move to session report screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SessionReportScreen(
          evaluations: _sessionEvaluations,
          averageWpm: _voiceWpmSamples.isEmpty
              ? null
              : _voiceWpmSamples.reduce((a, b) => a + b) /
                    _voiceWpmSamples.length,
          fillerWordCount: _voiceFillerCount,
          averageTypingWpm: _chatWpmSamples.isEmpty
              ? null
              : _chatWpmSamples.reduce((a, b) => a + b) /
                    _chatWpmSamples.length,
          multitaskingScore: finalMultitaskingScore,
        ),
      ),
    );
  }

  //TEMPORARY DEBUG SHORTCUT
  void _debugFinishSimulation() {
    final random = Random();

    //stop any timers currently running so nothing keeps ticking
    //in the background after we navigate away
    _stopCallTimer();
    _postCallBreakTimer?.cancel();

    double randScore() => (4.0 + random.nextDouble() * 6.0).clamp(0, 10);

    SessionEvaluation buildRandomEval(String channel, String name) {
      final scores = List<double>.generate(10, (_) => randScore());
      final overall = scores.reduce((a, b) => a + b) / scores.length;
      return SessionEvaluation(
        sector: widget.sector,
        openingSpielScore: scores[0],
        positiveScriptingScore: scores[1],
        empathyScore: scores[2],
        activeListeningScore: scores[3],
        problemIdentificationScore: scores[4],
        solutionDeliveryScore: scores[5],
        communicationClarityScore: scores[6],
        toneScore: scores[7],
        sectorKnowledgeScore: scores[8],
        closingSpielScore: scores[9],
        overallScore: double.parse(overall.toStringAsFixed(1)),
        typingSpeedScore: channel == 'chat'
            ? 6.0 + random.nextDouble() * 3
            : null,
        errorRateAccuracyScore: channel == 'chat'
            ? 6.0 + random.nextDouble() * 3
            : null,
        responseConsistencyScore: channel == 'chat'
            ? 6.0 + random.nextDouble() * 3
            : null,
        paceAndSpeedScore: channel == 'voice'
            ? 6.0 + random.nextDouble() * 3
            : null,
        pronunciationClarityScore: channel == 'voice'
            ? 6.0 + random.nextDouble() * 3
            : null,
        fillerWordUsageScore: channel == 'voice'
            ? 6.0 + random.nextDouble() * 3
            : null,
        categoryNotes: {
          'Opening Spiel':
              'Practice greeting, agent and company ID, and a clear purpose for this channel.',
          'Positive Scripting':
              'Professional, constructive phrasing aligned with basic customer support standards.',
          'Empathy':
              'Acknowledgment of the customer feeling before process or policy talk.',
          'Active Listening':
              'Confirms understanding of stated details rather than generic replies.',
          'Problem Identification':
              'Whether the core issue was identified accurately before solution steps.',
          'Solution Delivery':
              'Clarity of actions or next steps and fit to the case type.',
          'Communication Clarity':
              'Plain language and structured explanations for the customer.',
          'Tone':
              'Calm, professional tone consistent with call center quality expectations.',
          'Sector Knowledge':
              'Sector-appropriate checks and policy-safe guidance for the assigned industry scenario.',
          'Closing Spiel':
              'Close with outcome summary, confirmation, offer of further help, and a polite end.',
        },
        categoryQuotes: {
          'Opening Spiel':
              'Thank you for contacting support. I can help with that.',
          'Empathy': 'I understand this has been difficult and I will help.',
          'Problem Identification': 'Hi, I need help with a sample issue.',
          'Closing Spiel':
              'Is there anything else I can assist you with today?',
        },
        strengths: [
          'Opening and structure follow expected call center greeting practice.',
          'Conversation history retained for review without re-transcription.',
        ],
        areasForImprovement: [
          'Run a live session for grounded coaching feedback.',
          'Practice sector-specific verification and closing confirmation.',
        ],
        feedback:
            'Practice report for layout checks. Scores are sample values only and are not used for hiring decisions.',
        evaluatedAt: DateTime.now(),
        customerName: name,
        channel: channel,
        problem: 'Sample practice problem',
        conversation: [
          {'role': 'customer', 'text': 'Hi, I need help with a sample issue.'},
          {
            'role': 'agent',
            'text': 'Thank you for contacting support. I can help with that.',
          },
          {'role': 'customer', 'text': 'Thanks, that helps.'},
        ],
      );
    }

    final channel = widget.mode == SimulationMode.voice ? 'voice' : 'chat';
    final fakeEvaluations = [
      buildRandomEval(channel, 'Practice Customer A'),
      buildRandomEval(channel, 'Practice Customer B'),
    ].map((e) => e.withDerivedCustomerRating()).toList();
    final fakeMultitasking = 40.0 + random.nextDouble() * 60.0;
    final fakeAvgWpm = 100.0 + random.nextDouble() * 60.0;
    final fakeFillerWords = random.nextInt(10);
    final fakeAvgTypingWpm = 25.0 + random.nextDouble() * 30.0;

    final historyProvider = Provider.of<SimulationHistoryProvider>(
      context,
      listen: false,
    );
    //save each fake evaluation into the flat evaluations list too
    for (final e in fakeEvaluations) {
      historyProvider.saveEvaluation(e);
    }
    historyProvider.saveMultitaskingScore(fakeMultitasking);
    //record this as one grouped session too, same as a real completed
    //run  so it shows up correctly in Session History / Score Trend
    historyProvider.saveSession(
      evaluations: fakeEvaluations,
      multitaskingScore: fakeMultitasking,
      mode: widget.mode,
    );
    MiniTrainingProgress.markSimulationSessionCompleted();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SessionReportScreen(
          evaluations: fakeEvaluations,
          averageWpm: fakeAvgWpm,
          fillerWordCount: fakeFillerWords,
          averageTypingWpm: fakeAvgTypingWpm,
          multitaskingScore: fakeMultitasking,
        ),
      ),
    );
  }

  //start the timer
  void _startCallTimer() {
    //if theres a timer already running, cancel it
    _callTimer?.cancel();

    //start the timer
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds.value++;
    });
  }

  //stop the timer
  void _stopCallTimer() {
    _callTimer?.cancel();
    _callTimer = null;
  }

  //format the timer display
  String _formatElapsed(int seconds) {
    //get the hours, minutes, and seconds
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;

    //return the formatted time
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  //get the phase of the voice call
  bool get _voiceCallInProgress =>
      _phase == SimulationPhase.active ||
      _phase == SimulationPhase.onHold ||
      _phase == SimulationPhase.afterCallWork ||
      _phase == SimulationPhase.postCallBreak;

  //when a call ends
  void _onEndCall() {
    //stop the timer
    _stopCallTimer();

    //Also clears voice's quota-occupancy flag here as a safety net
    //covering the case where a call ends without ever being resolved
    _voiceHasActiveCustomer = false;

    setState(() {
      _elapsedSeconds.value = 0;
      //then set the phase to after call
      _phase = SimulationPhase.afterCallWork;
    });
  }

  //after call work
  //grace period for voice channel
  static const int _postCallBreakMinSeconds = 5;
  static const int _postCallBreakMaxSeconds = 12;
  Timer? _postCallBreakTimer;
  int _remainingPostCallSeconds = 0;

  //after sending a report, start the grace period
  void _onSendReport() {
    // Last customer: go to session wrap-up, then finish after a short dwell.
    if (_sessionEnding || _completedInteractions >= _requiredInteractions) {
      _sessionEnding = true;
      setState(() => _phase = SimulationPhase.wrappingUp);
      if (!_chatInProgress && !_voiceCallInProgress) {
        Future.delayed(const Duration(seconds: 4), () {
          if (!mounted) return;
          if (_phase == SimulationPhase.wrappingUp) {
            _finishSession();
          }
        });
      }
      return;
    }

    final seconds =
        _postCallBreakMinSeconds +
        Random().nextInt(
          _postCallBreakMaxSeconds - _postCallBreakMinSeconds + 1,
        );

    setState(() {
      _phase = SimulationPhase.postCallBreak;
      _remainingPostCallSeconds = seconds;
    });

    _postCallBreakTimer?.cancel();

    _postCallBreakTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _remainingPostCallSeconds--;

        if (_remainingPostCallSeconds <= 0) {
          timer.cancel();
          _resolvePostCallBreak();
        }
      });
    });
  }

  //if the timer ends for grace period, do this
  void _resolvePostCallBreak() {
    if (_sessionEnding) {
      //don't finish or start a new call while chat is still in its
      //own after-work-report or grace-period flow
      if (_chatInProgress) {
        setState(() => _phase = SimulationPhase.wrappingUp);
      } else {
        _finishSession();
      }
      return;
    }
    //try to start a new interaction
    //if it returns true, make the phase incoming
    //else, wrap it up
    setState(() {
      _phase = _tryStartNewInteraction('voice')
          ? SimulationPhase.incoming
          : SimulationPhase.wrappingUp;
    });
  }

  Widget _buildVoicePanel() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MessageProvider>.value(value: _voiceMessages),
        ChangeNotifierProvider<AccountProvider>.value(value: _voiceAccounts),
      ],
      child: VoicePanel(
        key: const ValueKey('sim-voice-panel'),
        phase: _phase,
        sector: widget.sector,
        remainingBreakSeconds: _remainingPostCallSeconds,
        showScriptGuide: true,
        scriptGuideExpanded: AppSettings.autoScriptGuideExpanded,
        onAccept: () {
          _startCallTimer();
          setState(() {
            _phase = SimulationPhase.active;
            _voiceHasActiveCustomer = true;
          });
        },
        onEvaluation: (e) => _handleEvaluation('voice', e),
        onVoiceTurn: (wpm, fillerCount) {
          _voiceWpmSamples.add(wpm);
          _voiceFillerCount += fillerCount;
        },
        onResolutionSeconds: null,
        onSendReport: _onSendReport,
      ),
    );
  }

  Widget _buildChatPanel() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MessageProvider>.value(value: _chatMessages),
        ChangeNotifierProvider<AccountProvider>.value(value: _chatAccounts),
      ],
      child: ChatPanel(
        key: const ValueKey('sim-chat-panel'),
        sector: widget.sector,
        scriptGuideExpanded: AppSettings.autoScriptGuideExpanded,
        onEvaluation: (e) => _handleEvaluation('chat', e),
        onChatTurn: (wpm) => _chatWpmSamples.add(wpm),
        onResolutionSeconds: null,
        canStartNewCustomer: () => _tryStartNewInteraction('chat'),
        onBusyChanged: _handleChatBusyChanged,
        onCustomerStarted: _handleChatCustomerStarted,
      ),
    );
  }

  Widget _buildVoiceBottomBar(bool isOnHold, bool callInProgress) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color.fromARGB(255, 105, 106, 106), width: .3),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBottomButton(
              isOnHold ? 'RESUME' : 'HOLD',
              isOnHold ? Icons.play_arrow : Icons.pause,
              enabled: callInProgress,
              onTap: () {
                setState(() {
                  _phase = isOnHold
                      ? SimulationPhase.active
                      : SimulationPhase.onHold;
                });
              },
            ),
            _buildTimerDisplay(),
            _buildBottomButton(
              'END CALL',
              Icons.call_end,
              isEndCall: true,
              enabled: callInProgress,
              onTap: _onEndCall,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = _phase == SimulationPhase.active;
    final bool isOnHold = _phase == SimulationPhase.onHold;
    final bool callInProgress = isActive || isOnHold;
    final mode = widget.mode;
    final showVoice = mode == SimulationMode.voice;
    final showChat = mode == SimulationMode.chat;

    return Scaffold(
      body: _constrainWide(
        Column(
          children: [
            Header(
              sector: widget.sector,
              mode: widget.mode,
              completedInteractions: _completedInteractions,
              requiredInteractions: _requiredInteractions,
              onDebugFinish: _debugFinishSimulation,
              onOpenSettings: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showVoice)
                    Expanded(
                      flex: showChat ? 46 : 100,
                      child: Container(
                        decoration: showChat
                            ? const BoxDecoration(
                                border: Border(
                                  right: BorderSide(
                                    color: Color(0xFF2A313A),
                                    width: 1,
                                  ),
                                ),
                              )
                            : null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (showChat)
                              Container(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  8,
                                  14,
                                  6,
                                ),
                                color: const Color(0xFF12171E),
                                child: const Text(
                                  'Voice',
                                  style: TextStyle(
                                    color: Color(0xFF9CA3AF),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            Expanded(child: _buildVoicePanel()),
                          ],
                        ),
                      ),
                    ),
                  if (showChat)
                    Expanded(
                      flex: showVoice ? 54 : 100,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showVoice)
                            Container(
                              padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
                              color: const Color(0xFF12171E),
                              child: const Text(
                                'Non-Voice',
                                style: TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          Expanded(child: _buildChatPanel()),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (showVoice) _buildVoiceBottomBar(isOnHold, callInProgress),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton(
    String label,
    IconData icon, {
    bool isEndCall = false,
    bool enabled = true,
    VoidCallback? onTap,
  }) {
    final Color color = !enabled
        ? const Color(0xFF6B7280)
        : isEndCall
        ? const Color(0xFFEF4444)
        : const Color(0xFFE5E7EB);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: enabled ? onTap : null,
          icon: Icon(icon, color: color, size: 28),
        ),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTimerDisplay() {
    return ValueListenableBuilder<int>(
      valueListenable: _elapsedSeconds,
      builder: (context, seconds, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.timer_outlined,
              size: 28,
              color: Color(0xFFE5E7EB),
            ),
            Text(
              _formatElapsed(seconds),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Color(0xFFE5E7EB),
              ),
            ),
          ],
        );
      },
    );
  }
}
