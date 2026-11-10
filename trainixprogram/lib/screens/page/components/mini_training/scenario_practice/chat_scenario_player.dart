import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trainixprogram/models/training/scenarios/scenario_models.dart';
import 'package:trainixprogram/models/training/soft_text_match.dart';
import 'package:trainixprogram/models/training/training_categories.dart';
import 'package:trainixprogram/screens/page/components/mini_training/scenario_practice/scenario_briefing_view.dart';
import 'package:trainixprogram/screens/page/components/mini_training/scenario_practice/scenario_chat_bubble.dart';
import 'package:trainixprogram/screens/page/components/mini_training/scenario_practice/scenario_play_view.dart';
import 'package:trainixprogram/screens/page/components/mini_training/scenario_practice/scenario_result_view.dart';
import 'package:trainixprogram/screens/page/components/mini_training/scenario_practice/scenario_feedback_banner.dart';

class ChatScenarioPlayer extends StatefulWidget {
  final ScenarioDefinition scenario;

  const ChatScenarioPlayer({super.key, required this.scenario});

  @override
  State<ChatScenarioPlayer> createState() => _ChatScenarioPlayerState();
}

class _ChatScenarioPlayerState extends State<ChatScenarioPlayer> {
  ScenarioDefinition get _scenario => widget.scenario;
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _accountScrollController = ScrollController();

  bool _started = false;
  bool _finished = false;
  bool _passed = false;
  bool _waitingCustomer = false;
  bool _processing = false;
  int _turnIndex = 0;
  int _mistakes = 0;
  String? _hudText;
  String? _coachPrompt;
  String? _coachTarget;
  String? _inlineFeedback;
  int? _selectedChoice;
  String? _selectedAccountId;
  List<ScenarioAccount> _visibleAccounts = [];
  String _searchQuery = '';
  bool _issueResolved = false;
  bool _accountsRevealed = false;
  final Set<String> _completedMissionIds = {};
  ScenarioFeedbackKind? _feedbackKind;
  String _feedbackTitle = '';
  String _feedbackMessage = '';
  bool _inputFlashError = false;
  bool _inputFlashSuccess = false;
  final List<ScenarioChatBubbleData> _bubbles = [];

