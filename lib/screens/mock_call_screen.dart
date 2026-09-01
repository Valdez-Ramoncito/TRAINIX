import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainixprogram/models/session_score.dart';
import 'package:trainixprogram/models/customer_account.dart';
import 'package:trainixprogram/models/messages.dart';
import 'package:trainixprogram/models/simulation_history.dart';
import 'package:trainixprogram/models/simulation_phase.dart';
import 'package:trainixprogram/screens/session_report_screen.dart';
import 'package:trainixprogram/screens/mock_call_ui/header.dart';
import 'package:trainixprogram/widgets/chat_panel.dart';
import 'package:trainixprogram/widgets/voice_panel.dart';

//simulates a call-center workstation with two simultaneous channels
//Voice and Call channels
//both channels receive the same sector
class MockCallScreen extends StatefulWidget {
  //accept a sector that will be used for this simulation
  final String sector;
  const MockCallScreen({super.key, required this.sector});

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

  //the call timer
  int _elapsedSeconds = 0;

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
  final List<double> _voiceResolutionSeconds = [];
  final List<double> _chatResolutionSeconds = [];

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

  //get the multitasking score
  double? get _multitaskingScore {
    //return nothing if both of them is empty
    if (_voiceResolutionSeconds.isEmpty && _chatResolutionSeconds.isEmpty) {
      return null;
    }
    if (_voiceResolutionSeconds.isEmpty || _chatResolutionSeconds.isEmpty) {
      return 0.0;
    }

    final avgVoice =
        _voiceResolutionSeconds.reduce((a, b) => a + b) /
        _voiceResolutionSeconds.length;
    final avgChat =
        _chatResolutionSeconds.reduce((a, b) => a + b) /
        _chatResolutionSeconds.length;

    //numerator should never be higher than the denominator
    //hence we find which of them is the smallest
    //and which of them is the largest
    //so that it doesnt go beyond 100%
    final smaller = avgVoice < avgChat ? avgVoice : avgChat;
    final larger = avgVoice > avgChat ? avgVoice : avgChat;
    if (larger <= 0) return 100.0;
    return (smaller / larger) * 100;
  }

  //at the start, set the required calls to a minimum of 3
  //with a set maximum of random
  @override
  void initState() {
    super.initState();
    _requiredInteractions = Random().nextInt(3) + 3;
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _postCallBreakTimer?.cancel();
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
      //add the evaluation
      _sessionEvaluations.add(e);
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

  //handle the resolution seconds
  void _handleResolutionSeconds(String channel, double seconds) {
    if (channel == 'voice') {
      _voiceResolutionSeconds.add(seconds);
    } else {
      _chatResolutionSeconds.add(seconds);
    }
  }

  //called whenever chat enters or leaves its own after-work-report or
  //grace-period flow. Re-checks whether the session can finish now
  //that chat just became idle, the same way voice's postCallBreak does
  void _handleChatBusyChanged(bool busy) {
    setState(() => _chatInProgress = busy);
    if (!busy && _sessionEnding && !_voiceCallInProgress) {
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
    );

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

    SessionEvaluation buildRandomEval() {
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
        strengths: const [
          'Randomly generated  no real session was run (debug shortcut)',
        ],
        areasForImprovement: const [
          'Randomly generated  no real session was run (debug shortcut)',
        ],
        feedback:
            'This report was generated by the temporary "Finish '
            'Simulation" debug shortcut  no real interaction happened, '
            'every number here is random.',
        evaluatedAt: DateTime.now(),
      );
    }

    final fakeEvaluations = [buildRandomEval(), buildRandomEval()];
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
    );

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
      setState(() => _elapsedSeconds++);
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
      _elapsedSeconds = 0;
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
    final seconds =
        _postCallBreakMinSeconds +
        Random().nextInt(
          _postCallBreakMaxSeconds - _postCallBreakMinSeconds + 1,
        );

    //set the phase to post call break
    setState(() {
      _phase = SimulationPhase.postCallBreak;
      _remainingPostCallSeconds = seconds;
    });

    //cancel the timer first if there's already running
    _postCallBreakTimer?.cancel();

    //then start a timer
    _postCallBreakTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      //if not in a state, cancel the timer
      if (!mounted) {
        timer.cancel();
        return;
      }

