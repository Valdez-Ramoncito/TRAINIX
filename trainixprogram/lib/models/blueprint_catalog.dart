import 'package:trainixprogram/models/case_blueprint.dart';
import 'package:trainixprogram/models/problem_family.dart';

class BlueprintCatalog {
  static CaseBlueprint resolve({
    required String sector,
    required String problem,
    required ProblemFamily family,
    bool needsAccount = true,
    bool escalateFromStart = false,
    String? casePackId,
  }) {
    final key = '${sector.toLowerCase()} ${problem.toLowerCase()}';
    if (key.contains('upgrade') ||
        key.contains('plan') && key.contains('den')) {
      return planUpgradeDenied(needsAccount: needsAccount);
    }
    if (key.contains('freeze') ||
        key.contains('crash') ||
        key.contains('app freezes') ||
        key.contains('recent file') ||
        (key.contains('app') & key.contains('open'))) {
      return techAppIssue(needsAccount: false);
    }
    if (key.contains('password') ||
        key.contains('login') ||
        key.contains('sign-in') ||
        key.contains('sign in') ||
        key.contains('locked')) {
      return passwordLocked(needsAccount: needsAccount);
    }
    if (key.contains('bill') ||
        key.contains('charge') ||
        key.contains('invoice')) {
      return billSurprise(needsAccount: needsAccount);
    }
    if (key.contains('claim')) {
      return claimStatus(needsAccount: needsAccount);
    }
    if (key.contains('refill') || key.contains('prescription')) {
      return prescriptionRefill(needsAccount: needsAccount);
    }
    if (key.contains('transfer') ||
        key.contains('fund') ||
        key.contains('money still') ||
        key.contains('has not arrived')) {
      return fundTransfer(needsAccount: needsAccount);
    }
    if (key.contains('network') ||
        key.contains('signal') ||
        key.contains('outage') ||
        key.contains('internet') ||
        key.contains('wifi')) {
      return networkIssue(needsAccount: needsAccount);
    }
    return genericForFamily(
      family: family,
      sector: sector,
      needsAccount: needsAccount,
      escalateFromStart: escalateFromStart,
    );
  }

