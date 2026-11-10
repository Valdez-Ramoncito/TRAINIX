import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:trainixprogram/models/customer_account.dart';
import 'package:trainixprogram/models/messages.dart';
import 'package:trainixprogram/models/session_score.dart';
import 'package:trainixprogram/models/simulation_history.dart';
import 'package:trainixprogram/models/simulation_phase.dart';
import 'package:trainixprogram/services/gemini_voice_evaluation_api_service.dart';
import 'package:trainixprogram/services/speech_to_text_service.dart';
import 'package:trainixprogram/services/type_cast_api_service.dart';
import 'package:trainixprogram/models/simulation_coach.dart';
import 'package:trainixprogram/models/simulation_stage.dart';
import 'package:trainixprogram/models/problem_family.dart';
import 'package:trainixprogram/models/coach_view_model.dart';
import 'package:trainixprogram/models/simulation_session_controller.dart';
import 'package:trainixprogram/models/sim_mission_catalog.dart';
import 'package:trainixprogram/models/training/pack_session_scorer.dart';
import 'package:trainixprogram/screens/mock_call_ui/left_call.dart';
import 'package:trainixprogram/widgets/account_lookup_view.dart';
import 'package:trainixprogram/widgets/sector_issue_guide_view.dart';
import 'package:trainixprogram/widgets/scenario_guide_view.dart';
import 'package:trainixprogram/widgets/agent_notepad.dart';
import 'package:trainixprogram/widgets/session_guidance_banner.dart';
import 'package:trainixprogram/screens/settings_screen.dart';

//enumeration for the phases of the voice call
enum _VoicePhase {
  idle,
  customerSpeaking,
  traineeSpeaking,
  transcribing,
  processing,
  awaitingClosing,
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
  final bool showScriptGuide;
  final bool scriptGuideExpanded;

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
    this.showScriptGuide = true,
    this.scriptGuideExpanded = true,
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
  final StageTracker _stageTracker = StageTracker();
  ProblemFamily? _problemFamily;
  String _familyCustomerKey = '';
  final List<CoachMessage> _coachMessages = [];
  bool _customerConfirmed = false;
  double? _handleSeconds;
  bool _traineeHasSpoken = false;
  static int _scriptedPackSalt = 0;
  final SimulationSessionController _sessionController =
      SimulationSessionController();
  bool _missionStartedForCall = false;
  bool? _lastSyncedIdentity;
  bool? _lastSyncedToolWork;
  String _lastSyncedToolAction = '';
  bool _toolSyncScheduled = false;
  bool _postingScripted = false;

