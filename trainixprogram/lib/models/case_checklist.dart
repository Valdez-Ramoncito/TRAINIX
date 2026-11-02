import 'package:trainixprogram/models/problem_family.dart';
import 'package:trainixprogram/models/sim_flow_log.dart';
import 'package:trainixprogram/models/simulation_coach.dart';
import 'package:trainixprogram/models/simulation_stage.dart';

/// One next action for the Script Guide (Mini Practice style beats, live customer).
class CaseNextStep {
  final String id;
  final String tip;
  final List<ScriptLine> examples;
  final String amberLabel;
  final int stepNumber;
  final int stepTotal;
  final bool allowEscalateTab;

  const CaseNextStep({
    required this.id,
    required this.tip,
    required this.examples,
    required this.amberLabel,
    required this.stepNumber,
    required this.stepTotal,
    this.allowEscalateTab = false,
  });
}

/// Fact flags derived from the full customer side of the thread (+ problem brief).
class CaseFacts {
  final bool planKnown;
  final bool whenDeniedKnown;
  final bool loginIdHint;
  final bool alreadyTriedReset;
  final bool billPeriodHint;
  final bool claimRefHint;
  final bool amountOrTransferHint;
  final bool symptomsKnown;
  final bool pharmacyOrRefillHint;
  final bool appointmentHint;
  final bool identitySpoken;

  const CaseFacts({
    this.planKnown = false,
    this.whenDeniedKnown = false,
    this.loginIdHint = false,
    this.alreadyTriedReset = false,
    this.billPeriodHint = false,
    this.claimRefHint = false,
    this.amountOrTransferHint = false,
    this.symptomsKnown = false,
    this.pharmacyOrRefillHint = false,
    this.appointmentHint = false,
    this.identitySpoken = false,
  });

  static CaseFacts fromCustomerCorpus(
    String problemText,
    String customerCorpus,
  ) {
    final t = '${problemText} ${customerCorpus}'.toLowerCase();

    final planKnown =
        t.contains('premium') ||
        t.contains('plan') &&
            (t.contains('upgrade') ||
                t.contains('downgrade') ||
                t.contains('plus') ||
                t.contains('basic') ||
                t.contains('promo')) ||
        RegExp(r'upgrade to (the )?[\w\s]+ plan').hasMatch(t);

    final whenDeniedKnown =
        t.contains('yesterday') ||
        t.contains('today') ||
        t.contains('this morning') ||
        t.contains('last night') ||
        t.contains('last week') ||
        t.contains('when i tried') ||
        t.contains('when it was denied') ||
        t.contains('denied yesterday') ||
        RegExp(r'\b\d{1,2}[/-]\d{1,2}\b').hasMatch(t);

    final loginIdHint =
        t.contains('@') ||
        t.contains('email') ||
        t.contains('username') ||
        t.contains('user name');

    final alreadyTriedReset =
        t.contains('tried') ||
        t.contains('already') ||
        t.contains('spam') ||
        t.contains('three times') ||
        t.contains('several times');

    final billPeriodHint =
        t.contains('last month') ||
        t.contains('this month') ||
        t.contains('billing period') ||
        t.contains('statement');

    final claimRefHint =
        t.contains('claim number') ||
        t.contains('reference') ||
        RegExp(r'\bclaim\s*#?\s*\w+').hasMatch(t) ||
        t.contains('date of service') ||
        (t.contains('claim') &&
            (t.contains('last week') ||
                t.contains('submitted') ||
                t.contains('status')));

    final amountOrTransferHint =
        t.contains('amount') ||
        t.contains('pesos') ||
        t.contains('php') ||
        t.contains('sent') ||
        t.contains('transfer');

    final symptomsKnown =
        t.contains('no signal') ||
        t.contains('slow') ||
        t.contains('outage') ||
        t.contains('wifi') ||
        t.contains('wi-fi') ||
        t.contains('data') ||
        t.contains('calls');

    final pharmacyOrRefillHint =
        t.contains('pharmacy') ||
        (t.contains('refill') &&
            (t.contains('delay') ||
                t.contains('delayed') ||
                t.contains('prescription')));

    final appointmentHint =
        t.contains('appointment') ||
        t.contains('schedule') ||
        t.contains('reschedule');

    final identitySpoken =
        t.contains('name on the record') ||
        t.contains('my name is') ||
        t.contains('the name is') ||
        t.contains('full name') && t.contains('is');

    return CaseFacts(
      planKnown: planKnown,
      whenDeniedKnown: whenDeniedKnown,
      loginIdHint: loginIdHint,
      alreadyTriedReset: alreadyTriedReset,
      billPeriodHint: billPeriodHint,
      claimRefHint: claimRefHint,
      amountOrTransferHint: amountOrTransferHint,
      symptomsKnown: symptomsKnown,
      pharmacyOrRefillHint: pharmacyOrRefillHint,
      appointmentHint: appointmentHint,
      identitySpoken: identitySpoken,
    );
  }
}

class CaseChecklist {
  static bool isCustomerSatisfied(String customerCorpus) {
    final t = customerCorpus.toLowerCase();
    if (t.contains("that's all") || t.contains('thats all')) return true;
    if (t.contains('that is all')) return true;
    if (t.contains('all i needed')) return true;
    if (t.contains("that's all i needed")) return true;
    if (t.contains('glad to know')) return true;
    if (t.contains('please go ahead and file')) return true;
    if (t.contains('thank you for filing')) return true;
    if (t.contains('nothing else')) return true;
    if (t.contains('no further questions')) return true;
    if (t.contains('that helps')) return true;
    if (t.contains("i'm good") || t.contains('im good')) return true;
    return false;
  }

  static bool traineeSaidExplain(String t) {
    final s = t.toLowerCase();
    return s.contains('because') ||
        s.contains('reason') ||
        s.contains('blocked') ||
        s.contains('eligib') ||
        s.contains('in plain words') ||
        s.contains('what i found') ||
        s.contains('the system shows');
  }