  static CaseBlueprint planUpgradeDenied({bool needsAccount = true}) {
    return CaseBlueprint(
      id: 'telco_plan_upgrade_denied',
      sector: 'Telco',
      title: 'Plan upgrade denied',
      needsAccount: needsAccount,
      family: ProblemFamily.planEligibility,
      groundTruth: const {
        'plan_wanted': 'Premium Plus',
        'denied_when': 'yesterday',
        'block_reason': 'an unpaid balance on the line',
        'option_a': 'pay the balance then retry the upgrade',
        'option_b': 'file an upgrade review request',
      },
      knowsAtStart: const ['plan_wanted', 'denied_when'],
      objectives: const [
        ObjectiveDef(
          id: 'open',
          phase: 'opening',
          label: 'Greet and acknowledge the denied upgrade',
          evidenceKind: ObjectiveEvidenceKind.phrases,
          phrases: ['trainix', 'help', 'upgrade', 'denied', 'understand'],
          tip:
              'Give your name and Trainix Support, then acknowledge the denied plan upgrade.',
          examples: [
            'Thank you for contacting Trainix Support. This is [your name]. I understand your plan upgrade was denied, and I will help you with that.',
          ],
        ),
        ObjectiveDef(
          id: 'clarify',
          phase: 'exploring',
          label: 'Confirm plan and when it was denied',
          requires: ['open'],
          evidenceKind: ObjectiveEvidenceKind.customerFacts,
          customerFactKeys: ['plan_wanted', 'denied_when'],
          tip:
              'Plan and timing may already be on the record. If not, confirm which plan and when it was denied. Do not treat this as a network outage.',
          examples: [
            'Just to confirm, which plan did you try to move to, and when did the app deny the change?',
          ],
        ),
        ObjectiveDef(
          id: 'verify',
          phase: 'exploring',
          label: 'Look up the account and confirm identity',
          requires: ['clarify'],
          evidenceKind: ObjectiveEvidenceKind.tool,
          toolEvent: ToolEvent.identityVerified,
          tip:
              'Open Account Lookup, select the customer account, then submit Confirm identity on file.',
          toolHint: 'Account Lookup: select account, Confirm identity on file',
          examples: [
            'I will pull up your account and confirm one detail, then explain what blocked the upgrade.',
          ],
        ),
        ObjectiveDef(
          id: 'explain',
          phase: 'acting',
          label: 'Explain the block reason in plain words',
          requires: ['verify'],
          evidenceKind: ObjectiveEvidenceKind.phrases,
          phrases: ['balance', 'unpaid', 'block', 'because', 'reason'],
          tip:
              'Explain the block using the account finding in plain words: {block_reason}.',
          examples: [
            'The upgrade is blocked because of {block_reason}. Once that is cleared, the upgrade can be tried again, or we can file a review.',
          ],
        ),
        ObjectiveDef(
          id: 'act',
          phase: 'acting',
          label: 'Offer options and file a review if agreed',
          requires: ['explain'],
          evidenceKind: ObjectiveEvidenceKind.tool,
          toolEvent: ToolEvent.requestFiled,
          tip:
              'Offer {option_a} or {option_b}. If they agree to a review, file the service request in Account Lookup.',
          toolHint: 'Account Lookup: File service request',
          examples: [
            'I can file an upgrade review request for you now. Would you like me to submit that?',
          ],
        ),
        ObjectiveDef(
          id: 'confirm',
          phase: 'acting',
          label: 'Set expectation and timeline',
          requires: ['act'],
          evidenceKind: ObjectiveEvidenceKind.phrases,
          phrases: ['timeline', 'follow', 'next', 'update', 'filed'],
          tip: 'Tell them what was filed and the usual next step or timeline.',
          examples: [
            'The review request is filed. You should see an update within the usual review window. Does that work for you?',
          ],
        ),
        ObjectiveDef(
          id: 'close',
          phase: 'closing',
          label: 'Close the interaction',
          requires: ['confirm'],
          evidenceKind: ObjectiveEvidenceKind.phrases,
          phrases: ['anything else', 'thank', 'good day', 'glad'],
          tip:
              'Closing spiel: short recap, ask if anything else is needed, thank them.',
          examples: [
            'Is there anything else I can help you with today? Thank you for contacting Trainix Support. Have a great day.',
          ],
        ),
      ],
      escalateObjectives: const [
        ObjectiveDef(
          id: 'collect',
          phase: 'escalating',
          label: 'Collect handoff details',
          evidenceKind: ObjectiveEvidenceKind.phrases,
          phrases: ['tried', 'impact', 'callback', 'summary'],
          tip:
              'Collect what was tried, account detail, impact, and what you told them.',
          examples: [
            'I am preparing a full summary for the specialist team, including what we tried and your account details.',
          ],
        ),
        ObjectiveDef(
          id: 'handoff',
          phase: 'escalating',
          label: 'Submit the escalation',
          requires: ['collect'],
          evidenceKind: ObjectiveEvidenceKind.tool,
          toolEvent: ToolEvent.escalationSubmitted,
          tip: 'Submit the escalation handoff in tools.',
          toolHint: 'Escalation tab or escalate action',
        ),
        ObjectiveDef(
          id: 'close_esc',
          phase: 'closing',
          label: 'Close without calling it resolved',
          requires: ['handoff'],
          evidenceKind: ObjectiveEvidenceKind.phrases,
          phrases: ['specialist', 'thank', 'anything else'],
          tip: 'Close clearly: specialist team continues, thank the customer.',
          examples: [
            'The specialist team will continue from here. Thank you for contacting Trainix Support.',
          ],
        ),
      ],
    );
  }

