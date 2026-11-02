import 'package:trainixprogram/models/case_blueprint.dart';
import 'package:trainixprogram/models/coach_view_model.dart';
import 'package:trainixprogram/models/problem_family.dart';
import 'package:trainixprogram/models/simulation_coach.dart';
import 'package:trainixprogram/models/simulation_stage.dart';
import 'package:trainixprogram/models/training/script_personalization.dart';

/// Scenario-practice style mission step for simulation.
enum SimStepKind { speak, tool, optionalSpeak }

class SimStep {
  final String id;
  final String label;
  final SimStepKind kind;
  final String tip;
  final List<String> examples;
  final List<String> passPhrases;

  /// Customer line shown when this step becomes current (scripted, not live AI).
  final String? customerLine;

  /// Customer line after this step is completed (reaction), before next step line.
  final String? customerLineAfterPass;
  final String? toolEvent;
  final String? toolHint;
  final bool highlightAccountLookup;
  final bool highlightSectorGuide;

  const SimStep({
    required this.id,
    required this.label,
    required this.kind,
    required this.tip,
    this.examples = const [],
    this.passPhrases = const [],
    this.customerLine,
    this.customerLineAfterPass,
    this.toolEvent,
    this.toolHint,
    this.highlightAccountLookup = false,
    this.highlightSectorGuide = false,
  });
}

class SimPack {
  final String id;
  final String title;
  final String sector;
  final ProblemFamily family;
  final bool needsAccount;
  final String customerName;
  final String problemSummary;
  final String emotion;

  /// First customer message when the case starts (before open step).
  final String openingCustomerLine;
  final List<SimStep> steps;

  /// Extra fields merged into the target Account Lookup record.
  final Map<String, String> accountDetails;

  const SimPack({
    required this.id,
    required this.title,
    required this.sector,
    required this.family,
    required this.needsAccount,
    required this.customerName,
    required this.problemSummary,
    this.emotion = 'neutral',
    required this.openingCustomerLine,
    required this.steps,
    this.accountDetails = const {},
  });
}

class SimMissionState {
  final int currentIndex;
  final Set<String> done;
  final String? currentId;

  const SimMissionState({
    this.currentIndex = 0,
    this.done = const {},
    this.currentId,
  });
}

/// Deterministic mission runner: fixed customer lines + fixed trainee steps.
/// No live model drives progression. Safe for concurrent local sessions
/// (each screen owns its own runner instance).
class SimMissionRunner {
  SimPack? pack;
  SimMissionState state = const SimMissionState();
  final List<CoachMessage> messages = [];
  Evidence evidence = const Evidence();
  bool toolAreaVisited = false;
  bool sectorGuideVisited = false;
  bool sectorGuideIssueOpened = false;

  /// Queued customer lines for the UI to post (scripted).
  final List<String> pendingCustomerLines = [];

  void start(SimPack next) {
    pack = next;
    state = SimMissionState(
      currentIndex: 0,
      done: {},
      currentId: next.steps.isEmpty ? null : next.steps.first.id,
    );
    messages.clear();
    evidence = const Evidence();
    toolAreaVisited = false;
    sectorGuideVisited = false;
    sectorGuideIssueOpened = false;
    pendingCustomerLines
      ..clear()
      ..add(next.openingCustomerLine);
    final first = currentStep;
    if (first?.customerLine != null &&
        first!.customerLine!.trim().isNotEmpty &&
        first.customerLine != next.openingCustomerLine) {
      pendingCustomerLines.add(first.customerLine!);
    }
  }

  void reset() {
    pack = null;
    state = const SimMissionState();
    messages.clear();
    evidence = const Evidence();
    toolAreaVisited = false;
    sectorGuideVisited = false;
    sectorGuideIssueOpened = false;
    pendingCustomerLines.clear();
  }

  List<String> takePendingCustomerLines() {
    final out = List<String>.from(pendingCustomerLines);
    pendingCustomerLines.clear();
    return out;
  }

