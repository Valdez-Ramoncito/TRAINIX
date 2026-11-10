import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:trainixprogram/models/customer_account.dart';
import 'package:trainixprogram/models/messages.dart';
import 'package:trainixprogram/models/session_score.dart';
import 'package:trainixprogram/models/sim_mission.dart';
import 'package:trainixprogram/models/simulation_coach.dart';
import 'package:trainixprogram/models/simulation_stage.dart';
import 'package:trainixprogram/models/problem_family.dart';
import 'package:trainixprogram/models/coach_view_model.dart';
import 'package:trainixprogram/models/case_checklist.dart';
import 'package:trainixprogram/models/simulation_session_controller.dart';
import 'package:trainixprogram/models/sim_mission_catalog.dart';
import 'package:trainixprogram/models/simulation_history.dart';
import 'package:trainixprogram/models/training/pack_session_scorer.dart';
import 'package:trainixprogram/services/gemini_evaluation_api_service.dart';
import 'package:trainixprogram/services/open_router_api_service.dart';
import 'package:trainixprogram/screens/mock_call_ui/right_message.dart';
import 'package:trainixprogram/widgets/agent_notepad.dart';
import 'package:trainixprogram/widgets/session_guidance_banner.dart';
import 'package:trainixprogram/screens/settings_screen.dart';

//enumeration for the phases of the chat conversation
enum _ChatPhase {
  active,
  awaitingClosing,
  afterCallWork,
  gracePeriod,
  waitingToEnd,
}

//handles the text based customer interaction
//runs parallel with the voice channel
//a customer in a voice channel is different from a customer
//in this channel
class ChatPanel extends StatefulWidget {
  //accept a sector that was chosen
  final String sector;

  //adds the evaluation and increments interaction
  final ValueChanged<SessionEvaluation>? onEvaluation;
  final bool scriptGuideExpanded;

  //records words per minute typed
  final ValueChanged<double>? onChatTurn;

  //how long did the problem got resolved
  final ValueChanged<double>? onResolutionSeconds;

  //can another chat start?
  final bool Function()? canStartNewCustomer;

  //tells the parent when chat enters/leaves its own after-work-report or
  //grace-period flow, so the session can't end out from under it
  final ValueChanged<bool>? onBusyChanged;

  //tells the parent chat has started serving a customer
  //fired for the first customer and such
  final VoidCallback? onCustomerStarted;

  //constructor
  const ChatPanel({
    super.key,
    required this.sector,
    this.onEvaluation,
    this.scriptGuideExpanded = true,
    this.onChatTurn,
    this.onResolutionSeconds,
    this.canStartNewCustomer,
    this.onBusyChanged,
    this.onCustomerStarted,
  });
  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  //grace period set
  static const int _graceMinSeconds = 15;
  static const int _graceMaxSeconds = 30;

  //starting type timer
  DateTime? _typingStartTime;

  //TESDA telemetry, scoped to the CURRENT customer interaction only

  //total backspace keystrokes across every message typed to this
  //customer so far. Detected as a length decrease in the input field
  //not a true per-keystroke listener
  int _interactionBackspaceCount = 0;

  //total characters actually sent across every
  //message this interaction used with the backspace count above to
  //derive a keystroke-accuracy percentage
  int _interactionCharsTyped = 0;

  //previous input field length, used to detect backspace events in
  //onChanged
  int _previousInputLength = 0;

  //one WPM sample per message sent this interaction, averaged at
  //evaluation time
  final List<double> _interactionWpmSamples = [];

  //whether a send is currently in progress
  //blocks a second send from starting before the first one
  //finishes
  bool _isSending = false;
  bool _openFailed = false;

  //controller for chat message
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();

  //controller for the after-chat-work report
  final TextEditingController _reportController = TextEditingController();
  String _acwDisposition = 'Resolved';
  bool _acwSubmitted = false;

  //selected tab
  //0 - Chat
  //1 - Account Lookup
  //2 - Scenario Guide
  int _selectedTab = 0;

  //thet phase of the chat
  _ChatPhase _chatPhase = _ChatPhase.active;
  final StageTracker _stageTracker = StageTracker();
  ProblemFamily? _problemFamily;
  String _familyCustomerKey = '';

  //remaining seconds of the grace period
  int _remainingSeconds = 0;

  //ticker for grace period
  Timer? _graceTimer;

  //declaring an instance of the API
  late final OpenRouterAPIService openRouterAPI;

  //resolution timer
  DateTime? _customerStartTime;
  bool _customerConfirmed = false;
  static int _scriptedPackSalt = 0;
  bool _postingScripted = false;
  bool? _lastSyncedIdentity;
  bool? _lastSyncedToolWork;
  String _lastSyncedToolAction = '';
  bool _missionStartedForCustomer = false;
  final SimulationSessionController _sessionController =
      SimulationSessionController();
  double? _handleSeconds;
  bool _traineeHasSpoken = false;
  bool _sessionEscalated = false;
  bool _waitingForCustomer = false;
  Timer? _customerCheckTimer;
  Timer? _idleNudgeTimer;
  final List<String> _reminders = [];

