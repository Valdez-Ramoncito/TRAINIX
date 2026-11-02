import 'package:trainixprogram/models/problem_family.dart';
import 'package:trainixprogram/models/simulation_stage.dart';

enum ObjectiveEvidenceKind { tool, phrases, customerFacts, judge }

class ObjectiveDef {
  final String id;
  final String phase;
  final String label;
  final List<String> requires;
  final ObjectiveEvidenceKind evidenceKind;
  final String? toolEvent;
  final List<String> phrases;
  final List<String> customerFactKeys;
  final String tip;
  final String? toolHint;
  final List<String> hints;
  final List<String> examples;

  const ObjectiveDef({
    required this.id,
    required this.phase,
    required this.label,
    this.requires = const [],
    required this.evidenceKind,
    this.toolEvent,
    this.phrases = const [],
    this.customerFactKeys = const [],
    required this.tip,
    this.toolHint,
    this.hints = const [],
    this.examples = const [],
  });

  SimulationStage get stage {
    switch (phase) {
      case 'opening':
        return SimulationStage.opening;
      case 'exploring':
        return SimulationStage.exploring;
      case 'acting':
        return SimulationStage.acting;
      case 'escalating':
        return SimulationStage.escalating;
      case 'closing':
        return SimulationStage.closing;
      case 'acw':
        return SimulationStage.acw;
      default:
        return SimulationStage.exploring;
    }
  }
}

class CaseBlueprint {
  final String id;
  final String sector;
  final String title;
  final bool needsAccount;
  final bool escalateFromStart;
  final Map<String, String> groundTruth;
  final List<String> knowsAtStart;
  final List<ObjectiveDef> objectives;
  final List<ObjectiveDef> escalateObjectives;
  final ProblemFamily family;

  const CaseBlueprint({
    required this.id,
    required this.sector,
    required this.title,
    this.needsAccount = true,
    this.escalateFromStart = false,
    this.groundTruth = const {},
    this.knowsAtStart = const [],
    required this.objectives,
    this.escalateObjectives = const [],
    this.family = ProblemFamily.genericAccount,
  });

  List<ObjectiveDef> activeObjectives({required String branch}) {
    if (branch == 'escalate' && escalateObjectives.isNotEmpty) {
      return escalateObjectives;
    }
    return objectives;
  }

  String fill(String text, {String agentName = ''}) {
    var out = text;
    groundTruth.forEach((k, v) {
      out = out.replaceAll('{$k}', v);
      out = out.replaceAll('[$k]', v);
    });
    if (agentName.isNotEmpty) {
      out = out.replaceAll('[your name]', agentName);
      out = out.replaceAll('[Your name]', agentName);
      out = out.replaceAll('[name]', agentName);
      out = out.replaceAll('[Name]', agentName);
    }
    return out;
  }
}

class ToolEvent {
  final String kind;
  final String note;

  const ToolEvent({required this.kind, this.note = ''});

  static const identityVerified = 'identityVerified';
  static const requestFiled = 'requestFiled';
  static const callbackScheduled = 'callbackScheduled';
  static const ticketOpened = 'ticketOpened';
  static const escalationSubmitted = 'escalationSubmitted';
}

class Evidence {
  final bool identityVerified;
  final bool requestFiled;
  final bool callbackScheduled;
  final bool ticketOpened;
  final bool escalationSubmitted;
  final bool customerReadyToClose;
  final Set<String> customerFactsKnown;
  final Set<String> judgedObjectiveIds;
  final String branch;
  final String lastTraineeText;
  final String customerCorpus;

  const Evidence({
    this.identityVerified = false,
    this.requestFiled = false,
    this.callbackScheduled = false,
    this.ticketOpened = false,
    this.escalationSubmitted = false,
    this.customerReadyToClose = false,
    this.customerFactsKnown = const {},
    this.judgedObjectiveIds = const {},
    this.branch = 'main',
    this.lastTraineeText = '',
    this.customerCorpus = '',
  });

  Evidence copyWith({
    bool? identityVerified,
    bool? requestFiled,
    bool? callbackScheduled,
    bool? ticketOpened,
    bool? escalationSubmitted,
    bool? customerReadyToClose,
    Set<String>? customerFactsKnown,
    Set<String>? judgedObjectiveIds,
    String? branch,
    String? lastTraineeText,
    String? customerCorpus,
  }) {
    return Evidence(
      identityVerified: identityVerified ?? this.identityVerified,
      requestFiled: requestFiled ?? this.requestFiled,
      callbackScheduled: callbackScheduled ?? this.callbackScheduled,
      ticketOpened: ticketOpened ?? this.ticketOpened,
      escalationSubmitted: escalationSubmitted ?? this.escalationSubmitted,
      customerReadyToClose: customerReadyToClose ?? this.customerReadyToClose,
      customerFactsKnown: customerFactsKnown ?? this.customerFactsKnown,
      judgedObjectiveIds: judgedObjectiveIds ?? this.judgedObjectiveIds,
      branch: branch ?? this.branch,
      lastTraineeText: lastTraineeText ?? this.lastTraineeText,
      customerCorpus: customerCorpus ?? this.customerCorpus,
    );
  }

  bool get toolWorkDone => requestFiled || callbackScheduled || ticketOpened;
}

class ObjectiveEvent {
  final String id;
  final DateTime completedAt;
  final String source;

  const ObjectiveEvent({
    required this.id,
    required this.completedAt,
    required this.source,
  });
}

enum ObjectiveStatus { done, current, upcoming }

class ObjectiveView {
  final String id;
  final String label;
  final ObjectiveStatus status;
  final String phase;

  const ObjectiveView({
    required this.id,
    required this.label,
    required this.status,
    required this.phase,
  });
}

class GuideState {
  final List<ObjectiveView> checklist;
  final ObjectiveView? current;
  final String focusText;
  final String? toolHint;
  final List<String> hints;
  final List<String> examples;
  final bool showEscalationTab;
  final String progressLabel;

  const GuideState({
    this.checklist = const [],
    this.current,
    this.focusText = '',
    this.toolHint,
    this.hints = const [],
    this.examples = const [],
    this.showEscalationTab = false,
    this.progressLabel = '',
  });

  static const empty = GuideState();
}