  static CaseBlueprint passwordLocked({bool needsAccount = true}) {
    return CaseBlueprint(
      id: 'tech_password_locked',
      sector: 'Tech Support',
      title: 'Password locked / cannot sign in',
      needsAccount: needsAccount,
      family: ProblemFamily.loginAccess,
      groundTruth: const {
        'reset_path': 'official forgot-password link',
        'next_path': 'secure access review',
      },
      knowsAtStart: const [],
      objectives: const [
        ObjectiveDef(
          id: 'open',
          phase: 'opening',
          label: 'Greet and acknowledge the sign-in issue',
          evidenceKind: ObjectiveEvidenceKind.phrases,
          phrases: ['trainix', 'help', 'login', 'password', 'sign'],
          tip:
              'Name, Trainix Support, acknowledge the sign-in problem. Do not ask for their full password.',
          examples: [
            'Thank you for contacting Trainix Support. This is [your name]. I understand you cannot sign in, and I will help you with that.',
          ],
        ),
        ObjectiveDef(
          id: 'clarify',
          phase: 'exploring',
          label: 'Confirm login email or username',
          requires: ['open'],
          evidenceKind: ObjectiveEvidenceKind.phrases,
          phrases: ['email', 'username', 'user name', 'login'],
          tip: 'Confirm the exact email or username on the account.',
          examples: [
            'Please confirm the exact email or username on the account so we reset the right login.',
          ],
        ),
        ObjectiveDef(
          id: 'verify',
          phase: 'exploring',
          label: 'Verify identity on file',
          requires: ['clarify'],
          evidenceKind: ObjectiveEvidenceKind.tool,
          toolEvent: ToolEvent.identityVerified,
          tip:
              'Account Lookup: select account, Confirm identity on file. Never ask for the full password.',
          toolHint: 'Account Lookup: Confirm identity on file',
        ),
        ObjectiveDef(
          id: 'act',
          phase: 'acting',
          label: 'Guide reset or file secure review',
          requires: ['verify'],
          evidenceKind: ObjectiveEvidenceKind.tool,
          toolEvent: ToolEvent.requestFiled,
          tip:
              'Guide the {reset_path}. If that already failed, file a {next_path}.',
          toolHint: 'Account Lookup: File service request when needed',
          examples: [
            'Please use the official forgot-password link and check spam. If nothing arrives, I will open a secure access review.',
          ],
        ),
        ObjectiveDef(
          id: 'confirm',
          phase: 'acting',
          label: 'Confirm next steps',
          requires: ['act'],
          evidenceKind: ObjectiveEvidenceKind.phrases,
          phrases: ['email', 'review', 'next', 'anything else'],
          tip: 'Confirm whether they can sign in or must wait on the review.',
          examples: [
            'You should receive the reset email shortly, or hear back from the secure review. Is there anything else on this login issue?',
          ],
        ),
        ObjectiveDef(
          id: 'close',
          phase: 'closing',
          label: 'Close the interaction',
          requires: ['confirm'],
          evidenceKind: ObjectiveEvidenceKind.phrases,
          phrases: ['thank', 'anything else', 'good day'],
          tip: 'Closing spiel: anything else, thanks, end politely.',
          examples: [
            'Thank you for contacting Trainix Support. Have a great day.',
          ],
        ),
      ],
    );
  }

