import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';
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
import 'package:trainixprogram/models/sim_mission.dart';
import 'package:trainixprogram/models/training/customer_emotion_style.dart';
import 'package:trainixprogram/models/training/pack_session_scorer.dart';
import 'package:trainixprogram/models/training/sim_pack_selector.dart';
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
  final ValueChanged<String>? onTraineeSpoke;
  final bool showScriptGuide;
  final bool scriptGuideExpanded;
  final bool guidedMode;

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
    this.onTraineeSpoke,
    this.showScriptGuide = true,
    this.scriptGuideExpanded = true,
    this.guidedMode = true,
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
  DateTime? _holdStartedAt;
  Timer? _holdTicker;
  int _holdSeconds = 0;
  bool _holdLongWarned = false;
  final StageTracker _stageTracker = StageTracker();
  ProblemFamily? _problemFamily;
  String _familyCustomerKey = '';
  final List<CoachMessage> _coachMessages = [];
  bool _customerConfirmed = false;
  double? _handleSeconds;
  bool _traineeHasSpoken = false;
  final SimulationSessionController _sessionController =
      SimulationSessionController();
  bool _missionStartedForCall = false;
  bool? _lastSyncedIdentity;
  bool? _lastSyncedToolWork;
  String _lastSyncedToolAction = '';
  bool _toolSyncScheduled = false;
  bool _postingScripted = false;
  bool _holdCustomerAcked = false;
  bool _holdResumeAcked = false;
  bool _holdPreAcked = false;
  bool _awaitingAgentResumeLine = false;
  Timer? _voiceSilenceTimer;
  int _refusalStreak = 0;
  int _customerHeatLevel = 0;
  int _idleNudgeCount = 0;
  final List<String> _recentCustomerReactions = [];
  final ScrollController _historyScrollController = ScrollController();

  String _liveCustomerEmotion(String base) {
    return CustomerEmotionStyle.effectiveEmotion(
      baseEmotion: base,
      heatLevel: _customerHeatLevel,
    );
  }

  /// Opening customer lines held until the agent finishes the open step.
  final List<String> _heldOpeningLines = [];
  String _acwDisposition = 'Resolved';
  bool _acwPrepared = false;
  bool _sessionEscalated = false;
  bool _evaluationSubmitted = false;
  bool _evaluationInFlight = false;

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
    _holdTicker?.cancel();
    _voiceSilenceTimer?.cancel();
    _historyScrollController.dispose();
    _sttService.dispose();
    _typeCastService.stop();
    _typeCastService.stopHoldMusic();
    _reportController.dispose();
    _typeCastService.openRouterAPI.releaseHeldScenario();
    _clearRetainedAudio();
    super.dispose();
  }

  void _scrollHistoryToEnd() {
    void attempt() {
      if (!mounted || !_historyScrollController.hasClients) return;
      final target = _historyScrollController.position.maxScrollExtent;
      _historyScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      attempt();
      WidgetsBinding.instance.addPostFrameCallback((_) => attempt());
    });
  }

  void _startHoldTimer() {
    _holdStartedAt = DateTime.now();
    _holdSeconds = 0;
    _holdLongWarned = false;
    _holdTicker?.cancel();
    _holdTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (widget.phase != SimulationPhase.onHold) {
        _stopHoldTimer();
        return;
      }
      final started = _holdStartedAt;
      if (started == null) return;
      final next = DateTime.now().difference(started).inSeconds;
      final crossed = next >= 60 && !_holdLongWarned;
      setState(() {
        _holdSeconds = next;
        if (crossed) _holdLongWarned = true;
      });
      if (crossed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _nudgeCustomerStillOnHold();
        });
      }
    });
  }

  Future<void> _nudgeCustomerStillOnHold() async {
    if (!mounted) return;
    if (widget.phase != SimulationPhase.onHold) return;
    const lines = [
      'Hello? I am still on hold.',
      'Are you still checking on my account?',
      'Just making sure I am still connected while I wait.',
    ];
    final line = lines[Random().nextInt(lines.length)];
    final emotion =
        _typeCastService.openRouterAPI.chosenSimulation['emotion'] ?? 'neutral';
    _coachMessages.add(CoachMessage(isTrainee: false, text: line));
    _scrollHistoryToEnd();
    if (mounted) {
      setState(() {
        _customerTranscript = line;
      });
    }
    try {
      await _typeCastService.playCustomerLine(line, emotion);
    } catch (_) {}
  }

  void _stopHoldTimer() {
    _holdTicker?.cancel();
    _holdTicker = null;
    _holdStartedAt = null;
    _holdSeconds = 0;
    _holdLongWarned = false;
  }

  Future<void> _playHoldCustomerAck({required bool thenStartMusic}) async {
    const lines = [
      'Okay, I will hold.',
      'Alright, I am on hold.',
      'Sure, I will wait on the line.',
      'Okay, take your time. I will stay on the line.',
    ];
    final line = lines[Random().nextInt(lines.length)];
    final emotion =
        _typeCastService.openRouterAPI.chosenSimulation['emotion'] ?? 'neutral';
    _coachMessages.add(CoachMessage(isTrainee: false, text: line));
    _scrollHistoryToEnd();
    if (mounted) {
      setState(() {
        _customerTranscript = line;
        _voicePhase = _VoicePhase.customerSpeaking;
      });
    }
    try {
      await _typeCastService.playCustomerLine(line, emotion);
    } catch (_) {}
    if (!mounted) return;
    if (thenStartMusic && widget.phase == SimulationPhase.onHold) {
      await _typeCastService.startHoldMusic();
    }
    if (mounted) {
      setState(() => _voicePhase = _VoicePhase.idle);
    }
  }

  Future<void> _acknowledgeCustomerOnHold() async {
    if (!mounted || _holdCustomerAcked) return;
    if (widget.phase != SimulationPhase.onHold) return;
    _holdCustomerAcked = true;
    if (_holdPreAcked) {
      await _typeCastService.startHoldMusic();
      return;
    }
    await _playHoldCustomerAck(thenStartMusic: true);
  }

  /// Customer acknowledges hold advice while the call is still active.
  Future<void> _preAckHoldWhileActive() async {
    if (!mounted || _holdPreAcked) return;
    if (widget.phase != SimulationPhase.active) return;
    _holdPreAcked = true;
    await _playHoldCustomerAck(thenStartMusic: false);
  }

  Future<void> _acknowledgeCustomerResumedFromHold() async {
    if (!mounted || _holdResumeAcked) return;
    if (widget.phase != SimulationPhase.active) return;
    if (!_awaitingAgentResumeLine) return;
    _holdResumeAcked = true;
    _awaitingAgentResumeLine = false;
    const lines = [
      'Thanks for holding. Do you have an update on my issue?',
      'Okay, I am back. What is the status now?',
      'Thanks for holding. Were you able to find anything?',
      'I am still here. Any update after the hold?',
    ];
    final line = lines[Random().nextInt(lines.length)];
    final emotion =
        _typeCastService.openRouterAPI.chosenSimulation['emotion'] ?? 'neutral';
    _coachMessages.add(CoachMessage(isTrainee: false, text: line));
    _scrollHistoryToEnd();
    if (mounted) {
      setState(() {
        _customerTranscript = line;
        _voicePhase = _VoicePhase.customerSpeaking;
      });
    }
    try {
      await _typeCastService.playCustomerLine(line, emotion);
    } catch (_) {}
    if (mounted &&
        widget.phase == SimulationPhase.active &&
        !_customerConfirmed) {
      setState(() => _voicePhase = _VoicePhase.idle);
      _scheduleVoiceSilenceNudge();
    }
  }

  String _buildVoiceIdleNudgeLine(String emotion) {
    final emo = emotion.toLowerCase();
    final hot = emo.contains('angry') ||
        emo.contains('upset') ||
        emo.contains('frustrat') ||
        emo.contains('impatient') ||
        emo.contains('annoy');
    final disappointed = emo.contains('disappoint');
    final worried = emo.contains('worried') ||
        emo.contains('anxious') ||
        emo.contains('concern');
    final confused = emo.contains('confused');
    final sad = emo.contains('sad');
    final level = _idleNudgeCount;

    List<String> pool;
    if (hot) {
      if (level >= 2) {
        pool = const [
          'I have been waiting long enough. Are you still working on this or do I need a supervisor?',
          'This silence is not helping. I need an update on my issue right now.',
          'Hello? I am still on the line. Move this forward or escalate it.',
          'I am losing patience. Update me on the next step or get someone who can.',
        ];
      } else if (level >= 1) {
        pool = const [
          'Still waiting here. Can we move faster on this?',
          'I have been waiting on this already. Do you have an update?',
          'Are you still there? I need progress, not more silence.',
          'Checking in again. My issue is still open. What is the next step?',
        ];
      } else {
        pool = const [
          'Are you still there? I need an update on this.',
          'Hello? Are you still on the line?',
          'Any update? I am still on the call about my issue.',
          'Just checking, are you still with me?',
        ];
      }
    } else if (disappointed) {
      if (level >= 1) {
        pool = const [
          'Still no update. This is disappointing. Are you working on it?',
          'I expected a response by now. Can we continue?',
          'Silence is not helping. Please tell me the next step.',
        ];
      } else {
        pool = const [
          'Are you still there? I was hoping for an update.',
          'Just checking in. I still need help with my issue.',
          'Any word yet? I am still waiting for a clear next step.',
        ];
      }
    } else if (confused) {
      if (level >= 1) {
        pool = const [
          'I am still confused about what to do next. Are you there?',
          'Can you come back to this? I do not know the next step yet.',
          'Still waiting. Please explain where we left off.',
        ];
      } else {
        pool = const [
          'Are you still there? I am a bit lost on the next step.',
          'Just checking in. I am not sure what I should do now.',
          'Hello? I still need help understanding what happens next.',
        ];
      }
    } else if (sad) {
      if (level >= 1) {
        pool = const [
          'I am still here. This is hard. Any update when you can?',
          'Please do not leave me hanging. I need help with this.',
          'Still waiting, and it is weighing on me. Can we continue?',
        ];
      } else {
        pool = const [
          'Are you still there? I could really use an update.',
          'Just checking in. I am still on the line.',
          'I am still here if you have a next step for me.',
        ];
      }
    } else if (worried) {
      if (level >= 1) {
        pool = const [
          'I am getting really worried. Are you still working on this?',
          'Still here, and a bit anxious. Any update when you can?',
          'Please do not leave me hanging. I need to know what happens next.',
        ];
      } else {
        pool = const [
          'Are you still there? I am a little worried about this.',
          'Just checking in. Do you still need anything from me?',
          'I am still here if you have an update for me.',
        ];
      }
    } else {
      if (level >= 2) {
        pool = const [
          'I am still waiting for a response. Can we continue?',
          'Any update yet? I need to know the next step.',
          'Still on the line. Please let me know how we proceed.',
        ];
      } else if (level >= 1) {
        pool = const [
          'Just checking in again. Do you still need anything from my side?',
          'I am still here if you have an update for me.',
          'Are you still working on this? I can wait a bit longer.',
        ];
      } else {
        pool = const [
          'Are you still there?',
          'Hello? Are you still on the line?',
          'Just checking, are you still with me?',
          'I am still on the call if you have an update.',
        ];
      }
    }
    return pool[Random().nextInt(pool.length)];
  }

  void _scheduleVoiceSilenceNudge() {
    _voiceSilenceTimer?.cancel();
    if (!mounted) return;
    if (widget.phase != SimulationPhase.active) return;
    if (_customerConfirmed) return;
    if (_voicePhase == _VoicePhase.customerSpeaking ||
        _voicePhase == _VoicePhase.processing ||
        _voicePhase == _VoicePhase.transcribing) {
      return;
    }
    final seconds = 28 + Random().nextInt(18);
    _voiceSilenceTimer = Timer(Duration(seconds: seconds), () async {
      if (!mounted) return;
      if (widget.phase != SimulationPhase.active || _customerConfirmed) return;
      if (widget.phase == SimulationPhase.onHold) return;
      if (_postingScripted) {
        _scheduleVoiceSilenceNudge();
        return;
      }
      if (_voicePhase == _VoicePhase.traineeSpeaking ||
          _voicePhase == _VoicePhase.transcribing ||
          _voicePhase == _VoicePhase.processing ||
          _voicePhase == _VoicePhase.customerSpeaking) {
        _scheduleVoiceSilenceNudge();
        return;
      }
      final emotion = _liveCustomerEmotion(
        (_sessionController.mission.pack?.emotion ??
                _typeCastService.openRouterAPI.chosenSimulation['emotion'] ??
                'neutral')
            .toString(),
      );
      final line = _buildVoiceIdleNudgeLine(emotion);
      _idleNudgeCount += 1;
      _coachMessages.add(CoachMessage(isTrainee: false, text: line));
      _scrollHistoryToEnd();
      if (mounted) {
        setState(() {
          _customerTranscript = line;
          _voicePhase = _VoicePhase.customerSpeaking;
        });
      }
      try {
        await _typeCastService.playCustomerLine(line, emotion);
      } catch (_) {}
      if (mounted) {
        setState(() => _voicePhase = _VoicePhase.idle);
      }
      _scheduleVoiceSilenceNudge();
    });
  }

  Widget _buildHoldStatusStrip(
    BuildContext context,
  ) {
    final waitMin = _holdSeconds ~/ 60;
    final waitSec = _holdSeconds % 60;
    final waitLabel =
        '${waitMin.toString().padLeft(1, '0')}:${waitSec.toString().padLeft(2, '0')}';
    final waitWarm = _holdSeconds >= 60;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: waitWarm
            ? AppColors.warningTint(context)
            : AppColors.chipBg(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: waitWarm
              ? AppColors.warningText()
              : AppColors.borderStrong(context),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            waitWarm ? Icons.warning_amber_rounded : Icons.pause_circle_outline,
            size: 18,
            color: waitWarm
                ? AppColors.warningText()
                : AppColors.textMuted(context),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  waitWarm
                      ? 'Long hold · $waitLabel'
                      : 'Customer on hold · $waitLabel',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: waitWarm
                        ? AppColors.warningText()
                        : AppColors.textSecondary(context),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  waitWarm
                      ? 'Hold is running long. Finish Account Lookup or the sector guide and resume the call.'
                      : 'Use Account Lookup or the sector guide, then resume the call.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: waitWarm
                        ? AppColors.warningText()
                        : AppColors.textMuted(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
        final hasScoreableWork = _traineeHasSpoken ||
            _coachMessages.any(
              (m) => m.isTrainee && m.text.trim().isNotEmpty,
            );
        if (hasScoreableWork && !_evaluationSubmitted && !_evaluationInFlight) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _evaluateVoiceInteraction();
          });
        }
      }

      if (widget.phase == SimulationPhase.onHold) {
        _typeCastService.stop();
        _sttService.cancel();
        _voiceSilenceTimer?.cancel();
        _startHoldTimer();
        _holdCustomerAcked = false;
        _holdResumeAcked = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _acknowledgeCustomerOnHold();
        });
      }

      if (oldWidget.phase == SimulationPhase.onHold &&
          widget.phase != SimulationPhase.onHold) {
        _holdPreAcked = false;
      }

      if (oldWidget.phase == SimulationPhase.onHold &&
          widget.phase == SimulationPhase.active) {
        _stopHoldTimer();
        _typeCastService.stopHoldMusic();
        _holdResumeAcked = false;
        _awaitingAgentResumeLine = true;
        if (mounted) {
          setState(() {
            _voicePhase = _VoicePhase.customerSpeaking;
            _customerTranscript = 'Waiting for you to come back on the line...';
          });
        }
      }

      //if the current phase is incoming, then set the voice phase
      //to idle and empty the customer and agent's transcripts
      //as well as the call start time to null
      if (widget.phase == SimulationPhase.incoming) {
        _callStartTime = null;
        _stopHoldTimer();

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
          _evaluationSubmitted = false;
          _evaluationInFlight = false;
          _sessionEscalated = false;
          _coachMessages.clear();
          _sessionController.reset(notify: false);
          _problemFamily = null;
          _familyCustomerKey = '';
          _lastSyncedIdentity = null;
          _lastSyncedToolWork = null;
          _lastSyncedToolAction = '';
          _refusalStreak = 0;
          _customerHeatLevel = 0;
          _idleNudgeCount = 0;
          _recentCustomerReactions.clear();
          SimulationCoach.clearOffTrackMemory();
          _holdCustomerAcked = false;
          _holdResumeAcked = false;
          _holdPreAcked = false;
          _awaitingAgentResumeLine = false;
        });
      }
    }
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

      final pack = SimPackSelector.resolveForSector(widget.sector);

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
        packOverride: pack,
      );

      accountProvider.configureCaseGates(
        needsAccount: pack.needsAccount,
        casePackSession: true,
      );
      if (pack.needsAccount && accountProvider.accounts.isEmpty) {
        final d = pack.accountDetails;
        String targetId;
        final accountId = d['Account ID']?.trim() ?? '';
        final card = d['Card Ending']?.trim() ?? '';
        final mobile = d['Mobile Ending']?.trim() ?? '';
        final member = d['Member ID']?.trim() ?? '';
        if (accountId.isNotEmpty) {
          final digits = accountId.replaceAll(RegExp(r'[^0-9]'), '');
          targetId = 'ACC-${digits.isNotEmpty ? digits : accountId}';
        } else if (card.isNotEmpty) {
          final digits = card.replaceAll(RegExp(r'[^0-9]'), '');
          targetId = 'ACC-${digits.isNotEmpty ? digits : card}';
        } else if (mobile.isNotEmpty) {
          final digits = mobile.replaceAll(RegExp(r'[^0-9]'), '');
          targetId = 'ACC-${digits.isNotEmpty ? digits : mobile}';
        } else if (member.isNotEmpty) {
          if (member.toUpperCase().startsWith('ACC-')) {
            targetId = member;
          } else {
            final digits = member.replaceAll(RegExp(r'[^0-9]'), '');
            targetId = 'ACC-${digits.isNotEmpty ? digits : member}';
          }
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
      final emotion = _liveCustomerEmotion(
        (_sessionController.mission.pack?.emotion ??
                _typeCastService.openRouterAPI.chosenSimulation['emotion'] ??
                'neutral')
            .toString(),
      );
      for (final line in lines) {
        if (!mounted) return;
        if (line.trim().isEmpty) continue;
        final styled = CustomerEmotionStyle.apply(line.trim(), emotion);
        _coachMessages.add(CoachMessage(isTrainee: false, text: styled));
        setState(() {
          _customerTranscript = styled;
          _voicePhase = _VoicePhase.customerSpeaking;
        });
        _scrollHistoryToEnd();
        // Speak the natural line; Typecast uses emotion preset for tone.
        await _typeCastService.playCustomerLine(line.trim(), emotion);
      }
      if (mounted &&
          widget.phase == SimulationPhase.active &&
          !_customerConfirmed) {
        setState(() => _voicePhase = _VoicePhase.idle);
        _scheduleVoiceSilenceNudge();
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
      final wordCount =
          words.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

      //to get the words per minute, divide the word count to
      //how many seconds have passed
      final wpm = elapsedSeconds > 0 ? (wordCount / elapsedSeconds) * 60 : 0.0;

      widget.onVoiceTurn?.call(wpm, _countFillerWords(words));
      _traineeHasSpoken = true;
      if (words.trim().isNotEmpty) {
        _coachMessages.add(CoachMessage(isTrainee: true, text: words.trim()));
        _scrollHistoryToEnd();
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
        final shouldFinish = SimulationCoach.looksLikeClosing(words) ||
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
        _voicePhase == _VoicePhase.awaitingClosing ||
        _voicePhase == _VoicePhase.idle) {
      _voiceSilenceTimer?.cancel();
      _typeCastService.stop();

      setState(() {
        _traineeTranscript = '';
        _voicePhase = _VoicePhase.traineeSpeaking;
      });

      _turnStartTime = DateTime.now();

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
    final trimmed = spoken.trim();
    if (trimmed.isNotEmpty) {
      widget.onTraineeSpoke?.call(trimmed);
    }

    // After RESUME: agent speaks first (e.g. sorry for the wait), then customer.
    if (_awaitingAgentResumeLine && trimmed.isNotEmpty) {
      await _acknowledgeCustomerResumedFromHold();
      if (!mounted) return;
    }

    if (SimulationSessionController.useMissionGuide &&
        _sessionController.mission.pack != null) {
      try {
        final holdAdvisory = SimulationCoach.isHoldAdvisory(spoken) &&
            widget.phase == SimulationPhase.active;
        // Hold advice must not advance mission steps or queue scripted lines.
        if (!holdAdvisory) {
          _syncMissionFromCoach();
        }
        final openDoneNow = _sessionController.mission.state.done.contains(
          'open',
        );
        final releasingHeldOpen =
            openDoneNow && _heldOpeningLines.isNotEmpty;
        if (releasingHeldOpen) {
          // Agent-first open: only the held opening should play once.
          // Completing the open step also queues after-pass / next-step lines;
          // those would double the customer reply right after the spiel.
          _sessionController.mission.pendingCustomerLines
            ..clear()
            ..addAll(_heldOpeningLines);
          _heldOpeningLines.clear();
        }
        final pack = _sessionController.mission.pack!;
        final step = _sessionController.mission.currentStep;
        final rude = SimulationCoach.isInsultingAgentReply(spoken) ||
            SimulationCoach.isNegativeAgentReply(spoken);
        final offTopic = SimulationCoach.isOffTopicReply(
          spoken,
          pack.problemSummary,
        );
        final wordCount = spoken
            .trim()
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .length;
        if (holdAdvisory) {
          // Hold advice is not a mission speak turn. Do not advance steps or
          // post scripted customer lines; the hold-ack path handles the reply.
          _sessionController.mission.pendingCustomerLines.clear();
        } else if (rude || (offTopic && wordCount <= 8)) {
          if (rude) {
            _refusalStreak += 1;
            _customerHeatLevel = CustomerEmotionStyle.raiseHeat(
              _customerHeatLevel,
              strong: _refusalStreak >= 2,
            );
          } else {
            _customerHeatLevel =
                CustomerEmotionStyle.raiseHeat(_customerHeatLevel);
          }
          final liveEmotion = _liveCustomerEmotion(pack.emotion);
          final reaction = SimulationCoach.offTrackCustomerReaction(
            agentText: spoken,
            problem: pack.problemSummary,
            emotion: liveEmotion,
            customerName: pack.customerName,
            refusalStreak: _refusalStreak,
            avoidRecent: List<String>.from(_recentCustomerReactions),
          );
          _recentCustomerReactions.add(reaction);
          while (_recentCustomerReactions.length > 6) {
            _recentCustomerReactions.removeAt(0);
          }
          _sessionController.mission.queueOffTrackCustomerReaction(reaction);
        } else if (!releasingHeldOpen &&
            _sessionController.mission.pendingCustomerLines.isEmpty &&
            _sessionController.mission.lastTraineeDidNotAdvance &&
            step != null &&
            step.kind != SimStepKind.tool) {
          final liveEmotion = _liveCustomerEmotion(pack.emotion);
          final judged = await _typeCastService.openRouterAPI.judgeMissionTurn(
            agentMessage: spoken,
            stepLabel: step.label,
            stepTip: step.tip,
            stepExamples: step.examples,
            problem: pack.problemSummary,
            emotion: liveEmotion,
            customerName: pack.customerName,
          );
          if (!mounted) return;
          if (judged.adequate) {
            _refusalStreak = 0;
            _customerHeatLevel =
                CustomerEmotionStyle.coolHeat(_customerHeatLevel);
            _sessionController.mission.forceCompleteCurrentSpeakStep(
              fallbackCustomerLine: judged.customerReply,
            );
          } else {
            _customerHeatLevel =
                CustomerEmotionStyle.raiseHeat(_customerHeatLevel);
            final reply = SimulationCoach.offTrackCustomerReaction(
              agentText: spoken,
              problem: pack.problemSummary,
              emotion: _liveCustomerEmotion(pack.emotion),
              customerName: pack.customerName,
              refusalStreak: _refusalStreak,
              avoidRecent: List<String>.from(_recentCustomerReactions),
            );
            _recentCustomerReactions.add(reply);
            while (_recentCustomerReactions.length > 6) {
              _recentCustomerReactions.removeAt(0);
            }
            _sessionController.mission.queueOffTrackCustomerReaction(
              reply.trim().isNotEmpty ? reply : judged.customerReply,
            );
          }
        } else {
          _refusalStreak = 0;
          if (!releasingHeldOpen &&
              (_sessionController.mission.pendingCustomerLines.isNotEmpty ||
                  (step != null &&
                      _sessionController.mission.state.done
                          .contains(step.id)))) {
            _customerHeatLevel =
                CustomerEmotionStyle.coolHeat(_customerHeatLevel);
          }
        }
        _idleNudgeCount = 0;
        if (!holdAdvisory) {
          await _postScriptedCustomerLinesVoice();
        }
        if (!mounted) return;
        final closeDone = _sessionController.mission.state.done.contains(
          'close',
        );
        if (closeDone || _sessionController.isMissionComplete) {
          if (_callStartTime != null) {
            final seconds =
                DateTime.now().difference(_callStartTime!).inSeconds.toDouble();
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
        if (holdAdvisory) {
          await _preAckHoldWhileActive();
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
        final seconds =
            DateTime.now().difference(_callStartTime!).inSeconds.toDouble();
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
    if (_evaluationSubmitted || _evaluationInFlight) return;
    _evaluationInFlight = true;
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

    final sector = _typeCastService.openRouterAPI.chosenSimulation['sector'] ??
        widget.sector;
    final customerName =
        _typeCastService.openRouterAPI.chosenSimulation['name']?.toString() ??
            'Customer';
    final problem = _typeCastService.openRouterAPI.chosenSimulation['problem']
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
    _evaluationSubmitted = true;
    _evaluationInFlight = false;
  }

  //build the voice channel
  @override
  Widget build(BuildContext context) {
    //if the current phase is incoming, return the incoming UI
    if (widget.phase == SimulationPhase.incoming)
      return _buildIncoming(
        context,
      );

    //if the current phase is after call work, return the after call
    //work UI
    if (widget.phase == SimulationPhase.afterCallWork) {
      return _buildAfterCallWork(
        context,
      );
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
    final showAccountLookup = packNeedsAccount ||
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
        if (onHold)
          _buildHoldStatusStrip(
            context,
          ),
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
                  : (onHold
                      ? _buildOnHold(
                          context,
                        )
                      : _buildActive(
                          context,
                        )),
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
    final needsToolSync = SimulationSessionController.useMissionGuide &&
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
    final hideExamples = _postingScripted ||
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
    final guideName = _typeCastService.openRouterAPI.chosenSimulation['name'] ??
        _sessionController.mission.pack?.customerName;
    final guide = ScenarioGuideView(
      sector: voiceSector,
      emotion: _typeCastService.openRouterAPI.chosenSimulation['emotion'] ??
          _sessionController.mission.pack?.emotion,
      problem: guideProblem,
      customerName: guideName,
      coachTip: widget.guidedMode && AppSettings.coachTipsEnabled
          ? coachVm.tip
          : null,
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
        _acwDisposition = 'Escalated';
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
        _scrollHistoryToEnd();
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
          Future<void>.delayed(const Duration(milliseconds: 900), () async {
            if (!mounted || _customerConfirmed || _postingScripted) return;
            const reactions = [
              'Okay. Please make sure the specialist has my details.',
              'Thank you. I will wait for the next team to contact me.',
              'Alright. Please note that I already explained the full issue.',
            ];
            final line = reactions[Random().nextInt(reactions.length)];
            final emotion =
                _typeCastService.openRouterAPI.chosenSimulation['emotion'] ??
                    'neutral';
            _coachMessages.add(CoachMessage(isTrainee: false, text: line));
            setState(() {
              _customerTranscript = line;
              _voicePhase = _VoicePhase.customerSpeaking;
            });
            try {
              await _typeCastService.playCustomerLine(line, emotion);
            } catch (_) {}
          });
        }
      },
    );

    if (!widget.showScriptGuide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: mainColumn),
          const VerticalDivider(width: 1, thickness: 0.5),
          const SizedBox(
            width: 300,
            child: AgentNotepad(fillHeight: true),
          ),
        ],
      );
    }

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
    final showAccountLookup = packNeedsAccount ||
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

    final highlight =
        widget.guidedMode ? _sessionController.mission.highlightToolTab : null;
    final items = <Map<String, Object>>[
      {'id': 0, 'label': 'Call'},
      if (showAccountLookup) {'id': 1, 'label': 'Account Lookup'},
      if (showSectorGuide)
        {'id': 2, 'label': SimulationCoach.sectorGuideTabLabel(sectorForTabs)},
    ];

    final holdMin = _holdSeconds ~/ 60;
    final holdSec = _holdSeconds % 60;
    final holdLabel =
        '${holdMin.toString().padLeft(1, '0')}:${holdSec.toString().padLeft(2, '0')}';
    final holdWarm = onHold && _holdSeconds >= 60;

    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
      child: Row(
        children: [
          ...items.map((item) {
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
                            color: AppColors.warningText(),
                            width: 1.5,
                          ),
                          color: AppColors.warningTint(context),
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
                              ? AppColors.textMuted(context)
                              : isSelected
                                  ? AppColors.textPrimary(context)
                                  : needsAttention
                                      ? AppColors.warningText()
                                      : AppColors.textSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 2,
                        width: isSelected || needsAttention ? 36 : 0,
                        color: isSelected
                            ? AppColors.secondaryText()
                            : needsAttention
                                ? AppColors.warningText()
                                : Colors.transparent,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          if (onHold)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: holdWarm
                    ? AppColors.warningTint(context)
                    : AppColors.chipBg(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: holdWarm
                      ? AppColors.warningText()
                      : AppColors.borderStrong(context),
                ),
              ),
              child: Text(
                'On hold · $holdLabel',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: holdWarm
                      ? AppColors.warningText()
                      : AppColors.textSecondary(context),
                ),
              ),
            ),
        ],
      ),
    );
  }

  //Incoming call UI
  //Shows a customer calling using LeftCall design
  Widget _buildIncoming(
    BuildContext context,
  ) {
    return LeftCall(
      sector: widget.sector,
      phase: widget.phase,
      onAccept: widget.onAccept,
      remainingBreakSeconds: widget.remainingBreakSeconds,
    );
  }

  //Active UI
  //shows you're on a call with a customer
  Widget _buildActive(
    BuildContext context,
  ) {
    //checkers for each voice phase
    final bool isCustomerSpeaking = _voicePhase == _VoicePhase.customerSpeaking;
    final bool isTraineeSpeaking = _voicePhase == _VoicePhase.traineeSpeaking;
    final bool isTranscribing = _voicePhase == _VoicePhase.transcribing;
    final bool isProcessing = _voicePhase == _VoicePhase.processing;
    final bool isResolved = _voicePhase == _VoicePhase.resolved;
    final bool isAwaitingClosing = _voicePhase == _VoicePhase.awaitingClosing;

    final bool isIdle = _voicePhase == _VoicePhase.idle;
    final bool micEnabled = (isCustomerSpeaking ||
            isTraineeSpeaking ||
            isAwaitingClosing ||
            isIdle) &&
        !isResolved &&
        !isTranscribing &&
        !isProcessing &&
        widget.phase != SimulationPhase.onHold &&
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
    } else if (isIdle) {
      statusText = 'Your turn to speak';
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
        ? AppColors.nextTint(context)
        : isAwaitingClosing
            ? AppColors.warningText()
            : isCustomerSpeaking
                ? AppColors.nextTint(context)
                : isTraineeSpeaking
                    ? AppColors.completeTint(context)
                    : AppColors.chipBg(context);
    final statusBorder = isResolved
        ? AppColors.primaryText()
        : isAwaitingClosing
            ? AppColors.warningText()
            : isCustomerSpeaking
                ? AppColors.successText()
                : isTraineeSpeaking
                    ? AppColors.secondaryText()
                    : AppColors.borderStrong(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.elevated(context),
                ),
                child: Center(
                  child: Text(
                    customerName.isNotEmpty
                        ? customerName[0].toUpperCase()
                        : 'C',
                    style: TextStyle(
                      color: AppColors.secondaryText(),
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
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary(context),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.sector,
                      style: TextStyle(
                        color: AppColors.textMuted(context),
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
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textPrimary(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.guidedMode)
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
            hasCustomerSpoken: _customerTranscript.isNotEmpty,
            problem: _customerTranscript.isNotEmpty
                ? (_typeCastService.openRouterAPI.chosenSimulation['problem'] ??
                    '')
                : '',
            sector: _typeCastService.openRouterAPI.chosenSimulation['sector'] ??
                widget.sector,
            traineeTurnCount: _retainedAudioPaths.length,
            isChatChannel: false,
          ),
        Divider(height: 1, color: AppColors.border(context)),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Column(
              children: [
                Expanded(
                    child: _buildConversationHistory(
                  context,
                )),
                const SizedBox(height: 8),
                _buildLiveTurnStrip(
                  isTraineeSpeaking: isTraineeSpeaking,
                  isCustomerSpeaking: isCustomerSpeaking,
                  isProcessing: isProcessing,
                  isResolved: isResolved,
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
                  mouseCursor: micEnabled
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.basic,
                  onTap: micEnabled ? _onMicPressed : null,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isTraineeSpeaking
                          ? AppColors.errorStrongText()
                          : micEnabled
                              ? AppColors.nextTint(context)
                              : AppColors.chipBg(context),
                      border: Border.all(
                        color: isTraineeSpeaking
                            ? AppColors.errorStrongText()
                            : micEnabled
                                ? AppColors.successText()
                                : AppColors.borderStrong(context),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      isTraineeSpeaking ? Icons.stop_rounded : Icons.mic,
                      size: 28,
                      color: isTraineeSpeaking
                          ? AppColors.errorText()
                          : micEnabled
                              ? AppColors.successText()
                              : AppColors.textMuted(context),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 6),
              Text(
                isTraineeSpeaking
                    ? 'Tap to stop'
                    : micEnabled
                        ? 'Tap to speak'
                        : '',
                style: TextStyle(
                    fontSize: 11, color: AppColors.textMuted(context)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConversationHistory(
    BuildContext context,
  ) {
    final history =
        _coachMessages.where((m) => m.text.trim().isNotEmpty).toList();
    if (history.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Center(
          child: Text(
            'Conversation history will appear here as the call progresses.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted(context),
              height: 1.35,
            ),
          ),
        ),
      );
    }
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: ListView.builder(
        controller: _historyScrollController,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        itemCount: history.length,
        itemBuilder: (context, index) {
          final msg = history[index];
          final isTrainee = msg.isTrainee;
          final accent =
              isTrainee ? AppColors.secondaryText() : AppColors.successText();
          return Padding(
            padding:
                EdgeInsets.only(bottom: index == history.length - 1 ? 0 : 10),
            child: Column(
              crossAxisAlignment:
                  isTrainee ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  isTrainee ? 'You' : 'Customer',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
                SizedBox(height: 4),
                Container(
                  constraints: const BoxConstraints(maxWidth: 520),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isTrainee
                        ? AppColors.completeTint(context)
                        : AppColors.chipBg(context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isTrainee
                          ? AppColors.secondaryText()
                          : AppColors.borderStrong(context),
                    ),
                  ),
                  child: Text(
                    SimulationCoach.stripInternalFields(msg.text.trim()),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary(context),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLiveTurnStrip({
    required bool isTraineeSpeaking,
    required bool isCustomerSpeaking,
    required bool isProcessing,
    required bool isResolved,
  }) {
    String liveLabel;
    String liveText;
    Color accent;
    if (isResolved) {
      liveLabel = 'Status';
      liveText = 'Call resolved';
      accent = AppColors.successText();
    } else if (isTraineeSpeaking) {
      liveLabel = 'You (live)';
      liveText =
          _traineeTranscript.isEmpty ? 'Listening...' : _traineeTranscript;
      accent = AppColors.secondaryText();
    } else if (isProcessing) {
      liveLabel = 'Status';
      liveText = 'Processing your reply...';
      accent = AppColors.warningText();
    } else if (isCustomerSpeaking && _customerTranscript.isNotEmpty) {
      liveLabel = 'Customer (live)';
      liveText = SimulationCoach.stripInternalFields(_customerTranscript);
      accent = AppColors.successText();
    } else if (!_traineeHasSpoken && _customerTranscript.isEmpty) {
      liveLabel = 'You';
      liveText = 'Your turn: deliver the opening spiel';
      accent = AppColors.secondaryText();
    } else {
      liveLabel = 'Status';
      liveText = 'Your turn to speak';
      accent = AppColors.textMuted(context);
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            liveLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            liveText,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary(context),
              height: 1.35,
            ),
          ),
        ],
      ),
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
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? accent : AppColors.border(context),
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
          SizedBox(height: 6),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: empty
                      ? AppColors.textMuted(context)
                      : AppColors.textPrimary(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnHold(
    BuildContext context,
  ) {
    final waitMin = _holdSeconds ~/ 60;
    final waitSec = _holdSeconds % 60;
    final waitLabel =
        '${waitMin.toString().padLeft(1, '0')}:${waitSec.toString().padLeft(2, '0')}';
    final waitWarm = _holdSeconds >= 60;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.pause_circle_outline,
          size: 56,
          color: AppColors.warningText(),
        ),
        const SizedBox(height: 16),
        Text(
          'Call On Hold',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary(context),
            fontSize: 16,
          ),
        ),
        SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: waitWarm
                ? AppColors.warningTint(context)
                : AppColors.chipBg(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: waitWarm
                  ? AppColors.warningText()
                  : AppColors.borderStrong(context),
            ),
          ),
          child: Text(
            'Customer waiting · $waitLabel',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: waitWarm
                  ? AppColors.warningText()
                  : AppColors.textSecondary(context),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Use Account Lookup or the sector guide, then resume the call.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted(context), fontSize: 13),
          ),
        ),
        if (waitWarm)
          Padding(
            padding: EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Text(
              'Hold is running long. Finish the tool work and resume soon.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.warningText(), fontSize: 12),
            ),
          ),
      ],
    );
  }

  String _acwSuggestedNote() {
    final pack = _sessionController.mission.pack;
    final done = _sessionController.mission.state.done.toList();
    final name = _typeCastService.openRouterAPI.chosenSimulation['name'] ??
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

  Widget _buildAfterCallWork(
    BuildContext context,
  ) {
    if (!_acwPrepared) {
      _prepareAcwForm();
    }
    final textTheme = Theme.of(context).textTheme;
    final suggested = _acwSuggestedNote();
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  constraints.maxHeight > 32 ? constraints.maxHeight - 32 : 0,
              maxWidth: 640,
            ),
            child: Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.card(context),
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppColors.borderStrong(context)),
                    ),
                    child: Icon(
                      Icons.edit_note,
                      size: 32,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'After Call Work',
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Use the suggested disposition and note from this case. Edit if needed, then submit.',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary(context),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.nextTint(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.nextTint(context)),
                    ),
                    child: Text(
                      'Suggested from this case: $_acwDisposition. $suggested',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: AppColors.primaryText(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Disposition',
                    style: TextStyle(
                        color: AppColors.textMuted(context), fontSize: 12),
                  ),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _acwDisposition,
                    dropdownColor: AppColors.card(context),
                    style: TextStyle(
                        color: AppColors.textPrimary(context), fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.elevated(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Resolved',
                        child: Text('Resolved'),
                      ),
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
                    style: TextStyle(color: AppColors.textPrimary(context)),
                    decoration: InputDecoration(
                      hintText: 'Summary, next action, account notes...',
                      hintStyle: textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        color: AppColors.textMuted(context),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        borderSide: BorderSide(
                          color: AppColors.textMuted(context),
                          width: .5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        borderSide: BorderSide(
                            color: AppColors.textPrimary(context), width: 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (_evaluationInFlight) {
                        var waited = 0;
                        while (_evaluationInFlight && mounted && waited < 150) {
                          await Future<void>.delayed(
                            const Duration(milliseconds: 100),
                          );
                          waited++;
                        }
                      }
                      if (!mounted) return;
                      _reportController.clear();
                      _acwPrepared = false;
                      widget.onSendReport?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryText(),
                      foregroundColor: AppColors.onPrimary(context),
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
      },
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