  /// Opening customer lines held until the agent finishes the open step.
  final List<String> _heldOpeningLines = [];
  String _acwDisposition = 'Resolved';
  bool _acwPrepared = false;
  bool _sessionEscalated = false;

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
        if (SimulationSessionController.useMissionGuide) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _startScriptedMissionCase();
          });
        }
      }

      if (widget.phase == SimulationPhase.afterCallWork) {
        _prepareAcwForm();
      }

      //if the current phase is on hold
      //stop the typecast and cancel the speech to text
      if (widget.phase == SimulationPhase.onHold) {
        _typeCastService.stop();
        _sttService.cancel();
      }

      // Leaving hold: resume listening. Keep Account Lookup open if the
      // current mission step still needs a tool action.
      if (oldWidget.phase == SimulationPhase.onHold &&
          widget.phase == SimulationPhase.active) {
        setState(() {
          _voicePhase = _VoicePhase.customerSpeaking;
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
          _customerConfirmed = false;
          _handleSeconds = null;
          _traineeHasSpoken = false;
          _missionStartedForCall = false;
          _heldOpeningLines.clear();
          _acwPrepared = false;
          _acwDisposition = 'Resolved';
          _sessionEscalated = false;
          _coachMessages.clear();
          _sessionController.reset(notify: false);
          _problemFamily = null;
          _familyCustomerKey = '';
          _lastSyncedIdentity = null;
          _lastSyncedToolWork = null;
          _lastSyncedToolAction = '';
        });
      }
    }
  }

  ProblemFamily _scriptedFamilyForSector(String sector) {
    final s = sector.toLowerCase();
    final n = _scriptedPackSalt++;
    if (s.contains('finance') || s.contains('bank')) {
      return n.isEven
          ? ProblemFamily.billingSurprise
          : ProblemFamily.fundTransfer;
    }
    if (s.contains('health')) {
      const opts = [
        ProblemFamily.claimStatus,
        ProblemFamily.prescriptionRefill,
        ProblemFamily.appointmentPrep,
      ];
      return opts[n % opts.length];
    }
    if (s.contains('telco') || s.contains('telecom') || s.contains('mobile')) {
      return n.isEven
          ? ProblemFamily.networkConnectivity
          : ProblemFamily.planEligibility;
    }
    if (s.contains('tech') || s.contains('it')) {
      return n.isEven
          ? ProblemFamily.loginAccess
          : ProblemFamily.genericNonAccount;
    }
    return n.isEven
        ? ProblemFamily.genericAccount
        : ProblemFamily.genericNonAccount;
  }

  Future<void> _startScriptedMissionCase() async {
    if (!mounted || _missionStartedForCall) return;
    _missionStartedForCall = true;
    try {
      final accountProvider = Provider.of<AccountProvider>(
        context,
        listen: false,
      );
      accountProvider.reset();
      _coachMessages.clear();

      final family = _scriptedFamilyForSector(widget.sector);
      final pack = SimMissionCatalog.resolve(
        sector: widget.sector,
        problem: family.name,
        family: family,
        needsAccount: ProblemFamilyClassifier.defaultNeedsAccount(family),
      );

      _typeCastService.openRouterAPI.chosenSimulation = {
        'sector': pack.sector,
        'name': pack.customerName,
        'problem': pack.problemSummary,
        'emotion': pack.emotion,
        'needsAccount': pack.needsAccount ? 'true' : 'false',
        'casePackId': pack.id,
      };
      _typeCastService.openRouterAPI.hasStarted = true;

      _problemFamily = pack.family;
      _familyCustomerKey = '${pack.sector}|${pack.problemSummary}';
      _stageTracker.reset();
      _sessionController.startCase(
        sector: pack.sector,
        problem: pack.problemSummary,
        family: pack.family,
        needsAccount: pack.needsAccount,
      );

      accountProvider.configureCaseGates(
        needsAccount: pack.needsAccount,
        casePackSession: true,
      );
      if (pack.needsAccount && accountProvider.accounts.isEmpty) {
        final d = pack.accountDetails;
        String targetId;
        final card = d['Card Ending']?.trim() ?? '';
        final mobile = d['Mobile Ending']?.trim() ?? '';
        final member = d['Member ID']?.trim() ?? '';
        if (card.isNotEmpty) {
          final digits = card.replaceAll(RegExp(r'[^0-9]'), '');
          targetId = 'ACC-${digits.isNotEmpty ? digits : card}';
        } else if (mobile.isNotEmpty) {
          final digits = mobile.replaceAll(RegExp(r'[^0-9]'), '');
          targetId = 'ACC-${digits.isNotEmpty ? digits : mobile}';
        } else if (member.isNotEmpty) {
          final digits = member.replaceAll(RegExp(r'[^0-9]'), '');
          final n = int.tryParse(digits) ?? pack.customerName.hashCode.abs();
          targetId = 'ACC-${(n % 9000) + 1000}';
        } else {
          targetId = 'ACC-${pack.customerName.hashCode.abs() % 9000 + 1000}';
        }
        accountProvider.generateAccounts(
          sector: pack.sector,
          targetAccountId: targetId,
          problem: pack.problemSummary,
          targetOwnerName: pack.customerName,
          targetDetailExtras: pack.accountDetails,
        );
      }

      // Voice: agent greets first. Do not auto-play opening customer TTS.
      // startCase queues the opening line; hold it until open step is done.
      _heldOpeningLines
        ..clear()
        ..addAll(_sessionController.mission.takePendingCustomerLines());
      setState(() {
        _customerTranscript = '';
        _traineeTranscript = '';
        _voicePhase = _VoicePhase.customerSpeaking;
        _traineeHasSpoken = false;
        _acwPrepared = false;
      });
    } catch (e) {
      debugPrint('voice scripted mission open failed: $e');
      _missionStartedForCall = false;
    }
  }

  void _syncMissionFromCoach() {
    if (!mounted) return;
    _sessionController.replaceMessages(
      List<CoachMessage>.from(_coachMessages),
      notify: false,
    );
    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );
    _sessionController.syncFromAccount(
      identityVerified: accountProvider.identityVerified,
      toolWorkDone: accountProvider.toolWorkDone,
      lastToolAction: accountProvider.lastToolAction,
      notify: false,
    );
  }

  Future<void> _postScriptedCustomerLinesVoice() async {
    if (!mounted || _postingScripted) return;
    final lines = _sessionController.mission.takePendingCustomerLines();
    if (lines.isEmpty) return;
    _postingScripted = true;
    try {
      final emotion =
          _typeCastService.openRouterAPI.chosenSimulation['emotion'] ??
          'neutral';
      for (final line in lines) {
        if (!mounted) return;
        if (line.trim().isEmpty) continue;
        _coachMessages.add(CoachMessage(isTrainee: false, text: line.trim()));
        setState(() {
          _customerTranscript = line;
          _voicePhase = _VoicePhase.customerSpeaking;
        });
        await _typeCastService.playCustomerLine(line, emotion);
      }
    } finally {
      _postingScripted = false;
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

      widget.onVoiceTurn?.call(wpm, _countFillerWords(words));
      _traineeHasSpoken = true;
      if (words.trim().isNotEmpty) {
        _coachMessages.add(CoachMessage(isTrainee: true, text: words.trim()));
      }

      if (_customerConfirmed) {
        final wantsEscalation = SimulationCoach.looksLikeEscalation(words);
        if (wantsEscalation && !_sessionEscalated) {
          if (mounted) {
            setState(() {
              _traineeTranscript = words;
              _selectedTab = 0;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Open the Escalation tab and submit the handoff before closing.',
                ),
              ),
            );
          }
          return;
        }
        final shouldFinish =
            SimulationCoach.looksLikeClosing(words) ||
            (_sessionEscalated && wantsEscalation);
        if (shouldFinish) {
          setState(() {
            _traineeTranscript = words;
            _voicePhase = _VoicePhase.resolved;
          });
          await _evaluateVoiceInteraction();
          return;
        }
        setState(() {
          _traineeTranscript = words;
          _voicePhase = _VoicePhase.processing;
        });
        await _sendToCustomer(words);
        return;
      }
      setState(() {
        _traineeTranscript = words;
        _voicePhase = _VoicePhase.processing;
      });
      await _sendToCustomer(words);
      return;
    }
    if (_voicePhase == _VoicePhase.customerSpeaking ||
        _voicePhase == _VoicePhase.awaitingClosing) {
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

    if (SimulationSessionController.useMissionGuide &&
        _sessionController.mission.pack != null) {
      try {
        _syncMissionFromCoach();
        // After the agent completes the open step, release held opening lines.
        final openDoneNow = _sessionController.mission.state.done.contains(
          'open',
        );
        if (openDoneNow && _heldOpeningLines.isNotEmpty) {
          _sessionController.mission.pendingCustomerLines.addAll(
            _heldOpeningLines,
          );
          _heldOpeningLines.clear();
        }
        await _postScriptedCustomerLinesVoice();
        if (!mounted) return;
        final closeDone = _sessionController.mission.state.done.contains(
          'close',
        );
        if (closeDone || _sessionController.isMissionComplete) {
          if (_callStartTime != null) {
            final seconds = DateTime.now()
                .difference(_callStartTime!)
                .inSeconds
                .toDouble();
            widget.onResolutionSeconds?.call(seconds);
            _handleSeconds = seconds;
          }
          Provider.of<AccountProvider>(
            context,
            listen: false,
          ).confirmCustomerResolved();
          _prepareAcwForm();
          setState(() {
            _customerConfirmed = true;
            _voicePhase = _VoicePhase.awaitingClosing;
          });
          return;
        }
        if (mounted && _voicePhase == _VoicePhase.processing) {
          setState(() => _voicePhase = _VoicePhase.customerSpeaking);
        }
      } catch (e) {
        print('[VOICE] mission send failed: $e');
        if (mounted) {
          setState(() => _voicePhase = _VoicePhase.customerSpeaking);
        }
      }
      return;
    }

    try {
      final response = await _typeCastService.getResponse(context, spoken);
      print(
        '[VOICE] got response  reply="${response.reply}" callStatus=${response.callStatus} isError=${response.isError}',
      );
      if (!mounted) return;

      final cleaned = SimulationCoach.stripInternalFields(response.reply);
      if (cleaned.trim().isNotEmpty) {
        _coachMessages.add(
          CoachMessage(isTrainee: false, text: cleaned.trim()),
        );
      }

      if (response.isError) {
        setState(() {
          _customerTranscript =
              'Could not reach the customer. Please try again in a moment.';
          _voicePhase = _VoicePhase.customerSpeaking;
        });
        return;
      }

      await _handleCustomerResponse(response);
    } catch (e) {
      print('[VOICE] send failed: $e');
      if (!mounted) return;
      setState(() {
        _customerTranscript =
            'Connection problem. Check your network and try again.';
        _voicePhase = _VoicePhase.customerSpeaking;
      });
    }
  }

  Future<void> _handleCustomerResponse(dynamic response) async {
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

    if (response.callStatus == 'resolved' || response.callStatus == 'ended') {
      final accountProvider = Provider.of<AccountProvider>(
        context,
        listen: false,
      );
      accountProvider.confirmCustomerResolved();
      if (_callStartTime != null) {
        final seconds = DateTime.now()
            .difference(_callStartTime!)
            .inSeconds
            .toDouble();
        widget.onResolutionSeconds?.call(seconds);
        _handleSeconds = seconds;
      }
      setState(() {
        _customerTranscript = response.reply;
        _voicePhase = _VoicePhase.awaitingClosing;
        _customerConfirmed = true;
      });
      return;
    }

    if (_customerConfirmed && _voicePhase == _VoicePhase.awaitingClosing) {
      setState(() {
        _customerTranscript = response.reply;
        _voicePhase = _VoicePhase.resolved;
      });
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
    final messageProvider = Provider.of<MessageProvider>(
      context,
      listen: false,
    );
    final historyProvider = Provider.of<SimulationHistoryProvider>(
      context,
      listen: false,
    );
    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );

    final audioPaths = List<String>.from(_retainedAudioPaths);

    // Prefer coach transcript in mission mode; MessageProvider is often empty
    // on pure voice scripted runs and used to force a zero fallback score.
    final List<Message> evalMessages;
    if (_coachMessages.isNotEmpty) {
      evalMessages = _coachMessages
          .map(
            (m) => Message(
              role: m.isTrainee ? 'user' : 'assistant',
              message: m.text,
            ),
          )
          .toList();
    } else {
      evalMessages = List.from(messageProvider.messages);
    }

    final sector =
        _typeCastService.openRouterAPI.chosenSimulation['sector'] ??
        widget.sector;
    final customerName =
        _typeCastService.openRouterAPI.chosenSimulation['name']?.toString() ??
        'Customer';
    final problem =
        _typeCastService.openRouterAPI.chosenSimulation['problem']
            ?.toString() ??
        '';
    final emotion =
        _typeCastService.openRouterAPI.chosenSimulation['emotion'] ?? '';

    final localGates = PackSessionScorer.scoreChat(
      messages: evalMessages,
      sector: sector,
      customerName: customerName,
      problem: problem,
      emotion: emotion,
      toolWorkDone: accountProvider.toolWorkDone,
      accountSelected: accountProvider.selectedAccount != null,
      needsAccount: accountProvider.needsAccount,
      acwSubmitted: true,
      acwDisposition: _acwDisposition,
      handleSeconds: _handleSeconds,
    );

    SessionEvaluation evaluation;
    try {
      evaluation = await GeminiVoiceEvaluationApiService().evaluateVoiceTesda(
        messages: evalMessages,
        sector: sector,
        customerEmotion: emotion,
        customerProblem: problem,
        audioFilePaths: audioPaths,
      );
    } catch (_) {
      evaluation = localGates;
    }
    if (evaluation.overallScore < 1.0 &&
        localGates.overallScore > evaluation.overallScore) {
      evaluation = localGates;
    }

    await _clearRetainedAudio();

    if (!mounted) return;

    final conv = evalMessages
        .map(
          (m) => {
            'role': m.role == 'user' ? 'agent' : 'customer',
            'text': SimulationCoach.stripInternalFields(m.message),
          },
        )
        .toList();
    var finalEvaluation = evaluation.withMeta(
      customerName: customerName,
      channel: 'voice',
      problem: problem,
      conversation: conv,
    );
    if (_handleSeconds != null) {
      finalEvaluation = finalEvaluation.withAht(handleSeconds: _handleSeconds!);
    }

    historyProvider.saveEvaluation(finalEvaluation);
    widget.onEvaluation?.call(finalEvaluation);
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

    final bool onHold = widget.phase == SimulationPhase.onHold;
    final sectorForTabs =
        _typeCastService.openRouterAPI.chosenSimulation['sector'] ??
        widget.sector;
    final problemForTabs =
        _typeCastService.openRouterAPI.chosenSimulation['problem'] ?? '';
    final packNeedsAccount =
        _sessionController.mission.pack?.needsAccount == true;
    final showAccountLookup =
        packNeedsAccount ||
        SimulationCoach.needsAccountLookup(
          problemForTabs,
          sector: sectorForTabs,
        );
    final showSectorGuide = SimulationCoach.needsSectorGuide(
      problemForTabs,
      sector: sectorForTabs,
    );
    // Account Lookup only while on hold (agent must advise hold first).
    int effectiveTab = _selectedTab;
    if (effectiveTab == 1 && (!onHold || !showAccountLookup)) effectiveTab = 0;
    if (effectiveTab == 2 && !showSectorGuide) effectiveTab = 0;
    if (effectiveTab > 2) effectiveTab = 0;

    final mainColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTabBar(onHold: onHold),
        const Divider(height: 1),
        Expanded(
          child: effectiveTab == 1 && showAccountLookup && onHold
              ? AccountLookupView(sector: widget.sector)
              : effectiveTab == 2 && showSectorGuide
              ? SectorIssueGuideView(
                  sector: sectorForTabs,
                  customerProblem: problemForTabs,
                  onIssueOpened: () {
                    _sessionController.markSectorGuideIssueOpened();
                    if (mounted) setState(() {});
                  },
                )
              : (onHold ? _buildOnHold() : _buildActive()),
        ),
      ],
    );

    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );
    final voiceProblem =
        _typeCastService.openRouterAPI.chosenSimulation['problem'] ?? '';
    final voiceSector =
        _typeCastService.openRouterAPI.chosenSimulation['sector'] ??
        widget.sector;
    final voiceElapsed = _callStartTime == null
        ? 0
        : DateTime.now().difference(_callStartTime!).inSeconds;
    final familyKey = '$voiceSector|$voiceProblem';
    if (_problemFamily == null || _familyCustomerKey != familyKey) {
      if (SimulationSessionController.useMissionGuide &&
          _sessionController.mission.pack != null) {
        _problemFamily = _sessionController.mission.pack!.family;
        _familyCustomerKey = familyKey;
      } else if (!SimulationSessionController.useMissionGuide) {
        final needsAccount = SimulationCoach.needsAccountLookup(
          voiceProblem,
          sector: voiceSector,
        );
        _problemFamily = ProblemFamilyClassifier.classify(
          problem: voiceProblem,
          sector: voiceSector,
          lastCustomerMessage: _customerTranscript,
          needsAccount: needsAccount,
        );
        _familyCustomerKey = familyKey;
        _stageTracker.reset();
        _coachMessages.clear();
      } else {
        _problemFamily ??= ProblemFamily.genericNonAccount;
        _familyCustomerKey = familyKey;
      }
    }
    final idNow = accountProvider.identityVerified;
    final toolNow = accountProvider.toolWorkDone;
    final actionNow = accountProvider.lastToolAction;
    final needsToolSync =
        SimulationSessionController.useMissionGuide &&
        _sessionController.mission.pack != null &&
        (idNow != _lastSyncedIdentity ||
            toolNow != _lastSyncedToolWork ||
            actionNow != _lastSyncedToolAction);
    if (needsToolSync && !_toolSyncScheduled) {
      _lastSyncedIdentity = idNow;
      _lastSyncedToolWork = toolNow;
      _lastSyncedToolAction = actionNow;
      _toolSyncScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        _toolSyncScheduled = false;
        if (!mounted) return;
        _syncMissionFromCoach();
        // Never auto-play held opening or pending lines before the agent
        // has spoken at least once on this call.
        if (_traineeHasSpoken &&
            _sessionController.mission.pendingCustomerLines.isNotEmpty &&
            !_postingScripted) {
          await _postScriptedCustomerLinesVoice();
        } else if (mounted) {
          setState(() {});
        }
      });
    }
    CoachViewModel coachVm;
    if (SimulationSessionController.useMissionGuide &&
        _sessionController.mission.pack != null) {
      coachVm = _sessionController.toCoachViewModel(
        family: _sessionController.mission.pack!.family,
      );
    } else {
      final voiceState = CoachSessionState(
        sector: voiceSector,
        problemText: voiceProblem,
        needsAccount: ProblemFamilyClassifier.defaultNeedsAccount(
          _problemFamily!,
        ),
        messages: List<CoachMessage>.from(_coachMessages),
        identityVerified: accountProvider.identityVerified,
        toolWorkDone: accountProvider.toolWorkDone,
        customerResolved: _customerConfirmed,
        customerEmotion:
            _typeCastService.openRouterAPI.chosenSimulation['emotion'] ?? '',
        elapsed: Duration(seconds: voiceElapsed),
        channel: SimulationChannel.voice,
        readyToClose: _voicePhase == _VoicePhase.awaitingClosing,
      );
      coachVm = CoachViewModel.from(
        state: voiceState,
        tracker: _stageTracker,
        family: _problemFamily!,
      );
    }
    final hideExamples =
        _postingScripted ||
        _voicePhase == _VoicePhase.processing ||
        _voicePhase == _VoicePhase.transcribing;
    // Until the customer actually speaks, never show problem-specific open
    // lines. Applies to every sector and pack on voice.
    final customerSilent = _customerTranscript.trim().isEmpty;
    final openDone = _sessionController.mission.state.done.contains('open');
    final agentFirstPhase =
        _sessionController.mission.pack != null && customerSilent;
    if (agentFirstPhase && !openDone) {
      final agentName = SimulationCoach.agentName;
      coachVm = CoachViewModel(
        stage: coachVm.stage,
        family: coachVm.family,
        tip:
            'Give your name and Trainix Support. Invite them to share the issue. Do not name a specific problem until they say it.',
        examples: [
          ScriptLine(
            category: 'guide',
            choiceNumber: 1,
            title: 'Opening spiel',
            text:
                'Thank you for contacting Trainix Support. This is $agentName. How can I help you today?',
          ),
        ],
        steps: coachVm.steps,
        stepIndex: coachVm.stepIndex,
        showEscalation: coachVm.showEscalation,
        amberOverride: null,
        checklistLabels: coachVm.checklistLabels,
        checklistStatuses: coachVm.checklistStatuses,
        currentObjectiveLabel: 'Deliver opening spiel',
        highlightToolTab: null,
        hideFocusDuplicate: coachVm.hideFocusDuplicate,
      );
    } else if (agentFirstPhase && openDone) {
      coachVm = CoachViewModel(
        stage: coachVm.stage,
        family: coachVm.family,
        tip:
            'Wait for the customer to state their issue. Do not assume the problem yet.',
        examples: const [],
        steps: coachVm.steps,
        stepIndex: coachVm.stepIndex,
        showEscalation: coachVm.showEscalation,
        amberOverride: null,
        checklistLabels: coachVm.checklistLabels,
        checklistStatuses: coachVm.checklistStatuses,
        currentObjectiveLabel: 'Listen for the customer issue',
        highlightToolTab: null,
        hideFocusDuplicate: coachVm.hideFocusDuplicate,
      );
    } else if (hideExamples && coachVm.examples.isNotEmpty) {
      coachVm = CoachViewModel(
        stage: coachVm.stage,
        family: coachVm.family,
        tip: coachVm.tip,
        examples: const [],
        steps: coachVm.steps,
        stepIndex: coachVm.stepIndex,
        showEscalation: coachVm.showEscalation,
        amberOverride: coachVm.amberOverride,
        checklistLabels: coachVm.checklistLabels,
        checklistStatuses: coachVm.checklistStatuses,
        currentObjectiveLabel: coachVm.currentObjectiveLabel,
        highlightToolTab: coachVm.highlightToolTab,
        hideFocusDuplicate: coachVm.hideFocusDuplicate,
      );
    }
    final packProblem = _sessionController.mission.pack?.problemSummary ?? '';
    final guideProblem = agentFirstPhase
        ? ''
        : (voiceProblem.trim().isNotEmpty ? voiceProblem : packProblem);
    final guideName =
        _typeCastService.openRouterAPI.chosenSimulation['name'] ??
        _sessionController.mission.pack?.customerName;
    final guide = ScenarioGuideView(
      sector: voiceSector,
      emotion:
          _typeCastService.openRouterAPI.chosenSimulation['emotion'] ??
          _sessionController.mission.pack?.emotion,
      problem: guideProblem,
      customerName: guideName,
      coachTip: AppSettings.coachTipsEnabled ? coachVm.tip : null,
      customerConfirmed: _customerConfirmed,
      awaitingClosing: _voicePhase == _VoicePhase.awaitingClosing,
      hasTraineeSpoken: _traineeHasSpoken,
      hasCustomerSpoken: true,
      toolWorkDone: accountProvider.toolWorkDone,
      traineeTurnCount: _coachMessages.where((m) => m.isTrainee).length,
      lastCustomerMessage: _customerTranscript,
      showEscalationTab: coachVm.showEscalation,
      coachVm: coachVm,
      isEscalating: _sessionEscalated,
      onEscalationSubmit: (msg) {
        _sessionEscalated = true;
        final accountProvider = Provider.of<AccountProvider>(
          context,
          listen: false,
        );
        accountProvider.markToolWorkDone(
          action: 'Escalate to specialist',
          note: 'Escalation handoff submitted from Escalation tab.',
        );
        _coachMessages.add(CoachMessage(isTrainee: true, text: msg));
        _traineeHasSpoken = true;
        _traineeTranscript = msg;
        _sessionController.replaceMessages(
          List<CoachMessage>.from(_coachMessages),
          notify: false,
        );
        _sessionController.syncFromAccount(
          identityVerified: accountProvider.identityVerified,
          toolWorkDone: accountProvider.toolWorkDone,
          lastToolAction: accountProvider.lastToolAction,
          notify: false,
        );
        if (_sessionController.mission.pendingCustomerLines.isNotEmpty &&
            !_postingScripted) {
          _postScriptedCustomerLinesVoice();
        } else if (mounted) {
          setState(() {});
        }
      },
    );

    if (!widget.showScriptGuide) return mainColumn;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: mainColumn),
        const VerticalDivider(width: 1, thickness: 0.5),
        CollapsibleScriptGuide(
          initiallyExpanded: widget.scriptGuideExpanded,
          child: guide,
        ),
      ],
    );
  }

  Widget _buildTabBar({required bool onHold}) {
    final sectorForTabs =
        _typeCastService.openRouterAPI.chosenSimulation['sector'] ??
        widget.sector;
    final problemForTabs =
        _typeCastService.openRouterAPI.chosenSimulation['problem'] ?? '';
    final packNeedsAccount =
        _sessionController.mission.pack?.needsAccount == true;
    final showAccountLookup =
        packNeedsAccount ||
        SimulationCoach.needsAccountLookup(
          problemForTabs,
          sector: sectorForTabs,
        );
    final showSectorGuide = SimulationCoach.needsSectorGuide(
      problemForTabs,
      sector: sectorForTabs,
    );
    int safeTab = _selectedTab;
    if (safeTab == 1 && (!onHold || !showAccountLookup)) safeTab = 0;
    if (safeTab == 2 && !showSectorGuide) safeTab = 0;
    if (safeTab > 2) safeTab = 0;

    final highlight = _sessionController.mission.highlightToolTab;
    final items = <Map<String, Object>>[
      {'id': 0, 'label': 'Call'},
      if (showAccountLookup) {'id': 1, 'label': 'Account Lookup'},
      if (showSectorGuide)
        {'id': 2, 'label': SimulationCoach.sectorGuideTabLabel(sectorForTabs)},
    ];

    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
      child: Row(
        children: items.map((item) {
          final id = item['id'] as int;
          final label = item['label'] as String;
          final isSelected = safeTab == id;
          final needsAttention =
              highlight != null && highlight == id && !isSelected;
          final accountLocked = id == 1 && !onHold;
          return MouseRegion(
            cursor: accountLocked
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click,
            child: GestureDetector(
              onTap: accountLocked
                  ? null
                  : () {
                      setState(() => _selectedTab = id);
                      if (id == 1) {
                        _sessionController.markToolAreaVisited();
                      }
                    },
              child: Container(
                margin: const EdgeInsets.only(right: 20),
                padding: needsAttention
                    ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
                    : EdgeInsets.zero,
                decoration: needsAttention
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFF59E0B),
                          width: 1.5,
                        ),
                        color: const Color(0x33F59E0B),
                      )
                    : null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected || needsAttention
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: accountLocked
                            ? const Color(0xFF6B7280)
                            : isSelected
                            ? Colors.white
                            : needsAttention
                            ? const Color(0xFFFBBF24)
                            : const Color(0xFFB0B8C4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 2,
                      width: isSelected || needsAttention ? 36 : 0,
                      color: isSelected
                          ? const Color(0xFF3B82F6)
                          : needsAttention
                          ? const Color(0xFFF59E0B)
                          : Colors.transparent,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  //Incoming call UI
  //Shows a customer calling using LeftCall design
  Widget _buildIncoming() {
    return LeftCall(
      sector: widget.sector,
      phase: widget.phase,
      onAccept: widget.onAccept,
      remainingBreakSeconds: widget.remainingBreakSeconds,
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
    final bool isAwaitingClosing = _voicePhase == _VoicePhase.awaitingClosing;

    final bool micEnabled =
        (isCustomerSpeaking || isTraineeSpeaking || isAwaitingClosing) &&
        !isResolved &&
        _sttReady;

    String statusText;
    if (!_sttReady) {
      statusText = 'Preparing microphone...';
    } else if (isResolved) {
      statusText = 'Resolved';
    } else if (isAwaitingClosing) {
      statusText = 'Deliver closing spiel';
    } else if (isTranscribing) {
      statusText = 'Checking your reply...';
    } else if (isTraineeSpeaking) {
      statusText = 'Your turn';
    } else if (isProcessing) {
      statusText = 'Processing...';
    } else if (isCustomerSpeaking &&
        _customerTranscript.isEmpty &&
        !_traineeHasSpoken) {
      statusText = 'Your turn: deliver the opening spiel';
    } else if (isCustomerSpeaking && _customerTranscript.isEmpty) {
      statusText = 'Your turn to speak';
    } else if (isCustomerSpeaking) {
      statusText = 'Customer speaking';
    } else {
      statusText = 'Waiting';
    }

    final customerName =
        _typeCastService.openRouterAPI.chosenSimulation['name'] ?? 'Customer';
    final statusBg = isResolved
        ? const Color(0xFF14532D)
        : isAwaitingClosing
        ? const Color(0xFF78350F)
        : isCustomerSpeaking
        ? const Color(0xFF14532D)
        : isTraineeSpeaking
        ? const Color(0xFF1E3A5F)
        : const Color(0xFF1F2937);
    final statusBorder = isResolved
        ? const Color(0xFF22C55E)
        : isAwaitingClosing
        ? const Color(0xFFF59E0B)
        : isCustomerSpeaking
        ? const Color(0xFF4ADE80)
        : isTraineeSpeaking
        ? const Color(0xFF60A5FA)
        : const Color(0xFF374151);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF1E293B),
                ),
                child: Center(
                  child: Text(
                    customerName.isNotEmpty
                        ? customerName[0].toUpperCase()
                        : 'C',
                    style: const TextStyle(
                      color: Color(0xFF93C5FD),
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.sector,
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusBorder),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SessionGuidanceBanner(
          objective: SimulationCoach.objectiveForProblem(
            _typeCastService.openRouterAPI.chosenSimulation['problem'] ?? '',
            sector:
                _typeCastService.openRouterAPI.chosenSimulation['sector'] ??
                widget.sector,
          ),
          startedAt: _callStartTime,
          ahtLimitSeconds: SimulationCoach.ahtLimitSeconds,
          customerConfirmed: _customerConfirmed,
          awaitingClosing: isAwaitingClosing,
          hasTraineeSpoken: _traineeHasSpoken,
          // Banner tip uses real speech only so it does not say the
          // customer already stated the issue before they talk.
          hasCustomerSpoken: _customerTranscript.isNotEmpty,
          problem: _customerTranscript.isNotEmpty
              ? (_typeCastService.openRouterAPI.chosenSimulation['problem'] ??
                    '')
              : '',
          sector:
              _typeCastService.openRouterAPI.chosenSimulation['sector'] ??
              widget.sector,
          traineeTurnCount: _retainedAudioPaths.length,
          isChatChannel: false,
        ),
        const Divider(height: 1, color: Color(0xFF2A313A)),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Column(
              children: [
                Expanded(
                  child: _voiceTranscriptCard(
                    label: 'Customer',
                    text: _customerTranscript.isEmpty
                        ? 'Waiting for customer...'
                        : SimulationCoach.stripInternalFields(
                            _customerTranscript,
                          ),
                    empty: _customerTranscript.isEmpty,
                    accent: const Color(0xFF4ADE80),
                    active:
                        isCustomerSpeaking && _customerTranscript.isNotEmpty,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _voiceTranscriptCard(
                    label: 'You',
                    text: _traineeTranscript.isEmpty
                        ? (isTraineeSpeaking
                              ? 'Listening...'
                              : (!_traineeHasSpoken &&
                                        _customerTranscript.isEmpty
                                    ? 'Your turn: deliver the opening spiel'
                                    : 'Your response will appear here...'))
                        : _traineeTranscript,
                    empty: _traineeTranscript.isEmpty,
                    accent: const Color(0xFF60A5FA),
                    active:
                        isTraineeSpeaking ||
                        (!_traineeHasSpoken &&
                            _customerTranscript.isEmpty &&
                            !isProcessing &&
                            !isResolved),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: micEnabled ? _onMicPressed : null,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isTraineeSpeaking
                          ? const Color(0xFF7F1D1D)
                          : micEnabled
                          ? const Color(0xFF14532D)
                          : const Color(0xFF1F2937),
                      border: Border.all(
                        color: isTraineeSpeaking
                            ? const Color(0xFFEF4444)
                            : micEnabled
                            ? const Color(0xFF4ADE80)
                            : const Color(0xFF4B5563),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      isTraineeSpeaking ? Icons.stop_rounded : Icons.mic,
                      size: 28,
                      color: isTraineeSpeaking
                          ? const Color(0xFFFCA5A5)
                          : micEnabled
                          ? const Color(0xFF86EFAC)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isTraineeSpeaking
                    ? 'Tap to stop'
                    : micEnabled
                    ? 'Tap to speak'
                    : '',
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _voiceTranscriptCard({
    required String label,
    required String text,
    required bool empty,
    required Color accent,
    required bool active,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF12171E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? accent : const Color(0xFF2A313A),
          width: active ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: empty ? const Color(0xFF9CA3AF) : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnHold() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.pause_circle_outline, size: 56, color: Color(0xFFF59E0B)),
        SizedBox(height: 16),
        Text(
          'Call On Hold',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Use Account Lookup or the sector guide, then resume the call.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
          ),
        ),
      ],
    );
  }

  String _acwSuggestedNote() {
    final pack = _sessionController.mission.pack;
    final done = _sessionController.mission.state.done.toList();
    final name =
        _typeCastService.openRouterAPI.chosenSimulation['name'] ??
        pack?.customerName ??
        'Customer';
    final problem =
        _typeCastService.openRouterAPI.chosenSimulation['problem'] ??
        pack?.problemSummary ??
        '';
    final branch = _sessionController.mission.evidence.branch;
    final parts = <String>[
      'Customer: $name.',
      if (problem.toString().trim().isNotEmpty) 'Issue: $problem.',
    ];
    if (done.contains('verify') ||
        _sessionController.mission.evidence.identityVerified) {
      parts.add('Identity verified.');
    }
    if (done.contains('act') ||
        _sessionController.mission.evidence.requestFiled) {
      parts.add('Service request filed.');
    }
    if (done.contains('guide') || done.contains('confirm')) {
      parts.add('Guidance given and customer response noted.');
    }
    if (branch == 'escalate' ||
        done.contains('escalate') ||
        done.contains('handoff') ||
        _sessionEscalated ||
        _sessionController.mission.evidence.escalationSubmitted) {
      parts.add('Escalated to specialist path.');
    }
    if (done.contains('close')) {
      parts.add('Case closed with customer.');
    }
    if (parts.length <= 2) {
      parts.add('Summarize what you did and the next step.');
    }
    return parts.join(' ');
  }

  String _acwSuggestedDisposition() {
    final branch = _sessionController.mission.evidence.branch;
    if (branch == 'escalate' ||
        _sessionController.mission.state.done.contains('escalate') ||
        _sessionController.mission.state.done.contains('handoff') ||
        _sessionEscalated ||
        _sessionController.mission.evidence.escalationSubmitted ||
        _sessionController.mission.pack?.family == ProblemFamily.trueEscalate) {
      return 'Escalated';
    }
    if (_sessionController.isMissionComplete ||
        _sessionController.mission.state.done.contains('close')) {
      return 'Resolved';
    }
    return 'Pending customer';
  }

  void _prepareAcwForm() {
    _acwDisposition = _acwSuggestedDisposition();
    final suggested = _acwSuggestedNote();
    final notes = SessionNotesStore.selectedBody;
    if (notes.isNotEmpty) {
      _reportController.text = '$suggested\nAgent notes: $notes';
    } else {
      _reportController.text = suggested;
    }
    _acwPrepared = true;
  }

  Widget _buildAfterCallWork() {
    if (!_acwPrepared) {
      _prepareAcwForm();
    }
    final textTheme = Theme.of(context).textTheme;
    final suggested = _acwSuggestedNote();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF191919),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF303030)),
                ),
                child: const Icon(
                  Icons.edit_note,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'After Call Work',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Use the suggested disposition and note from this case. Edit if needed, then submit.',
                style: textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFF4F3F3),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF15201A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2E4A38)),
                ),
                child: Text(
                  'Suggested from this case: $_acwDisposition. $suggested',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: Color(0xFFD7E8DB),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Disposition',
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _acwDisposition,
                dropdownColor: const Color(0xFF1A1F26),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'Resolved', child: Text('Resolved')),
                  DropdownMenuItem(
                    value: 'Escalated',
                    child: Text('Escalated'),
                  ),
                  DropdownMenuItem(
                    value: 'Pending customer',
                    child: Text('Pending customer'),
                  ),
                  DropdownMenuItem(
                    value: 'Information only',
                    child: Text('Information only'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _acwDisposition = v);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _reportController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Summary, next action, account notes...',
                  hintStyle: textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    color: const Color(0xFFBBBBBB),
                  ),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    borderSide: BorderSide(color: Color(0xFFBBBBBB), width: .5),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    borderSide: BorderSide(color: Colors.white, width: 1),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _reportController.clear();
                  _acwPrepared = false;
                  widget.onSendReport?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text('Submit Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostCallBreak() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RepaintBoundary(
          child: Lottie.asset(
            'assets/animations/break_loading.json',
            width: 80,
          ),
        ),
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
