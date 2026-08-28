import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainixprogram/models/session_score.dart';
import 'package:trainixprogram/models/customer_account.dart';
import 'package:trainixprogram/models/messages.dart';
import 'package:trainixprogram/models/simulation_history.dart';
import 'package:trainixprogram/screens/session_report_screen.dart';
import 'package:trainixprogram/screens/training/class/class.dart';
import 'package:trainixprogram/services/evaluation_api_service.dart';
import 'package:trainixprogram/services/open_router_api_service.dart';
import 'package:trainixprogram/services/speech_to_text_service.dart';
import 'package:trainixprogram/services/type_cast_api_service.dart';

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
  // location in class folder simulation
  SimulationPhase _phase = SimulationPhase.incoming;

  //how many full calls were done
  int _completedInteractions = 0;

  //the quota to reach
  late final int _requiredInteractions;

  //is the mic muted?
  bool _isMuted = false;

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

  //check if the incoming customer is the last one to meet
  //the required quota
  bool _finalSlotClaimed = false;

  //whether chat is currently in its own after-work-report/grace-period
  //flow — mirrors _voiceCallInProgress below, so the session can't yank
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

  //try to start a new interaction
  //returns false if the session is ending
  //returns true if the agent hasn't reach the required quota yet
  //returns false if the final slot is already claimed
  //if none of the conditions were met, that means the next
  //call is the last call. set the final slot claim to true
  //then return true
  bool _tryStartNewInteraction() {
    if (_sessionEnding) return false;
    if (_completedInteractions < _requiredInteractions - 1) return true;
    if (_finalSlotClaimed) return false;
    _finalSlotClaimed = true;
    return true;
  }

  //handle the evaluation
  void _handleEvaluation(SessionEvaluation e) {
    setState(() {
      //add the evaluation
      _sessionEvaluations.add(e);
      //increase the completed interactions
      _completedInteractions++;
      //if it has reached the required interactions
      //set the session ending to true
      if (_completedInteractions >= _requiredInteractions) {
        _sessionEnding = true;
      }
    });
    //if the session is ending but neither channel is still actively
    //wrapping up its own call/chat, then finish the session
    if (_sessionEnding && !_voiceCallInProgress && !_chatInProgress) {
      _finishSession();
    }
  }

  //handle the resolution seconds
  void _handleResolutionSeconds(String channel, double seconds) {
    if (channel == 'voice') {
      _voiceResolutionSeconds.add(seconds);
    } else {
      _chatResolutionSeconds.add(seconds);
    }
  }

  //called whenever chat enters or leaves its own after-work-report/
  //grace-period flow — re-checks whether the session can finish now
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

    //record this whole play-through as one grouped session — this is
    //what Session History / Score Trend / Total Sessions read from, so
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

    //call the account provider and reset it
    Provider.of<AccountProvider>(context, listen: false).reset();

    setState(() {
      _isMuted = false;
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
      //don't finish (or start a new call) while chat is still in its
      //own after-work-report/grace-period flow — show wrapping up and
      //let chat's own completion re-check via _handleChatBusyChanged
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
      _phase = _tryStartNewInteraction()
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
          Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              Text("Mock Call Simulation — ${widget.sector}"),
              Text('Customer $_completedInteractions / $_requiredInteractions'),
            ],
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  //in the left side, build the voice channel
                  //pass in the needed data
                  flex: 44,
                  //voice gets its own scoped MessageProvider, separate
                  //from chat's — previously both channels shared the one
                  //global MessageProvider from main.dart, so chat's UI
                  //rendered voice's lines (and vice versa), and each
                  //channel's AI prompt included the other channel's
                  //conversation as if it were the same customer
                  child: ChangeNotifierProvider<MessageProvider>(
                    create: (_) => MessageProvider(),
                    child: _VoicePanel(
                      phase: _phase,
                      sector: widget.sector,
                      isMuted: _isMuted,
                      remainingBreakSeconds: _remainingPostCallSeconds,
                      onAccept: () {
                        //start the timer and set the phase to active
                        //when accepting a call
                        _startCallTimer();
                        setState(() => _phase = SimulationPhase.active);
                      },
                      //add the evaluation to the list of evaluations
                      onEvaluation: _handleEvaluation,
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
                const VerticalDivider(width: 1),
                Expanded(
                  //in the right side, build the chat channel UI
                  //pass in the required datas
                  flex: 56,
                  //chat's own scoped MessageProvider — see the note on
                  //the voice panel above
                  child: ChangeNotifierProvider<MessageProvider>(
                    create: (_) => MessageProvider(),
                    child: _ChatPanel(
                      sector: widget.sector,
                      //add the evaluation to the list of evaluations
                      onEvaluation: _handleEvaluation,
                      //when the agent types, record the words per
                      //minute
                      onChatTurn: (wpm) => _chatWpmSamples.add(wpm),
                      //record how long did the agent take to solve
                      //a customer's problem
                      onResolutionSeconds: (s) =>
                          _handleResolutionSeconds('chat', s),
                      //check if chat channel can still start a new
                      //conversation
                      canStartNewCustomer: _tryStartNewInteraction,
                      //let the parent know when chat enters/leaves its
                      //own after-work-report/grace-period flow
                      onBusyChanged: _handleChatBusyChanged,
                    ),
                  ),
                ),
              ],
            ),
          ),
          //build the bottom UI
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.black, width: 2)),
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
                  _buildBottomButton(
                    _isMuted ? 'UNMUTE' : 'MUTE',
                    _isMuted ? Icons.mic : Icons.mic_off,
                    enabled: isActive,
                    onTap: () => setState(() => _isMuted = !_isMuted),
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

//The voice channel - Voice Calls
class _VoicePanel extends StatefulWidget {
  //the enum phase
  final SimulationPhase phase;

  //callback
  final VoidCallback onAccept;

  //the sector chosen
  final String sector;

  //is the mic muted?
  final bool isMuted;

  //remaining break seconds
  final int remainingBreakSeconds;

  //on evaluation, handle the evaluation
  final ValueChanged<SessionEvaluation>? onEvaluation;

  //record the words per minute + fillercount
  final void Function(double wpm, int fillerCount)? onVoiceTurn;

  //on resolution, handle the resolution
  final ValueChanged<double>? onResolutionSeconds;

  //on after call phase, handle the after call
  final VoidCallback? onSendReport;

  //constructor
  const _VoicePanel({
    required this.phase,
    required this.onAccept,
    required this.sector,
    required this.isMuted,
    required this.remainingBreakSeconds,
    this.onEvaluation,
    this.onVoiceTurn,
    this.onResolutionSeconds,
    this.onSendReport,
  });
  @override
  State<_VoicePanel> createState() => _VoicePanelState();
}

class _VoicePanelState extends State<_VoicePanel> {
  //setup the service used for customer with voice
  late final TypeCastAPIService _typeCastService;

  //setup the speech to text
  late final SpeechToTextService _sttService;

  //set the phase to idle
  VoicePhase _voicePhase = VoicePhase.idle;

  //for words per minute calculation
  DateTime? _turnStartTime;

  //customer's response in transcript
  String _customerTranscript = '';

  //agent's response in transcript
  String _traineeTranscript = '';

  //the start time of the call
  DateTime? _callStartTime;

  //controller for report
  final TextEditingController _reportController = TextEditingController();

  //has the mic permission check actually finished (successfully)?
  //gates mic interactivity so the UI can't pretend to be listening
  //before this is confirmed true
  bool _sttReady = false;

  //initialize the services and pass the needed datas
  @override
  void initState() {
    super.initState();
    _typeCastService = TypeCastAPIService(fixedSector: widget.sector);
    _sttService = SpeechToTextService();
    _initializeStt();
  }

  //awaits the mic permission check properly (instead of firing and
  //forgetting it) and updates the UI once it's actually known ready —
  //this is what closes the race that let the first mic tap do nothing
  Future<void> _initializeStt() async {
    final ready = await _sttService.initialize();
    if (mounted) {
      setState(() => _sttReady = ready);
    }
  }

  @override
  void dispose() {
    _sttService.dispose();
    _typeCastService.stop();
    _reportController.dispose();
    super.dispose();
  }

  //override the did update widget
  //we need to do it this way to properly update
  //the widget's properties
  @override
  void didUpdateWidget(_VoicePanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    //if the oldwidget phase is not the same with the current phase
    if (oldWidget.phase != widget.phase) {
      //if the current phase is active and the voice phase is in idle
      //state, then set the voice phase into customer speaking
      //and the call start time to now
      if (widget.phase == SimulationPhase.active &&
          _voicePhase == VoicePhase.idle) {
        _callStartTime = DateTime.now();
        setState(() => _voicePhase = VoicePhase.customerSpeaking);
      }

      //if the current phase is on hold
      //stop the typecast and cancel the speech to text
      if (widget.phase == SimulationPhase.onHold) {
        _typeCastService.stop();
        _sttService.cancel();
      }

      //if the old phase is on hold but the current phase is active
      //then set the voice phase to customer speaking
      if (oldWidget.phase == SimulationPhase.onHold &&
          widget.phase == SimulationPhase.active) {
        setState(() => _voicePhase = VoicePhase.customerSpeaking);
      }

      //if the current phase is incoming, then set the voice phase
      //to idle and empty the customer and agent's transcripts
      //as well as the call start time to null
      if (widget.phase == SimulationPhase.incoming) {
        _callStartTime = null;
        //reset the voice-only conversation and scenario for the next
        //customer — clears this panel's scoped MessageProvider and
        //regenerates a fresh name/emotion/problem on the next exchange
        _typeCastService.clearMessages(context);
        setState(() {
          _voicePhase = VoicePhase.idle;
          _customerTranscript = '';
          _traineeTranscript = '';
        });
      }
    }

    //if the old widget is not muted but the current widget is muted
    //and the voice phase is traineeSpeaking
    //then cancel the speech to text and empty the trainee's transcript
    if (!oldWidget.isMuted &&
        widget.isMuted &&
        _voicePhase == VoicePhase.traineeSpeaking) {
      _sttService.cancel();
      setState(() => _traineeTranscript = '');
    }
  }

  //when the mic is pressed
  void _onMicPressed() async {
    print(
      '[VOICE] mic pressed — phase=$_voicePhase sttReady=$_sttReady isMuted=${widget.isMuted}',
    );
    //if its muted, do nothing
    if (widget.isMuted) return;

    //if the voice phase is trainee speaking
    //stop the speech to text service
    //and get the last words spoken
    if (_voicePhase == VoicePhase.traineeSpeaking) {
      setState(() => _voicePhase = VoicePhase.transcribing);
      //stopListening now waits for the actual final transcript instead
      //of returning immediately, so this is no longer a race
      final wordsFromStt = await _sttService.stopListening();
      print('[VOICE] stopListening returned: "$wordsFromStt"');
      //if its empty, set the phase to customer speaking
      final words = wordsFromStt.trim().isNotEmpty
          ? wordsFromStt.trim()
          : _traineeTranscript.trim();

      if (words.isEmpty) {
        print(
          '[VOICE] words empty — resetting to customerSpeaking without sending anything',
        );
        setState(() {
          _traineeTranscript = '';
          _voicePhase = VoicePhase.customerSpeaking;
        });
        return;
      }

      //if the timer is null, set this to 0.0
      //otherwise set this to the current seconds
      final elapsedSeconds = _turnStartTime == null
          ? 0.0
          : DateTime.now().difference(_turnStartTime!).inMilliseconds / 1000;

      //trim the words, split them, and find the words where its not
      //an empty string. Then return the length of that list
      final wordCount = words
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .length;

      //to get the words per minute, divide the word count to
      //how many seconds have passed
      final wpm = elapsedSeconds > 0 ? (wordCount / elapsedSeconds) * 60 : 0.0;

      //when on voice turn, call the function and pass the data
      widget.onVoiceTurn?.call(wpm, countFillerWords(words));

      //then refresh the UI to set the transcript of the agent
      //and set the voice phase to processing
      setState(() {
        _traineeTranscript = words;
        _voicePhase = VoicePhase.processing;
      });

      //then send those words to this function
      await _sendToCustomer(words);
      return;
      //if the voice phase is customer speaking
    }
    if (_voicePhase == VoicePhase.customerSpeaking) {
      //stop the service then get the date
      _typeCastService.stop();

      setState(() {
        _traineeTranscript = '';
        _voicePhase = VoicePhase.traineeSpeaking;
      });

      _turnStartTime = DateTime.now();

      //start listening to the words
      await _sttService.startListening(
        onResult: (words) {
          if (mounted && _voicePhase == VoicePhase.traineeSpeaking) {
            setState(() => _traineeTranscript = words);
          }
        },
      );

      // //then set the voice phase to trainee speaking
      // setState(() => _voicePhase = _VoicePhase.traineeSpeaking);
    }
  }

  //send to the customer what the agent said
  Future<void> _sendToCustomer(String spoken) async {
    print('[VOICE] _sendToCustomer called with: "$spoken"');
    //wait for the response customer object
    final response = await _typeCastService.getResponse(context, spoken);
    print(
      '[VOICE] got response — reply="${response.reply}" callStatus=${response.callStatus} isError=${response.isError}',
    );
    if (!mounted) return;

    //if the account was provided and the id is present, do this
    if (response.accountProvided && response.accountId != null) {
      //initialize the provider for the account
      final accountProvider = Provider.of<AccountProvider>(
        context,
        listen: false,
      );

      //if theres no accounts generated, pass in the needed data
      //then generate the accounts
      if (accountProvider.accounts.isEmpty) {
        accountProvider.generateAccounts(
          sector: widget.sector,
          targetAccountId: response.accountId!,
          problem:
              _typeCastService.openRouterAPI.chosenSimulation['problem'] ?? '',
          //name the account after the actual customer this call is
          //with, so Account Lookup always matches who's on the line
          targetOwnerName:
              _typeCastService.openRouterAPI.chosenSimulation['name'] ??
              'Customer',
        );
      }
    }

    //if its resolved or has ended, set the customer's transcript to
    //the reply, set the voice phase to resolved, get the time
    //it took to resolve the problem, then evaluate the
    //voice interaction, lastly, return back
    if (response.callStatus == 'resolved' || response.callStatus == 'ended') {
      setState(() {
        _customerTranscript = response.reply;
        _voicePhase = VoicePhase.resolved;
      });
      if (_callStartTime != null) {
        final seconds = DateTime.now()
            .difference(_callStartTime!)
            .inSeconds
            .toDouble();
        widget.onResolutionSeconds?.call(seconds);
      }
      _evaluateVoiceInteraction();
      return;
    }

    //if the phase of the current widget is not active
    //set the voice phase to idle, then return back
    if (widget.phase != SimulationPhase.active) {
      setState(() => _voicePhase = VoicePhase.idle);
      return;
    }

    //set the transcript of the customer to the reply
    //set the voice phase of the customer to customer speaking
    setState(() {
      _customerTranscript = response.reply;
      _voicePhase = VoicePhase.customerSpeaking;
    });
  }

  //evaluate the voice interaction
  Future<void> _evaluateVoiceInteraction() async {
    //intialize the message, and history provider
    final messageProvider = Provider.of<MessageProvider>(
      context,
      listen: false,
    );
    final historyProvider = Provider.of<SimulationHistoryProvider>(
      context,
      listen: false,
    );

    //send the evaluation service the necessary data to evaluate
    //the conversation then save it to this variable
    final evaluation = await EvaluationAPIService().evaluateChat(
      messages: List.from(messageProvider.messages),
      sector:
          _typeCastService.openRouterAPI.chosenSimulation['sector'] ??
          widget.sector,
      customerEmotion:
          _typeCastService.openRouterAPI.chosenSimulation['emotion'] ?? '',
      customerProblem:
          _typeCastService.openRouterAPI.chosenSimulation['problem'] ?? '',
    );
    if (!mounted) return;

    //save the evaluation to the history
    historyProvider.saveEvaluation(evaluation);

    //add the evaluation to the list of session evaluation
    widget.onEvaluation?.call(evaluation);
  }

  //build the voice channel
  @override
  Widget build(BuildContext context) {
    //if the current phase is incoming, return the incoming UI
    if (widget.phase == SimulationPhase.incoming) return _buildIncoming();

    //if the current phase is on hold, return the on hold UI
    if (widget.phase == SimulationPhase.onHold) return _buildOnHold();

    //if the current phase is after call work, return the after call
    //work UI
    if (widget.phase == SimulationPhase.afterCallWork) {
      return _buildAfterCallWork();
    }

    //if the current phase is post call break, then return the post call
    //break UI
    if (widget.phase == SimulationPhase.postCallBreak) {
      return _buildPostCallBreak();
    }

    //if the current phase is wrapping up, then return the wrapping
    //up UI
    if (widget.phase == SimulationPhase.wrappingUp) {
      return _buildWrappingUp();
    }

    //otherwise, return the build active
    return _buildActive();
  }

  //Incoming call UI
  //Shows a customer calling
  Widget _buildIncoming() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.phone_in_talk, size: 56),
        const SizedBox(height: 16),
        const Text(
          'Incoming Call',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text('New Customer · ${widget.sector}'),
        const SizedBox(height: 32),
        Column(
          children: [
            IconButton(
              onPressed: widget.onAccept,
              icon: const Icon(Icons.call, color: Colors.green, size: 40),
            ),
            const Text('Accept'),
          ],
        ),
      ],
    );
  }

  //Active UI
  //shows you're on a call with a customer
  Widget _buildActive() {
    //checkers for each voice phase
    final bool isCustomerSpeaking = _voicePhase == VoicePhase.customerSpeaking;
    final bool isTraineeSpeaking = _voicePhase == VoicePhase.traineeSpeaking;
    final bool isTranscribing = _voicePhase == VoicePhase.transcribing;
    final bool isProcessing = _voicePhase == VoicePhase.processing;
    final bool isResolved = _voicePhase == VoicePhase.resolved;

    //becomes true if the customer is speaking or the agent is speaking
    //and if the mic is not muted, the call isnt resolved yet, and the
    //mic permission check has actually finished — without that last
    //check, the mic could look interactive before it's genuinely ready
    final bool micEnabled =
        (isCustomerSpeaking || isTraineeSpeaking) &&
        !widget.isMuted &&
        !isResolved &&
        _sttReady;

    String statusText;
    if (widget.isMuted) {
      statusText = 'Muted';
    } else if (!_sttReady) {
      statusText = 'Preparing microphone...';
    } else if (isResolved) {
      statusText = 'Resolved';
    } else if (isTranscribing) {
      statusText = 'Transcribing...';
    } else if (isTraineeSpeaking) {
      statusText = 'Your turn';
    } else if (isProcessing) {
      statusText = 'Processing...';
    } else if (isCustomerSpeaking && _customerTranscript.isEmpty) {
      statusText = 'Your turn to speak';
    } else if (isCustomerSpeaking) {
      statusText = 'Customer speaking';
    } else {
      statusText = 'Waiting';
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              const Icon(Icons.account_circle, size: 36),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    //if the name of the customer is not known yet, default to
                    //Customer
                    _typeCastService.openRouterAPI.chosenSimulation['name'] ??
                        'Customer',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              //state of the call
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.isMuted
                      ? Colors.orange.shade100
                      : isResolved
                      ? Colors.blue.shade100
                      : isCustomerSpeaking
                      ? Colors.green.shade100
                      : isTraineeSpeaking
                      ? Colors.red.shade100
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(statusText, style: const TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ),
        //a waveform - no visuals for now
        const Divider(height: 1),
        Container(
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '[Waveform]',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ),
        ),
        //Customer transcript
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Customer',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      //check the customer transcript
                      _customerTranscript.isEmpty
                          ? 'Waiting for customer...'
                          : _customerTranscript,
                      style: TextStyle(
                        fontSize: 12,
                        color: _customerTranscript.isEmpty
                            ? Colors.grey
                            : Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                //agent's transcript
                const Text(
                  'You',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        //change the border to red if the agent
                        //is speaking
                        color: isTraineeSpeaking
                            ? Colors.red.shade300
                            : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      //check the agent's transcript
                      _traineeTranscript.isEmpty
                          ? 'Your response will appear here...'
                          : _traineeTranscript,
                      style: TextStyle(
                        fontSize: 12,
                        color: _traineeTranscript.isEmpty
                            ? Colors.grey
                            : Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        //Mic
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              IconButton(
                //is the mic enabled? enable the method
                //otherwise disable it
                onPressed: micEnabled ? _onMicPressed : null,
                icon: Icon(
                  //change the icon depending on the variable state
                  widget.isMuted
                      ? Icons.mic_off
                      : isTraineeSpeaking
                      ? Icons.stop_circle
                      : Icons.mic,
                  size: 36,
                  //change the color depending on the variable state
                  color: widget.isMuted
                      ? Colors.grey
                      : isTraineeSpeaking
                      ? Colors.red
                      : isCustomerSpeaking
                      ? Colors.black
                      : Colors.grey,
                ),
              ),
              Text(
                //change the text depending on the variable state
                widget.isMuted
                    ? 'Mic muted'
                    : isTraineeSpeaking
                    ? 'Tap to stop'
                    : isCustomerSpeaking
                    ? 'Tap to speak'
                    : '—',
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  //UI for the on hold state
  Widget _buildOnHold() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.pause_circle, size: 56),
        SizedBox(height: 16),
        Text('Call On Hold', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text('[Looking up account]'),
      ],
    );
  }

  //feedback/report after customer call
  Widget _buildAfterCallWork() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.edit_note, size: 56),
          const SizedBox(height: 16),
          const Text(
            'After Call Work',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Call ended. Jot down a quick report before your next call.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reportController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Call summary, outcome, notes...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              _reportController.clear();
              widget.onSendReport?.call();
            },
            child: const Text('Send Report'),
          ),
        ],
      ),
    );
  }

  //build post call break UI
  Widget _buildPostCallBreak() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.coffee, size: 56),
        const SizedBox(height: 16),
        const Text('On Break', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Next call in ${widget.remainingBreakSeconds}s...'),
      ],
    );
  }

  //wrapping up UI
  Widget _buildWrappingUp() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle_outline, size: 56),
        SizedBox(height: 16),
        Text('No More Calls', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text(
          'Session is wrapping up — waiting for the last customer to finish.',
        ),
      ],
    );
  }
}

