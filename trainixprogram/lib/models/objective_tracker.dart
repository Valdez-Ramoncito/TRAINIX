import 'package:trainixprogram/models/case_blueprint.dart';

class ObjectiveState {
  final Set<String> done;
  final String? currentId;
  final List<ObjectiveEvent> log;
  final String branch;

  const ObjectiveState({
    this.done = const {},
    this.currentId,
    this.log = const [],
    this.branch = 'main',
  });

  factory ObjectiveState.from({
    required Set<String> done,
    required CaseBlueprint bp,
    required String branch,
    List<ObjectiveEvent> log = const [],
  }) {
    final list = bp.activeObjectives(branch: branch);
    String? current;
    for (final o in list) {
      if (done.contains(o.id)) continue;
      if (!o.requires.every(done.contains)) continue;
      current = o.id;
      break;
    }
    return ObjectiveState(
      done: done,
      currentId: current,
      log: log,
      branch: branch,
    );
  }
}

class ObjectiveTracker {
  ObjectiveState state = const ObjectiveState();

  void reset() {
    state = const ObjectiveState();
  }

  ObjectiveState apply(CaseBlueprint bp, Evidence e) {
    var done = {...state.done};
    var log = List<ObjectiveEvent>.from(state.log);
    final branch = e.branch;
    var changed = true;
    while (changed) {
      changed = false;
      for (final o in bp.activeObjectives(branch: branch)) {
        if (done.contains(o.id)) continue;
        if (!o.requires.every(done.contains)) continue;
        final source = _sourceIfSatisfied(o, e, bp);
        if (source != null) {
          done.add(o.id);
          log.add(
            ObjectiveEvent(
              id: o.id,
              completedAt: DateTime.now(),
              source: source,
            ),
          );
          changed = true;
        }
      }
    }
    state = ObjectiveState.from(done: done, bp: bp, branch: branch, log: log);
    return state;
  }

  String? _sourceIfSatisfied(ObjectiveDef o, Evidence e, CaseBlueprint bp) {
    switch (o.evidenceKind) {
      case ObjectiveEvidenceKind.tool:
        return _toolMet(o.toolEvent, e) ? 'tool' : null;
      case ObjectiveEvidenceKind.customerFacts:
        if (o.customerFactKeys.isEmpty) return null;
        final known = e.customerFactsKnown;
        final start = bp.knowsAtStart;
        final allKnown = o.customerFactKeys.every(
          (k) => known.contains(k) || start.contains(k),
        );
        return allKnown ? 'facts' : null;
      case ObjectiveEvidenceKind.phrases:
        if (_phrasesMet(o.phrases, e.lastTraineeText)) return 'phrases';
        // Clarify-style: customer already stated the details in chat
        if (o.id == 'clarify' && _phrasesMet(o.phrases, e.customerCorpus)) {
          return 'customer';
        }
        if (e.judgedObjectiveIds.contains(o.id)) return 'judge';
        return null;
      case ObjectiveEvidenceKind.judge:
        if (e.judgedObjectiveIds.contains(o.id)) return 'judge';
        if (_phrasesMet(o.phrases, e.lastTraineeText)) return 'phrases';
        return null;
    }
  }

  bool _toolMet(String? toolEvent, Evidence e) {
    switch (toolEvent) {
      case ToolEvent.identityVerified:
        return e.identityVerified;
      case ToolEvent.requestFiled:
        return e.requestFiled;
      case ToolEvent.callbackScheduled:
        return e.callbackScheduled;
      case ToolEvent.ticketOpened:
        return e.ticketOpened;
      case ToolEvent.escalationSubmitted:
        return e.escalationSubmitted;
      default:
        return false;
    }
  }

  bool _phrasesMet(List<String> phrases, String text) {
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
}