  static bool traineeSaidRequest(String t) {
    final s = t.toLowerCase();
    return s.contains('file') ||
        s.contains('request') ||
        s.contains('ticket') ||
        s.contains('review') ||
        s.contains('callback') ||
        s.contains('submit');
  }

  static bool traineeAcknowledged(String t) {
    final s = t.toLowerCase();
    return s.contains('sorry') ||
        s.contains('understand') ||
        s.contains('thank you for') ||
        s.contains('i can help') ||
        s.contains('i will help');
  }

  /// Single next step for Script Guide. One tip, matched examples, one amber line.
  static CaseNextStep resolve({
    required ProblemFamily family,
    required SimulationStage stage,
    required String problemText,
    required String customerCorpus,
    required String lastTraineeText,
    required int traineeTurns,
    required bool hasCustomerMessage,
    required bool hasTraineeMessage,
    required bool needsAccount,
    required bool identityVerified,
    required bool toolWorkDone,
    required bool escalateFromStart,
    required bool readyToClose,
    required Duration elapsed,
    String accountStatusLabel = '',
    String accountOwnerName = '',
    String accountIssueLine = '',
    Map<String, String> accountDetails = const {},
  }) {
    final facts = CaseFacts.fromCustomerCorpus(problemText, customerCorpus);
    final lastTrainee = lastTraineeText;
    SimFlowLog.block('checklist.resolve.in', {
      'family': family.name,
      'stage': stage.name,
      'traineeTurns': traineeTurns,
      'identityVerified': identityVerified,
      'toolWorkDone': toolWorkDone,
      'needsAccount': needsAccount,
      'accountStatus': accountStatusLabel,
      'accountOwner': accountOwnerName,
      'facts.claimRef': facts.claimRefHint,
      'facts.identitySpoken': facts.identitySpoken,
      'facts.planKnown': facts.planKnown,
      'facts.whenDenied': facts.whenDeniedKnown,
      'lastTrainee': lastTraineeText,
      'customerCorpus': customerCorpus,
    });
    final escalateAllowed = _escalateAllowed(
      family: family,
      stage: stage,
      traineeTurns: traineeTurns,
      toolWorkDone: toolWorkDone,
      escalateFromStart: escalateFromStart,
      lastTraineeText: lastTraineeText,
      elapsed: elapsed,
    );

    if (stage == SimulationStage.waitCustomer || !hasCustomerMessage) {
      return CaseNextStep(
        id: 'wait',
        tip: 'Wait for the customer to speak.',
        examples: const [],
        amberLabel: 'Wait for the customer opening.',
        stepNumber: 0,
        stepTotal: 6,
      );
    }

    if (stage == SimulationStage.opening || !hasTraineeMessage) {
      final agent = SimulationCoach.agentName;
      final company = SimulationCoach.companyName;
      return CaseNextStep(
        id: 'open',
        tip: _openTip(family),
        examples: [
          ScriptLine(
            category: 'opening',
            choiceNumber: 1,
            title: 'Opening spiel',
            text:
                'Thank you for contacting $company. This is $agent. I understand the issue you described, and I will help you with this.',
          ),
          ScriptLine(
            category: 'opening',
            choiceNumber: 2,
            title: 'Opening + empathy',
            text:
                'Thank you for contacting $company. This is $agent. I am sorry you are dealing with this, and I am here to help.',
          ),
        ],
        amberLabel:
            'Step 1: Opening spiel (name + company) and acknowledge the issue.',
        stepNumber: 1,
        stepTotal: 6,
      );
    }

    if (stage == SimulationStage.escalating ||
        (escalateFromStart && StagePhrases.escalationSaid(lastTrainee))) {
      return CaseNextStep(
        id: 'escalate',
        tip:
            'Collect handoff details: what was tried, account detail if any, impact, and what you told them.',
        examples: [
          const ScriptLine(
            category: 'escalate',
            choiceNumber: 1,
            title: 'Handoff',
            text:
                'I am preparing a full summary for the specialist team, including what we tried and your account details.',
          ),
        ],
        amberLabel: 'Step: Complete escalation handoff details.',
        stepNumber: 6,
        stepTotal: 6,
        allowEscalateTab: true,
      );
    }

    if (stage == SimulationStage.closing || readyToClose) {
      final agent = SimulationCoach.agentName;
      final company = SimulationCoach.companyName;
      return CaseNextStep(
        id: 'close',
        tip:
            'Closing spiel: brief recap, ask if anything else is needed, thank them, and end politely (use your name as trained).',
        examples: [
          ScriptLine(
            category: 'closing',
            choiceNumber: 1,
            title: 'Closing spiel',
            text:
                'Is there anything else I can help you with today? Thank you for contacting $company. This is $agent, and I am glad I could help. Have a great day.',
          ),
          ScriptLine(
            category: 'closing',
            choiceNumber: 2,
            title: 'Short close',
            text:
                'I am glad that is clear. Thank you for contacting $company. Have a good day.',
          ),
        ],
        amberLabel:
            'Step: Deliver closing spiel (recap, anything else, thanks).',
        stepNumber: 6,
        stepTotal: 6,
        allowEscalateTab: escalateAllowed,
      );
    }

    // Family-specific checklist while exploring / acting
    // After work is done and customer accepts, prefer close checklist
    if (toolWorkDone && isCustomerSatisfied(customerCorpus)) {
      final agent = SimulationCoach.agentName;
      final company = SimulationCoach.companyName;
      final closeStep = CaseNextStep(
        id: 'close_after_accept',
        tip:
            'Customer accepted the outcome. Deliver your closing spiel: short recap, anything else, thanks.',
        examples: [
          ScriptLine(
            category: 'closing',
            choiceNumber: 1,
            title: 'Closing spiel',
            text:
                'Is there anything else I can help you with today? Thank you for contacting $company. Have a great day.',
          ),
          ScriptLine(
            category: 'closing',
            choiceNumber: 2,
            title: 'Closing with name',
            text:
                'I am glad I could help with your claim status. Thank you for contacting $company. This is $agent. Have a good day.',
          ),
        ],
        amberLabel: 'Step: Closing spiel, then end the interaction.',
        stepNumber: 5,
        stepTotal: 5,
        allowEscalateTab: escalateAllowed,
      );
      SimFlowLog.block('checklist.resolve.out', {
        'stepId': closeStep.id,
        'stepNum': '${closeStep.stepNumber}/${closeStep.stepTotal}',
        'tip': closeStep.tip,
        'amber': closeStep.amberLabel,
        'examples': closeStep.examples.map((e) => e.text).join(' | '),
        'allowEscalate': closeStep.allowEscalateTab,
      });
      return closeStep;
    }

    final step = _familyNext(
      family: family,
      facts: facts,
      stage: stage,
      escalateAllowed: escalateAllowed,
      lastTraineeText: lastTraineeText,
      traineeTurns: traineeTurns,
      needsAccount: needsAccount,
      identityVerified: identityVerified,
      toolWorkDone: toolWorkDone,
      accountStatusLabel: accountStatusLabel,
      accountOwnerName: accountOwnerName,
      accountIssueLine: accountIssueLine,
      accountDetails: accountDetails,
    );
    SimFlowLog.block('checklist.resolve.out', {
      'stepId': step.id,
      'stepNum': '${step.stepNumber}/${step.stepTotal}',
      'tip': step.tip,
      'amber': step.amberLabel,
      'examples': step.examples.map((e) => e.text).join(' | '),
      'allowEscalate': step.allowEscalateTab,
    });
    return step;
  }

