import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:trainixprogram/models/training/scenarios/scenario_models.dart';
import 'package:trainixprogram/models/training/training_categories.dart';
import 'package:trainixprogram/models/training/voice_line_player.dart';
import 'package:trainixprogram/screens/page/components/mini_training/scenario_practice/scenario_briefing_view.dart';
import 'package:trainixprogram/screens/page/components/mini_training/scenario_practice/scenario_chat_bubble.dart';
import 'package:trainixprogram/screens/page/components/mini_training/scenario_practice/scenario_feedback_banner.dart';
import 'package:trainixprogram/screens/page/components/mini_training/scenario_practice/scenario_result_view.dart';
import 'package:trainixprogram/screens/page/components/mini_training/scenario_practice/voice_scenario_play_view.dart';
import 'package:trainixprogram/services/speech_to_text_service.dart';

class VoiceScenarioPlayer extends StatefulWidget {
  final ScenarioDefinition scenario;

  const VoiceScenarioPlayer({super.key, required this.scenario});

  @override
  State<VoiceScenarioPlayer> createState() => _VoiceScenarioPlayerState();
}

class _VoiceScenarioPlayerState extends State<VoiceScenarioPlayer> {
  ScenarioDefinition get _scenario => widget.scenario;
  final SpeechToTextService _stt = SpeechToTextService();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _accountScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool _started = false;
  bool _finished = false;
  bool _passed = false;
  bool _waitingCustomer = false;
  bool _processing = false;
  bool _recording = false;
  bool _sttReady = false;
  int _turnIndex = 0;
  int _mistakes = 0;
  String? _hudText;
  String? _coachPrompt;
  String? _coachTarget;
  String? _lastTranscript;
  String? _lastAudioPath;
  bool _playingLastTake = false;
  String? _selectedAccountId;
  String _searchQuery = '';
  bool _issueResolved = false;
  bool _accountsRevealed = false;
  bool _inputFlashError = false;
  bool _inputFlashSuccess = false;
  final Set<String> _completedMissionIds = {};
  ScenarioFeedbackKind? _feedbackKind;
  String _feedbackTitle = '';
  String _feedbackMessage = '';
  final List<ScenarioChatBubbleData> _bubbles = [];

  @override
  void initState() {
    super.initState();
    _initStt();
  }

  Future<void> _initStt() async {
    final ok = await _stt.initialize();
    if (!mounted) return;
    setState(() {
      _sttReady = ok;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _accountScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    void jump() {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      jump();
      WidgetsBinding.instance.addPostFrameCallback((_) => jump());
    });
  }

  void _scrollAccountPanel({bool toSelected = false}) {
    void jump() {
      if (!_accountScrollController.hasClients) return;
      final max = _accountScrollController.position.maxScrollExtent;
      _accountScrollController.jumpTo(toSelected ? max * 0.35 : 0);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      jump();
      WidgetsBinding.instance.addPostFrameCallback((_) => jump());
    });
  }

  String _norm(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _matchesTarget(String transcript, String target) {
    final a = _norm(transcript);
    final b = _norm(target);
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b) return true;
    if (a.contains(b) || b.contains(a)) return true;
    final aw = a.split(' ').where((w) => w.length > 2).toSet();
    final bw = b.split(' ').where((w) => w.length > 2).toSet();
    if (bw.isEmpty) return false;
    final hit = bw.where(aw.contains).length;
    return hit / bw.length >= 0.65;
  }

  bool get _isAccountTurn {
    if (_turnIndex >= _scenario.turns.length) return false;
    final t = _scenario.turns[_turnIndex].type;
    return t == ScenarioTurnType.accountSearch ||
        t == ScenarioTurnType.accountSelect ||
        t == ScenarioTurnType.accountResolve;
  }

  String? get _currentMissionStepId {
    if (_turnIndex >= _scenario.turns.length) return null;
    return _scenario.turns[_turnIndex].missionStepId;
  }

