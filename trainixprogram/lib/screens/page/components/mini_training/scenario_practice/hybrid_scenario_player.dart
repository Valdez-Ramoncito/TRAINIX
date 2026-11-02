import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trainixprogram/models/training/scenarios/scenario_models.dart';
import 'package:trainixprogram/screens/page/components/mini_training/scenario_practice/scenario_chat_bubble.dart';
import 'package:trainixprogram/screens/page/components/mini_training/scenario_practice/scenario_feedback_banner.dart';
import 'package:trainixprogram/models/training/soft_text_match.dart';
import 'package:trainixprogram/models/training/training_categories.dart';
import 'package:trainixprogram/screens/page/components/mini_training/scenario_practice/scenario_briefing_view.dart';
import 'package:trainixprogram/screens/page/components/mini_training/scenario_practice/scenario_result_view.dart';
import 'package:trainixprogram/screens/page/components/mini_training/scenario_practice/hybrid_scenario_play_view.dart';
import 'package:trainixprogram/services/speech_to_text_service.dart';

class HybridScenarioPlayer extends StatefulWidget {
  final ScenarioDefinition scenario;

  const HybridScenarioPlayer({super.key, required this.scenario});

  @override
  State<HybridScenarioPlayer> createState() => _HybridScenarioPlayerState();
}

class _HybridScenarioPlayerState extends State<HybridScenarioPlayer> {
  ScenarioDefinition get _scenario => widget.scenario;
  final SpeechToTextService _stt = SpeechToTextService();
  final ScrollController _voiceScroll = ScrollController();
  final ScrollController _chatScroll = ScrollController();
  final ScrollController _voiceAccountScroll = ScrollController();
  final ScrollController _chatAccountScroll = ScrollController();
  final TextEditingController _chatInput = TextEditingController();
  final TextEditingController _voiceSearch = TextEditingController();
  final TextEditingController _chatSearch = TextEditingController();
  final FocusNode _chatFocus = FocusNode();

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
  String? _selectedVoiceAccountId;
  String? _selectedChatAccountId;
  String _voiceSearchQuery = '';
  String _chatSearchQuery = '';
  bool _voiceAccountsRevealed = false;
  bool _chatAccountsRevealed = false;
  bool _voiceIssueResolved = false;
  bool _chatIssueResolved = false;
  final Set<String> _completedMissionIds = {};
  ScenarioFeedbackKind? _feedbackKind;
  String _feedbackTitle = '';
  String _feedbackMessage = '';
  final List<ScenarioChatBubbleData> _voiceBubbles = [];
  final List<ScenarioChatBubbleData> _chatBubbles = [];

  @override
  void initState() {
    super.initState();
    _initStt();
  }

  Future<void> _initStt() async {
    final ok = await _stt.initialize();
    if (!mounted) return;
    setState(() => _sttReady = ok);
  }

  @override
  void dispose() {
    _voiceScroll.dispose();
    _chatScroll.dispose();
    _voiceAccountScroll.dispose();
    _chatAccountScroll.dispose();
    _chatInput.dispose();
    _voiceSearch.dispose();
    _chatSearch.dispose();
    _chatFocus.dispose();
    super.dispose();
  }