  void replaceMessages(List<CoachMessage> next) {
    messages
      ..clear()
      ..addAll(next);
    String lastTrainee = '';
    for (var i = messages.length - 1; i >= 0; i--) {
      if (messages[i].isTrainee) {
        lastTrainee = messages[i].text;
        break;
      }
    }
    final corpus = messages
        .where((m) => !m.isTrainee)
        .map((m) => m.text)
        .join(' ');
    evidence = evidence.copyWith(
      lastTraineeText: lastTrainee,
      customerCorpus: corpus,
    );
    _evaluate();
  }

  void syncTools({
    required bool identityVerified,
    required bool toolWorkDone,
    required String lastToolAction,
  }) {
    final action = lastToolAction.toLowerCase();
    var next = evidence.copyWith(identityVerified: identityVerified);
    if (toolWorkDone) {
      if (action.contains('escalat')) {
        next = next.copyWith(escalationSubmitted: true, branch: 'escalate');
      } else if (action.contains('callback')) {
        next = next.copyWith(callbackScheduled: true, requestFiled: true);
      } else if (action.contains('identity') ||
          action.contains('confirm identity')) {
        next = next.copyWith(identityVerified: true);
      } else {
        next = next.copyWith(requestFiled: true);
      }
    }
    if (identityVerified) {
      next = next.copyWith(identityVerified: true);
    }
    evidence = next;
    _evaluate();
  }

  void markToolAreaVisited() {
    toolAreaVisited = true;
  }

  void markSectorGuideVisited() {
    sectorGuideVisited = true;
  }

  void markSectorGuideIssueOpened() {
    sectorGuideIssueOpened = true;
    sectorGuideVisited = true;
  }

  SimStep? get currentStep {
    final p = pack;
    if (p == null || p.steps.isEmpty) return null;
    if (state.currentIndex < 0 || state.currentIndex >= p.steps.length) {
      return null;
    }
    return p.steps[state.currentIndex];
  }

  bool get isComplete {
    final p = pack;
    if (p == null || p.steps.isEmpty) return false;
    return state.done.length >= p.steps.length;
  }

  int? get highlightToolTab {
    final step = currentStep;
    if (step == null) return null;
    if (step.highlightAccountLookup &&
        step.kind == SimStepKind.tool &&
        !_toolMet(step.toolEvent)) {
      return 1;
    }
    if (step.highlightSectorGuide && !sectorGuideIssueOpened) {
      return 2;
    }
    return null;
  }

  List<String> examplesForGuide() {
    final step = currentStep;
    if (step == null) return const [];
    if (step.kind == SimStepKind.tool && !_toolMet(step.toolEvent)) {
      return const [];
    }
    if (step.highlightSectorGuide && !sectorGuideIssueOpened) {
      return const [];
    }
    if (step.highlightAccountLookup &&
        step.kind == SimStepKind.tool &&
        !toolAreaVisited &&
        !_toolMet(step.toolEvent)) {
      return const [];
    }
    final name = SimulationCoach.agentName;
    return step.examples
        .map(
          (e) => ScriptPersonalization.resolve(
            e
                .replaceAll('[your name]', name)
                .replaceAll('[Your name]', name)
                .replaceAll('[name]', name),
          ),
        )
        .toList();
  }

  String tipForGuide() {
    final step = currentStep;
    if (step == null) {
      return isComplete
          ? 'Mission complete. Close with the customer if needed, then ACW.'
          : 'Wait for the customer.';
    }
    if (step.highlightSectorGuide && !sectorGuideIssueOpened) {
      return 'Open the sector guide, then open the matching issue for this customer. Suggested replies unlock after you open that issue.';
    }
    if (step.kind == SimStepKind.tool && !_toolMet(step.toolEvent)) {
      if (step.highlightAccountLookup) {
        if (!toolAreaVisited) {
          return 'Voice: tell the customer you will place them on a brief hold, press Hold, then open Account Lookup. Chat: open Account Lookup directly.';
        }
        return step.tip;
      }
      if (!toolAreaVisited) {
        return 'Open Account Lookup, complete the required tool action, then suggested wording unlocks.';
      }
      return step.tip;
    }
    return step.tip;
  }