  static bool _escalateAllowed({
    required ProblemFamily family,
    required SimulationStage stage,
    required int traineeTurns,
    required bool toolWorkDone,
    required bool escalateFromStart,
    required String lastTraineeText,
    required Duration elapsed,
  }) {
    if (stage == SimulationStage.escalating) return true;
    if (family == ProblemFamily.trueEscalate && traineeTurns >= 2) {
      return true;
    }
    if (StagePhrases.escalationSaid(lastTraineeText)) return true;
    if (stage == SimulationStage.acting &&
        traineeTurns >= 5 &&
        !toolWorkDone &&
        elapsed >= const Duration(minutes: 8)) {
      return true;
    }
    return false;
  }

  static String _openTip(ProblemFamily family) {
    switch (family) {
      case ProblemFamily.planEligibility:
        return 'Open with your name, acknowledge the denied plan upgrade, and do not treat this as a network outage.';
      case ProblemFamily.loginAccess:
        return 'Open with your name, acknowledge the sign-in issue, and do not ask for their full password.';
      case ProblemFamily.billingSurprise:
        return 'Open with your name, acknowledge the unexpected bill or charge.';
      case ProblemFamily.claimStatus:
        return 'Open with your name, acknowledge the claim status concern.';
      case ProblemFamily.prescriptionRefill:
        return 'Open with your name, acknowledge the refill delay. Do not prescribe or change medication.';
      case ProblemFamily.networkConnectivity:
        return 'Open with your name, acknowledge the connectivity issue.';
      case ProblemFamily.fundTransfer:
        return 'Open with your name, acknowledge the transfer concern.';
      case ProblemFamily.appointmentPrep:
        return 'Open with your name, acknowledge the appointment question.';
      case ProblemFamily.trueEscalate:
        return 'Open with your name, acknowledge the issue, and prepare to gather handoff details.';
      case ProblemFamily.genericAccount:
        return 'Open with your name, acknowledge the specific issue.';
      case ProblemFamily.genericNonAccount:
        return 'Open with your name, acknowledge the specific issue.';
    }
  }

  static CaseNextStep _familyNext({
    required ProblemFamily family,
    required CaseFacts facts,
    required SimulationStage stage,
    required bool escalateAllowed,
    required String lastTraineeText,
    required int traineeTurns,
    required bool needsAccount,
    required bool identityVerified,
    required bool toolWorkDone,
    String accountStatusLabel = '',
    String accountOwnerName = '',
    String accountIssueLine = '',
    Map<String, String> accountDetails = const {},
  }) {
    switch (family) {
      case ProblemFamily.planEligibility:
        return _planEligibility(
          facts: facts,
          escalateAllowed: escalateAllowed,
          lastTraineeText: lastTraineeText,
          traineeTurns: traineeTurns,
          needsAccount: needsAccount,
          identityVerified: identityVerified,
          toolWorkDone: toolWorkDone,
        );
      case ProblemFamily.loginAccess:
        return _loginAccess(
          facts: facts,
          escalateAllowed: escalateAllowed,
          traineeTurns: traineeTurns,
          needsAccount: needsAccount,
          identityVerified: identityVerified,
          toolWorkDone: toolWorkDone,
        );
      case ProblemFamily.billingSurprise:
        return _billing(
          facts: facts,
          escalateAllowed: escalateAllowed,
          needsAccount: needsAccount,
          identityVerified: identityVerified,
          toolWorkDone: toolWorkDone,
        );
      case ProblemFamily.claimStatus:
        return _claim(
          facts: facts,
          escalateAllowed: escalateAllowed,
          needsAccount: needsAccount,
          identityVerified: identityVerified,
          toolWorkDone: toolWorkDone,
          accountStatusLabel: accountStatusLabel,
          accountOwnerName: accountOwnerName,
          accountIssueLine: accountIssueLine,
          accountDetails: accountDetails,
        );
      case ProblemFamily.prescriptionRefill:
        return _refill(
          facts: facts,
          escalateAllowed: escalateAllowed,
          toolWorkDone: toolWorkDone,
          lastTraineeText: lastTraineeText,
        );
      case ProblemFamily.networkConnectivity:
        return _network(
          facts: facts,
          escalateAllowed: escalateAllowed,
          toolWorkDone: toolWorkDone,
        );
      case ProblemFamily.fundTransfer:
        return _transfer(
          facts: facts,
          escalateAllowed: escalateAllowed,
          needsAccount: needsAccount,
          identityVerified: identityVerified,
          toolWorkDone: toolWorkDone,
        );
      case ProblemFamily.appointmentPrep:
        return _appointment(
          facts: facts,
          escalateAllowed: escalateAllowed,
          traineeTurns: traineeTurns,
        );
      case ProblemFamily.trueEscalate:
        return CaseNextStep(
          id: 'escalate_path',
          tip:
              'This case needs specialist handling. Gather details, then complete the handoff.',
          examples: [
            const ScriptLine(
              category: 'escalate',
              choiceNumber: 1,
              title: 'Handoff',
              text:
                  'I will escalate this with a full summary so the specialist team can continue.',
            ),
          ],
          amberLabel: 'Step: Escalate with a complete summary.',
          stepNumber: 3,
          stepTotal: 4,
          allowEscalateTab: true,
        );
      case ProblemFamily.genericAccount:
        return _genericAccount(
          escalateAllowed: escalateAllowed,
          identityVerified: identityVerified,
          toolWorkDone: toolWorkDone,
        );
      case ProblemFamily.genericNonAccount:
        return _genericNonAccount(
          escalateAllowed: escalateAllowed,
          traineeTurns: traineeTurns,
        );
    }
  }