  @override
  void initState() {
    super.initState();
    openRouterAPI = OpenRouterAPIService(fixedSector: widget.sector);
    _customerStartTime = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onCustomerStarted?.call();
      _attachAccountListener();
      _requestOpeningMessage();
    });
  }

  AccountProvider? _accountProviderRef;

  void _attachAccountListener() {
    if (!mounted) return;
    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );
    _accountProviderRef?.removeListener(_onAccountChanged);
    _accountProviderRef = accountProvider;
    accountProvider.addListener(_onAccountChanged);
  }

  void _onAccountChanged() {
    if (!mounted) return;
    if (!SimulationSessionController.useMissionGuide) return;
    if (_sessionController.mission.pack == null) return;
    final accountProvider = _accountProviderRef;
    if (accountProvider == null) return;
    final idNow = accountProvider.identityVerified;
    final toolNow = accountProvider.toolWorkDone;
    final actionNow = accountProvider.lastToolAction;
    if (idNow == _lastSyncedIdentity &&
        toolNow == _lastSyncedToolWork &&
        actionNow == _lastSyncedToolAction) {
      return;
    }
    _lastSyncedIdentity = idNow;
    _lastSyncedToolWork = toolNow;
    _lastSyncedToolAction = actionNow;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncMissionMessages();
      if (_sessionController.mission.pendingCustomerLines.isNotEmpty &&
          !_postingScripted) {
        _postScriptedCustomerLines();
      } else if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _accountProviderRef?.removeListener(_onAccountChanged);
    _accountProviderRef = null;
    _graceTimer?.cancel();
    _customerCheckTimer?.cancel();
    _idleNudgeTimer?.cancel();
    _inputController.dispose();
    _inputFocusNode.dispose();
    _reportController.dispose();
    openRouterAPI.releaseHeldScenario();
    super.dispose();
  }

  //make the customer in the chat channel to chat first
  Future<void> _requestOpeningMessage() async {
    if (SimulationSessionController.useMissionGuide) {
      await _startScriptedMissionCase();
      return;
    }
    setState(() {
      _isSending = true;
      _openFailed = false;
    });

    Future<bool> tryOpen() async {
      final response = await openRouterAPI.getOpeningMessage(context);
      if (!mounted) return false;
      if (response.isError) return false;
      final accountProvider = Provider.of<AccountProvider>(
        context,
        listen: false,
      );
      final needsAccount =
          openRouterAPI.chosenSimulation['needsAccount'] == 'true';
      final casePack = openRouterAPI.chosenSimulation['casePackId'] != null;
      accountProvider.configureCaseGates(
        needsAccount: needsAccount,
        casePackSession: casePack,
      );
      if (needsAccount && accountProvider.accounts.isEmpty) {
        final targetId =
            response.accountId ??
            'ACC-${(openRouterAPI.chosenSimulation['name'] ?? 'C').hashCode.abs() % 90000 + 10000}';
        accountProvider.generateAccounts(
          sector: widget.sector,
          targetAccountId: targetId,
          problem: openRouterAPI.chosenSimulation['problem'] ?? '',
          targetOwnerName: openRouterAPI.chosenSimulation['name'] ?? 'Customer',
        );
      }
      if (response.accountProvided && response.accountId != null) {
        if (accountProvider.accounts.isEmpty) {
          accountProvider.generateAccounts(
            sector: widget.sector,
            targetAccountId: response.accountId!,
            problem: openRouterAPI.chosenSimulation['problem'] ?? '',
            targetOwnerName:
                openRouterAPI.chosenSimulation['name'] ?? 'Customer',
          );
        }
      }
      return true;
    }

    try {
      var ok = await tryOpen();
      if (!ok && mounted) {
        await Future<void>.delayed(const Duration(milliseconds: 700));
        if (!mounted) return;
        ok = await tryOpen();
      }
      if (!mounted) return;
      if (!ok) {
        setState(() => _openFailed = true);
        return;
      }
    } catch (e) {
      debugPrint('chat opening failed: $e');
      if (mounted) {
        try {
          await Future<void>.delayed(const Duration(milliseconds: 700));
          if (!mounted) return;
          final ok = await tryOpen();
          if (!ok && mounted) setState(() => _openFailed = true);
        } catch (_) {
          if (mounted) setState(() => _openFailed = true);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        if (!_openFailed) {
          _ensureAhtStarted();
          _scheduleIdleNudge();
          _focusChatInputIfReady();
        }
      }
    }
  }

  Future<void> _startScriptedMissionCase() async {
    if (_missionStartedForCustomer) return;
    if (!mounted) return;
    _missionStartedForCustomer = true;
    if (mounted) {
      setState(() {
        _isSending = true;
        _openFailed = false;
        _customerConfirmed = false;
        _sessionEscalated = false;
      });
    }
    try {
      if (!mounted) return;
      final messageProvider = Provider.of<MessageProvider>(
        context,
        listen: false,
      );
      final accountProvider = Provider.of<AccountProvider>(
        context,
        listen: false,
      );
      messageProvider.clearMessage(notify: false);
      accountProvider.reset(notify: false);

      final family = _scriptedFamilyForSector(widget.sector);
      final pack = SimMissionCatalog.resolve(
        sector: widget.sector,
        problem: family.name,
        family: family,
        needsAccount: ProblemFamilyClassifier.defaultNeedsAccount(family),
      );

      openRouterAPI.chosenSimulation = {
        'sector': pack.sector,
        'name': pack.customerName,
        'problem': pack.problemSummary,
        'emotion': pack.emotion,
        'needsAccount': pack.needsAccount ? 'true' : 'false',
        'casePackId': pack.id,
      };
      openRouterAPI.hasStarted = true;

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
        notify: false,
      );
      if (pack.needsAccount && accountProvider.accounts.isEmpty) {
        final targetId = _targetAccountIdForPack(pack);
        accountProvider.generateAccounts(
          sector: pack.sector,
          targetAccountId: targetId,
          problem: pack.problemSummary,
          targetOwnerName: pack.customerName,
          targetDetailExtras: pack.accountDetails,
          notify: false,
        );
      }

      if (!mounted) return;
      messageProvider.notifyNow();
      accountProvider.notifyNow();
      setState(() {
        _isSending = false;
        _openFailed = false;
        _waitingForCustomer = true;
      });
      _ensureAhtStarted();
      // Slight delay before the customer's first line so the open feels natural.
      await Future<void>.delayed(
        Duration(milliseconds: 900 + Random().nextInt(700)),
      );
      if (!mounted) return;
      await _postScriptedCustomerLines();
      if (!mounted) return;
      _focusChatInputIfReady();
      _scheduleIdleNudge();
    } catch (e) {
      debugPrint('scripted mission open failed: $e');
      _missionStartedForCustomer = false;
      if (mounted) {
        setState(() {
          _isSending = false;
          _openFailed = true;
        });
      }
    }
  }

  String _targetAccountIdForPack(SimPack pack) {
    final d = pack.accountDetails;
    final card = d['Card Ending'];
    if (card != null && card.trim().isNotEmpty) {
      final digits = card.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.isNotEmpty) return 'ACC-$digits';
    }
    final mobile = d['Mobile Ending'];
    if (mobile != null && mobile.trim().isNotEmpty) {
      final digits = mobile.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.isNotEmpty) return 'ACC-$digits';
    }
    final member = d['Member ID'];
    if (member != null && member.trim().isNotEmpty) {
      final digits = member.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.isNotEmpty) {
        final n = int.tryParse(digits) ?? pack.customerName.hashCode.abs();
        return 'ACC-${(n % 9000) + 1000}';
      }
    }
    return 'ACC-${pack.customerName.hashCode.abs() % 9000 + 1000}';
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

  void _syncMissionMessages() {
    if (!mounted) return;
    final messageProvider = Provider.of<MessageProvider>(
      context,
      listen: false,
    );
    final coachMessages = <CoachMessage>[
      for (final m in messageProvider.messages)
        CoachMessage(isTrainee: m.role == 'user', text: m.message),
    ];
    _sessionController.replaceMessages(coachMessages, notify: false);
    if (!mounted) return;
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

  Future<void> _postScriptedCustomerLines() async {
    if (!mounted || _postingScripted) return;
    final lines = _sessionController.mission.takePendingCustomerLines();
    if (lines.isEmpty) return;
    _postingScripted = true;
    final messageProvider = Provider.of<MessageProvider>(
      context,
      listen: false,
    );
    if (!mounted) {
      _postingScripted = false;
      return;
    }
    setState(() => _waitingForCustomer = true);
    try {
      for (final line in lines) {
        if (!mounted) return;
        final delayMs = 1400 + Random().nextInt(1200);
        await Future<void>.delayed(Duration(milliseconds: delayMs));
        if (!mounted) return;
        if (line.trim().isEmpty) continue;
        messageProvider.addMessage('assistant', line);
        if (!mounted) return;
        _syncMissionMessages();
      }
    } finally {
      _postingScripted = false;
    }
    if (mounted) {
      setState(() => _waitingForCustomer = false);
      _focusChatInputIfReady();
    }
  }

  void _focusChatInputIfReady() {
    if (!mounted || _openFailed) return;
    if (_chatPhase != _ChatPhase.active) return;
    if (_isSending || _waitingForCustomer) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_inputFocusNode.hasFocus) {
        _inputFocusNode.requestFocus();
      }
    });
  }

  //build the chat panel connect with right_message

  CoachViewModel _buildCoachVm({
    required List messages,
    required String problem,
    required String sector,
    required bool toolWorkDone,
    required bool identityVerified,
    required bool hasCustomerMessage,
    required int elapsedSeconds,
    required AccountProvider accountProvider,
  }) {
    final key = '$sector|$problem';
    // Never mutate mission/session controllers during build.
    // Scripted packs are started only in _startScriptedMissionCase.
    if (_problemFamily == null || _familyCustomerKey != key) {
      if (SimulationSessionController.useMissionGuide &&
          _sessionController.mission.pack != null) {
        _problemFamily = _sessionController.mission.pack!.family;
        _familyCustomerKey = key;
      } else if (!SimulationSessionController.useMissionGuide) {
        final escalateFromStart =
            (openRouterAPI.chosenSimulation['escalateFromStart'] == true) ||
            (openRouterAPI.chosenSimulation['escalateFromStart'] == 'true');
        final needsAccount =
            openRouterAPI.chosenSimulation['needsAccount'] == true ||
            openRouterAPI.chosenSimulation['needsAccount'] == 'true' ||
            SimulationCoach.needsAccountLookup(problem, sector: sector);
        String lastCust = '';
        for (var i = messages.length - 1; i >= 0; i--) {
          if (messages[i].role == 'assistant') {
            lastCust = messages[i].message;
            break;
          }
        }
        _problemFamily = ProblemFamilyClassifier.classify(
          problem: problem,
          sector: sector,
          lastCustomerMessage: lastCust,
          escalateFromStart: escalateFromStart,
          needsAccount: needsAccount,
        );
        _familyCustomerKey = key;
        _stageTracker.reset();
      } else {
        // Mission mode but pack not ready yet (opening in progress).
        _problemFamily ??= ProblemFamily.genericNonAccount;
        _familyCustomerKey = key;
      }
    }
    final coachMessages = <CoachMessage>[
      for (final m in messages)
        CoachMessage(isTrainee: m.role == 'user', text: m.message),
    ];
    final needsAccount =
        ProblemFamilyClassifier.defaultNeedsAccount(_problemFamily!) ||
        openRouterAPI.chosenSimulation['needsAccount'] == true ||
        openRouterAPI.chosenSimulation['needsAccount'] == 'true';
    final acc = accountProvider.selectedAccount;
    final details = acc == null
        ? <String, String>{}
        : Map<String, String>.from(acc.details);
    final statusLabel =
        details['Coverage'] ??
        details['Status'] ??
        details['Claim Status'] ??
        details['Plan Status'] ??
        '';
    final issueLine = details['Issue'] ?? details['Problem'] ?? problem;
    final state = CoachSessionState(
      sector: sector,
      problemText: problem,
      needsAccount: needsAccount,
      escalateFromStart:
          openRouterAPI.chosenSimulation['escalateFromStart'] == true ||
          openRouterAPI.chosenSimulation['escalateFromStart'] == 'true',
      messages: coachMessages,
      identityVerified: identityVerified,
      toolWorkDone: toolWorkDone,
      customerResolved:
          _customerConfirmed || accountProvider.customerConfirmedResolved,
      customerEmotion: openRouterAPI.chosenSimulation['emotion'] ?? '',
      elapsed: Duration(seconds: elapsedSeconds),
      channel: SimulationChannel.chat,
      readyToClose: _chatPhase == _ChatPhase.awaitingClosing,
      accountStatusLabel: statusLabel,
      accountOwnerName: acc?.ownerName ?? '',
      accountIssueLine: issueLine,
      accountDetails: details,
    );
    // Pure read during build. Mission advances only on send/tool/start.
    if (SimulationSessionController.useMissionGuide) {
      if (_sessionController.mission.pack != null) {
        final vm = _sessionController.toCoachViewModel(
          family: _sessionController.mission.pack!.family,
        );
        if (_waitingForCustomer || _postingScripted) {
          return CoachViewModel(
            stage: vm.stage,
            family: vm.family,
            tip: vm.tip,
            examples: const [],
            steps: vm.steps,
            stepIndex: vm.stepIndex,
            showEscalation: vm.showEscalation,
            amberOverride: vm.amberOverride,
            checklistLabels: vm.checklistLabels,
            checklistStatuses: vm.checklistStatuses,
            currentObjectiveLabel: vm.currentObjectiveLabel,
            highlightToolTab: vm.highlightToolTab,
            hideFocusDuplicate: vm.hideFocusDuplicate,
          );
        }
        return vm;
      }
      return CoachViewModel(
        stage: SimulationStage.waitCustomer,
        family: _problemFamily ?? ProblemFamily.genericNonAccount,
        tip: 'Connecting you with the next customer...',
        examples: const [],
        steps: const [],
        stepIndex: 0,
        showEscalation: false,
      );
    }
    return CoachViewModel.from(
      state: state,
      tracker: _stageTracker,
      family: _problemFamily!,
    );
  }

  @override
  Widget build(BuildContext context) {
    //non-active phases take over the whole panel, the same way voice's
    //After Call Work, break, wrapping-up screens replace its content
    //entirely instead of showing as a small banner
    if (_chatPhase == _ChatPhase.afterCallWork) {
      return _buildAfterCallWork();
    }
    if (_chatPhase == _ChatPhase.gracePeriod) {
      return _buildGracePeriodScreen();
    }
    if (_chatPhase == _ChatPhase.waitingToEnd) {
      return _buildWaitingToEndScreen();
    }
    if (_openFailed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: Colors.white54,
              ),
              const SizedBox(height: 12),
              const Text(
                'Could not reach the customer',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Connection problem. Check your network and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isSending ? null : _requestOpeningMessage,
                child: Text(_isSending ? 'Retrying...' : 'Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final messageProvider = Provider.of<MessageProvider>(context, listen: true);
    final accountProvider = Provider.of<AccountProvider>(context, listen: true);
    final hasCustomerMessage = messageProvider.messages.any(
      (m) => m.role == 'assistant',
    );
    final problem = openRouterAPI.chosenSimulation['problem'] ?? '';
    final awaitingClosing = _chatPhase == _ChatPhase.awaitingClosing;
    final toolWorkDone = accountProvider.toolWorkDone;
    final messages = messageProvider.messages;
    final lastCustomerText = messages.any((m) => m.role == 'assistant')
        ? messages.reversed.firstWhere((m) => m.role == 'assistant').message
        : '';
    final lastTraineeText = messages.any((m) => m.role == 'user')
        ? messages.reversed.firstWhere((m) => m.role == 'user').message
        : '';
    final elapsedSeconds = _customerStartTime == null
        ? 0
        : DateTime.now().difference(_customerStartTime!).inSeconds;
    final sector = openRouterAPI.chosenSimulation['sector'] ?? widget.sector;
    final coachVm = _buildCoachVm(
      messages: messages,
      problem: problem,
      sector: sector,
      toolWorkDone: toolWorkDone,
      identityVerified: accountProvider.identityVerified,
      hasCustomerMessage: hasCustomerMessage,
      elapsedSeconds: elapsedSeconds,
      accountProvider: accountProvider,
    );
    final showEscalation = coachVm.showEscalation;

    final panel = RightMessage(
      sector: hasCustomerMessage
          ? (openRouterAPI.chosenSimulation['sector'] ?? widget.sector)
          : widget.sector,
      customerName: hasCustomerMessage
          ? (openRouterAPI.chosenSimulation['name'] ?? 'New Customer')
          : 'Waiting for customer',
      customerProblem: hasCustomerMessage
          ? openRouterAPI.chosenSimulation['problem']
          : null,
      customerEmotion: hasCustomerMessage
          ? openRouterAPI.chosenSimulation['emotion']
          : null,
      selectedTab: _selectedTab,
      highlightToolTab: SimulationSessionController.useBlueprintGuide
          ? _sessionController.highlightToolTab
          : null,
      onTabChanged: (index) {
        setState(() => _selectedTab = index);
        if (index == 1) {
          _sessionController.markToolAreaVisited();
        }
        if (index == 1 || index == 2) {
          setState(() {});
        }
      },
      onSectorGuideIssueOpened: () {
        _sessionController.markSectorGuideIssueOpened();
        if (mounted) setState(() {});
      },
      inputController: _inputController,
      inputFocusNode: _inputFocusNode,
      onSendMessage: sendChatmessage,
      isSending: _isSending || _waitingForCustomer,
      waitingForCustomer: _waitingForCustomer,
      customerHasSpoken: hasCustomerMessage || awaitingClosing,
      customerNameForGuide: hasCustomerMessage
          ? openRouterAPI.chosenSimulation['name']
          : null,
      accountId: openRouterAPI.chosenSimulation['accountId'],
      coachTip: AppSettings.coachTipsEnabled ? coachVm.tip : null,
      customerConfirmed: _customerConfirmed,
      awaitingClosing: awaitingClosing,
      hasTraineeSpoken: _traineeHasSpoken,
      reminders: List<String>.from(_reminders),
      scriptGuideExpanded: widget.scriptGuideExpanded,
      toolWorkDone: toolWorkDone,
      showEscalationTab: showEscalation,
      coachVm: coachVm,
      isEscalating: _sessionEscalated,
      traineeTurnCount: _interactionWpmSamples.length,
      lastCustomerMessage: lastCustomerText,
      lastTraineeMessage: lastTraineeText,
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
        _syncMissionMessages();
        _inputController.text = msg;
        sendChatmessage();
      },
      inputHint: awaitingClosing
          ? (_sessionEscalated
                ? 'Type your escalation closing...'
                : 'Type your closing spiel...')
          : null,
      onInputChanged: (value) {
        if (value.length < _previousInputLength) {
          _interactionBackspaceCount += (_previousInputLength - value.length);
        }
        _previousInputLength = value.length;
        if (value.isNotEmpty && _typingStartTime == null) {
          _typingStartTime = DateTime.now();
        } else if (value.isEmpty) {
          _typingStartTime = null;
        }
      },
      chatHeader: SessionGuidanceBanner(
        objective: SimulationCoach.objectiveForProblem(
          problem,
          sector: openRouterAPI.chosenSimulation['sector'] ?? widget.sector,
        ),
        startedAt: _customerStartTime,
        ahtLimitSeconds: SimulationCoach.ahtLimitSeconds,
        customerConfirmed: _customerConfirmed,
        awaitingClosing: awaitingClosing,
        hasTraineeSpoken: _traineeHasSpoken,
        hasCustomerSpoken: hasCustomerMessage,
        problem: problem,
        sector: openRouterAPI.chosenSimulation['sector'] ?? widget.sector,
        traineeTurnCount: _interactionWpmSamples.length,
        toolWorkDone: toolWorkDone,
        isEscalating: _sessionEscalated,
        lastCustomerMessage: lastCustomerText,
        lastTraineeMessage: lastTraineeText,
        isChatChannel: true,
      ),
    );
    return panel;
  }

  String _acwSuggestedNote() {
    final pack = _sessionController.mission.pack;
    final done = _sessionController.mission.state.done.toList();
    final name = openRouterAPI.chosenSimulation['name'] ?? 'Customer';
    final problem =
        openRouterAPI.chosenSimulation['problem'] ?? pack?.problemSummary ?? '';
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
        _sessionController.mission.evidence.escalationSubmitted) {
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
    _acwSubmitted = false;
  }

  //after chat work report UI
  Widget _buildAfterCallWork() {
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
              const Gap(20),
              const Text(
                'After Chat Work',
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
              const Gap(12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF15201A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2E4A38)),
                ),
                child: Text(
                  'Suggested from this case: ${_acwSuggestedDisposition()}. $suggested',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: Color(0xFFD7E8DB),
                  ),
                ),
              ),
              const Gap(24),
              const Text(
                'Disposition',
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
              ),
              const Gap(8),
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
              const Gap(16),
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
                  setState(() => _acwSubmitted = true);
                  _reportController.clear();
                  _startGracePeriod();
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

  //grace period UI
  Widget _buildGracePeriodScreen() {
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
        Text('Next chat in $_remainingSeconds seconds...'),
      ],
    );
  }

  Widget _buildWaitingToEndScreen() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle_outline, size: 56, color: Color(0xFF34D399)),
        SizedBox(height: 16),
        Text(
          'Wrapping Up',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        SizedBox(height: 8),
        Text(
          'Quota complete. Session is wrapping up.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _evaluateResolution() async {
    //initialize message and history providers
    final messageProvider = Provider.of<MessageProvider>(
      context,
      listen: false,
    );
    final historyProvider = Provider.of<SimulationHistoryProvider>(
      context,
      listen: false,
    );

    //compute this interaction's average typing pace
    final avgWpm = _interactionWpmSamples.isEmpty
        ? 0.0
        : _interactionWpmSamples.reduce((a, b) => a + b) /
              _interactionWpmSamples.length;

    //keystroke accuracy - characters that survived to being sent,
    //divided by total keystrokes
    final totalKeystrokes = _interactionCharsTyped + _interactionBackspaceCount;
    final accuracy = totalKeystrokes > 0
        ? (_interactionCharsTyped / totalKeystrokes) * 100
        : 100.0;

    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );
    final localGates = PackSessionScorer.scoreChat(
      messages: List.from(messageProvider.messages),
      sector: openRouterAPI.chosenSimulation['sector'] ?? widget.sector,
      customerName:
          openRouterAPI.chosenSimulation['name']?.toString() ?? 'Customer',
      problem: openRouterAPI.chosenSimulation['problem']?.toString() ?? '',
      emotion: openRouterAPI.chosenSimulation['emotion']?.toString() ?? '',
      toolWorkDone: accountProvider.toolWorkDone,
      accountSelected: accountProvider.selectedAccount != null,
      needsAccount: accountProvider.needsAccount,
      acwSubmitted: _acwSubmitted,
      acwDisposition: _acwDisposition,
      handleSeconds: _handleSeconds,
    );

    SessionEvaluation evaluation;
    try {
      evaluation = await GeminiEvaluationApiService().evaluateChatTesda(
        messages: List.from(messageProvider.messages),
        sector: openRouterAPI.chosenSimulation['sector'] ?? '',
        customerEmotion: openRouterAPI.chosenSimulation['emotion'] ?? '',
        customerProblem: openRouterAPI.chosenSimulation['problem'] ?? '',
        typingWpm: avgWpm,
        typingAccuracy: accuracy,
        backspaceCount: _interactionBackspaceCount,
      );
    } catch (_) {
      evaluation = localGates;
    }
    // Never keep a near-zero API score when the agent clearly worked the case.
    if (evaluation.overallScore < 1.0 &&
        localGates.overallScore > evaluation.overallScore) {
      evaluation = localGates;
    }

    if (mounted) {
      final conv = messageProvider.messages
          .map(
            (m) => {
              'role': m.role == 'user' ? 'agent' : 'customer',
              'text': SimulationCoach.stripInternalFields(m.message),
            },
          )
          .toList();
      var finalEvaluation = evaluation.withMeta(
        customerName:
            openRouterAPI.chosenSimulation['name']?.toString() ?? 'Customer',
        channel: 'chat',
        problem: openRouterAPI.chosenSimulation['problem']?.toString() ?? '',
        conversation: conv,
      );
      if (_handleSeconds != null) {
        finalEvaluation = finalEvaluation.withAht(
          handleSeconds: _handleSeconds!,
        );
      }
      historyProvider.saveEvaluation(finalEvaluation);
      widget.onEvaluation?.call(finalEvaluation);
    }
  }

  void _startGracePeriod() {
    _graceTimer?.cancel();
    final canStart = widget.canStartNewCustomer?.call() ?? true;
    if (!canStart) {
      setState(() => _chatPhase = _ChatPhase.waitingToEnd);
      // Keep parent busy briefly so wrapping-up can show before session report.
      Future.delayed(const Duration(seconds: 4), () {
        if (!mounted) return;
        widget.onBusyChanged?.call(false);
      });
      return;
    }

    final seconds =
        _graceMinSeconds +
        Random().nextInt(_graceMaxSeconds - _graceMinSeconds + 1);

    setState(() {
      _chatPhase = _ChatPhase.gracePeriod;
      _remainingSeconds = seconds;
    });

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
    //the parent chat is no longer busy. This is what lets the
    //session finish if chat was the last thing blocking it
    if (!canStart) {
      setState(() => _chatPhase = _ChatPhase.waitingToEnd);
      widget.onBusyChanged?.call(false);
      return;
    }

    //this customer is starting for real. Let the parent know chat
    //now occupies a quota slot again
    widget.onCustomerStarted?.call();

    //initialize the message provider
    final messageProvider = Provider.of<MessageProvider>(
      context,
      listen: false,
    );

    //clear the messages for the next chat
    messageProvider.clearMessage();
    Provider.of<AccountProvider>(context, listen: false).reset();
    openRouterAPI.clearMessages(context);

    _customerStartTime = null;
    _customerConfirmed = false;
    _sessionEscalated = false;
    _handleSeconds = null;
    _traineeHasSpoken = false;
    _waitingForCustomer = false;
    _missionStartedForCustomer = false;
    _sessionController.reset(notify: false);
    _problemFamily = null;
    _familyCustomerKey = '';
    _lastSyncedIdentity = null;
    _lastSyncedToolWork = null;
    _lastSyncedToolAction = '';
    _customerCheckTimer?.cancel();
    _idleNudgeTimer?.cancel();
    _reminders.clear();
    _acwSubmitted = false;
    _acwDisposition = 'Resolved';
    _interactionBackspaceCount = 0;
    _interactionCharsTyped = 0;
    _interactionWpmSamples.clear();
    _previousInputLength = 0;

    setState(() => _chatPhase = _ChatPhase.active);
    widget.onBusyChanged?.call(false);

    //and make the customer chat first again
    _requestOpeningMessage();
  }

  void _ensureAhtStarted() {
    if (!mounted) return;
    if (_customerStartTime != null) return;
    _customerStartTime = DateTime.now();
  }

  void sendChatmessage() {
    if (_inputController.text.isEmpty || _isSending || _waitingForCustomer)
      return;

    if (_chatPhase == _ChatPhase.awaitingClosing) {
      final text = _inputController.text;
      _inputController.clear();
      _previousInputLength = 0;
      _exchangeWhileClosing(text);
      return;
    }

    if (_chatPhase != _ChatPhase.active) return;

    final hasCustomerMessage = Provider.of<MessageProvider>(
      context,
      listen: false,
    ).messages.any((m) => m.role == 'assistant');
    if (!hasCustomerMessage) return;

    final text = _inputController.text;
    _inputController.clear();
    _previousInputLength = 0;
    _sendUserMessage(text);
  }

  Future<void> _exchangeWhileClosing(String text) async {
    setState(() => _isSending = true);
    _traineeHasSpoken = true;
    final wantsEscalation = SimulationCoach.looksLikeEscalation(text);
    if (wantsEscalation && !_sessionEscalated) {
      if (mounted) {
        setState(() {
          _isSending = false;
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
      _inputController.text = text;
      return;
    }
    try {
      final response = await openRouterAPI.getResponseWithoutTypeCast(
        context,
        text,
        forceEscalating: _sessionEscalated,
      );
      if (!mounted) return;
      if (response.isError) {
        setState(() => _isSending = false);
        return;
      }
    } catch (_) {
      if (mounted) setState(() => _isSending = false);
      return;
    }

    if (_coachRequiresEscalation() && !_sessionEscalated) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This case needs a specialist handoff. Open Escalation in Script Guide, submit the form, then close.',
            ),
          ),
        );
      }
      _inputController.text = text;
      return;
    }

    final shouldFinish =
        SimulationCoach.looksLikeClosing(text) ||
        (_sessionEscalated && SimulationCoach.looksLikeEscalation(text));
    if (!shouldFinish) {
      if (mounted) setState(() => _isSending = false);
      return;
    }

    await _evaluateResolution();
    if (!mounted) return;
    _prepareAcwForm();
    setState(() {
      _isSending = false;
      _chatPhase = _ChatPhase.afterCallWork;
    });
  }

  bool _coachRequiresEscalation() {
    if (_sessionEscalated) return false;
    if (_problemFamily == ProblemFamily.trueEscalate) return true;
    try {
      final mission = _sessionController.mission;
      if (mission.evidence.branch == 'escalate') return true;
      if (mission.pack?.id == 'mission_escalate') return true;
    } catch (_) {}
    return false;
  }

  void _scheduleIdleNudge() {
    _idleNudgeTimer?.cancel();
    if (_chatPhase != _ChatPhase.active || _waitingForCustomer) return;
    final minutes = 4 + Random().nextInt(3);
    _idleNudgeTimer = Timer(Duration(minutes: minutes), () async {
      if (!mounted) return;
      if (_chatPhase != _ChatPhase.active ||
          _isSending ||
          _waitingForCustomer ||
          _customerConfirmed) {
        return;
      }
      if (SimulationSessionController.useMissionGuide) {
        final messageProvider = Provider.of<MessageProvider>(
          context,
          listen: false,
        );
        const nudges = [
          'Are you still there? I am waiting for the next step.',
          'Just checking in. Do you still need anything from my side?',
          'I am still on the chat if you have an update for me.',
        ];
        final line = nudges[Random().nextInt(nudges.length)];
        setState(() => _waitingForCustomer = true);
        await Future<void>.delayed(
          Duration(milliseconds: 1200 + Random().nextInt(800)),
        );
        if (!mounted) return;
        messageProvider.addMessage('assistant', line);
        _syncMissionMessages();
        if (mounted) setState(() => _waitingForCustomer = false);
        _scheduleIdleNudge();
        return;
      }
      try {
        setState(() => _isSending = true);
        final response = await openRouterAPI.nudgeIfAgentSilent(context);
        if (!mounted) return;
        setState(() => _isSending = false);
        if (response.isError) return;
        final cleaned = SimulationCoach.stripInternalFields(response.reply);
        if ((response.callStatus == 'resolved' ||
                response.callStatus == 'ended') &&
            _chatPhase == _ChatPhase.active) {
          if (_customerStartTime != null) {
            final seconds = DateTime.now()
                .difference(_customerStartTime!)
                .inSeconds
                .toDouble();
            widget.onResolutionSeconds?.call(seconds);
            _handleSeconds = seconds;
          }
          Provider.of<AccountProvider>(
            context,
            listen: false,
          ).confirmCustomerResolved();
          widget.onBusyChanged?.call(true);
          setState(() {
            _chatPhase = _ChatPhase.awaitingClosing;
            _selectedTab = 0;
            _customerConfirmed = true;
          });
          return;
        }
        if (SimulationCoach.customerIsChecking(cleaned)) {
          _startCustomerCheckWait();
        }
        _scheduleIdleNudge();
      } catch (_) {
        if (mounted) setState(() => _isSending = false);
      }
    });
  }

  void _startCustomerCheckWait() {
    _customerCheckTimer?.cancel();
    _idleNudgeTimer?.cancel();
    setState(() => _waitingForCustomer = true);
    _customerCheckTimer = Timer(const Duration(seconds: 5), () async {
      if (!mounted) return;
      try {
        final response = await openRouterAPI.continueAfterCustomerPause(
          context,
        );
        if (!mounted) return;
        if (response.isError) {
          setState(() => _waitingForCustomer = false);
          return;
        }
        final cleaned = SimulationCoach.stripInternalFields(response.reply);
        if ((response.callStatus == 'resolved' ||
                response.callStatus == 'ended') &&
            _chatPhase == _ChatPhase.active) {
          if (_customerStartTime != null) {
            final seconds = DateTime.now()
                .difference(_customerStartTime!)
                .inSeconds
                .toDouble();
            widget.onResolutionSeconds?.call(seconds);
            _handleSeconds = seconds;
          }
          Provider.of<AccountProvider>(
            context,
            listen: false,
          ).confirmCustomerResolved();
          widget.onBusyChanged?.call(true);
          setState(() {
            _chatPhase = _ChatPhase.awaitingClosing;
            _selectedTab = 0;
            _customerConfirmed = true;
            _waitingForCustomer = false;
          });
          return;
        }
        if (SimulationCoach.customerIsChecking(cleaned)) {
          _startCustomerCheckWait();
          return;
        }
        setState(() => _waitingForCustomer = false);
        _focusChatInputIfReady();
      } catch (_) {
        if (mounted) {
          setState(() => _waitingForCustomer = false);
          _focusChatInputIfReady();
        }
      }
    });
  }

  Future<void> _sendUserMessage(String text) async {
    final wantsEscalation = SimulationCoach.looksLikeEscalation(text);
    if (wantsEscalation && !_sessionEscalated) {
      if (mounted) {
        setState(() {
          _selectedTab = 0;
          _isSending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Use the Escalation tab in Script Guide and submit the handoff. Typing the closing line alone is not enough.',
            ),
          ),
        );
      }
      _inputController.text = text;
      return;
    }
    setState(() {
      _isSending = true;
      // Stay on chat so the customer reply is visible.
      _selectedTab = 0;
    });
    _traineeHasSpoken = true;
    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );
    if (SimulationCoach.isNegativeAgentReply(text)) {
      setState(() {
        _reminders.add(
          'Tone issue in: "$text" ${SimulationCoach.suggestionForNegative(text)}',
        );
      });
    } else if (SimulationCoach.isOffTopicReply(
      text,
      openRouterAPI.chosenSimulation['problem'] ?? '',
    )) {
      setState(() {
        _reminders.add(
          'Off-track reply: "$text" ${SimulationCoach.suggestionForOffTopic()}',
        );
      });
    }

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

      //also feed this interaction's own TESDA telemetry
      _interactionWpmSamples.add(wpm);
      _interactionCharsTyped += text.trim().length;

      //then set the date to null
      _typingStartTime = null;

      if (SimulationSessionController.useMissionGuide &&
          _sessionController.mission.pack != null) {
        final messageProvider = Provider.of<MessageProvider>(
          context,
          listen: false,
        );
        messageProvider.addMessage('user', text);
        _syncMissionMessages();
        await _postScriptedCustomerLines();
        if (!mounted) return;
        final closeDone = _sessionController.mission.state.done.contains(
          'close',
        );
        if (closeDone || _sessionController.isMissionComplete) {
          if (_customerStartTime != null) {
            final seconds = DateTime.now()
                .difference(_customerStartTime!)
                .inSeconds
                .toDouble();
            widget.onResolutionSeconds?.call(seconds);
            _handleSeconds = seconds;
          }
          accountProvider.confirmCustomerResolved();
          widget.onBusyChanged?.call(true);
          if (mounted) {
            setState(() => _isSending = false);
          }
          await Future<void>.delayed(const Duration(milliseconds: 1400));
          if (!mounted) return;
          _prepareAcwForm();
          if (mounted) {
            setState(() {
              _customerConfirmed = true;
              _chatPhase = _ChatPhase.afterCallWork;
            });
          }
          await _evaluateResolution();
          return;
        }
        setState(() => _isSending = false);
        _focusChatInputIfReady();
        return;
      }

      //wait for the response
      final response = await openRouterAPI.getResponseWithoutTypeCast(
        context,
        text,
        forceEscalating: _sessionEscalated,
      );

      if (!mounted) return;

      if (response.isError) {
        if (mounted) setState(() => _isSending = false);
        return;
      }

      if (response.accountProvided && response.accountId != null) {
        if (accountProvider.accounts.isEmpty) {
          accountProvider.generateAccounts(
            sector: openRouterAPI.chosenSimulation['sector'] ?? 'Tech Support',
            targetAccountId: response.accountId!,
            problem: openRouterAPI.chosenSimulation['problem'] ?? '',
            targetOwnerName:
                openRouterAPI.chosenSimulation['name'] ?? 'Customer',
          );
        }
      }

      var cleanedReply = SimulationCoach.stripInternalFields(response.reply);
      if (SimulationCoach.looksLikeAgentSpeech(cleanedReply)) {
        cleanedReply =
            'Sorry, I am still waiting on this. Can you tell me the next step for my issue?';
      }
      _ensureAhtStarted();
      // Escalation is only confirmed by the Escalation tab submit, not AI status.
      if (!_customerConfirmed &&
          SimulationCoach.customerIsChecking(cleanedReply)) {
        _startCustomerCheckWait();
      }

      final satisfied =
          CaseChecklist.isCustomerSatisfied(cleanedReply) ||
          CaseChecklist.isCustomerSatisfied(
            Provider.of<MessageProvider>(context, listen: false).messages
                .where((m) => m.role == 'assistant')
                .map((m) => m.message)
                .join(' '),
          );
      final coachNeedsEscalate = _coachRequiresEscalation();
      if (coachNeedsEscalate && !_sessionEscalated) {
        // Keep the case open until the Escalation tab is submitted.
      } else if ((response.callStatus == 'resolved' ||
              response.callStatus == 'ended' ||
              (satisfied && accountProvider.toolWorkDone)) &&
          _chatPhase == _ChatPhase.active) {
        if (_customerStartTime != null) {
          final seconds = DateTime.now()
              .difference(_customerStartTime!)
              .inSeconds
              .toDouble();
          widget.onResolutionSeconds?.call(seconds);
          _handleSeconds = seconds;
        }
        accountProvider.confirmCustomerResolved();
        widget.onBusyChanged?.call(true);
        setState(() {
          _chatPhase = _ChatPhase.awaitingClosing;
          _selectedTab = 0;
          _customerConfirmed = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        if (!_waitingForCustomer) {
          _scheduleIdleNudge();
          _focusChatInputIfReady();
        }
      }
    }
  }
}
