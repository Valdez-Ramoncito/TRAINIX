import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainixprogram/models/customer_account.dart';
import 'package:trainixprogram/models/messages.dart';
import 'package:trainixprogram/models/session_score.dart';
import 'package:trainixprogram/models/simulation_history.dart';
import 'package:trainixprogram/models/simulation_phase.dart';
import 'package:trainixprogram/services/gemini_voice_evaluation_api_service.dart';
import 'package:trainixprogram/services/speech_to_text_service.dart';
import 'package:trainixprogram/services/type_cast_api_service.dart';
import 'package:trainixprogram/widgets/account_lookup_view.dart';
import 'package:trainixprogram/widgets/scenario_guide_view.dart';

//enumeration for the phases of the voice call
enum _VoicePhase {
  idle,
  customerSpeaking,
  traineeSpeaking,
  transcribing,
  processing,
  resolved,
}

//regular expressions for filler words used in Voice Call
final RegExp _fillerWordPattern = RegExp(
  r'\b(um+|uh+|hmm+|like|you know|i mean)\b',
  caseSensitive: false,
);

//count all the filler words that are present in the text
//then return the result
int _countFillerWords(String text) {
  return _fillerWordPattern.allMatches(text).length;
}

//The voice channel - Voice Calls
class VoicePanel extends StatefulWidget {
  //the enum phase
  final SimulationPhase phase;

  //callback
  final VoidCallback onAccept;

  //the sector chosen
  final String sector;

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
  const VoicePanel({
    super.key,
    required this.phase,
    required this.onAccept,
    required this.sector,
    required this.remainingBreakSeconds,
    this.onEvaluation,
    this.onVoiceTurn,
    this.onResolutionSeconds,
    this.onSendReport,
  });
  @override
  State<VoicePanel> createState() => _VoicePanelState();
}

class _VoicePanelState extends State<VoicePanel> {
  //setup the service used for customer with voice
  late final TypeCastAPIService _typeCastService;

  //setup the speech to text
  late final SpeechToTextService _sttService;

  //set the phase to idle
  _VoicePhase _voicePhase = _VoicePhase.idle;

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

  //audio file paths retained for the CURRENT customer interaction,
  //one per trainee turn, fed to Gemini's voice evaluation, then
  //deleted
  final List<String> _retainedAudioPaths = [];

  //deletes every currently-retained turn recording and clears the
  //list called after evaluation runs, when a new customer starts, and
  //on dispose, so nothing is left orphaned on disk in any exit path
  Future<void> _clearRetainedAudio() async {
    final paths = List<String>.from(_retainedAudioPaths);
    _retainedAudioPaths.clear();
    for (final path in paths) {
      await _sttService.deleteRetainedFile(path);
    }
  }

  //has the mic permission check actually finished?
  //gates mic interactivity so the UI can't pretend to be listening
  //before this is confirmed true
  bool _sttReady = false;

  //selected tab within the tabbed call view
  //0 - Call
  //1 - Account Lookup (only usable while on hold)
  //2 - Scenario Guide
  int _selectedTab = 0;

  //initialize the services and pass the needed datas
  @override
  void initState() {
    super.initState();
    _typeCastService = TypeCastAPIService(fixedSector: widget.sector);
    _sttService = SpeechToTextService();
    _initializeStt();
  }

  //awaits the mic permission check properly
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
    //release this customer's name/problem back to the shared pool so
    //the other channel isn't blocked from ever picking it again
    _typeCastService.openRouterAPI.releaseHeldScenario();