  void _showErrorFeedback(String message) {
    setState(() {
      _feedbackKind = ScenarioFeedbackKind.error;
      _feedbackTitle = 'Not quite';
      _feedbackMessage = message;
      _inputFlashError = true;
      _inputFlashSuccess = false;
    });
    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      setState(() {
        _inputFlashError = false;
      });
    });
  }

  void _showSuccessFeedback(String message, {String? missionStepId}) {
    setState(() {
      _feedbackKind = ScenarioFeedbackKind.success;
      _feedbackTitle = 'Correct';
      _feedbackMessage = message;
      _inputFlashSuccess = true;
      _inputFlashError = false;
      if (missionStepId != null) {
        _completedMissionIds.add(missionStepId);
      }
    });
    Future.delayed(const Duration(milliseconds: 550), () {
      if (!mounted) return;
      setState(() {
        _inputFlashSuccess = false;
      });
    });
  }

  void _clearFeedback() {
    setState(() {
      _feedbackKind = null;
      _feedbackTitle = '';
      _feedbackMessage = '';
    });
  }

  void _startScenario() {
    setState(() {
      _started = true;
      _finished = false;
      _passed = false;
      _waitingCustomer = false;
      _processing = false;
      _recording = false;
      _turnIndex = 0;
      _mistakes = 0;
      _hudText = null;
      _coachPrompt = null;
      _coachTarget = null;
      _lastTranscript = null;
      _selectedAccountId = null;
      _searchQuery = '';
      _issueResolved = false;
      _accountsRevealed = false;
      _completedMissionIds.clear();
      _feedbackKind = null;
      _bubbles.clear();
      _searchController.clear();
    });
    _advance();
  }

  Future<void> _advance() async {
    if (_processing) return;
    _processing = true;

    while (_turnIndex < _scenario.turns.length) {
      final turn = _scenario.turns[_turnIndex];

      if (turn.type == ScenarioTurnType.guide) {
        setState(() {
          _hudText = turn.text;
          _coachPrompt = null;
          _coachTarget = null;
          _waitingCustomer = false;
        });
        _processing = false;
        return;
      }

      if (turn.type == ScenarioTurnType.customer) {
        setState(() {
          _waitingCustomer = true;
          _hudText = "Customer's reply is playing...";
          _coachPrompt = null;
          _coachTarget = null;
        });
        final customerText = turn.text;
        await VoiceLinePlayer.instance.playText(
          customerText,
          emotion: _scenario.emotion,
        );
        if (!mounted) return;
        setState(() {
          _bubbles.add(
            ScenarioChatBubbleData(isCustomer: true, text: customerText),
          );
          _waitingCustomer = false;
          _hudText = 'Customer replied. Continue with the next guided step.';
        });
        _scrollToBottom();
        _turnIndex++;
        continue;
      }

      if (turn.type == ScenarioTurnType.speakExact) {
        setState(() {
          _hudText = 'Your turn. Record the guided line.';
          _coachPrompt = turn.coachPrompt;
          _coachTarget = turn.resolvedTargetText;
          _lastTranscript = null;
          _waitingCustomer = false;
        });
        _processing = false;
        return;
      }

      if (turn.type == ScenarioTurnType.accountSearch) {
        setState(() {
          _hudText = 'Open the Account Lookup tab. Search for the customer.';
          _coachPrompt = turn.coachPrompt;
          _coachTarget = null;
          _selectedAccountId = null;
          _accountsRevealed = false;
          _searchController.clear();
          _searchQuery = '';
          _waitingCustomer = false;
        });
        _processing = false;
        return;
      }

      if (turn.type == ScenarioTurnType.accountSelect) {
        setState(() {
          _hudText =
              'In Account Lookup, select the correct account. Decoys are included on purpose.';
          _coachPrompt = turn.coachPrompt;
          _coachTarget = null;
          _accountsRevealed = true;
          _waitingCustomer = false;
        });
        _processing = false;
        return;
      }

      if (turn.type == ScenarioTurnType.accountResolve) {
        setState(() {
          _hudText =
              'In Account Lookup, use the resolve action on the correct account.';
          _coachPrompt = turn.coachPrompt;
          _coachTarget = null;
          _accountsRevealed = true;
          _waitingCustomer = false;
        });
        _processing = false;
        return;
      }

      _turnIndex++;
    }

    _processing = false;
    _complete(true);
  }

  void _onHudNext() {
    if (_waitingCustomer || _coachPrompt != null) return;
    if (_isAccountTurn) return;
    final turn = _scenario.turns[_turnIndex];
    if (turn.type == ScenarioTurnType.guide) {
      _turnIndex++;
      _advance();
    }
  }

  Future<void> _toggleRecord() async {
    if (_waitingCustomer || _coachTarget == null) return;
    if (!_sttReady) {
      await _initStt();
      if (!_sttReady) {
        _showErrorFeedback(
          'Microphone is not available. Check permissions and try again.',
        );
        return;
      }
    }

    if (_recording) {
      setState(() {
        _recording = false;
        _processing = true;
        _hudText = 'Checking your reply...';
      });
      final result = await _stt.stopListening();
      final transcript = result.$1;
      final audioPath = result.$2;
      if (!mounted) return;
      setState(() {
        _processing = false;
        _lastTranscript = transcript;
        if (audioPath != null) _lastAudioPath = audioPath;
      });
      _evaluateTranscript(transcript);
      return;
    }

    setState(() {
      _recording = true;
      _hudText = 'Recording... speak clearly, then stop.';
      _feedbackKind = null;
    });
    await _stt.startListening(onResult: (_) {});
  }

  Future<void> _playLastTake() async {
    final path = _lastAudioPath;
    if (path == null || !File(path).existsSync()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recording is not available for this line.'),
        ),
      );
      return;
    }
    if (_playingLastTake) return;
    setState(() => _playingLastTake = true);
    try {
      await VoiceLinePlayer.instance.playFile(path);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording is not available for this line.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _playingLastTake = false);
    }
  }

  Future<void> _playTargetExample() async {
    final target = _coachTarget;
    if (target == null || target.trim().isEmpty || _playingLastTake) return;
    setState(() => _playingLastTake = true);
    try {
      await VoiceLinePlayer.instance.playText(target, emotion: 'professional');
    } finally {
      if (mounted) setState(() => _playingLastTake = false);
    }
  }

  void _evaluateTranscript(String transcript) {
    final turn = _scenario.turns[_turnIndex];
    final target = turn.resolvedTargetText;
    final ok = _matchesTarget(transcript, target);

    if (ok) {
      final msg = turn.successReply ?? 'Good response.';
      setState(() {
        _bubbles.add(ScenarioChatBubbleData(isAgent: true, text: transcript));
        _coachPrompt = null;
        _coachTarget = null;
        _hudText = msg;
      });
      _showSuccessFeedback(msg, missionStepId: turn.missionStepId);
      _scrollToBottom();
      _turnIndex++;
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        _clearFeedback();
        _advance();
      });
      return;
    }

    final failMsg = turn.failReply ?? 'That was not close enough. Try again.';
    setState(() {
      _hudText = failMsg;
      if (!_scenario.isGuided) {
        _mistakes++;
      }
    });
    _showErrorFeedback(failMsg);
    if (!_scenario.isGuided && _mistakes >= _scenario.maxMistakes) {
      _complete(false);
    }
  }

  void _submitAccountSearch() {
    final turn = _scenario.turns[_turnIndex];
    if (turn.type != ScenarioTurnType.accountSearch) return;
    final target = (turn.searchTarget ?? '').trim().toLowerCase();
    final input = _searchController.text.trim().toLowerCase();
    final ok = input == target;
    if (ok) {
      final msg =
          turn.successReply ??
          'Search complete. Review the account list and select the correct one.';
      setState(() {
        _searchQuery = '';
        _accountsRevealed = true;
        _coachPrompt = null;
        _hudText = msg;
      });
      _showSuccessFeedback(msg, missionStepId: turn.missionStepId);
      _scrollAccountPanel();
      _turnIndex++;
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        _clearFeedback();
        _advance();
      });
      return;
    }
    _handleToolFail(turn.failReply ?? 'Search using the guided customer name.');
  }

  void _submitAccountSelect() {
    final turn = _scenario.turns[_turnIndex];
    if (turn.type != ScenarioTurnType.accountSelect) return;
    final ok = _selectedAccountId == turn.selectAccountId;
    if (ok) {
      final msg = turn.successReply ?? 'Account selected.';
      setState(() {
        _coachPrompt = null;
        _hudText = msg;
      });
      _showSuccessFeedback(msg, missionStepId: turn.missionStepId);
      _scrollAccountPanel(toSelected: true);
      _turnIndex++;
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        _clearFeedback();
        _advance();
      });
      return;
    }
    _handleToolFail(turn.failReply ?? 'Select the correct account.');
  }

  void _submitAccountResolve() {
    final turn = _scenario.turns[_turnIndex];
    if (turn.type != ScenarioTurnType.accountResolve) return;
    final msg = turn.successReply ?? 'Issue resolved.';
    setState(() {
      _issueResolved = true;
      _coachPrompt = null;
      _hudText = msg;
    });
    _showSuccessFeedback(msg, missionStepId: turn.missionStepId);
    _turnIndex++;
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      _clearFeedback();
      _advance();
    });
  }

  void _handleToolFail(String message) {
    if (_scenario.isGuided) {
      setState(() {
        _hudText = message;
      });
      _showErrorFeedback(message);
      return;
    }
    setState(() {
      _mistakes++;
      _hudText = message;
    });
    _showErrorFeedback(message);
    if (_mistakes >= _scenario.maxMistakes) {
      _complete(false);
    }
  }

  void _complete(bool passed) {
    setState(() {
      _finished = true;
      _passed = passed;
      _coachPrompt = null;
      _coachTarget = null;
      _recording = false;
    });
  }

  void _finishAndExit() {
    if (_passed) {
      MiniTrainingProgress.markVoiceScenarioCompleted(_scenario.id);
    }
    Navigator.of(context).pop(_passed);
  }

  @override
  Widget build(BuildContext context) {
    if (!_started) {
      return ScenarioBriefingView(scenario: _scenario, onStart: _startScenario);
    }
    if (_finished) {
      return ScenarioResultView(
        scenario: _scenario,
        passed: _passed,
        mistakes: _mistakes,
        onContinue: _finishAndExit,
        onRetry: _startScenario,
      );
    }

    final canNext =
        !_waitingCustomer &&
        _coachPrompt == null &&
        !_isAccountTurn &&
        _turnIndex < _scenario.turns.length &&
        _scenario.turns[_turnIndex].type == ScenarioTurnType.guide;

    final turnType = _turnIndex < _scenario.turns.length
        ? _scenario.turns[_turnIndex].type
        : null;

    return VoiceScenarioPlayView(
      scenario: _scenario,
      mistakes: _mistakes,
      hudText: _hudText,
      canNext: canNext,
      feedbackKind: _feedbackKind,
      feedbackTitle: _feedbackTitle,
      feedbackMessage: _feedbackMessage,
      completedMissionIds: _completedMissionIds,
      currentMissionStepId: _currentMissionStepId,
      bubbles: _bubbles,
      scrollController: _scrollController,
      accountScrollController: _accountScrollController,
      searchController: _searchController,
      searchQuery: _searchQuery,
      selectedAccountId: _selectedAccountId,
      issueResolved: _issueResolved,
      accountsRevealed: _accountsRevealed,
      coachPrompt: _coachPrompt,
      coachTarget: _coachTarget,
      lastTranscript: _lastTranscript,
      recording: _recording,
      processing: _processing || _playingLastTake,
      isAccountTurn: _isAccountTurn,
      turnType: turnType,
      inputFlashError: _inputFlashError,
      inputFlashSuccess: _inputFlashSuccess,
      onHudNext: _onHudNext,
      onToggleRecord: _toggleRecord,
      onPlayLastTake: _playLastTake,
      canPlayLastTake: _lastAudioPath != null,
      onPlayExample: _playTargetExample,
      canPlayExample: (_coachTarget ?? '').trim().isNotEmpty,
      onSearchChanged: (q) => setState(() => _searchQuery = q),
      onSelectAccount: (id) => setState(() => _selectedAccountId = id),
      onConfirmSearch: _submitAccountSearch,
      onConfirmSelect: _submitAccountSelect,
      onResolve: _submitAccountResolve,
    );
  }
}
