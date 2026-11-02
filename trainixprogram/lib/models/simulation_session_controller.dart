import 'package:flutter/foundation.dart';
import 'package:trainixprogram/models/case_blueprint.dart';
import 'package:trainixprogram/models/coach_view_model.dart';
import 'package:trainixprogram/models/problem_family.dart';
import 'package:trainixprogram/models/sim_flow_log.dart';
import 'package:trainixprogram/models/sim_mission.dart';
import 'package:trainixprogram/models/sim_mission_catalog.dart';
import 'package:trainixprogram/models/simulation_stage.dart';

/// Session owner for scripted simulation guide.
/// Mission advances only on explicit events (start, send, tool), never during build.
class SimulationSessionController extends ChangeNotifier {
  static const useBlueprintGuide = true;
  static const useMissionGuide = true;

  final SimMissionRunner mission = SimMissionRunner();

  CaseBlueprint? blueprint;
  Evidence evidence = const Evidence();
  final List<CoachMessage> messages = [];
  Duration elapsed = Duration.zero;
  List<String> mistakes = [];
  bool customerReadyToClose = false;
  bool toolAreaVisited = false;
  bool sectorGuideVisited = false;

  void startCase({
    required String sector,
    required String problem,
    required ProblemFamily family,
    bool needsAccount = true,
    bool escalateFromStart = false,
    String? casePackId,
  }) {
    messages.clear();
    mistakes.clear();
    elapsed = Duration.zero;
    customerReadyToClose = false;
    toolAreaVisited = false;
    sectorGuideVisited = false;
    evidence = const Evidence();
    blueprint = null;

    final pack = SimMissionCatalog.resolve(
      sector: sector,
      problem: problem,
      family: family,
      needsAccount: needsAccount,
      escalateFromStart: escalateFromStart,
    );
    mission.start(pack);
    _mirrorFromMission();
    SimFlowLog.block('mission.start', {
      'pack': pack.id,
      'family': family.name,
      'steps': pack.steps.length,
      'needsAccount': pack.needsAccount,
      'current': mission.state.currentId,
    });
  }

  void reset({bool notify = false}) {
    mission.reset();
    blueprint = null;
    messages.clear();
    mistakes.clear();
    evidence = const Evidence();
    elapsed = Duration.zero;
    customerReadyToClose = false;
    toolAreaVisited = false;
    sectorGuideVisited = false;
    if (notify) notifyListeners();
  }

  void onTick(Duration value) {
    elapsed = value;
  }

  void markToolAreaVisited() {
    if (toolAreaVisited) return;
    toolAreaVisited = true;
    mission.markToolAreaVisited();
  }

  void markSectorGuideVisited() {
    if (sectorGuideVisited) return;
    sectorGuideVisited = true;
    mission.markSectorGuideVisited();
  }

  void markSectorGuideIssueOpened() {
    sectorGuideVisited = true;
    mission.markSectorGuideIssueOpened();
  }

  void markCustomerReadyToClose() {
    customerReadyToClose = true;
  }

  void replaceMessages(List<CoachMessage> next, {bool notify = false}) {
    messages
      ..clear()
      ..addAll(next);
    mission.replaceMessages(next);
    _mirrorFromMission();
    _logMission('mission.messages');
    if (notify) notifyListeners();
  }

  void syncFromAccount({
    required bool identityVerified,
    required bool toolWorkDone,
    required String lastToolAction,
    bool notify = false,
  }) {
    mission.syncTools(
      identityVerified: identityVerified,
      toolWorkDone: toolWorkDone,
      lastToolAction: lastToolAction,
    );
    _mirrorFromMission();
    _logMission('mission.tools');
    if (notify) notifyListeners();
  }

  int? get highlightToolTab => mission.highlightToolTab;

  SimulationStage get stage => mission.stageForCurrent();

  bool get toolWorkDone => mission.evidence.toolWorkDone;

  bool get isMissionComplete => mission.isComplete;

  CoachViewModel toCoachViewModel({required ProblemFamily family}) {
    return mission.toCoachViewModel(family: family);
  }

  void _mirrorFromMission() {
    evidence = mission.evidence;
    messages
      ..clear()
      ..addAll(mission.messages);
  }

  void _logMission(String tag) {
    final step = mission.currentStep;
    SimFlowLog.block(tag, {
      'pack': mission.pack?.id,
      'current': mission.state.currentId,
      'done': mission.state.done.join(','),
      'index': mission.state.currentIndex,
      'stepKind': step?.kind.name,
      'identity': mission.evidence.identityVerified,
      'requestFiled': mission.evidence.requestFiled,
      'lastTrainee': mission.evidence.lastTraineeText,
    });
  }
}