      //while timer is ticking, reduce the seconds set
      setState(() {
        _remainingPostCallSeconds--;

        //if it reaches 0, cancel the timer and call the
        //post call break
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

  //build the UI
  @override
  Widget build(BuildContext context) {
    //are we in the active phase?
    final bool isActive = _phase == SimulationPhase.active;

    //are we in the on hold phase?
    final bool isOnHold = _phase == SimulationPhase.onHold;

    //is the call in progress?
    final bool callInProgress = isActive || isOnHold;

    return Scaffold(
      body: Column(
        children: [
          Header(
            sector: widget.sector,
            completedInteractions: _completedInteractions,
            requiredInteractions: _requiredInteractions,
            onDebugFinish: _debugFinishSimulation,
            onToggleTheme: () {},
            onOpenSettings: () {},
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  //in the left side, build the voice channel
                  //pass in the needed data
                  flex: 44,
                  //voice gets its own scoped MessageProvider AND its
                  //own scoped AccountProvider, both separate from
                  //chat's. One channel generating accounts can never
                  //make the other think accounts already exist
                  child: MultiProvider(
                    providers: [
                      ChangeNotifierProvider<MessageProvider>(
                        create: (_) => MessageProvider(),
                      ),
                      ChangeNotifierProvider<AccountProvider>(
                        create: (_) => AccountProvider(),
                      ),
                    ],
                    child: VoicePanel(
                      phase: _phase,
                      sector: widget.sector,
                      remainingBreakSeconds: _remainingPostCallSeconds,
                      onAccept: () {
                        //start the timer and set the phase to active
                        //when accepting a call. This customer now
                        //occupies voice's quota slot until resolved
                        _startCallTimer();
                        setState(() {
                          _phase = SimulationPhase.active;
                          _voiceHasActiveCustomer = true;
                        });
                      },
                      //add the evaluation to the list of evaluations
                      onEvaluation: (e) => _handleEvaluation('voice', e),
                      //when its the agent's turn, record the words
                      //per minute
                      onVoiceTurn: (wpm, fillerCount) {
                        _voiceWpmSamples.add(wpm);
                        _voiceFillerCount += fillerCount;
                      },
                      //record the time it takes for the agent
                      //to resolve the problem
                      onResolutionSeconds: (s) =>
                          _handleResolutionSeconds('voice', s),
                      //after call report
                      onSendReport: _onSendReport,
                    ),
                  ),
                ),
                const VerticalDivider(
                  width: .5,
                  thickness: .3,
                  color: Color.fromARGB(255, 105, 106, 106),
                ),
                Expanded(
                  //in the right side, build the chat channel UI
                  //pass in the required datas
                  flex: 56,
                  //chat's own scoped MessageProvider + AccountProvider
                  child: MultiProvider(
                    providers: [
                      ChangeNotifierProvider<MessageProvider>(
                        create: (_) => MessageProvider(),
                      ),
                      ChangeNotifierProvider<AccountProvider>(
                        create: (_) => AccountProvider(),
                      ),
                    ],
                    child: ChatPanel(
                      sector: widget.sector,
                      //add the evaluation to the list of evaluations
                      onEvaluation: (e) => _handleEvaluation('chat', e),
                      //when the agent types, record the words per
                      //minute
                      onChatTurn: (wpm) => _chatWpmSamples.add(wpm),
                      //record how long did the agent take to solve
                      //a customer's problem
                      onResolutionSeconds: (s) =>
                          _handleResolutionSeconds('chat', s),
                      //check if chat channel can still start a new
                      //conversation
                      canStartNewCustomer: () =>
                          _tryStartNewInteraction('chat'),
                      //let the parent know when chat enters/leaves its
                      //own after-work-report/grace-period flow
                      onBusyChanged: _handleChatBusyChanged,
                      //let the parent know chat has started serving a
                      //customer, so its quota-occupancy flag stays
                      //accurate from the very first customer onward
                      onCustomerStarted: _handleChatCustomerStarted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          //build the bottom UI
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Color.fromARGB(255, 105, 106, 106),
                  width: .3,
                ),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                //controls for the voice call
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
                  //build the timer UI
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
          ),
        ],
      ),
    );
  }

  //Bottom UI for Voice call
  Widget _buildBottomButton(
    String label,
    IconData icon, {
    bool isEndCall = false,
    bool enabled = true,
    VoidCallback? onTap,
  }) {
    //set the color depending on the value
    final Color activeColor = isEndCall ? Colors.red : Colors.black;
    final Color color = enabled ? activeColor : Colors.grey;

    //return the widget
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          //if its enabled, enable the button, if not, disable it
          onPressed: enabled ? onTap : null,
          icon: Icon(icon, color: color, size: 28),
        ),
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  //Timer display for the Bottom UI
  Widget _buildTimerDisplay() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.timer, size: 28),
        Text(
          //get the formatted seconds
          _formatElapsed(_elapsedSeconds),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