  static CaseBlueprint billSurprise({bool needsAccount = true}) {
    return CaseBlueprint(
      id: 'finance_bill_surprise',
      sector: 'Finance',
      title: 'Unexpected bill or charge',
      needsAccount: needsAccount,
      family: ProblemFamily.billingSurprise,
      groundTruth: const {'review_action': 'billing review request'},
      knowsAtStart: const [],
      objectives: const [
        ObjectiveDef(
          id: 'open',
          phase: 'opening',
          label: 'Greet and acknowledge the bill concern',
          evidenceKind: ObjectiveEvidenceKind.phrases,
          phrases: ['trainix', 'help', 'bill', 'charge'],
          tip: 'Name, company, acknowledge the unexpected bill or charge.',
          examples: [
            'Thank you for contacting Trainix Support. This is [your name]. I understand there is a charge that looks unexpected, and I will help review it.',
          ],
        ),
        ObjectiveDef(
          id: 'clarify',
          phase: 'exploring',
          label: 'Confirm billing period',
          requires: ['open'],
          evidenceKind: ObjectiveEvidenceKind.phrases,
          phrases: ['month', 'period', 'statement', 'bill'],
          tip: 'Confirm which billing period looks wrong.',
          examples: ['Which billing period looks higher than you expected?'],
        ),
        ObjectiveDef(
          id: 'verify',
          phase: 'exploring',
          label: 'Verify identity',
          requires: ['clarify'],
          evidenceKind: ObjectiveEvidenceKind.tool,
          toolEvent: ToolEvent.identityVerified,
          tip: 'Account Lookup: Confirm identity before reviewing charges.',
          toolHint: 'Account Lookup: Confirm identity on file',
        ),
        ObjectiveDef(
          id: 'explain',
          phase: 'acting',
          label: 'Explain unusual items in plain words',
          requires: ['verify'],
          evidenceKind: ObjectiveEvidenceKind.phrases,
          phrases: ['charge', 'item', 'because', 'shows', 'line'],
          tip: 'List unusual charges simply compared with a typical month.',
          examples: [
            'I will list the unusual items in plain words compared with a typical month, then we can file a review if needed.',
          ],
        ),
        ObjectiveDef(
          id: 'act',
          phase: 'acting',
          label: 'File billing review if needed',
          requires: ['explain'],
          evidenceKind: ObjectiveEvidenceKind.tool,
          toolEvent: ToolEvent.requestFiled,
          tip: 'File a {review_action} when a correction may be needed.',
          toolHint: 'Account Lookup: File service request',
        ),
        ObjectiveDef(
          id: 'confirm',
          phase: 'acting',
          label: 'Confirm outcome',
          requires: ['act'],
          evidenceKind: ObjectiveEvidenceKind.phrases,
          phrases: ['review', 'timeline', 'anything else', 'filed'],
          tip: 'Confirm what was filed and the usual timeline.',
          examples: [
            'The billing review is filed. You will see the outcome in the usual timeline. Does that help?',
          ],
        ),
        ObjectiveDef(
          id: 'close',
          phase: 'closing',
          label: 'Close the interaction',
          requires: ['confirm'],
          evidenceKind: ObjectiveEvidenceKind.phrases,
          phrases: ['thank', 'anything else', 'good day'],
          tip: 'Closing spiel.',
          examples: [
            'Thank you for contacting Trainix Support. Have a great day.',
          ],
        ),
      ],
    );
  }

  static CaseBlueprint claimStatus({bool needsAccount = true}) {
    return CaseBlueprint(
      id: 'healthcare_claim_status',
      sector: 'Healthcare',
      title: 'Claim status update',
      needsAccount: needsAccount,
      family: ProblemFamily.claimStatus,
      groundTruth: const {'status_field': 'Coverage'},
      knowsAtStart: const [],
      objectives: const [
        ObjectiveDef(
          id: 'open',
          phase: 'opening',
          label: 'Greet and acknowledge the claim concern',
          evidenceKind: ObjectiveEvidenceKind.phrases,
          phrases: ['trainix', 'help', 'claim'],
          tip: 'Name, company, acknowledge the claim status concern.',
          examples: [
            'Thank you for contacting Trainix Support. This is [your name]. I understand you need an update on a claim, and I will help you with that.',
          ],
        ),
        ObjectiveDef(
          id: 'clarify',
          phase: 'exploring',
          label: 'Collect claim reference or service date',
          requires: ['open'],
          evidenceKind: ObjectiveEvidenceKind.phrases,
          phrases: ['claim', 'last week', 'submitted', 'date', 'reference'],
          tip:
              'Ask for claim number or date of service if not already given. A submitted-last-week statement can be enough to move on.',
          examples: [
            'Do you have the claim number or the date of service for this claim?',
          ],
        ),
        ObjectiveDef(
          id: 'verify',
          phase: 'exploring',
          label: 'Verify identity on the member record',
          requires: ['clarify'],
          evidenceKind: ObjectiveEvidenceKind.tool,
          toolEvent: ToolEvent.identityVerified,
          tip: 'Account Lookup: Confirm identity before sharing claim status.',
          toolHint: 'Account Lookup: Confirm identity on file',
        ),
        ObjectiveDef(
          id: 'explain',
          phase: 'acting',
          label: 'State the on-file status in plain words',
          requires: ['verify'],
          evidenceKind: ObjectiveEvidenceKind.phrases,
          phrases: [
            'pending',
            'approved',
            'denied',
            'status',
            'coverage',
            'review',
          ],
          tip:
              'Read Coverage or Status in Account Lookup and explain that exact value. Do not promise payment.',
          examples: [
            'Your claim status on file is Claim Pending. That means it is still under review and is not approved or denied yet.',
          ],
        ),
        ObjectiveDef(
          id: 'act',
          phase: 'acting',
          label: 'File status follow-up if needed',
          requires: ['explain'],
          evidenceKind: ObjectiveEvidenceKind.tool,
          toolEvent: ToolEvent.requestFiled,
          tip:
              'Offer and file a claim status follow-up if the customer wants one.',
          toolHint: 'Account Lookup: File service request',
          examples: [
            'I can file a claim status review so the team can re-check the file. Would you like me to submit that?',
          ],
        ),
        ObjectiveDef(
          id: 'confirm',
          phase: 'acting',
          label: 'Confirm next steps',
          requires: ['act'],
          evidenceKind: ObjectiveEvidenceKind.phrases,
          phrases: ['follow', 'anything else', 'filed', 'update'],
          tip: 'Confirm what was filed and ask if anything else is needed.',
          examples: [
            'To recap, your claim shows the status we reviewed and the follow-up is filed where needed. Is there anything else on this claim?',
          ],
        ),
        ObjectiveDef(
          id: 'close',
          phase: 'closing',
          label: 'Close the interaction',
          requires: ['confirm'],
          evidenceKind: ObjectiveEvidenceKind.phrases,
          phrases: ['thank', 'anything else', 'good day'],
          tip: 'Closing spiel.',
          examples: [
            'Thank you for contacting Trainix Support. Have a great day.',
          ],
        ),
      ],
    );
  }