//handles the text based customer interaction
//runs parallel with the voice channel
//a customer in a voice channel is different from a customer
//in this channel
class _ChatPanel extends StatefulWidget {
  //accept a sector that was chosen
  final String sector;

  //adds the evaluation and increments interaction
  final ValueChanged<SessionEvaluation>? onEvaluation;

  //records words per minute typed
  final ValueChanged<double>? onChatTurn;

  //how long did the problem got resolved
  final ValueChanged<double>? onResolutionSeconds;

  //can another chat start?
  final bool Function()? canStartNewCustomer;

  //tells the parent when chat enters/leaves its own after-work-report/
  //grace-period flow, so the session can't end out from under it
  final ValueChanged<bool>? onBusyChanged;

  //constructor
  const _ChatPanel({
    required this.sector,
    this.onEvaluation,
    this.onChatTurn,
    this.onResolutionSeconds,
    this.canStartNewCustomer,
    this.onBusyChanged,
  });
  @override
  State<_ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<_ChatPanel> {
  //grace period set
  static const int _graceMinSeconds = 15;
  static const int _graceMaxSeconds = 30;

  //starting type timer
  DateTime? _typingStartTime;

  //whether a send (or the opening-message fetch) is currently in
  //progress — blocks a second send from starting before the first one
  //finishes, which is what previously allowed multiple concurrent
  //requests to race each other
  bool _isSending = false;

  //whether the last send/opening-fetch attempt failed after every
  //retry, and what to retry if the trainee taps the banner (null means
  //it was the opening message that failed, not a specific typed one)
  bool _showSendError = false;
  String? _failedMessageText;

  //controller for chat message
  final TextEditingController _inputController = TextEditingController();

  //controller for account search
  final TextEditingController _accountSearchController =
      TextEditingController();

  //controller for the after-chat-work report
  final TextEditingController _reportController = TextEditingController();

  //selected tab
  //0 - Chat
  //1 - Account Lookup
  //2 - Scenario Guide
  int _selectedTab = 0;

  //thet phase of the chat
  ChatPhase _chatPhase = ChatPhase.active;

  //remaining seconds of the grace period
  int _remainingSeconds = 0;

  //ticker for grace period
  Timer? _graceTimer;

  //how long the resolved chat stays visible before auto-advancing into
  //After Chat Work
  static const int _resolvedPauseSeconds = 5;
  Timer? _resolvedTimer;
  int _remainingResolvedSeconds = 0;

  //declaring an instance of the API
  late final OpenRouterAPIService openRouterAPI;

  //resolution timer
  DateTime? _customerStartTime;

  //initialize the variables
  @override
  void initState() {
    super.initState();
    openRouterAPI = OpenRouterAPIService(fixedSector: widget.sector);
    _customerStartTime = DateTime.now();

    //make the customer chat first
    //in a real scenario, customer is the first to reach out
    //their concerncs to the customer support
    _requestOpeningMessage();
  }

  //make the customer in the chat channel to chat first
  Future<void> _requestOpeningMessage() async {
    setState(() {
      _isSending = true;
      _showSendError = false;
    });

    try {
      //wait for the response
      final response = await openRouterAPI.getOpeningMessage(context);
      if (!mounted) return;

      //every retry failed — show the retry banner instead of leaving
      //an empty, unexplained chat with no way to know it's broken
      if (response.isError) {
        setState(() {
          _showSendError = true;
          _failedMessageText = null;
        });
        return;
      }

      //if the account was provided as well as the account id, do this
      if (response.accountProvided && response.accountId != null) {
        //initialize the account provider
        final accountProvider = Provider.of<AccountProvider>(
          context,
          listen: false,
        );

        //if there's no list of accounts yet, generate accounts
        if (accountProvider.accounts.isEmpty) {
          accountProvider.generateAccounts(
            sector: widget.sector,
            targetAccountId: response.accountId!,
            problem: openRouterAPI.chosenSimulation['problem'] ?? '',
            //name the account after the actual customer, so Account
            //Lookup always matches who the agent is chatting with
            targetOwnerName:
                openRouterAPI.chosenSimulation['name'] ?? 'Customer',
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _graceTimer?.cancel();
    _resolvedTimer?.cancel();
    _inputController.dispose();
    _accountSearchController.dispose();
    _reportController.dispose();
    super.dispose();
  }

  //build the chat panel
  @override
  Widget build(BuildContext context) {
    //non-active phases take over the whole panel, the same way voice's
    //After Call Work / break / wrapping-up screens replace its content
    //entirely instead of showing as a small banner
    if (_chatPhase == ChatPhase.afterCallWork) {
      return _buildAfterCallWork();
    }
    if (_chatPhase == ChatPhase.gracePeriod) {
      return _buildGracePeriodScreen();
    }
    if (_chatPhase == ChatPhase.waitingToEnd) {
      return _buildWaitingToEndScreen();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        //build the tabs
        _buildTabBar(),
        const Divider(height: 1),
        Expanded(
          child: _selectedTab == 0
              ? _buildChatArea()
              : _selectedTab == 1
              ? _buildAccountLookup()
              : _buildScenarioGuide(),
        ),
        if (_selectedTab == 0) _buildChatInput(),
      ],
    );
  }

  //build Tab Bar UI
  Widget _buildTabBar() {
    return Row(
      children: [
        //Chat UI
        TextButton(
          onPressed: () => setState(() => _selectedTab = 0),
          child: Text(
            'Chat',
            style: TextStyle(
              fontWeight: _selectedTab == 0
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
        //Account Lookup UI
        TextButton(
          onPressed: () => setState(() => _selectedTab = 1),
          child: Text(
            'Account Lookup',
            style: TextStyle(
              fontWeight: _selectedTab == 1
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
        //Scenario Guide
        TextButton(
          onPressed: () => setState(() => _selectedTab = 2),
          child: Text(
            'Scenario Guide',
            style: TextStyle(
              fontWeight: _selectedTab == 2
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  //build the Chat UI
  Widget _buildChatArea() {
    return Consumer<MessageProvider>(
      builder: (context, value, child) {
        if (value.messages.isEmpty) {
          return const Center(child: Text('No messages yet.'));
        }
        return ListView.builder(
          itemCount: value.messages.length,
          itemBuilder: (_, index) {
            final data = value.messages[index];
            //strip the internal "[AGENT]: " tag used to tell the AI
            //who's speaking — it's not meant to be shown to the trainee
            final displayText = data.role == 'user'
                ? data.message.replaceFirst('[AGENT]: ', '')
                : data.message;
            return ListTile(
              title: Text(
                textAlign: data.role != 'user'
                    ? TextAlign.left
                    : TextAlign.right,
                data.role != 'user'
                    ? 'Customer: $displayText'
                    : 'You: $displayText',
              ),
            );
          },
        );
      },
    );
  }

  //shown in place of the input box for the 5-second pause after
  //resolution — keeps the transcript on screen and readable instead of
  //cutting straight to After Chat Work
  Widget _buildResolvedBanner() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Issue resolved — continuing in $_remainingResolvedSeconds...',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  //build Account Lookup UI
  Widget _buildAccountLookup() {
    return Consumer<AccountProvider>(
      builder: (context, accountProvider, child) {
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _accountSearchController,
                      onChanged: accountProvider.search,
                      decoration: const InputDecoration(
                        labelText: 'Search by account ID or name',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (accountProvider.accounts.isEmpty)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'No account lookup needed for this conversation.\n'
                        'If you\'ve answered the customer\'s question, given '
                        'guidance, or handled an escalation, the customer '
                        'should wrap up naturally on their own. If they '
                        'don\'t, you can close it out manually below.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      if (accountProvider.issueResolved)
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Issue resolved',
                              style: TextStyle(color: Colors.green),
                            ),
                          ],
                        )
                      else
                        ElevatedButton(
                          onPressed: accountProvider.resolveIssue,
                          child: const Text('Mark as Resolved'),
                        ),
                    ],
                  ),
                )
              else ...[
                const Text(
                  'Accounts',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 160,
                  child: ListView.builder(
                    itemCount: accountProvider.filteredAccounts.length,
                    itemBuilder: (_, index) {
                      final account = accountProvider.filteredAccounts[index];
                      final isSelected =
                          accountProvider.selectedAccount?.accountId ==
                          account.accountId;
                      return ListTile(
                        dense: true,
                        selected: isSelected,
                        title: Text(
                          '${account.accountId}  —  ${account.ownerName}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onTap: () => accountProvider.selectAccount(account),
                      );
                    },
                  ),
                ),
                const Divider(),
                if (accountProvider.selectedAccount != null) ...[
                  const Text(
                    'Account Details',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  ...accountProvider.selectedAccount!.details.entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        '${e.key}: ${e.value}',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              e.key == 'Issue' &&
                                  accountProvider.selectedAccount!.isTarget
                              ? Colors.red
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (accountProvider.issueResolved)
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Issue resolved in system',
                          style: TextStyle(color: Colors.green),
                        ),
                      ],
                    )
                  else if (accountProvider.selectedAccount!.isTarget)
                    ElevatedButton(
                      onPressed: accountProvider.resolveIssue,
                      child: Text(
                        _getActionLabel(
                          openRouterAPI.chosenSimulation['sector'] ?? '',
                        ),
                      ),
                    )
                  else
                    const Text(
                      'This is not the customer\'s account.',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  //Action for account fix UI
  //Return the appropriate text for the sector received
  String _getActionLabel(String sector) {
    switch (sector) {
      case 'Finance':
        return 'Apply Financial Adjustment';
      case 'Healthcare':
        return 'Process Healthcare Request';
      case 'Telco':
        return 'Restore Service';
      default:
        return 'Apply Technical Fix';
    }
  }

  //build scenario guide UI
  Widget _buildScenarioGuide() {
    //get the required datas
    final sector = openRouterAPI.chosenSimulation['sector'];
    final emotion = openRouterAPI.chosenSimulation['emotion'];
    final problem = openRouterAPI.chosenSimulation['problem'];

    //if this is empty, return a neutral text
    if (sector == null || sector.isEmpty) {
      return const Center(
        child: Text(
          'Start the conversation to reveal the scenario.',
          textAlign: TextAlign.center,
        ),
      );
    }

    //return the guide
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //build guide section - sections
          //get handling tip - depending on the emotion
          //build guide list - a list of tips
          //get sector reminder - get reminders depending on the sector
          //get key phrases - list of phrases to use
          //get things to avoid - depending on the emotion
          _buildGuideSection('Sector', sector),
          _buildGuideSection(
            'Customer emotion',
            (emotion ?? 'unknown')[0].toUpperCase() +
                (emotion ?? 'unknown').substring(1),
          ),
          _buildGuideSection('Customer problem', problem ?? 'Unknown'),
          const Divider(height: 24),
          _buildGuideSection(
            'Handling approach',
            _getHandlingTip(emotion ?? ''),
          ),
          _buildGuideSection('Sector reminders', _getSectorReminder(sector)),
          const Divider(height: 24),
          _buildGuideList('Key phrases to use', _getKeyPhrases()),
          const SizedBox(height: 12),
          _buildGuideList('Things to avoid', _getThingsToAvoid(emotion ?? '')),
        ],
      ),
    );
  }

  //build the sections
  Widget _buildGuideSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Text(content, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  //build the list of guides
  Widget _buildGuideList(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 3.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 13)),
                  Expanded(
                    child: Text(item, style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  //get tips based on the emotion received
  String _getHandlingTip(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'angry':
        return 'De-escalate first. Acknowledge the frustration sincerely '
            'before offering any solution. Never argue or match their tone.';
      case 'frustrated':
        return 'Validate their experience, then move quickly to a solution. '
            'Keep your tone calm and apologetic without being defensive.';
      case 'anxious':
        return 'Reassure early and often. Use confident, steady language. '
            '"I will take care of this for you right away."';
      case 'confused':
        return 'Slow down. Avoid jargon. Confirm understanding at each step '
            'before moving forward. Repeat key points if needed.';
      case 'impatient':
        return 'Be efficient. Skip long explanations — summarize steps briefly '
            'and keep the customer updated on progress.';
      case 'polite but urgent':
        return 'Acknowledge the urgency immediately. Work quickly and provide '
            'clear timelines so they know you are taking it seriously.';
      default:
        return 'Stay professional and solution-focused. Mirror their calm '
            'tone and guide the conversation toward resolution.';
    }
  }

  //get reminders based on the received sector
  String _getSectorReminder(String sector) {
    switch (sector) {
      case 'Finance':
        return 'Verify account identity before sharing or adjusting any details. '
            'Comply with the Data Privacy Act. Explain all adjustments clearly '
            'and confirm the customer understands before ending the call.';
      case 'Healthcare':
        return 'Use plain language — avoid medical jargon. Protect patient privacy '
            'at all times. Confirm appointment or claim details before making changes.';
      case 'Telco':
        return 'Run basic troubleshooting before escalating. Confirm the service area '
            'and check the billing cycle when handling charge disputes.';
      default:
        return 'Gather device and OS information early. Confirm any recent changes '
            'such as updates or new installs. Guide the customer step by step '
            'and confirm each action before proceeding.';
    }
  }

  //get key phrases
  List<String> _getKeyPhrases() {
    return [
      'Instead of "I can\'t do that" ? "What I can do for you is..."',
      'Instead of "You need to wait" ? "I\'ll have this resolved as quickly as possible."',
      'Instead of "That\'s not my department" ? "Let me connect you with the right team."',
      '"I completely understand your concern."',
      '"Thank you for bringing this to our attention."',
      '"Is there anything else I can help you with today?"',
    ];
  }

  //get tips for things to avoid
  //if the customer's emotion gets unstable or is unstable
  //update the universal accordingly
  List<String> _getThingsToAvoid(String emotion) {
    final universal = [
      'Never say "calm down" — it escalates tension.',
      'Do not place the customer on hold without explaining why and asking permission.',
      'Avoid filler words: "um", "uh", "like", "you know".',
      'Never promise something you cannot deliver.',
    ];
    if (emotion == 'angry' || emotion == 'frustrated') {
      universal.add('Do not say "That\'s not our fault" — take ownership.');
    }
    if (emotion == 'confused') {
      universal.add(
        'Avoid using technical terms without explaining them first.',
      );
    }
    return universal;
  }

  //after-chat-work report — same purpose as voice's After Call Work,
  //a deliberate manual beat between a resolved conversation and the
  //grace period, instead of jumping straight into the countdown
  Widget _buildAfterCallWork() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.edit_note, size: 56),
          const SizedBox(height: 16),
          const Text(
            'After Chat Work',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Conversation ended. Jot down a quick report before your next chat.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reportController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Chat summary, outcome, notes...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              _reportController.clear();
              _startGracePeriod();
            },
            child: const Text('Send Report'),
          ),
        ],
      ),
    );
  }

  //grace period — now a full-panel screen, matching voice's post-call
  //break, instead of a small banner while the rest of the chat (tabs,
  //message list) stayed visible and interactive
  Widget _buildGracePeriodScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.hourglass_bottom, size: 56),
        const SizedBox(height: 16),
        const Text('On Break', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Next chat in $_remainingSeconds seconds...'),
      ],
    );
  }

  //full-panel wrapping-up screen, mirroring voice's
  Widget _buildWaitingToEndScreen() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle_outline, size: 56),
        SizedBox(height: 16),
        Text('No More Chats', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text(
          'Session is wrapping up — waiting for the last customer to finish.',
        ),
      ],
    );
  }

  //red "failed, tap to retry" banner shown above the input — used both
  //when a typed message fails to send and when the opening message
  //itself fails to arrive, instead of putting an error string in the
  //customer's mouth
  Widget _buildSendErrorBanner() {
    if (!_showSendError) return const SizedBox.shrink();
    final label = _failedMessageText == null
        ? "Couldn't reach the customer — tap to retry."
        : 'Message failed to send — tap to retry.';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: InkWell(
        onTap: _isSending ? null : _retry,
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //retries whatever last failed — a specific typed message, or the
  //opening message fetch
  void _retry() {
    if (_isSending) return;
    final text = _failedMessageText;
    if (text != null) {
      _sendUserMessage(text);
    } else {
      _requestOpeningMessage();
    }
  }

  //evaluate the chat that just finished — the grace period itself now
  //starts separately, once the agent submits the after-chat-work
  //report (see _buildAfterCallWork / _startGracePeriod)
  void _evaluateResolution() async {
    //initialize message and history providers
    final messageProvider = Provider.of<MessageProvider>(
      context,
      listen: false,
    );
    final historyProvider = Provider.of<SimulationHistoryProvider>(
      context,
      listen: false,
    );

    //evaluate the chat that got finished. Send the necessary data
    //and wait for the result
    final evaluation = await EvaluationAPIService().evaluateChat(
      messages: List.from(messageProvider.messages),
      sector: openRouterAPI.chosenSimulation['sector'] ?? '',
      customerEmotion: openRouterAPI.chosenSimulation['emotion'] ?? '',
      customerProblem: openRouterAPI.chosenSimulation['problem'] ?? '',
    );

    //while in this state, save the evaluation and add that evaluation
    //to the list of session evaluations
    if (mounted) {
      historyProvider.saveEvaluation(evaluation);
      widget.onEvaluation?.call(evaluation);
    }
  }

  //keeps the resolved chat visible for a fixed pause, then auto-
  //advances into After Chat Work — no tap needed, just not an instant
  //cut away from the customer's last message
  void _startResolvedPause() {
    _resolvedTimer?.cancel();
    setState(() => _remainingResolvedSeconds = _resolvedPauseSeconds);
    _resolvedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingResolvedSeconds--;
        if (_remainingResolvedSeconds <= 0) {
          timer.cancel();
          _chatPhase = ChatPhase.afterCallWork;
        }
      });
    });
  }

