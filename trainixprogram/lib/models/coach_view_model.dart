import 'package:trainixprogram/models/case_checklist.dart';
import 'package:trainixprogram/models/sim_flow_log.dart';
import 'package:trainixprogram/models/guide_templates.dart';
import 'package:trainixprogram/models/problem_family.dart';
import 'package:trainixprogram/models/simulation_coach.dart';
import 'package:trainixprogram/models/simulation_stage.dart';

enum SimulationChannel { chat, voice, hybrid }

class CoachMessage {
  final bool isTrainee;
  final String text;

  const CoachMessage({required this.isTrainee, required this.text});
}

class CoachSessionState {
  final String sector;
  final String problemText;
  final bool needsAccount;
  final bool escalateFromStart;
  final List<CoachMessage> messages;
  final bool identityVerified;
  final bool toolWorkDone;
  final bool customerResolved;
  final String customerEmotion;
  final Duration elapsed;
  final SimulationChannel channel;
  final bool readyToClose;
  final String accountStatusLabel;
  final String accountOwnerName;
  final String accountIssueLine;
  final Map<String, String> accountDetails;

  const CoachSessionState({
    required this.sector,
    required this.problemText,
    required this.needsAccount,
    this.escalateFromStart = false,
    required this.messages,
    required this.identityVerified,
    required this.toolWorkDone,
    this.customerResolved = false,
    this.customerEmotion = '',
    required this.elapsed,
    this.channel = SimulationChannel.chat,
    this.readyToClose = false,
    this.accountStatusLabel = '',
    this.accountOwnerName = '',
    this.accountIssueLine = '',
    this.accountDetails = const {},
  });

  int get traineeTurns =>
      messages.where((m) => m.isTrainee && m.text.trim().isNotEmpty).length;

  String get lastCustomerText {
    for (var i = messages.length - 1; i >= 0; i--) {
      if (!messages[i].isTrainee) return messages[i].text;
    }
    return '';
  }

  String get lastTraineeText {
    for (var i = messages.length - 1; i >= 0; i--) {
      if (messages[i].isTrainee) return messages[i].text;
    }
    return '';
  }

  bool get hasCustomerMessage =>
      messages.any((m) => !m.isTrainee && m.text.trim().isNotEmpty);

  bool get hasTraineeMessage => traineeTurns > 0;
}

class CoachViewModel {
  final SimulationStage stage;
  final ProblemFamily family;
  final String tip;
  final List<ScriptLine> examples;
  final List<GuideStep> steps;
  final int stepIndex;
  final bool showEscalation;
  final String? amberOverride;
  final List<String> checklistLabels;
  final List<String> checklistStatuses;
  final String? currentObjectiveLabel;
  final int? highlightToolTab;
  final bool hideFocusDuplicate;

  const CoachViewModel({
    required this.stage,
    required this.family,
    required this.tip,
    required this.examples,
    required this.steps,
    required this.stepIndex,
    required this.showEscalation,
    this.amberOverride,
    this.checklistLabels = const [],
    this.checklistStatuses = const [],
    this.currentObjectiveLabel,
    this.highlightToolTab,
    this.hideFocusDuplicate = false,
  });

  String? get amberStepText {
    if (amberOverride != null && amberOverride!.trim().isNotEmpty) {
      return amberOverride;
    }
    if (steps.isEmpty) return null;
    if (stage == SimulationStage.waitCustomer ||
        stage == SimulationStage.acw ||
        stage == SimulationStage.next) {
      return null;
    }
    final i = stepIndex.clamp(0, steps.length - 1);
    return 'Step ${i + 1} of ${steps.length}: ${steps[i].text}';
  }