  static CaseBlueprint prescriptionRefill({bool needsAccount = true}) {
    return CaseBlueprint(
      id: 'healthcare_prescription_refill',
      sector: 'Healthcare',
      title: 'Prescription refill delay',
      needsAccount: needsAccount,
      family: ProblemFamily.prescriptionRefill,
      groundTruth: const {'typical_timing': '24 to 48 hours'},
      knowsAtStart: const [],
      objectives: const [
        ObjectiveDef(
          id: 'open',
          phase: 'opening',
          label: 'Greet and acknowledge the refill delay',
          evidenceKind: ObjectiveEvidenceKind.phrases,
          phrases: ['trainix', 'help', 'refill', 'prescription'],
          tip:
              'Name, company, acknowledge the delay. Do not prescribe or change medication.',
          examples: [
            'Thank you for contacting Trainix Support. This is [your name]. I understand your prescription refill is delayed, and I will help you with the next steps.',
          ],
        ),
        ObjectiveDef(
          id: 'clarify',
          phase: 'exploring',
          label: 'Confirm pharmacy and request timing if needed',
          requires: ['open'],
          evidenceKind: ObjectiveEvidenceKind.phrases,
          phrases: ['pharmacy', 'when', 'requested', 'refill', 'delayed'],
          tip:
              'Confirm pharmacy and when the refill was requested when missing.',
          examples: [
            'Which pharmacy is handling the refill, and when was the request submitted?',
          ],
        ),
        ObjectiveDef(
          id: 'explain',
          phase: 'acting',
          label: 'Explain typical timing and next step',
          requires: ['clarify'],
          evidenceKind: ObjectiveEvidenceKind.phrases,
          phrases: ['24', '48', 'hour', 'day', 'pharmacy', 'typically'],
          tip:
              'Give typical timing ({typical_timing}) and ask them to check queue/hold/stock with the pharmacy. Do not prescribe.',
          examples: [
            'Typical refill processing is about 24 to 48 hours after the pharmacy receives the request. Please check with the pharmacy first for any hold or stock issue. I cannot prescribe or change the medication itself.',
          ],
        ),
        ObjectiveDef(
          id: 'act',
          phase: 'acting',
          label: 'File refill follow-up if still delayed',
          requires: ['explain'],
          evidenceKind: ObjectiveEvidenceKind.tool,
          toolEvent: ToolEvent.requestFiled,
          tip:
              'If still delayed after the usual window, file a refill follow-up request.',
          toolHint: 'Account Lookup: File service request',
          examples: [
            'If the pharmacy still has no update, I can file a refill follow-up request for you.',
          ],
        ),
        ObjectiveDef(
          id: 'confirm',
          phase: 'acting',
          label: 'Confirm the plan',
          requires: ['act'],
          evidenceKind: ObjectiveEvidenceKind.phrases,
          phrases: ['pharmacy', 'follow', 'anything else', 'recap'],
          tip: 'Confirm pharmacy check and any follow-up filed.',
          examples: [
            'To recap: check with the pharmacy on timing, and the follow-up is filed if we submitted one. Is there anything else on the refill?',
          ],
        ),
        ObjectiveDef(
          id: 'close',
          phase: 'closing',
          label: 'Close the interaction',
          requires: ['confirm'],
          evidenceKind: ObjectiveEvidenceKind.phrases,
          phrases: ['thank', 'anything else', 'good day'],
          tip: 'Closing spiel.',
          examples: [
            'Thank you for contacting Trainix Support. Have a great day.',
          ],
        ),
      ],
    );
  }