  List<ObjectiveView> checklistViews() {
    final p = pack;
    if (p == null) return const [];
    final views = <ObjectiveView>[];
    for (var i = 0; i < p.steps.length; i++) {
      final s = p.steps[i];
      final status = state.done.contains(s.id)
          ? ObjectiveStatus.done
          : (i == state.currentIndex
                ? ObjectiveStatus.current
                : ObjectiveStatus.upcoming);
      views.add(
        ObjectiveView(
          id: s.id,
          label: s.label,
          status: status,
          phase: s.kind == SimStepKind.tool ? 'acting' : 'exploring',
        ),
      );
    }
    return views;
  }

  SimulationStage stageForCurrent() {
    final step = currentStep;
    if (step == null) {
      return isComplete
          ? SimulationStage.closing
          : SimulationStage.waitCustomer;
    }
    if (step.id == 'open') return SimulationStage.opening;
    if (step.id == 'close') return SimulationStage.closing;
    if (step.kind == SimStepKind.tool) return SimulationStage.acting;
    if (step.id == 'confirm' || step.id == 'act' || step.id == 'guide') {
      return SimulationStage.acting;
    }
    return SimulationStage.exploring;
  }

  CoachViewModel toCoachViewModel({required ProblemFamily family}) {
    final step = currentStep;
    final examples = examplesForGuide()
        .asMap()
        .entries
        .map(
          (e) => ScriptLine(
            category: 'guide',
            choiceNumber: e.key + 1,
            title: step?.label ?? 'Guide',
            text: e.value,
          ),
        )
        .toList();
    final filtered = SimulationCoach.filterAlreadyUsedLines(
      examples,
      evidence.lastTraineeText,
      allTraineeMessages: messages
          .where((m) => m.isTrainee)
          .map((m) => m.text)
          .toList(),
    );
    final views = checklistViews();
    final doneCount = state.done.length;
    final total = pack?.steps.length ?? 0;
    // Escalation only when the case is true escalate, the branch is escalate,
    // or we are past first-line troubleshooting on a network/outage pack.
    final lateNetwork =
        family == ProblemFamily.networkConnectivity && doneCount >= 2;
    final showEscalate =
        evidence.branch == 'escalate' ||
        family == ProblemFamily.trueEscalate ||
        (pack?.id == 'mission_escalate') ||
        lateNetwork;
    String? amber;
    if (step != null) {
      if (step.kind == SimStepKind.tool &&
          !_toolMet(step.toolEvent) &&
          step.toolHint != null) {
        amber = step.toolHint;
      } else if (step.highlightSectorGuide &&
          !sectorGuideVisited &&
          step.toolHint != null) {
        amber = step.toolHint;
      } else if (step.toolHint != null && step.kind != SimStepKind.tool) {
        amber = step.toolHint;
      }
    }
    return CoachViewModel(
      stage: stageForCurrent(),
      family: family,
      tip: tipForGuide(),
      examples: filtered.isNotEmpty ? filtered : examples,
      steps: const [],
      stepIndex: 0,
      showEscalation: showEscalate,
      amberOverride: amber,
      checklistLabels: views.map((v) => v.label).toList(),
      checklistStatuses: views.map((v) => v.status.name).toList(),
      currentObjectiveLabel: step?.label,
      highlightToolTab: highlightToolTab,
      hideFocusDuplicate: true,
    );
  }

  void _evaluate() {
    final p = pack;
    if (p == null || p.steps.isEmpty) return;
    var guard = 0;
    while (guard < 12) {
      guard++;
      final step = currentStep;
      if (step == null) return;
      if (state.done.contains(step.id)) {
        _moveForwardFrom(step);
        continue;
      }
      if (_stepPassed(step)) {
        _completeStep(step);
        // One speak step per trainee turn so a long message does not
        // auto-clear later steps that share common words.
        if (step.kind == SimStepKind.speak ||
            step.kind == SimStepKind.optionalSpeak) {
          return;
        }
        continue;
      }
      return;
    }
  }