  factory CoachViewModel.from({
    required CoachSessionState state,
    required StageTracker tracker,
    required ProblemFamily family,
  }) {
    final escalationSaid = StagePhrases.escalationSaid(state.lastTraineeText);
    final closingSaid = StagePhrases.closingSpiel(state.lastTraineeText);
    final facts = CaseFacts.fromCustomerCorpus(
      state.problemText,
      state.messages.where((m) => !m.isTrainee).map((m) => m.text).join(' '),
    );
    final factsComplete = _factsComplete(family, facts);
    tracker.update(
      traineeTurns: state.traineeTurns,
      hasCustomerMessage: state.hasCustomerMessage,
      identityVerified: state.identityVerified,
      toolWorkDone: state.toolWorkDone,
      customerResolved: state.customerResolved,
      needsAccount: state.needsAccount,
      escalateFromStart: state.escalateFromStart,
      escalationSaid: escalationSaid,
      closingSpielSent: closingSaid,
      acwSubmitted: false,
      readyToClose: state.readyToClose,
      family: family,
      factsComplete: factsComplete,
      customerSatisfied: CaseChecklist.isCustomerSatisfied(
        state.messages.where((m) => !m.isTrainee).map((m) => m.text).join(' '),
      ),
    );
    final stage = tracker.stage;
    final customerCorpus = state.messages
        .where((m) => !m.isTrainee)
        .map((m) => m.text)
        .join(' ');
    final traineeCorpus = state.messages
        .where((m) => m.isTrainee)
        .map((m) => m.text)
        .toList();
    final next = CaseChecklist.resolve(
      family: family,
      stage: stage,
      problemText: state.problemText,
      customerCorpus: customerCorpus,
      lastTraineeText: state.lastTraineeText,
      traineeTurns: state.traineeTurns,
      hasCustomerMessage: state.hasCustomerMessage,
      hasTraineeMessage: state.hasTraineeMessage,
      needsAccount: state.needsAccount,
      identityVerified: state.identityVerified,
      toolWorkDone: state.toolWorkDone,
      escalateFromStart: state.escalateFromStart,
      readyToClose: state.readyToClose,
      elapsed: state.elapsed,
      accountStatusLabel: state.accountStatusLabel,
      accountOwnerName: state.accountOwnerName,
      accountIssueLine: state.accountIssueLine,
      accountDetails: state.accountDetails,
    );
    final beforeFilter = next.examples.map((e) => e.text).toList();
    var examples = SimulationCoach.filterAlreadyUsedLines(
      next.examples,
      state.lastTraineeText,
      allTraineeMessages: traineeCorpus,
    );
    examples = SimulationCoach.guardExamples(
      examples,
      stage: stage,
      toolWorkDone: state.toolWorkDone,
    );
    final filteredOut = examples.isEmpty && beforeFilter.isNotEmpty;
    if (examples.isEmpty) {
      // Prefer unused alternates from the same next step, never recycle used lines
      final alts = next.examples
          .where(
            (e) => !traineeCorpus.any((said) {
              final s = said.toLowerCase();
              final x = e.text.toLowerCase();
              return s.contains(x) ||
                  x.contains(s) ||
                  SimulationCoach.roughOverlapPublic(s, x) >= 0.35;
            }),
          )
          .toList();
      if (alts.isNotEmpty) {
        examples = alts;
      } else if (next.id.contains('close') ||
          stage == SimulationStage.closing) {
        examples = SimulationCoach.fallbackFor(SimulationStage.closing);
      } else if (next.id.contains('refill') || next.id.contains('timing')) {
        examples = [
          const ScriptLine(
            category: 'explain',
            choiceNumber: 1,
            title: 'Timing detail',
            text:
                'Most pharmacies need about 24 to 48 hours. Please ask them if the order is queued, on hold, or out of stock, then tell me what they report.',
          ),
        ];
      } else {
        examples = SimulationCoach.fallbackFor(stage);
      }
      examples = SimulationCoach.filterAlreadyUsedLines(
        examples,
        state.lastTraineeText,
        allTraineeMessages: traineeCorpus,
      );
    }
    final steps = GuideTemplates.forFamily(family);
    final idx = (next.stepNumber - 1).clamp(
      0,
      steps.isEmpty ? 0 : steps.length - 1,
    );
    tracker.noteStep(idx);
    final showEsc =
        next.allowEscalateTab || _showEscalation(state, stage, family);
    SimFlowLog.block('coachViewModel', {
      'family': family.name,
      'stageBefore': stage.name,
      'stage': tracker.stage.name,
      'factsComplete': factsComplete,
      'identityVerified': state.identityVerified,
      'toolWorkDone': state.toolWorkDone,
      'accountStatus': state.accountStatusLabel,
      'stepId': next.id,
      'tip': next.tip,
      'amber': next.amberLabel,
      'examplesBeforeFilter': beforeFilter.join(' | '),
      'examplesAfterFilter': examples.map((e) => e.text).join(' | '),
      'filteredOutAllBank': filteredOut,
      'showEscalation': showEsc,
      'traineeTurns': state.traineeTurns,
      'msgCount': state.messages.length,
    });
    return CoachViewModel(
      stage: tracker.stage,
      family: family,
      tip: next.tip,
      examples: examples,
      steps: steps,
      stepIndex: idx,
      showEscalation: showEsc,
      amberOverride: next.amberLabel,
    );
  }

  static bool _factsComplete(ProblemFamily family, CaseFacts facts) {
    switch (family) {
      case ProblemFamily.planEligibility:
        return facts.planKnown && facts.whenDeniedKnown;
      case ProblemFamily.loginAccess:
        return facts.loginIdHint;
      case ProblemFamily.billingSurprise:
        return facts.billPeriodHint;
      case ProblemFamily.claimStatus:
        return facts.claimRefHint;
      case ProblemFamily.fundTransfer:
        return facts.amountOrTransferHint;
      case ProblemFamily.networkConnectivity:
        return facts.symptomsKnown;
      case ProblemFamily.prescriptionRefill:
        return false;
      case ProblemFamily.appointmentPrep:
        return facts.appointmentHint;
      default:
        return false;
    }
  }

  static bool _showEscalation(
    CoachSessionState s,
    SimulationStage stage,
    ProblemFamily f,
  ) {
    if (stage == SimulationStage.escalating) return true;
    if (f == ProblemFamily.trueEscalate) return s.traineeTurns >= 2;
    if (stage != SimulationStage.acting) return false;
    final softElapsed = s.elapsed >= const Duration(minutes: 8);
    final stuck = s.traineeTurns >= 5 && !s.toolWorkDone;
    final upset = _isNegativeEmotion(s.customerEmotion);
    return softElapsed && stuck && upset;
  }

  static bool _isNegativeEmotion(String e) {
    final t = e.toLowerCase();
    return t.contains('angry') ||
        t.contains('irate') ||
        t.contains('furious') ||
        t.contains('upset') ||
        t.contains('frustrated');
  }
}