  static CaseBlueprint fundTransfer({bool needsAccount = true}) {
    return CaseBlueprint(
      id: 'finance_fund_transfer',
      sector: 'Finance',
      title: 'Fund transfer not arrived',
      needsAccount: needsAccount,
      family: ProblemFamily.fundTransfer,
      groundTruth: const {'typical_window': '3 to 5 business days'},
      knowsAtStart: const [],
      objectives: const [
        ObjectiveDef(
          id: 'open',
          phase: 'opening',
          label: 'Greet and acknowledge the transfer concern',
          evidenceKind: ObjectiveEvidenceKind.phrases,
          phrases: ['trainix', 'help', 'transfer', 'understand'],
          tip:
              'Name, Trainix Support, acknowledge the missing or delayed transfer.',
          examples: [
            'Thank you for contacting Trainix Support. This is [your name]. I understand a transfer has not arrived as expected, and I will help you with that.',
          ],
        ),
        ObjectiveDef(
          id: 'clarify',
          phase: 'exploring',
          label: 'Confirm amount, send time, and status shown',
          requires: ['open'],
          evidenceKind: ObjectiveEvidenceKind.phrases,
          phrases: [
            'amount',
            'when',
            'sent',
            'processing',
            'business day',
            '2500',
            'week',
          ],
          tip:
              'Confirm amount, about when it was sent, and what status the customer sees. If they already gave those details, acknowledge them and move on. Do not ask them to paste full account numbers in chat.',
          examples: [
            'Thank you. I have the amount, about when it was sent, and that it still shows processing. I will verify the account next, then check what we can do.',
          ],
        ),
        ObjectiveDef(
          id: 'verify',
          phase: 'exploring',
          label: 'Verify identity in Account Lookup',
          requires: ['clarify'],
          evidenceKind: ObjectiveEvidenceKind.tool,
          toolEvent: ToolEvent.identityVerified,
          tip:
              'Customer already described the transfer in chat. Open Account Lookup, select their account, and submit Confirm identity on file. This is a tool step, not a request for passwords or full account numbers in the message box.',
          toolHint:
              'Account Lookup: select account, then Confirm identity on file',
          examples: [
            'Thank you for those details. I am verifying the name on the account now, then I will review the transfer status.',
          ],
        ),
        ObjectiveDef(
          id: 'explain',
          phase: 'acting',
          label: 'Explain normal timing and what the record shows',
          requires: ['verify'],
          evidenceKind: ObjectiveEvidenceKind.phrases,
          phrases: [
            'business day',
            'processing',
            'timeline',
            'window',
            'status',
            'shows',
          ],
          tip:
              'Explain the normal window ({typical_window}) and that a review is needed when it is past that window. Do not claim the money has moved until a tool action is done.',
          examples: [
            'Transfers often complete within 3 to 5 business days. Since this one is past that window and still shows processing, the next step is a formal transfer review.',
          ],
        ),
        ObjectiveDef(
          id: 'act',
          phase: 'acting',
          label: 'File a transfer review request',
          requires: ['explain'],
          evidenceKind: ObjectiveEvidenceKind.tool,
          toolEvent: ToolEvent.requestFiled,
          tip:
              'File a transfer review or investigation request in Account Lookup, then tell the customer it is submitted.',
          toolHint: 'Account Lookup: File service request',
          examples: [
            'I will file a transfer review request now so the team can investigate the transfer that is still processing.',
          ],
        ),
        ObjectiveDef(
          id: 'confirm',
          phase: 'acting',
          label: 'Confirm next steps and timeline',
          requires: ['act'],
          evidenceKind: ObjectiveEvidenceKind.phrases,
          phrases: ['filed', 'review', 'update', 'anything else', 'timeline'],
          tip: 'Confirm the request is filed and what happens next.',
          examples: [
            'The transfer review is filed. You should receive an update within the usual review window. Is there anything else on this transfer?',
          ],
        ),
        ObjectiveDef(
          id: 'close',
          phase: 'closing',
          label: 'Close the interaction',
          requires: ['confirm'],
          evidenceKind: ObjectiveEvidenceKind.phrases,
          phrases: ['thank', 'anything else', 'good day'],
          tip: 'Closing spiel: anything else, thanks, end politely.',
          examples: [
            'Thank you for contacting Trainix Support. Have a great day.',
          ],
        ),
      ],
    );
  }

