import 'package:flutter/foundation.dart';
import 'package:trainixprogram/models/sim_flow_log.dart';
import 'package:trainixprogram/models/problem_family.dart';

enum SimulationStage {
  waitCustomer,
  opening,
  exploring,
  acting,
  escalating,
  closing,
  acw,
  next,
}

extension SimulationStageX on SimulationStage {
  String get key {
    switch (this) {
      case SimulationStage.waitCustomer:
        return 'wait';
      case SimulationStage.opening:
        return 'open';
      case SimulationStage.exploring:
        return 'explore';
      case SimulationStage.acting:
        return 'act';
      case SimulationStage.escalating:
        return 'escalate';
      case SimulationStage.closing:
        return 'close';
      case SimulationStage.acw:
        return 'acw';
      case SimulationStage.next:
        return 'next';
    }
  }

  bool get isCoachVisible =>
      this != SimulationStage.acw && this != SimulationStage.next;
}

class StageTracker extends ChangeNotifier {
  SimulationStage _stage = SimulationStage.waitCustomer;
  int _maxStepIndex = 0;

  SimulationStage get stage => _stage;
  int get maxStepIndex => _maxStepIndex;

  void noteStep(int index) {
    if (index > _maxStepIndex) {
      _maxStepIndex = index;
      notifyListeners();
    }
  }

  void update({
    required int traineeTurns,
    required bool hasCustomerMessage,
    required bool identityVerified,
    required bool toolWorkDone,
    required bool customerResolved,
    required bool needsAccount,
    required bool escalateFromStart,
    required bool escalationSaid,
    required bool closingSpielSent,
    required bool acwSubmitted,
    required bool readyToClose,
    required ProblemFamily family,
    bool factsComplete = false,
    bool customerSatisfied = false,
  }) {
    var current = _stage;
    for (var i = 0; i < 8; i++) {
      final next = _computeNext(
        current: current,
        traineeTurns: traineeTurns,
        hasCustomerMessage: hasCustomerMessage,
        identityVerified: identityVerified,
        toolWorkDone: toolWorkDone,
        customerResolved: customerResolved,
        needsAccount: needsAccount,
        escalateFromStart: escalateFromStart,
        escalationSaid: escalationSaid,
        closingSpielSent: closingSpielSent,
        acwSubmitted: acwSubmitted,
        readyToClose: readyToClose,
        family: family,
        factsComplete: factsComplete,
        customerSatisfied: customerSatisfied,
      );
      if (next.index <= current.index &&
          !(current == SimulationStage.escalating &&
              next == SimulationStage.closing)) {
        break;
      }
      current = next;
    }
    if (current != _stage) {
      SimFlowLog.line('stage ${_stage.name} -> ${current.name}');
      _stage = current;
      notifyListeners();
    }
  }

  SimulationStage _computeNext({
    required SimulationStage current,
    required int traineeTurns,
    required bool hasCustomerMessage,
    required bool identityVerified,
    required bool toolWorkDone,
    required bool customerResolved,
    required bool needsAccount,
    required bool escalateFromStart,
    required bool escalationSaid,
    required bool closingSpielSent,
    required bool acwSubmitted,
    required bool readyToClose,
    required ProblemFamily family,
    bool factsComplete = false,
    bool customerSatisfied = false,
  }) {
    switch (current) {
      case SimulationStage.waitCustomer:
        if (hasCustomerMessage) return SimulationStage.opening;
        return current;
      case SimulationStage.opening:
        if (traineeTurns >= 1) return SimulationStage.exploring;
        return current;
      case SimulationStage.exploring:
        if (escalationSaid) return SimulationStage.escalating;
        if (escalateFromStart && traineeTurns >= 2) {
          return SimulationStage.escalating;
        }
        if (customerResolved &&
            (family == ProblemFamily.genericNonAccount ||
                family == ProblemFamily.appointmentPrep) &&
            traineeTurns >= 2) {
          return SimulationStage.closing;
        }
        if (toolWorkDone) return SimulationStage.acting;
        // Stay in exploring until real progress (identity or enough turns).
        // Fact hints only skip collect lines inside the checklist, not the stage.
        if (needsAccount && identityVerified && traineeTurns >= 2) {
          return SimulationStage.acting;
        }
        if (!needsAccount && traineeTurns >= 3) return SimulationStage.acting;
        if (factsComplete && traineeTurns >= 3) return SimulationStage.acting;
        return current;
      case SimulationStage.acting:
        if (escalationSaid) return SimulationStage.escalating;
        if (customerResolved && traineeTurns >= 2) {
          return SimulationStage.closing;
        }
        // Customer accepted outcome after work was done
        if (toolWorkDone && customerSatisfied && traineeTurns >= 2) {
          return SimulationStage.closing;
        }
        if (readyToClose) return SimulationStage.closing;
        return current;
      case SimulationStage.escalating:
        if (closingSpielSent || customerResolved) {
          return SimulationStage.closing;
        }
        return current;
      case SimulationStage.closing:
        if (closingSpielSent) return SimulationStage.acw;
        return current;
      case SimulationStage.acw:
        if (acwSubmitted) return SimulationStage.next;
        return current;
      case SimulationStage.next:
        return current;
    }
  }

  void reset() {
    _stage = SimulationStage.waitCustomer;
    _maxStepIndex = 0;
    notifyListeners();
  }
}

class StagePhrases {
  static bool escalationSaid(String text) {
    final t = text.toLowerCase();
    const phrases = [
      'escalate',
      'escalating',
      'supervisor',
      'senior agent',
      'higher tier',
      'second level',
      'tier 2',
      'tier two',
      'hand this over',
      'transfer you to',
      'endorse this',
      'endorsing',
    ];
    for (final p in phrases) {
      if (t.contains(p)) return true;
    }
    return false;
  }

  static bool closingSpiel(String text) {
    final t = text.toLowerCase();
    return t.contains('thank you for calling') ||
        t.contains('thanks for calling') ||
        t.contains('have a great day') ||
        t.contains('have a good day') ||
        t.contains('is there anything else') ||
        t.contains('glad i could help') ||
        t.contains('has been escalated') ||
        t.contains('reference for follow-up') ||
        t.contains('take care');
  }
}