  //start the grace timer
  void _startGracePeriod() {
    //set the seconds for how long the grace timer is
    final seconds =
        _graceMinSeconds +
        Random().nextInt(_graceMaxSeconds - _graceMinSeconds + 1);

    //cancel any previous grace timer first — without this, two
    //triggers in a row would leave two timers running independently,
    //each clearing the chat and generating a new customer on its own
    //schedule
    _graceTimer?.cancel();

    //set the phase to grace period (still "busy" from the parent's
    //perspective — onBusyChanged(true) was already sent when we
    //entered afterCallWork, and grace period is a continuation of that
    //same manual wrap-up flow)
    setState(() {
      _chatPhase = ChatPhase.gracePeriod;
      _remainingSeconds = seconds;
    });

    //start the timer
    _graceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          timer.cancel();
          _startNewCustomer();
        }
      });
    });
  }

  //start a new customer for the chat channel
  void _startNewCustomer() {
    //check if we can start a new chat
    final canStart = widget.canStartNewCustomer?.call() ?? true;

    //if we cannot anymore, set the phase to waiting to end and tell
    //the parent chat is no longer busy — this is what lets the
    //session finish if chat was the last thing blocking it
    if (!canStart) {
      setState(() => _chatPhase = ChatPhase.waitingToEnd);
      widget.onBusyChanged?.call(false);
      return;
    }

    //initialize the message provider
    final messageProvider = Provider.of<MessageProvider>(
      context,
      listen: false,
    );

    //clear the messages for the next chat
    messageProvider.clearMessage();
    Provider.of<AccountProvider>(context, listen: false).reset();
    openRouterAPI.clearMessages(context);

    //reset the starting time again
    _customerStartTime = DateTime.now();

    //clear any leftover error state from the previous customer
    _showSendError = false;
    _failedMessageText = null;

    //set the chat phase to active and tell the parent chat is no
    //longer in its wrap-up flow
    setState(() => _chatPhase = ChatPhase.active);
    widget.onBusyChanged?.call(false);

    //and make the customer chat first again
    _requestOpeningMessage();
  }

  //send the chat message
  void sendChatmessage() {
    //if the agent sent nothing, isn't in the active chat phase, or a
    //previous message is still being processed, do nothing
    if (_inputController.text.isEmpty ||
        _chatPhase != ChatPhase.active ||
        _isSending) {
      return;
    }

    //the agent can't speak first — only allow sending once the
    //customer has actually said something
    final hasCustomerMessage = Provider.of<MessageProvider>(
      context,
      listen: false,
    ).messages.any((m) => m.role == 'assistant');
    if (!hasCustomerMessage) return;

    final text = _inputController.text;
    _inputController.clear();
    _sendUserMessage(text);
  }

  //does the actual send + response handling — split out from
  //sendChatmessage so a failed send can be retried with the exact same
  //text without the agent needing to retype it
  Future<void> _sendUserMessage(String text) async {
    setState(() {
      _isSending = true;
      _showSendError = false;
    });

    try {
      //get the seconds passed
      final elapsedSeconds = _typingStartTime == null
          ? 0.0
          : DateTime.now().difference(_typingStartTime!).inMilliseconds / 1000;

      //get the word count
      final wordCount = text
          .trim()
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .length;

      //and get the words per minute based on the seconds had passed
      //and the word count
      final wpm = elapsedSeconds > 0 ? (wordCount / elapsedSeconds) * 60 : 0.0;

      //then save that to a list of words per minute
      widget.onChatTurn?.call(wpm);

      //then set the date to null
      _typingStartTime = null;

      //wait for the response
      final response = await openRouterAPI.getResponseWithoutTypeCast(
        context,
        text,
      );

      if (!mounted) return;

      //every retry failed — show the retry banner instead of putting
      //an error message in the customer's mouth
      if (response.isError) {
        setState(() {
          _showSendError = true;
          _failedMessageText = text;
        });
        return;
      }

      _failedMessageText = null;

      //if the account was provided as well as the id, do this
      if (response.accountProvided && response.accountId != null) {
        //initialize account provider
        final accountProvider = Provider.of<AccountProvider>(
          context,
          listen: false,
        );

        //if its empty, then generate a list of accounts
        if (accountProvider.accounts.isEmpty) {
          accountProvider.generateAccounts(
            sector: openRouterAPI.chosenSimulation['sector'] ?? 'Tech Support',
            targetAccountId: response.accountId!,
            problem: openRouterAPI.chosenSimulation['problem'] ?? '',
            //name the account after the actual customer, so Account
            //Lookup always matches who the agent is chatting with
            targetOwnerName:
                openRouterAPI.chosenSimulation['name'] ?? 'Customer',
          );
        }
      }

      //if the problem is already resolved or already ended — and we're
      //still genuinely in the active phase, which guards against a
      //late/stale reply acting on a customer that's already being
      //wrapped up — do this
      if ((response.callStatus == 'resolved' ||
              response.callStatus == 'ended') &&
          _chatPhase == ChatPhase.active) {
        //check first if theres a start time
        //then calculate the seconds had passed
        if (_customerStartTime != null) {
          final seconds = DateTime.now()
              .difference(_customerStartTime!)
              .inSeconds
              .toDouble();

          //then add that to a list of chat resolution
          widget.onResolutionSeconds?.call(seconds);
        }

        //kick off evaluation in the background and tell the parent chat
        //is now busy wrapping up — but don't jump straight into the
        //full-panel After Chat Work screen yet. Land on "resolved" for
        //a fixed 5-second pause first, which keeps the chat (including
        //the customer's final resolution message) visible instead of
        //it vanishing instantly, and switch to the Chat tab in case the
        //agent was on Account Lookup / Scenario Guide when it landed.
        _evaluateResolution();
        widget.onBusyChanged?.call(true);
        setState(() {
          _chatPhase = ChatPhase.resolved;
          _selectedTab = 0;
        });
        _startResolvedPause();
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  //build the Chat input area
  Widget _buildChatInput() {
    //once resolved, replace the input with a countdown banner instead
    //of auto-advancing into After Chat Work instantly — this keeps the
    //resolution message on screen for a beat instead of it vanishing
    //the moment it arrives
    if (_chatPhase == ChatPhase.resolved) {
      return _buildResolvedBanner();
    }

    return Consumer<MessageProvider>(
      builder: (context, messageProvider, _) {
        //the agent can't speak first — this only becomes true once the
        //customer's opening message has actually arrived
        final customerHasSpoken = messageProvider.messages.any(
          (m) => m.role == 'assistant',
        );
        final canSend = customerHasSpoken && !_isSending;

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!customerHasSpoken && !_showSendError)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Text(
                    'Waiting for the customer to say something first...',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
              _buildSendErrorBanner(),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      enabled: customerHasSpoken,
                      onChanged: (value) {
                        if (value.isNotEmpty && _typingStartTime == null) {
                          _typingStartTime = DateTime.now();
                        } else if (value.isEmpty) {
                          _typingStartTime = null;
                        }
                      },
                      decoration: InputDecoration(
                        hintText: customerHasSpoken
                            ? 'Type a message...'
                            : 'Waiting for customer...',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: canSend ? sendChatmessage : null,
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