  static CaseBlueprint networkIssue({bool needsAccount = true}) {
    return genericForFamily(
      family: ProblemFamily.networkConnectivity,
      sector: 'Telco',
      needsAccount: needsAccount,
    );
  }

  static CaseBlueprint techAppIssue({bool needsAccount = false}) {
    return CaseBlueprint(
      id: 'tech_app_issue',
      sector: 'Tech Support',
      title: 'App or device issue',
      needsAccount: false,
      family: ProblemFamily.genericNonAccount,
      groundTruth: const {},
      knowsAtStart: const [],
      objectives: const [
        ObjectiveDef(
          id: 'open',
          phase: 'opening',
          label: 'Greet and acknowledge the app issue',
          evidenceKind: ObjectiveEvidenceKind.phrases,
          phrases: ['trainix', 'help', 'app', 'freeze', 'understand'],
          tip:
              'Name, Trainix Support, acknowledge the freeze or app issue. This is not an Account Lookup case.',
          examples: [
            'Thank you for contacting Trainix Support. This is [your name]. I understand the app is freezing, and I will help you with that.',
          ],
        ),
        ObjectiveDef(
          id: 'clarify',
          phase: 'exploring',
          label: 'Confirm when it happens and what they already tried',
          requires: ['open'],
          evidenceKind: ObjectiveEvidenceKind.phrases,
          phrases: [
            'when',
            'every',
            'force',
            'tried',
            'freeze',
            'recent',
            'file',
          ],
          tip:
              'If they already said the app freezes on recent files, acknowledge that. Ask only for a missing detail (device or last change). Do not re-ask the same problem.',
          examples: [
            'Thanks, I have that it freezes when opening recent files. On which device does this happen, and did it start after an update?',
          ],
        ),
        ObjectiveDef(
          id: 'guide',
          phase: 'acting',
          label: 'Give one fix path and confirm the result',
          requires: ['clarify'],
          evidenceKind: ObjectiveEvidenceKind.phrases,
          phrases: [
            'try',
            'restart',
            'update',
            'cache',
            'reinstall',
            'step',
            'please',
          ],
          tip:
              'Give one clear fix at a time (for example force-close and reopen, or clear cache). Confirm the result before the next step. Use Tech Guide for reference steps if needed.',
          toolHint:
              'Optional: open Tech Guide for standard app troubleshooting steps',
          examples: [
            'Please force-close the app fully, reopen it, then try one recent file again and tell me whether it still freezes.',
          ],
        ),
        ObjectiveDef(
          id: 'confirm',
          phase: 'acting',
          label: 'Confirm they can continue',
          requires: ['guide'],
          evidenceKind: ObjectiveEvidenceKind.phrases,
          phrases: ['working', 'anything else', 'fixed', 'continue'],
          tip:
              'Confirm the app works for them or set a clear next step if not.',
          examples: [
            'Glad that helped. Is the app stable now when you open recent files, or is there anything else on this issue?',
          ],
        ),
        ObjectiveDef(
          id: 'close',
          phase: 'closing',
          label: 'Close the interaction',
          requires: ['confirm'],
          evidenceKind: ObjectiveEvidenceKind.phrases,
          phrases: ['thank', 'anything else', 'good day'],
          tip: 'Closing spiel.',
          examples: [
            'Thank you for contacting Trainix Support. Have a great day.',
          ],
        ),
      ],
    );
  }