  @override
  void dispose() {
    _inputController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _accountScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    void jump() {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      _scrollController.jumpTo(max);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      jump();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        jump();
      });
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        jump();
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
      _turnIndex = 0;
      _mistakes = 0;
      _hudText = null;
      _coachPrompt = null;
      _coachTarget = null;
      _inlineFeedback = null;
      _selectedChoice = null;
      _selectedAccountId = null;
      _visibleAccounts = [];
      _searchQuery = '';
      _issueResolved = false;
      _accountsRevealed = false;
      _completedMissionIds.clear();
      _feedbackKind = null;
      _feedbackTitle = '';
      _feedbackMessage = '';
      _inputFlashError = false;
      _inputFlashSuccess = false;
      _bubbles.clear();
      _inputController.clear();
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
          _hudText = "Let's wait for the customer's reply...";
          _coachPrompt = null;
          _coachTarget = null;
        });
        await Future.delayed(const Duration(milliseconds: 1400));
        if (!mounted) return;
        setState(() {
          _bubbles.add(
            ScenarioChatBubbleData(isCustomer: true, text: turn.text),
          );
          _waitingCustomer = false;
          _hudText = 'Customer replied. Continue with the next guided step.';
        });
        _scrollToBottom();
        _turnIndex++;
        continue;
      }

      if (turn.type == ScenarioTurnType.typeExact) {
        setState(() {
          _hudText = 'Your turn. Follow the coach panel below.';
          _coachPrompt = turn.coachPrompt;
          _coachTarget = turn.resolvedTargetText;
          _inlineFeedback = null;
          _selectedChoice = null;
          _waitingCustomer = false;
        });
        _processing = false;
        return;
      }

      if (turn.type == ScenarioTurnType.chooseOne) {
        setState(() {
          _hudText = 'Your turn. Choose the best response below.';
          _coachPrompt = turn.coachPrompt;
          _coachTarget = null;
          _inlineFeedback = null;
          _selectedChoice = null;
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
          _inlineFeedback = null;
          _selectedAccountId = null;
          _accountsRevealed = false;
          _visibleAccounts = [];
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
          _inlineFeedback = null;
          _waitingCustomer = false;
          _accountsRevealed = true;
          _visibleAccounts = List<ScenarioAccount>.from(_scenario.accounts);
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
          _inlineFeedback = null;
          _waitingCustomer = false;
          _accountsRevealed = true;
          _visibleAccounts = List<ScenarioAccount>.from(_scenario.accounts);
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

  String? get _currentMissionStepId {
    if (_turnIndex >= _scenario.turns.length) return null;
    return _scenario.turns[_turnIndex].missionStepId;
  }

  void _submitTyped() {
    if (_coachTarget == null || _waitingCustomer) return;

    final turn = _scenario.turns[_turnIndex];
    final target = turn.resolvedTargetText.trim();
    final input = _inputController.text.trim();
    final ok = SoftTextMatch.typingMatches(input, target);

    if (ok) {
      final msg = turn.successReply ?? 'Good response.';
      setState(() {
        _bubbles.add(ScenarioChatBubbleData(isAgent: true, text: input));
        _inlineFeedback = msg;
        _coachPrompt = null;
        _coachTarget = null;
        _inputController.clear();
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

    final failMsg =
        turn.failReply ?? 'That response is not correct yet. Try again.';
    if (_scenario.isGuided) {
      setState(() {
        _inlineFeedback = failMsg;
        _hudText = failMsg;
        _inputController.clear();
      });
      _showErrorFeedback(failMsg);
      return;
    }

    setState(() {
      _mistakes++;
      _inlineFeedback = failMsg;
      _hudText = failMsg;
      _inputController.clear();
    });
    _showErrorFeedback(failMsg);

    if (_mistakes >= _scenario.maxMistakes) {
      _complete(false);
    }
  }

  void _submitChoice() {
    final turn = _scenario.turns[_turnIndex];
    if (turn.type != ScenarioTurnType.chooseOne) return;
    if (_selectedChoice == null) return;

    final correct = turn.correctIndex ?? 0;
    final ok = _selectedChoice == correct;
    final chosenText = (turn.options ?? const [])[_selectedChoice!];

    if (ok) {
      final msg = turn.successReply ?? 'Good response.';
      setState(() {
        _bubbles.add(ScenarioChatBubbleData(isAgent: true, text: chosenText));
        _inlineFeedback = msg;
        _coachPrompt = null;
        _coachTarget = null;
        _selectedChoice = null;
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

    final failMsg =
        turn.failReply ??
        'That choice is not the strongest response. Try again.';
    if (_scenario.isGuided) {
      setState(() {
        _inlineFeedback = failMsg;
        _hudText = failMsg;
        _selectedChoice = null;
      });
      _showErrorFeedback(failMsg);
      return;
    }

    setState(() {
      _mistakes++;
      _inlineFeedback = failMsg;
      _hudText = failMsg;
      _selectedChoice = null;
    });
    _showErrorFeedback(failMsg);

    if (_mistakes >= _scenario.maxMistakes) {
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
        _visibleAccounts = List<ScenarioAccount>.from(_scenario.accounts);
        _inlineFeedback = msg;
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
    final needed = turn.selectAccountId;
    final ok = _selectedAccountId != null && _selectedAccountId == needed;
    if (ok) {
      final msg = turn.successReply ?? 'Account selected.';
      setState(() {
        _inlineFeedback = msg;
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
      _inlineFeedback = msg;
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
        _inlineFeedback = message;
        _hudText = message;
      });
      _showErrorFeedback(message);
      return;
    }
    setState(() {
      _mistakes++;
      _inlineFeedback = message;
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
      _waitingCustomer = false;
    });
  }

  void _finishAndExit() {
    if (_passed) {
      MiniTrainingProgress.markChatScenarioCompleted(_scenario.id);
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
    return ScenarioPlayView(
      scenario: _scenario,
      mistakes: _mistakes,
      hudText: _hudText,
      bubbles: _bubbles,
      scrollController: _scrollController,
      accountScrollController: _accountScrollController,
      coachPrompt: _coachPrompt,
      coachTarget: _coachTarget,
      turnIndex: _turnIndex,
      selectedChoice: _selectedChoice,
      inputController: _inputController,
      searchController: _searchController,
      searchQuery: _searchQuery,
      waitingCustomer: _waitingCustomer,
      selectedAccountId: _selectedAccountId,
      visibleAccounts: _visibleAccounts.isEmpty
          ? _scenario.accounts
          : _visibleAccounts,
      issueResolved: _issueResolved,
      accountsRevealed: _accountsRevealed,
      inlineFeedback: _inlineFeedback,
      feedbackKind: _feedbackKind,
      feedbackTitle: _feedbackTitle,
      feedbackMessage: _feedbackMessage,
      inputFlashError: _inputFlashError,
      inputFlashSuccess: _inputFlashSuccess,
      completedMissionIds: _completedMissionIds,
      currentMissionStepId: _currentMissionStepId,
      onHudNext: _onHudNext,
      onSubmitTyped: _submitTyped,
      onSubmitChoice: _submitChoice,
      onSubmitAccountSearch: _submitAccountSearch,
      onSubmitAccountSelect: _submitAccountSelect,
      onSubmitAccountResolve: _submitAccountResolve,
      onSelectChoice: (i) {
        setState(() {
          _selectedChoice = i;
        });
      },
      onSelectAccount: (id) {
        setState(() {
          _selectedAccountId = id;
        });
      },
      onSearchChanged: (q) {
        setState(() {
          _searchQuery = q;
        });
      },
    );
  }
}