  void _completeStep(SimStep step) {
    final p = pack!;
    final done = {...state.done, step.id};
    // Tool actions are silent in chat. The agent must speak first after any
    // Account Lookup action. Customer reactions only come from speak steps.
    if (step.kind != SimStepKind.tool &&
        step.customerLineAfterPass != null &&
        step.customerLineAfterPass!.trim().isNotEmpty) {
      pendingCustomerLines.add(step.customerLineAfterPass!.trim());
    }
    final nextIndex = state.currentIndex + 1;
    if (nextIndex >= p.steps.length) {
      state = SimMissionState(
        currentIndex: p.steps.length,
        done: done,
        currentId: null,
      );
      return;
    }
    state = SimMissionState(
      currentIndex: nextIndex,
      done: done,
      currentId: p.steps[nextIndex].id,
    );
    final next = p.steps[nextIndex];
    if (next.customerLine != null && next.customerLine!.trim().isNotEmpty) {
      pendingCustomerLines.add(next.customerLine!);
    }
  }

  void _moveForwardFrom(SimStep step) {
    final p = pack!;
    final nextIndex = state.currentIndex + 1;
    if (nextIndex >= p.steps.length) {
      state = SimMissionState(
        currentIndex: p.steps.length,
        done: state.done,
        currentId: null,
      );
      return;
    }
    state = SimMissionState(
      currentIndex: nextIndex,
      done: state.done,
      currentId: p.steps[nextIndex].id,
    );
  }

  bool _stepPassed(SimStep step) {
    switch (step.kind) {
      case SimStepKind.tool:
        return _toolMet(step.toolEvent);
      case SimStepKind.speak:
        if (step.id == 'close') {
          return _anyPhrase(const [
            'thank',
            'trainix',
            'great day',
            'good day',
            'goodbye',
            'once again',
          ], evidence.lastTraineeText);
        }
        // Opening spiel is lenient across channels. STT often hears
        // "training" for "Trainix"; one clear greeting signal is enough.
        if (step.id == 'open') {
          return _anyPhrase(const [
            'trainix',
            'training',
            'support',
            'help',
            'hello',
            'this is',
            'thank you',
            'good morning',
            'good afternoon',
            'how can i',
            'how may i',
          ], evidence.lastTraineeText);
        }
        return _phrasesHit(step.passPhrases, evidence.lastTraineeText);
      case SimStepKind.optionalSpeak:
        return _phrasesHit(step.passPhrases, evidence.lastTraineeText) ||
            _anyPhrase(step.passPhrases, evidence.customerCorpus);
    }
  }

  bool _toolMet(String? toolEvent) {
    switch (toolEvent) {
      case ToolEvent.identityVerified:
        return evidence.identityVerified;
      case ToolEvent.requestFiled:
        return evidence.requestFiled;
      case ToolEvent.callbackScheduled:
        return evidence.callbackScheduled;
      case ToolEvent.ticketOpened:
        return evidence.ticketOpened;
      case ToolEvent.escalationSubmitted:
        return evidence.escalationSubmitted;
      default:
        return false;
    }
  }

  bool _phrasesHit(List<String> phrases, String text) {
    if (phrases.isEmpty || text.trim().isEmpty) return false;
    var t = text.toLowerCase().trim();
    if (t.startsWith('[agent]:')) {
      t = t.replaceFirst('[agent]:', '').trim();
    }
    var hits = 0;
    for (final p in phrases) {
      final needle = p.toLowerCase().trim();
      if (needle.isEmpty) continue;
      if (t.contains(needle)) hits++;
    }
    if (phrases.length <= 2) return hits >= 1;
    return hits >= 2;
  }

  bool _anyPhrase(List<String> phrases, String text) {
    if (phrases.isEmpty || text.trim().isEmpty) return false;
    final t = text.toLowerCase();
    for (final p in phrases) {
      final needle = p.toLowerCase().trim();
      if (needle.isEmpty) continue;
      if (t.contains(needle)) return true;
    }
    return false;
  }
}