  static CaseNextStep _planEligibility({
    required CaseFacts facts,
    required bool escalateAllowed,
    required String lastTraineeText,
    required int traineeTurns,
    required bool needsAccount,
    required bool identityVerified,
    required bool toolWorkDone,
  }) {
    final collectDone = facts.planKnown && facts.whenDeniedKnown;
    final trainee = lastTraineeText;

    if (!collectDone) {
      return CaseNextStep(
        id: 'plan_collect',
        tip:
            'Confirm which plan they wanted and when it was denied. Do not treat this as a network outage.',
        examples: [
          const ScriptLine(
            category: 'clarify',
            choiceNumber: 1,
            title: 'Confirm plan',
            text:
                'Just to confirm, which plan did you try to move to, and when did the app deny the change?',
          ),
        ],
        amberLabel: 'Step 2 of 6: Confirm plan wanted and when it was denied.',
        stepNumber: 2,
        stepTotal: 6,
        allowEscalateTab: escalateAllowed,
      );
    }

    // Facts already in thread (screenshot case): never re-ask plan/when
    if (needsAccount && !identityVerified) {
      return CaseNextStep(
        id: 'plan_identity',
        tip:
            'Plan and timing are already on the record. Look up the account and confirm one detail before sharing account-level reasons.',
        examples: [
          const ScriptLine(
            category: 'guide',
            choiceNumber: 1,
            title: 'Account check',
            text:
                'I have the Premium plan request and when it was denied. I will pull up your account and confirm one detail, then explain what blocked the upgrade.',
          ),
          const ScriptLine(
            category: 'verify',
            choiceNumber: 1,
            title: 'Verify',
            text:
                'For security, can you confirm the full name or mobile number on the account?',
          ),
        ],
        amberLabel: 'Step 3 of 6: Look up the account and confirm one detail.',
        stepNumber: 3,
        stepTotal: 6,
        allowEscalateTab: escalateAllowed,
      );
    }

    if (!toolWorkDone && !traineeSaidExplain(trainee) && traineeTurns < 4) {
      return CaseNextStep(
        id: 'plan_explain',
        tip:
            'Explain why the upgrade was denied in plain words, then offer options or a review request. Do not claim you already fixed it.',
        examples: [
          const ScriptLine(
            category: 'explain',
            choiceNumber: 1,
            title: 'Explain block',
            text:
                'Here is what blocked the upgrade in plain words, and the options we can take next.',
          ),
          const ScriptLine(
            category: 'guide',
            choiceNumber: 1,
            title: 'Offer review',
            text:
                'I can file an upgrade review for you. Would you like me to submit that request?',
          ),
        ],
        amberLabel:
            'Step 4 of 6: Explain the denial reason and available options.',
        stepNumber: 4,
        stepTotal: 6,
        allowEscalateTab: escalateAllowed,
      );
    }

    if (!toolWorkDone) {
      return CaseNextStep(
        id: 'plan_request',
        tip:
            'File a service request or upgrade review, or clearly state the option the customer chooses. Frontline cannot force an instant plan change.',
        examples: [
          const ScriptLine(
            category: 'guide',
            choiceNumber: 1,
            title: 'File request',
            text:
                'I will file an upgrade review request now and tell you what happens next and the usual timeline.',
          ),
        ],
        amberLabel:
            'Step 5 of 6: File review request or confirm the chosen option.',
        stepNumber: 5,
        stepTotal: 6,
        allowEscalateTab: escalateAllowed,
      );
    }

    return CaseNextStep(
      id: 'plan_confirm',
      tip:
          'Confirm what was filed and the timeline, then check that the customer is satisfied before closing.',
      examples: [
        const ScriptLine(
          category: 'confirm',
          choiceNumber: 1,
          title: 'Confirm',
          text:
              'The review request is filed. You should see an update within the stated timeline. Does that work for you?',
        ),
      ],
      amberLabel: 'Step 6 of 6: Confirm outcome and prepare to close.',
      stepNumber: 6,
      stepTotal: 6,
      allowEscalateTab: escalateAllowed,
    );
  }