  static CaseBlueprint genericForFamily({
    required ProblemFamily family,
    required String sector,
    bool needsAccount = true,
    bool escalateFromStart = false,
  }) {
    final objectives = <ObjectiveDef>[
      const ObjectiveDef(
        id: 'open',
        phase: 'opening',
        label: 'Greet and acknowledge the issue',
        evidenceKind: ObjectiveEvidenceKind.phrases,
        phrases: ['trainix', 'help', 'understand'],
        tip:
            'Give your name and Trainix Support, then acknowledge their specific issue.',
        examples: [
          'Thank you for contacting Trainix Support. This is [your name]. I understand the issue you described, and I will help you with this.',
        ],
      ),
      const ObjectiveDef(
        id: 'clarify',
        phase: 'exploring',
        label: 'Clarify the goal or missing detail',
        requires: ['open'],
        evidenceKind: ObjectiveEvidenceKind.phrases,
        phrases: ['confirm', 'when', 'which', 'could you', 'tell me'],
        tip: 'Ask one clear clarifying question if needed.',
        examples: [
          'Could you tell me a little more about what happened so I can take the right next step?',
        ],
      ),
    ];
    if (needsAccount) {
      objectives.add(
        const ObjectiveDef(
          id: 'verify',
          phase: 'exploring',
          label: 'Verify identity on file',
          requires: ['clarify'],
          evidenceKind: ObjectiveEvidenceKind.tool,
          toolEvent: ToolEvent.identityVerified,
          tip: 'Account Lookup: Confirm identity before account actions.',
          toolHint: 'Account Lookup: Confirm identity on file',
        ),
      );
      objectives.add(
        const ObjectiveDef(
          id: 'act',
          phase: 'acting',
          label: 'Explain findings and file the right request',
          requires: ['verify'],
          evidenceKind: ObjectiveEvidenceKind.tool,
          toolEvent: ToolEvent.requestFiled,
          tip:
              'Explain findings in plain words, then file a service request, callback, or review.',
          toolHint: 'Account Lookup: File service request',
          examples: [
            'Here is what I found in plain words. I can file a request or schedule a callback next.',
          ],
        ),
      );
    } else {
      objectives.add(
        const ObjectiveDef(
          id: 'act',
          phase: 'acting',
          label: 'Give a clear guided next step',
          requires: ['clarify'],
          evidenceKind: ObjectiveEvidenceKind.phrases,
          phrases: ['next', 'please', 'step', 'try'],
          tip: 'Give one clear guided step, then confirm they can continue.',
          examples: [
            'Here is the next step in plain words. Please try it and tell me the result.',
          ],
        ),
      );
    }
    objectives.add(
      ObjectiveDef(
        id: 'confirm',
        phase: 'acting',
        label: 'Confirm outcome',
        requires: [needsAccount ? 'act' : 'act'],
        evidenceKind: ObjectiveEvidenceKind.phrases,
        phrases: ['anything else', 'next', 'filed', 'help'],
        tip: 'Confirm what happens next and check satisfaction.',
        examples: const [
          'That is what we completed and what happens next. Is there anything else I can help with?',
        ],
      ),
    );
    objectives.add(
      const ObjectiveDef(
        id: 'close',
        phase: 'closing',
        label: 'Close the interaction',
        requires: ['confirm'],
        evidenceKind: ObjectiveEvidenceKind.phrases,
        phrases: ['thank', 'anything else', 'good day'],
        tip: 'Closing spiel: anything else, thanks, end politely.',
        examples: [
          'Thank you for contacting Trainix Support. Have a great day.',
        ],
      ),
    );
    return CaseBlueprint(
      id: 'generic_${family.name}',
      sector: sector,
      title: 'Generic ${family.name}',
      needsAccount: needsAccount,
      escalateFromStart: escalateFromStart,
      family: family,
      objectives: objectives,
    );
  }
}