    //attempts cleanup rather than leaking retained recordings
    _clearRetainedAudio();
    super.dispose();
  }

  //override the did update widget
  //we need to do it this way to properly update
  //the widget's properties
  @override
  void didUpdateWidget(VoicePanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    //if the oldwidget phase is not the same with the current phase
    if (oldWidget.phase != widget.phase) {
      //if the current phase is active and the voice phase is in idle
      //state, then set the voice phase into customer speaking
      //and the call start time to now
      if (widget.phase == SimulationPhase.active &&
          _voicePhase == _VoicePhase.idle) {
        _callStartTime = DateTime.now();
        setState(() => _voicePhase = _VoicePhase.customerSpeaking);
      }

      //if the current phase is on hold
      //stop the typecast and cancel the speech to text
      if (widget.phase == SimulationPhase.onHold) {
        _typeCastService.stop();
        _sttService.cancel();
      }

      //if the old phase is on hold but the current phase is active
      //then set the voice phase to customer speaking, and if the agent
      //was sitting on the Account Lookup tab, bounce
      //them back to Call  Account Lookup is only usable while on hold
      if (oldWidget.phase == SimulationPhase.onHold &&
          widget.phase == SimulationPhase.active) {
        setState(() {
          _voicePhase = _VoicePhase.customerSpeaking;
          if (_selectedTab == 1) _selectedTab = 0;
        });
      }

      //if the current phase is incoming, then set the voice phase
      //to idle and empty the customer and agent's transcripts
      //as well as the call start time to null
      if (widget.phase == SimulationPhase.incoming) {
        _callStartTime = null;

        //covers the case where a call ends WITHOUT ever hitting a
        //resolved/ended status
        _clearRetainedAudio();

        //reset the voice-only conversation and scenario for the next
        //customer. clears this panel's scoped MessageProvider and
        //regenerates a fresh name/emotion/problem on the next exchange.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _typeCastService.clearMessages(context);
            //also reset the channel's scoped AccountProvider
            Provider.of<AccountProvider>(context, listen: false).reset();
          }
        });

        //also land back on the Call tab for the new customer, so the
        //agent doesn't stay stuck on Account Lookup / Scenario Guide
        //from the previous call
        setState(() {
          _voicePhase = _VoicePhase.idle;
          _customerTranscript = '';
          _traineeTranscript = '';
          _selectedTab = 0;
        });
      }
    }
  }

  //when the mic is pressed
  void _onMicPressed() async {
    print('[VOICE] mic pressed  phase=$_voicePhase sttReady=$_sttReady');

    //if the voice phase is trainee speaking
    //stop the speech to text service
    //and get the last words spoken
    if (_voicePhase == _VoicePhase.traineeSpeaking) {
      //disable the mic and show "Transcribing" immediately
      setState(() => _voicePhase = _VoicePhase.transcribing);

      //stopListening now waits for the actual final transcript instead
      //of returning immediately
      final (wordsFromStt, audioPath) = await _sttService.stopListening();
      print('[VOICE] stopListening returned: "$wordsFromStt"');

      //if its empty, set the phase to customer speaking
      final words = wordsFromStt.trim().isNotEmpty
          ? wordsFromStt.trim()
          : _traineeTranscript.trim();

      if (words.isEmpty) {
        print(
          '[VOICE] words empty  resetting to customerSpeaking without sending anything',
        );
        //nothing usable was said. This recording has no evaluation
        //value either, delete it now instead of retaining junk audio
        if (audioPath != null) {
          await _sttService.deleteRetainedFile(audioPath);
        }
        setState(() {
          _traineeTranscript = '';
          _voicePhase = _VoicePhase.customerSpeaking;
        });
        return;
      }

      //keep this turn's audio, it'll be attached to the evaluation
      //request once this customer's interaction gets scored
      if (audioPath != null) _retainedAudioPaths.add(audioPath);

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
      widget.onVoiceTurn?.call(wpm, _countFillerWords(words));

      //then refresh the UI to set the transcript of the agent
      //and set the voice phase to processing
      setState(() {
        _traineeTranscript = words;
        _voicePhase = _VoicePhase.processing;
      });

      //then send those words to this function
      await _sendToCustomer(words);
      return;
      //if the voice phase is customer speaking
    }
    if (_voicePhase == _VoicePhase.customerSpeaking) {
      //stop the service then get the date
      _typeCastService.stop();

      setState(() {
        _traineeTranscript = '';
        _voicePhase = _VoicePhase.traineeSpeaking;
      });

      _turnStartTime = DateTime.now();

      //start listening to the words
      await _sttService.startListening(
        onResult: (words) {
          if (mounted && _voicePhase == _VoicePhase.traineeSpeaking) {
            setState(() => _traineeTranscript = words);
          }
        },
      );
    }
  }

  //send to the customer what the agent said
  Future<void> _sendToCustomer(String spoken) async {
    print('[VOICE] _sendToCustomer called with: "$spoken"');

    //wait for the response customer object
    final response = await _typeCastService.getResponse(context, spoken);
    print(
      '[VOICE] got response  reply="${response.reply}" callStatus=${response.callStatus} isError=${response.isError}',
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
        _voicePhase = _VoicePhase.resolved;
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
      setState(() => _voicePhase = _VoicePhase.idle);
      return;
    }

    //set the transcript of the customer to the reply
    //set the voice phase of the customer to customer speaking
    setState(() {
      _customerTranscript = response.reply;
      _voicePhase = _VoicePhase.customerSpeaking;
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

    //snapshot the retained audio before clearing it below, so the
    //request still has the files while they exist on disk
    final audioPaths = List<String>.from(_retainedAudioPaths);

    //send the evaluation service the necessary data to evaluate
    //the conversation, including this interaction's retained turn
    //audio, then save it to this variable
    final evaluation = await GeminiVoiceEvaluationApiService()
        .evaluateVoiceTesda(
          messages: List.from(messageProvider.messages),
          sector:
              _typeCastService.openRouterAPI.chosenSimulation['sector'] ??
              widget.sector,
          customerEmotion:
              _typeCastService.openRouterAPI.chosenSimulation['emotion'] ?? '',
          customerProblem:
              _typeCastService.openRouterAPI.chosenSimulation['problem'] ?? '',
          audioFilePaths: audioPaths,
        );

    //the request is done. Whether it was a success or a fallback, the retained
    //recordings served their purpose, clear them out now
    await _clearRetainedAudio();

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

    //active and on-hold both render inside the same tabbed container
    //Call tab shows the live call view or a simple on-hold placeholder
    //depending on phase
    //Account Lookup is only usable while on hold
    final bool onHold = widget.phase == SimulationPhase.onHold;
    final int effectiveTab = (_selectedTab == 1 && !onHold) ? 0 : _selectedTab;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTabBar(onHold: onHold),
        const Divider(height: 1),
        Expanded(
          child: effectiveTab == 0
              ? (onHold ? _buildOnHold() : _buildActive())
              : effectiveTab == 1
              ? AccountLookupView(sector: widget.sector)
              : ScenarioGuideView(
                  sector:
                      _typeCastService.openRouterAPI.chosenSimulation['sector'],
                  emotion: _typeCastService
                      .openRouterAPI
                      .chosenSimulation['emotion'],
                  problem: _typeCastService
                      .openRouterAPI
                      .chosenSimulation['problem'],
                ),
        ),
      ],
    );
  }

  //build the tab bar for the tabbed call view. Account Lookup is
  //disabled unless the call is actually on hold. Scenario Guide is always enabled.
  Widget _buildTabBar({required bool onHold}) {
    return Row(
      children: [
        TextButton(
          onPressed: () => setState(() => _selectedTab = 0),
          child: Text(
            'Call',
            style: TextStyle(
              fontWeight: _selectedTab == 0
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
        Tooltip(
          message: onHold ? '' : 'Put the call on hold to look up the account',
          child: TextButton(
            onPressed: onHold ? () => setState(() => _selectedTab = 1) : null,
            child: Text(
              'Account Lookup',
              style: TextStyle(
                fontWeight: _selectedTab == 1
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: onHold ? null : Colors.grey,
              ),
            ),
          ),
        ),
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
    final bool isCustomerSpeaking = _voicePhase == _VoicePhase.customerSpeaking;
    final bool isTraineeSpeaking = _voicePhase == _VoicePhase.traineeSpeaking;
    final bool isTranscribing = _voicePhase == _VoicePhase.transcribing;
    final bool isProcessing = _voicePhase == _VoicePhase.processing;
    final bool isResolved = _voicePhase == _VoicePhase.resolved;

    //becomes true if the customer is speaking or the agent is speaking
    //and if the call isnt resolved yet and the mic permission check
    //has actually finished
    final bool micEnabled =
        (isCustomerSpeaking || isTraineeSpeaking) && !isResolved && _sttReady;

    String statusText;
    if (!_sttReady) {
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
                  color: isResolved
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
                  isTraineeSpeaking ? Icons.stop_circle : Icons.mic,
                  size: 36,
                  //change the color depending on the variable state
                  color: isTraineeSpeaking
                      ? Colors.red
                      : isCustomerSpeaking
                      ? Colors.black
                      : Colors.grey,
                ),
              ),
              Text(
                //change the text depending on the variable state
                isTraineeSpeaking
                    ? 'Tap to stop'
                    : isCustomerSpeaking
                    ? 'Tap to speak'
                    : '',
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
        Text('Check the Account Lookup tab to look up their account.'),
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
          'Session is wrapping up  waiting for the last customer to finish.',
        ),
      ],
    );
  }
}