  static CaseNextStep _loginAccess({
    required CaseFacts facts,
    required bool escalateAllowed,
    required int traineeTurns,
    required bool needsAccount,
    required bool identityVerified,
    required bool toolWorkDone,
  }) {
    if (!facts.loginIdHint) {
      return CaseNextStep(
        id: 'login_id',
        tip:
            'Confirm the exact email or username used to sign in. Do not ask for their full password.',
        examples: [
          const ScriptLine(
            category: 'clarify',
            choiceNumber: 1,
            title: 'Login id',
            text:
                'Please confirm the exact email or username on the account so we reset the right login.',
          ),
        ],
        amberLabel: 'Step 2 of 5: Confirm login email or username.',
        stepNumber: 2,
        stepTotal: 5,
        allowEscalateTab: escalateAllowed,
      );
    }
    if (facts.alreadyTriedReset && traineeTurns <= 2) {
      return CaseNextStep(
        id: 'login_ack_tried',
        tip:
            'They already tried the reset path. Acknowledge that, then move to account verify or a secure review. Do not ask what they tried again.',
        examples: [
          const ScriptLine(
            category: 'guide',
            choiceNumber: 1,
            title: 'Next path',
            text:
                'Thank you for trying those steps. Since the reset email is still not arriving, I will take the next secure path with you.',
          ),
        ],
        amberLabel: 'Step 3 of 5: Move past retry; verify or review.',
        stepNumber: 3,
        stepTotal: 5,
        allowEscalateTab: escalateAllowed,
      );
    }
    if (needsAccount && !identityVerified) {
      return CaseNextStep(
        id: 'login_identity',
        tip:
            'Verify identity on file, then guide only the official reset path or open a secure review.',
        examples: [
          const ScriptLine(
            category: 'verify',
            choiceNumber: 1,
            title: 'Verify',
            text:
                'For security, can you confirm the full name or mobile number on the account?',
          ),
        ],
        amberLabel: 'Step 3 of 5: Confirm identity on file.',
        stepNumber: 3,
        stepTotal: 5,
        allowEscalateTab: escalateAllowed,
      );
    }
    if (!toolWorkDone) {
      return CaseNextStep(
        id: 'login_act',
        tip:
            'Guide the official reset one step at a time, or file a secure access review if email still fails.',
        examples: [
          const ScriptLine(
            category: 'guide',
            choiceNumber: 1,
            title: 'Reset or review',
            text:
                'Please use the official forgot-password link once more and check spam. If nothing arrives, I will open a secure access review.',
          ),
        ],
        amberLabel: 'Step 4 of 5: Official reset or secure review.',
        stepNumber: 4,
        stepTotal: 5,
        allowEscalateTab: escalateAllowed,
      );
    }
    return CaseNextStep(
      id: 'login_confirm',
      tip:
          'Confirm next steps and whether they can sign in or must wait on the review.',
      examples: [
        const ScriptLine(
          category: 'confirm',
          choiceNumber: 1,
          title: 'Confirm',
          text:
              'You should either receive the reset email shortly or hear back from the secure review. Is there anything else on this login issue?',
        ),
      ],
      amberLabel: 'Step 5 of 5: Confirm and close when ready.',
      stepNumber: 5,
      stepTotal: 5,
      allowEscalateTab: escalateAllowed,
    );
  }

  static CaseNextStep _billing({
    required CaseFacts facts,
    required bool escalateAllowed,
    required bool needsAccount,
    required bool identityVerified,
    required bool toolWorkDone,
  }) {
    if (!facts.billPeriodHint) {
      return CaseNextStep(
        id: 'bill_period',
        tip:
            'Confirm which billing period looks wrong. This is a billing review, not a network outage.',
        examples: [
          const ScriptLine(
            category: 'clarify',
            choiceNumber: 1,
            title: 'Period',
            text: 'Which billing period looks higher than you expected?',
          ),
        ],
        amberLabel: 'Step 2 of 5: Confirm billing period.',
        stepNumber: 2,
        stepTotal: 5,
        allowEscalateTab: escalateAllowed,
      );
    }
    if (needsAccount && !identityVerified) {
      return CaseNextStep(
        id: 'bill_identity',
        tip: 'Verify identity, then review unusual charges in plain words.',
        examples: [
          const ScriptLine(
            category: 'verify',
            choiceNumber: 1,
            title: 'Verify',
            text:
                'For security, can you confirm the full name on the account before we review the charges?',
          ),
        ],
        amberLabel: 'Step 3 of 5: Confirm identity on file.',
        stepNumber: 3,
        stepTotal: 5,
        allowEscalateTab: escalateAllowed,
      );
    }
    if (!toolWorkDone) {
      return CaseNextStep(
        id: 'bill_explain',
        tip:
            'List unusual charges simply and file a billing review if a correction may be needed.',
        examples: [
          const ScriptLine(
            category: 'explain',
            choiceNumber: 1,
            title: 'Explain',
            text:
                'I will list the unusual items in plain words compared with a typical month, then we can file a review if needed.',
          ),
        ],
        amberLabel: 'Step 4 of 5: Explain charges or file review.',
        stepNumber: 4,
        stepTotal: 5,
        allowEscalateTab: escalateAllowed,
      );
    }
    return CaseNextStep(
      id: 'bill_confirm',
      tip: 'Confirm what was filed and check the customer is satisfied.',
      examples: [
        const ScriptLine(
          category: 'confirm',
          choiceNumber: 1,
          title: 'Confirm',
          text:
              'The billing review is filed. You will see the outcome in the usual timeline. Does that help?',
        ),
      ],
      amberLabel: 'Step 5 of 5: Confirm and close when ready.',
      stepNumber: 5,
      stepTotal: 5,
      allowEscalateTab: escalateAllowed,
    );
  }