  void _focusChatIfTyping() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_turnIndex < _scenario.turns.length &&
          _scenario.turns[_turnIndex].type == ScenarioTurnType.typeExact) {
        if (!_chatFocus.hasFocus) {
          _chatFocus.requestFocus();
        }
      }
    });
  }

  String? get _lane => _turnIndex < _scenario.turns.length
      ? _scenario.turns[_turnIndex].lane
      : null;

  String? get _currentMissionStepId {
    if (_turnIndex >= _scenario.turns.length) return null;
    return _scenario.turns[_turnIndex].missionStepId;
  }

  String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  bool _matchesTarget(String transcript, String target) {
    final a = _norm(transcript);
    final b = _norm(target);
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b || a.contains(b) || b.contains(a)) return true;
    final aw = a.split(' ').where((w) => w.length > 2).toSet();
    final bw = b.split(' ').where((w) => w.length > 2).toSet();
    if (bw.isEmpty) return false;
    return bw.where(aw.contains).length / bw.length >= 0.72;
  }

  void _showError(String msg) {
    setState(() {
      _feedbackKind = ScenarioFeedbackKind.error;
      _feedbackTitle = 'Not quite';
      _feedbackMessage = msg;
      _hudText = msg;
    });
  }

  void _showSuccess(String msg, {String? missionStepId}) {
    setState(() {
      _feedbackKind = ScenarioFeedbackKind.success;
      _feedbackTitle = 'Correct';
      _feedbackMessage = msg;
      _hudText = msg;
      if (missionStepId != null) _completedMissionIds.add(missionStepId);
    });
  }

  void _clearFeedback() {
    setState(() {
      _feedbackKind = null;
      _feedbackTitle = '';
      _feedbackMessage = '';
    });
  }

  void _scrollLane(String? lane) {
    void jump(ScrollController c) {
      if (!c.hasClients) return;
      c.jumpTo(c.position.maxScrollExtent);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (lane == 'voice' || lane == null) jump(_voiceScroll);
      if (lane == 'chat' || lane == null) jump(_chatScroll);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (lane == 'voice' || lane == null) jump(_voiceScroll);
        if (lane == 'chat' || lane == null) jump(_chatScroll);
      });
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
      _selectedVoiceAccountId = null;
      _selectedChatAccountId = null;
      _voiceSearchQuery = '';
      _chatSearchQuery = '';
      _voiceAccountsRevealed = false;
      _chatAccountsRevealed = false;
      _voiceIssueResolved = false;
      _chatIssueResolved = false;
      _completedMissionIds.clear();
      _feedbackKind = null;
      _voiceBubbles.clear();
      _chatBubbles.clear();
      _chatInput.clear();
      _voiceSearch.clear();
      _chatSearch.clear();
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
          _hudText = turn.lane == 'chat'
              ? 'Waiting for chat message...'
              : turn.lane == 'voice'
              ? "Waiting for the voice customer's line..."
              : 'Waiting for the next customer activity...';
          _coachPrompt = null;
          _coachTarget = null;
        });
        await Future.delayed(const Duration(milliseconds: 1100));
        if (!mounted) return;
        setState(() {
          final bubble = ScenarioChatBubbleData(
            isCustomer: true,
            text: turn.text,
          );
          if (turn.lane == 'chat') {
            _chatBubbles.add(bubble);
          } else {
            _voiceBubbles.add(bubble);
          }
          _waitingCustomer = false;
          _hudText = 'Customer activity received. Follow the coach prompt.';
        });
        _scrollLane(turn.lane);
        _turnIndex++;
        continue;
      }

      if (turn.type == ScenarioTurnType.speakExact) {
        setState(() {
          _hudText = 'Voice lane active. Record the guided line.';
          _coachPrompt = turn.coachPrompt;
          _coachTarget = turn.resolvedTargetText;
          _lastTranscript = null;
          _waitingCustomer = false;
        });
        _processing = false;
        return;
      }

      if (turn.type == ScenarioTurnType.typeExact) {
        setState(() {
          _hudText = 'Chat lane active. Type the guided reply.';
          _coachPrompt = turn.coachPrompt;
          _coachTarget = turn.resolvedTargetText;
          _waitingCustomer = false;
        });
        _processing = false;
        _focusChatIfTyping();
        return;
      }

      if (turn.type == ScenarioTurnType.accountSearch ||
          turn.type == ScenarioTurnType.accountSelect ||
          turn.type == ScenarioTurnType.accountResolve) {
        final isChatTool = turn.lane == 'tool_chat';
        setState(() {
          _hudText = isChatTool
              ? 'Use Chat Account Lookup.'
              : 'Use Voice Account Lookup.';
          _coachPrompt = turn.coachPrompt;
          _coachTarget = null;
          if (turn.type == ScenarioTurnType.accountSearch) {
            if (isChatTool) {
              _chatAccountsRevealed = false;
              _chatSearch.clear();
              _chatSearchQuery = '';
            } else {
              _voiceAccountsRevealed = false;
              _voiceSearch.clear();
              _voiceSearchQuery = '';
            }
          } else {
            if (isChatTool) {
              _chatAccountsRevealed = true;
            } else {
              _voiceAccountsRevealed = true;
            }
          }
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
    final turn = _scenario.turns[_turnIndex];
    if (turn.type == ScenarioTurnType.guide) {
      _turnIndex++;
      _advance();
    }
  }

  Future<void> _toggleRecord() async {
    final turn = _scenario.turns[_turnIndex];
    if (turn.type != ScenarioTurnType.speakExact) return;
    if (!_sttReady) {
      await _initStt();
      if (!_sttReady) {
        _showError('Microphone is not available.');
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
      if (!mounted) return;
      setState(() {
        _processing = false;
        _lastTranscript = result.$1;
      });
      _scoreVoice(result.$1);
      return;
    }

    setState(() {
      _recording = true;
      _hudText = 'Recording voice lane...';
      _feedbackKind = null;
    });
    await _stt.startListening(onResult: (_) {});
  }

  void _scoreVoice(String transcript) {
    final turn = _scenario.turns[_turnIndex];
    final ok = _matchesTarget(transcript, turn.resolvedTargetText ?? '');
    if (ok) {
      final msg = turn.successReply ?? 'Good voice reply.';
      setState(() {
        _voiceBubbles.add(
          ScenarioChatBubbleData(isAgent: true, text: transcript),
        );
        _coachPrompt = null;
        _coachTarget = null;
      });
      _showSuccess(msg, missionStepId: turn.missionStepId);
      _scrollLane('voice');
      _turnIndex++;
      Future.delayed(const Duration(milliseconds: 850), () {
        if (!mounted) return;
        _clearFeedback();
        _advance();
      });
      return;
    }
    final fail = turn.failReply ?? 'Try the guided voice line again.';
    if (!_scenario.isGuided) {
      setState(() => _mistakes++);
    }
    _showError(fail);
    if (!_scenario.isGuided && _mistakes >= _scenario.maxMistakes) {
      _complete(false);
    }
  }

  void _submitChatTyped() {
    final turn = _scenario.turns[_turnIndex];
    if (turn.type != ScenarioTurnType.typeExact) return;
    final input = _chatInput.text.trim();
    final target = (turn.resolvedTargetText ?? '').trim();
    final ok = SoftTextMatch.typingMatches(input, target);
    if (ok) {
      final msg = turn.successReply ?? 'Good chat reply.';
      setState(() {
        _chatBubbles.add(ScenarioChatBubbleData(isAgent: true, text: input));
        _coachPrompt = null;
        _coachTarget = null;
        _chatInput.clear();
      });
      _showSuccess(msg, missionStepId: turn.missionStepId);
      _scrollLane('chat');
      _turnIndex++;
      Future.delayed(const Duration(milliseconds: 850), () {
        if (!mounted) return;
        _clearFeedback();
        _advance();
      });
      return;
    }
    final fail =
        turn.failReply ??
        'Match the guided chat meaning. Exact wording is not required.';
    if (!_scenario.isGuided) {
      setState(() => _mistakes++);
    }
    setState(() => _chatInput.clear());
    _showError(fail);
    _focusChatIfTyping();
    if (!_scenario.isGuided && _mistakes >= _scenario.maxMistakes) {
      _complete(false);
    }
  }

  void _submitSearch({required bool chat}) {
    final turn = _scenario.turns[_turnIndex];
    if (turn.type != ScenarioTurnType.accountSearch) return;
    final target = (turn.searchTarget ?? '').trim().toLowerCase();
    final input = (chat ? _chatSearch : _voiceSearch).text.trim().toLowerCase();
    if (input == target) {
      final msg = turn.successReply ?? 'Search complete.';
      setState(() {
        if (chat) {
          _chatAccountsRevealed = true;
          _chatSearchQuery = '';
        } else {
          _voiceAccountsRevealed = true;
          _voiceSearchQuery = '';
        }
        _coachPrompt = null;
      });
      _showSuccess(msg, missionStepId: turn.missionStepId);
      _turnIndex++;
      Future.delayed(const Duration(milliseconds: 850), () {
        if (!mounted) return;
        _clearFeedback();
        _advance();
      });
      return;
    }
    _toolFail(turn.failReply ?? 'Search the guided customer name.');
  }

  void _submitSelect({required bool chat}) {
    final turn = _scenario.turns[_turnIndex];
    if (turn.type != ScenarioTurnType.accountSelect) return;
    final selected = chat ? _selectedChatAccountId : _selectedVoiceAccountId;
    if (selected == turn.selectAccountId) {
      final msg = turn.successReply ?? 'Account selected.';
      setState(() => _coachPrompt = null);
      _showSuccess(msg, missionStepId: turn.missionStepId);
      _turnIndex++;
      Future.delayed(const Duration(milliseconds: 850), () {
        if (!mounted) return;
        _clearFeedback();
        _advance();
      });
      return;
    }
    _toolFail(turn.failReply ?? 'Select the correct account.');
  }

  void _submitResolve({required bool chat}) {
    final turn = _scenario.turns[_turnIndex];
    if (turn.type != ScenarioTurnType.accountResolve) return;
    final msg = turn.successReply ?? 'Resolved.';
    setState(() {
      if (chat) {
        _chatIssueResolved = true;
      } else {
        _voiceIssueResolved = true;
      }
      _coachPrompt = null;
    });
    _showSuccess(msg, missionStepId: turn.missionStepId);
    _turnIndex++;
    Future.delayed(const Duration(milliseconds: 850), () {
      if (!mounted) return;
      _clearFeedback();
      _advance();
    });
  }

  void _toolFail(String message) {
    if (!_scenario.isGuided) {
      setState(() => _mistakes++);
    }
    _showError(message);
    if (!_scenario.isGuided && _mistakes >= _scenario.maxMistakes) {
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
      MiniTrainingProgress.markHybridScenarioCompleted(_scenario.id);
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
        _turnIndex < _scenario.turns.length &&
        _scenario.turns[_turnIndex].type == ScenarioTurnType.guide;

    final turnType = _turnIndex < _scenario.turns.length
        ? _scenario.turns[_turnIndex].type
        : null;

    return HybridScenarioPlayView(
      scenario: _scenario,
      mistakes: _mistakes,
      hudText: _hudText,
      lane: _lane,
      canNext: canNext,
      feedbackKind: _feedbackKind,
      feedbackTitle: _feedbackTitle,
      feedbackMessage: _feedbackMessage,
      completedMissionIds: _completedMissionIds,
      currentMissionStepId: _currentMissionStepId,
      voiceBubbles: _voiceBubbles,
      chatBubbles: _chatBubbles,
      voiceScroll: _voiceScroll,
      chatScroll: _chatScroll,
      voiceAccountScroll: _voiceAccountScroll,
      chatAccountScroll: _chatAccountScroll,
      chatInput: _chatInput,
      chatFocusNode: _chatFocus,
      voiceSearch: _voiceSearch,
      chatSearch: _chatSearch,
      selectedVoiceAccountId: _selectedVoiceAccountId,
      selectedChatAccountId: _selectedChatAccountId,
      voiceSearchQuery: _voiceSearchQuery,
      chatSearchQuery: _chatSearchQuery,
      voiceAccountsRevealed: _voiceAccountsRevealed,
      chatAccountsRevealed: _chatAccountsRevealed,
      voiceIssueResolved: _voiceIssueResolved,
      chatIssueResolved: _chatIssueResolved,
      coachPrompt: _coachPrompt,
      coachTarget: _coachTarget,
      lastTranscript: _lastTranscript,
      recording: _recording,
      processing: _processing,
      turnType: turnType,
      onHudNext: _onHudNext,
      onToggleRecord: _toggleRecord,
      onSubmitChatTyped: _submitChatTyped,
      onVoiceSearchChanged: (q) => setState(() => _voiceSearchQuery = q),
      onChatSearchChanged: (q) => setState(() => _chatSearchQuery = q),
      onSelectVoiceAccount: (id) =>
          setState(() => _selectedVoiceAccountId = id),
      onSelectChatAccount: (id) => setState(() => _selectedChatAccountId = id),
      onConfirmVoiceSearch: () => _submitSearch(chat: false),
      onConfirmChatSearch: () => _submitSearch(chat: true),
      onConfirmVoiceSelect: () => _submitSelect(chat: false),
      onConfirmChatSelect: () => _submitSelect(chat: true),
      onResolveVoice: () => _submitResolve(chat: false),
      onResolveChat: () => _submitResolve(chat: true),
    );
  }
}