  static CaseNextStep _claim({
    required CaseFacts facts,
    required bool escalateAllowed,
    required bool needsAccount,
    required bool identityVerified,
    required bool toolWorkDone,
    String accountStatusLabel = '',
    String accountOwnerName = '',
    String accountIssueLine = '',
    Map<String, String> accountDetails = const {},
  }) {
    final status = accountStatusLabel.trim().isNotEmpty
        ? accountStatusLabel.trim()
        : (accountDetails['Coverage'] ??
              accountDetails['Status'] ??
              accountDetails['Claim Status'] ??
              '');
    final issue = accountIssueLine.trim().isNotEmpty
        ? accountIssueLine.trim()
        : 'the submitted claim';

    if (!facts.claimRefHint) {
      return CaseNextStep(
        id: 'claim_ref',
        tip: 'Ask for claim number or date of service before status details.',
        examples: [
          const ScriptLine(
            category: 'clarify',
            choiceNumber: 1,
            title: 'Reference',
            text:
                'Do you have the claim number or the date of service for this claim?',
          ),
        ],
        amberLabel: 'Step 2 of 5: Collect claim reference.',
        stepNumber: 2,
        stepTotal: 5,
        allowEscalateTab: escalateAllowed,
      );
    }

    if (needsAccount && !identityVerified) {
      if (facts.identitySpoken) {
        return CaseNextStep(
          id: 'claim_identity_tool',
          tip:
              'The customer already confirmed their name in chat. Open Account Lookup, select the member account, then submit Confirm identity on file.',
          examples: [
            ScriptLine(
              category: 'guide',
              choiceNumber: 1,
              title: 'Tool next',
              text: accountOwnerName.isNotEmpty
                  ? 'Thank you, $accountOwnerName. I am verifying that on the member record now, then I will share the claim status.'
                  : 'Thank you for confirming your name. I am verifying that on the member record now, then I will share the claim status.',
            ),
          ],
          amberLabel:
              'Step 3 of 5: In Account Lookup, submit Confirm identity on file.',
          stepNumber: 3,
          stepTotal: 5,
          allowEscalateTab: escalateAllowed,
        );
      }
      return CaseNextStep(
        id: 'claim_identity',
        tip: 'Confirm identity before sharing protected claim details.',
        examples: [
          const ScriptLine(
            category: 'verify',
            choiceNumber: 1,
            title: 'Verify',
            text:
                'For privacy, can you confirm the full name on the member record?',
          ),
        ],
        amberLabel: 'Step 3 of 5: Confirm identity.',
        stepNumber: 3,
        stepTotal: 5,
        allowEscalateTab: escalateAllowed,
      );
    }

    if (!toolWorkDone) {
      if (status.isNotEmpty) {
        final statusLower = status.toLowerCase();
        final pending = statusLower.contains('pending');
        return CaseNextStep(
          id: 'claim_status_concrete',
          tip: pending
              ? 'The account shows "$status". Tell the customer that in plain words: it is still under review, not approved or denied yet, and whether any documents are missing.'
              : 'The account shows "$status". Explain that status in plain words and what happens next. Do not promise payment.',
          examples: [
            ScriptLine(
              category: 'explain',
              choiceNumber: 1,
              title: 'Concrete status',
              text: pending
                  ? 'Your claim status is "$status". That means it is still being reviewed and is not approved or denied yet. I do not see an extra document request on file from here. Would you like me to file a status follow-up?'
                  : 'Your claim status on file is "$status" regarding $issue. Here is what that means in plain words and what you can expect next.',
            ),
            const ScriptLine(
              category: 'guide',
              choiceNumber: 1,
              title: 'Offer follow-up',
              text:
                  'If you want a formal follow-up, I can file a claim status review request so the team can re-check the file.',
            ),
          ],
          amberLabel:
              'Step 4 of 5: State the on-file status in plain words (use Account Lookup).',
          stepNumber: 4,
          stepTotal: 5,
          allowEscalateTab: escalateAllowed,
        );
      }
      return CaseNextStep(
        id: 'claim_status',
        tip:
            'Open Account Lookup, read Coverage or Status, then explain that exact status in plain words. Do not give a vague answer.',
        examples: [
          const ScriptLine(
            category: 'guide',
            choiceNumber: 1,
            title: 'Use lookup',
            text:
                'I am checking the claim record now and will tell you the exact status shown on file.',
          ),
        ],
        amberLabel:
            'Step 4 of 5: Read claim status in Account Lookup, then explain it.',
        stepNumber: 4,
        stepTotal: 5,
        allowEscalateTab: escalateAllowed,
      );
    }

    return CaseNextStep(
      id: 'claim_confirm',
      tip: 'Confirm next steps and close when the customer is ready.',
      examples: [
        ScriptLine(
          category: 'confirm',
          choiceNumber: 1,
          title: 'Confirm',
          text: status.isNotEmpty
              ? 'To recap, your claim shows "$status". I filed the follow-up where needed. Is there anything else on this claim?'
              : 'That is the current status and what happens next. Is there anything else on this claim?',
        ),
      ],
      amberLabel: 'Step 5 of 5: Confirm and close when ready.',
      stepNumber: 5,
      stepTotal: 5,
      allowEscalateTab: escalateAllowed,
    );
  }

  static CaseNextStep _refill({
    required CaseFacts facts,
    required bool escalateAllowed,
    required bool toolWorkDone,
    String lastTraineeText = '',
  }) {
    final said = lastTraineeText.toLowerCase();
    final gaveTiming =
        said.contains('hour') ||
        said.contains('day') ||
        said.contains('timeline') ||
        said.contains('usually') ||
        said.contains('typically') ||
        said.contains('24') ||
        said.contains('48') ||
        said.contains('business day');
    final offeredFollowUp =
        said.contains('follow') ||
        said.contains('request') ||
        said.contains('file') ||
        said.contains('ticket');

    if (!facts.pharmacyOrRefillHint) {
      return CaseNextStep(
        id: 'refill_info',
        tip: 'Confirm pharmacy name and when the refill was requested.',
        examples: [
          const ScriptLine(
            category: 'clarify',
            choiceNumber: 1,
            title: 'Pharmacy',
            text:
                'Which pharmacy is handling the refill, and when was the request submitted?',
          ),
        ],
        amberLabel: 'Step 2 of 5: Confirm pharmacy and request time.',
        stepNumber: 2,
        stepTotal: 5,
        allowEscalateTab: escalateAllowed,
      );
    }

    if (!gaveTiming && !toolWorkDone) {
      return CaseNextStep(
        id: 'refill_timing',
        tip:
            'Give a clear typical timeline in plain words, then the next step the customer should take. Do not prescribe or change medication.',
        examples: [
          const ScriptLine(
            category: 'explain',
            choiceNumber: 1,
            title: 'Timing',
            text:
                'Typical refill processing is about 24 to 48 hours after the pharmacy receives the request. Please check with the pharmacy first for any hold or stock issue. I cannot prescribe or change the medication itself.',
          ),
          const ScriptLine(
            category: 'explain',
            choiceNumber: 2,
            title: 'Next step',
            text:
                'Please call or visit the pharmacy and ask if the refill is queued, on hold, or waiting on stock. Then tell me what they say so we can decide the next step.',
          ),
        ],
        amberLabel: 'Step 3 of 5: Explain typical timing and the next step.',
        stepNumber: 3,
        stepTotal: 5,
        allowEscalateTab: escalateAllowed,
      );
    }

    if (!toolWorkDone && !offeredFollowUp) {
      return CaseNextStep(
        id: 'refill_followup',
        tip:
            'Offer to file a refill follow-up request if the pharmacy still has no update after the usual window.',
        examples: [
          const ScriptLine(
            category: 'guide',
            choiceNumber: 1,
            title: 'Follow-up',
            text:
                'If the pharmacy still has no update after the usual window, I can file a refill follow-up request so the team can check the order status.',
          ),
        ],
        amberLabel: 'Step 4 of 5: Offer follow-up request if still delayed.',
        stepNumber: 4,
        stepTotal: 5,
        allowEscalateTab: escalateAllowed,
      );
    }

    if (!toolWorkDone && offeredFollowUp) {
      return CaseNextStep(
        id: 'refill_file',
        tip:
            'Use Account Lookup or the service request action to file the follow-up, then tell the customer what happens next.',
        examples: [
          const ScriptLine(
            category: 'guide',
            choiceNumber: 1,
            title: 'File it',
            text:
                'I will file the refill follow-up now and share the usual response window once it is submitted.',
          ),
        ],
        amberLabel: 'Step 4 of 5: File the follow-up in tools, then confirm.',
        stepNumber: 4,
        stepTotal: 5,
        allowEscalateTab: escalateAllowed,
      );
    }

    return CaseNextStep(
      id: 'refill_confirm',
      tip: 'Confirm the plan and close when the customer is ready.',
      examples: [
        const ScriptLine(
          category: 'confirm',
          choiceNumber: 1,
          title: 'Confirm',
          text:
              'To recap: check with the pharmacy on timing, and the follow-up is filed if we submitted one. Is there anything else on the refill?',
        ),
      ],
      amberLabel: 'Step 5 of 5: Confirm and close when ready.',
      stepNumber: 5,
      stepTotal: 5,
      allowEscalateTab: escalateAllowed,
    );
  }

  static CaseNextStep _network({
    required CaseFacts facts,
    required bool escalateAllowed,
    required bool toolWorkDone,
  }) {
    if (!facts.symptomsKnown) {
      return CaseNextStep(
        id: 'net_symptoms',
        tip:
            'Confirm service type and symptoms (calls, data, SMS, outage). Not a plan-billing issue unless they say so.',
        examples: [
          const ScriptLine(
            category: 'clarify',
            choiceNumber: 1,
            title: 'Symptoms',
            text:
                'Are you having trouble with calls, mobile data, SMS, or a full outage, and when did it start?',
          ),
        ],
        amberLabel: 'Step 2 of 4: Confirm symptoms and timing.',
        stepNumber: 2,
        stepTotal: 4,
        allowEscalateTab: escalateAllowed,
      );
    }
    if (!toolWorkDone) {
      return CaseNextStep(
        id: 'net_guide',
        tip:
            'Guide one check at a time and confirm the result. File a network review if still down.',
        examples: [
          const ScriptLine(
            category: 'guide',
            choiceNumber: 1,
            title: 'One check',
            text:
                'Please try this one check, then tell me the result before we move on.',
          ),
        ],
        amberLabel: 'Step 3 of 4: Guided check or network review.',
        stepNumber: 3,
        stepTotal: 4,
        allowEscalateTab: escalateAllowed,
      );
    }
    return CaseNextStep(
      id: 'net_confirm',
      tip: 'Confirm service is acceptable or set expectation on the review.',
      examples: [
        const ScriptLine(
          category: 'confirm',
          choiceNumber: 1,
          title: 'Confirm',
          text:
              'Please confirm whether service is usable now, or if we should keep the review in place.',
        ),
      ],
      amberLabel: 'Step 4 of 4: Confirm and close when ready.',
      stepNumber: 4,
      stepTotal: 4,
      allowEscalateTab: escalateAllowed,
    );
  }

  static CaseNextStep _transfer({
    required CaseFacts facts,
    required bool escalateAllowed,
    required bool needsAccount,
    required bool identityVerified,
    required bool toolWorkDone,
  }) {
    if (!facts.amountOrTransferHint) {
      return CaseNextStep(
        id: 'tx_details',
        tip: 'Confirm amount, send time, and where it was sent.',
        examples: [
          const ScriptLine(
            category: 'clarify',
            choiceNumber: 1,
            title: 'Details',
            text: 'What amount was sent, about when, and to which destination?',
          ),
        ],
        amberLabel: 'Step 2 of 5: Confirm transfer details.',
        stepNumber: 2,
        stepTotal: 5,
        allowEscalateTab: escalateAllowed,
      );
    }
    if (needsAccount && !identityVerified) {
      return CaseNextStep(
        id: 'tx_identity',
        tip: 'Verify identity before sharing transfer status.',
        examples: [
          const ScriptLine(
            category: 'verify',
            choiceNumber: 1,
            title: 'Verify',
            text: 'For security, can you confirm the full name on the account?',
          ),
        ],
        amberLabel: 'Step 3 of 5: Confirm identity.',
        stepNumber: 3,
        stepTotal: 5,
        allowEscalateTab: escalateAllowed,
      );
    }
    if (!toolWorkDone) {
      return CaseNextStep(
        id: 'tx_explain',
        tip:
            'Explain normal timing and what the record shows. File a transfer review if past the promised window.',
        examples: [
          const ScriptLine(
            category: 'explain',
            choiceNumber: 1,
            title: 'Status',
            text:
                'Here is what the record shows and the usual timing. If it is past that window, I can file a review.',
          ),
        ],
        amberLabel: 'Step 4 of 5: Explain status or file review.',
        stepNumber: 4,
        stepTotal: 5,
        allowEscalateTab: escalateAllowed,
      );
    }
    return CaseNextStep(
      id: 'tx_confirm',
      tip: 'Confirm next steps and close when ready.',
      examples: [
        const ScriptLine(
          category: 'confirm',
          choiceNumber: 1,
          title: 'Confirm',
          text:
              'That is the status and what happens next. Is there anything else on this transfer?',
        ),
      ],
      amberLabel: 'Step 5 of 5: Confirm and close when ready.',
      stepNumber: 5,
      stepTotal: 5,
      allowEscalateTab: escalateAllowed,
    );
  }

  static CaseNextStep _appointment({
    required CaseFacts facts,
    required bool escalateAllowed,
    required int traineeTurns,
  }) {
    if (!facts.appointmentHint && traineeTurns < 2) {
      return CaseNextStep(
        id: 'appt_confirm',
        tip: 'Confirm the appointment details before giving prep steps.',
        examples: [
          const ScriptLine(
            category: 'clarify',
            choiceNumber: 1,
            title: 'Confirm',
            text:
                'Just to confirm, which appointment date and service is this about?',
          ),
        ],
        amberLabel: 'Step 2 of 3: Confirm appointment details.',
        stepNumber: 2,
        stepTotal: 3,
        allowEscalateTab: escalateAllowed,
      );
    }
    return CaseNextStep(
      id: 'appt_prep',
      tip:
          'Share preparation steps and what to expect. Do not invent clinical advice.',
      examples: [
        const ScriptLine(
          category: 'guide',
          choiceNumber: 1,
          title: 'Prep',
          text:
              'Here are the standard preparation steps and what you should expect next.',
        ),
      ],
      amberLabel: 'Step 3 of 3: Give prep steps and confirm understanding.',
      stepNumber: 3,
      stepTotal: 3,
      allowEscalateTab: escalateAllowed,
    );
  }

  static CaseNextStep _genericAccount({
    required bool escalateAllowed,
    required bool identityVerified,
    required bool toolWorkDone,
  }) {
    if (!identityVerified) {
      return CaseNextStep(
        id: 'gen_identity',
        tip:
            'Acknowledge the issue, then verify identity before any account action.',
        examples: [
          const ScriptLine(
            category: 'verify',
            choiceNumber: 1,
            title: 'Verify',
            text:
                'For security, can you confirm the full name or mobile number on the account?',
          ),
        ],
        amberLabel: 'Step 2 of 4: Confirm identity on file.',
        stepNumber: 2,
        stepTotal: 4,
        allowEscalateTab: escalateAllowed,
      );
    }
    if (!toolWorkDone) {
      return CaseNextStep(
        id: 'gen_act',
        tip:
            'Explain findings in plain words, then file a service request, callback, or review ticket.',
        examples: [
          const ScriptLine(
            category: 'guide',
            choiceNumber: 1,
            title: 'Next',
            text:
                'Here is what I found in plain words. I can file a request or schedule a callback next.',
          ),
        ],
        amberLabel: 'Step 3 of 4: Explain and file the right request.',
        stepNumber: 3,
        stepTotal: 4,
        allowEscalateTab: escalateAllowed,
      );
    }
    return CaseNextStep(
      id: 'gen_confirm',
      tip: 'Confirm outcome and close when ready.',
      examples: [
        const ScriptLine(
          category: 'confirm',
          choiceNumber: 1,
          title: 'Confirm',
          text:
              'That is what we completed and what happens next. Is there anything else I can help with?',
        ),
      ],
      amberLabel: 'Step 4 of 4: Confirm and close when ready.',
      stepNumber: 4,
      stepTotal: 4,
      allowEscalateTab: escalateAllowed,
    );
  }

  static CaseNextStep _genericNonAccount({
    required bool escalateAllowed,
    required int traineeTurns,
  }) {
    if (traineeTurns < 2) {
      return CaseNextStep(
        id: 'gen_clarify',
        tip:
            'Acknowledge what they need, clarify one detail if required, then give a clear next step.',
        examples: [
          const ScriptLine(
            category: 'clarify',
            choiceNumber: 1,
            title: 'Clarify',
            text:
                'Could you tell me a little more about what happened so I can help with the next step?',
          ),
        ],
        amberLabel: 'Step 2 of 3: Clarify the goal.',
        stepNumber: 2,
        stepTotal: 3,
        allowEscalateTab: escalateAllowed,
      );
    }
    return CaseNextStep(
      id: 'gen_guide',
      tip:
          'Give one clear guided step, then confirm the customer can continue.',
      examples: [
        const ScriptLine(
          category: 'guide',
          choiceNumber: 1,
          title: 'Guide',
          text:
              'Here is the next step in plain words. Please try it and tell me the result.',
        ),
      ],
      amberLabel: 'Step 3 of 3: Guide and confirm understanding.',
      stepNumber: 3,
      stepTotal: 3,
      allowEscalateTab: escalateAllowed,
    );
  }
}
