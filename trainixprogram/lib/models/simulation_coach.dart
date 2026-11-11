import 'package:trainixprogram/models/training/script_personalization.dart';
import 'package:trainixprogram/models/training/soft_text_match.dart';
import 'package:trainixprogram/models/simulation_stage.dart';

enum PracticeFocus { general, typing, pronunciation, irateHandling }

String practiceFocusLabel(PracticeFocus focus) {
  switch (focus) {
    case PracticeFocus.general:
      return 'General';
    case PracticeFocus.typing:
      return 'Typing';
    case PracticeFocus.pronunciation:
      return 'Pronunciation';
    case PracticeFocus.irateHandling:
      return 'Irate handling';
  }
}

enum _CoachIssueKind {
  escalation,
  connectivity,
  accountBilling,
  healthcare,
  finance,
  telco,
  techSupport,
  irate,
  nonAccountGuide,
  general,
}

class SimulationCoach {
  static String stageFor({
    required bool hasCustomerSpoken,
    required bool hasTraineeSpoken,
    required bool customerConfirmed,
    required bool awaitingClosing,
    required bool isEscalating,
    required int traineeTurnCount,
    bool toolWorkDone = false,
    bool identityVerified = false,
  }) {
    if (!hasCustomerSpoken) return 'wait';
    if (!hasTraineeSpoken) return 'open';
    if (customerConfirmed || awaitingClosing) return 'close';
    if (isEscalating) return 'escalate';
    if (toolWorkDone || identityVerified || traineeTurnCount >= 3) return 'act';
    return 'explore';
  }

  static const int ahtLimitSeconds = 600;

  static _CoachIssueKind _classify({
    required String problem,
    required String sector,
  }) {
    final p = problem.toLowerCase();
    final s = sector.toLowerCase();

    if (p.contains('escalat')) return _CoachIssueKind.escalation;

    if (p.contains('angry') ||
        p.contains('irate') ||
        p.contains('upset') ||
        p.contains('frustrated') ||
        p.contains('furious')) {
      return _CoachIssueKind.irate;
    }

    if (p.contains('slow') ||
        p.contains('speed') ||
        p.contains('internet') ||
        p.contains('connection') ||
        p.contains('router') ||
        p.contains('wifi') ||
        p.contains('wi-fi') ||
        p.contains('network') ||
        p.contains('outage') ||
        p.contains('signal') ||
        p.contains('latency')) {
      return _CoachIssueKind.connectivity;
    }

    if (p.contains('appointment') ||
        p.contains('prescription') ||
        p.contains('medication') ||
        p.contains('claim') ||
        p.contains('insurance') ||
        p.contains('lab') ||
        p.contains('doctor') ||
        p.contains('clinic') ||
        p.contains('patient') ||
        p.contains('referral') ||
        p.contains('coverage') ||
        s.contains('health')) {
      return _CoachIssueKind.healthcare;
    }

    if (p.contains('loan') ||
        p.contains('card') ||
        p.contains('transfer') ||
        p.contains('fraud') ||
        p.contains('transaction') ||
        p.contains('deposit') ||
        p.contains('withdrawal') ||
        p.contains('interest') ||
        p.contains('statement') ||
        (s.contains('finance') &&
            (p.contains('account') ||
                p.contains('billing') ||
                p.contains('payment') ||
                p.contains('balance')))) {
      return _CoachIssueKind.finance;
    }

    if (p.contains('billing') ||
        p.contains('payment') ||
        p.contains('balance') ||
        p.contains('account') ||
        p.contains('order') ||
        p.contains('ticket') ||
        p.contains('invoice') ||
        p.contains('refund') ||
        p.contains('charge')) {
      return _CoachIssueKind.accountBilling;
    }

    if (p.contains('sim') ||
        p.contains('plan') ||
        p.contains('data') ||
        p.contains('minutes') ||
        p.contains('roaming') ||
        p.contains('number port') ||
        p.contains('prepaid') ||
        p.contains('postpaid') ||
        s.contains('telco')) {
      return _CoachIssueKind.telco;
    }

    if (p.contains('password') ||
        p.contains('login') ||
        p.contains('app') ||
        p.contains('software') ||
        p.contains('device') ||
        p.contains('install') ||
        p.contains('update') ||
        p.contains('error') ||
        p.contains('bug') ||
        p.contains('crash') ||
        s.contains('tech')) {
      return _CoachIssueKind.techSupport;
    }

    if (p.contains('how to') ||
        p.contains('guide') ||
        p.contains('walk me') ||
        p.contains('help me set') ||
        p.contains('configure') ||
        p.contains('explain')) {
      return _CoachIssueKind.nonAccountGuide;
    }

    return _CoachIssueKind.general;
  }

  static bool _looksAccountRelated(String problem, String sector) {
    final kind = _classify(problem: problem, sector: sector);
    final p = problem.toLowerCase();
    return kind == _CoachIssueKind.accountBilling ||
        kind == _CoachIssueKind.finance ||
        (kind == _CoachIssueKind.healthcare &&
            (p.contains('claim') ||
                p.contains('insurance') ||
                p.contains('coverage') ||
                p.contains('billing')));
  }

  static String objectiveForProblem(String problem, {String sector = ''}) {
    final kind = _classify(problem: problem, sector: sector);
    switch (kind) {
      case _CoachIssueKind.escalation:
        return 'Gather key details, escalate correctly, set a clear next step, and close cleanly.';
      case _CoachIssueKind.connectivity:
        return 'Guide focused troubleshooting one step at a time, confirm each result, and close only when the customer is satisfied.';
      case _CoachIssueKind.accountBilling:
        return 'Verify the correct account, explain what you found, apply or propose a fix, and confirm the customer is satisfied.';
      case _CoachIssueKind.healthcare:
        return 'Handle the healthcare concern carefully: confirm identity if needed, clarify the request, follow policy, and confirm next steps with the customer.';
      case _CoachIssueKind.finance:
        return 'Protect the customer: verify identity when needed, explain the financial issue clearly, resolve or escalate, and confirm they understand the outcome.';
      case _CoachIssueKind.telco:
        return 'Diagnose the telco issue, guide the customer through the right checks, resolve or escalate, and confirm service is acceptable before closing.';
      case _CoachIssueKind.techSupport:
        return 'Identify the tech issue, guide one clear fix at a time, confirm results, and close when the customer can continue successfully.';
      case _CoachIssueKind.irate:
        return 'De-escalate first, take ownership, solve or escalate with a clear plan, and confirm the customer feels heard and helped.';
      case _CoachIssueKind.nonAccountGuide:
        return 'Guide the customer without relying on account lookup. Use clear steps, confirm understanding, and close when they can proceed.';
      case _CoachIssueKind.general:
        return 'Understand the concern, help with clear next steps, and confirm the customer is satisfied before closing.';
    }
  }

  static bool needsAccountLookup(String problem, {String sector = ''}) {
    final kind = _classify(problem: problem, sector: sector);
    final p = problem.toLowerCase();
    if (kind == _CoachIssueKind.accountBilling ||
        kind == _CoachIssueKind.finance) {
      return true;
    }
    if (kind == _CoachIssueKind.healthcare &&
        (p.contains('claim') ||
            p.contains('billing') ||
            p.contains('insurance') ||
            p.contains('account') ||
            p.contains('payment'))) {
      return true;
    }
    if (p.contains('account') ||
        p.contains('unauthorized') ||
        p.contains('charge') ||
        p.contains('balance') ||
        p.contains('card') ||
        p.contains('bill') ||
        p.contains('invoice') ||
        p.contains('transfer') ||
        p.contains('payment') ||
        p.contains('password') ||
        p.contains('locked') ||
        p.contains('sign in') ||
        p.contains('login')) {
      return true;
    }
    // Pure app / device troubleshooting is not Account Lookup
    if (p.contains('freeze') ||
        p.contains('crash') ||
        p.contains('app ') ||
        p.contains('slow computer') ||
        p.contains('blue screen')) {
      return false;
    }
    return false;
  }

  static bool needsSectorGuide(String problem, {String sector = ''}) {
    final kind = _classify(problem: problem, sector: sector);
    if (kind == _CoachIssueKind.connectivity ||
        kind == _CoachIssueKind.techSupport ||
        kind == _CoachIssueKind.telco ||
        kind == _CoachIssueKind.nonAccountGuide ||
        kind == _CoachIssueKind.general ||
        kind == _CoachIssueKind.irate) {
      return true;
    }
    if (kind == _CoachIssueKind.healthcare &&
        !needsAccountLookup(problem, sector: sector)) {
      return true;
    }
    final s = sector.toLowerCase();
    if (s.contains('tech') ||
        s.contains('telco') ||
        s.contains('telecom') ||
        s.contains('it support')) {
      return true;
    }
    final p = problem.toLowerCase();
    if (p.contains('wifi') ||
        p.contains('router') ||
        p.contains('password') ||
        p.contains('app') ||
        p.contains('signal') ||
        p.contains('appointment') ||
        p.contains('delivery') ||
        p.contains('return') ||
        p.contains('how to') ||
        p.contains('not working')) {
      return true;
    }
    return false;
  }

  static String sectorGuideTabLabel(String sector) {
    final s = sector.toLowerCase();
    if (s.contains('health')) return 'Care Guide';
    if (s.contains('tech') || s.contains('it')) return 'Tech Guide';
    if (s.contains('telco') || s.contains('telecom') || s.contains('mobile')) {
      return 'Network Guide';
    }
    if (s.contains('finance') || s.contains('bank')) return 'Process Guide';
    if (s.contains('retail') || s.contains('ecommerce')) return 'Order Guide';
    return 'Issue Guide';
  }

  static bool looksUnlistedNonAccount(String problem, String sector) {
    if (problem.trim().isEmpty) return false;
    if (requiresEscalationFromStart(problem, sector: sector)) return true;
    final kind = _classify(problem: problem, sector: sector);
    if (kind == _CoachIssueKind.accountBilling ||
        kind == _CoachIssueKind.finance) {
      return false;
    }
    final p = problem.toLowerCase();
    const known = [
      'wifi',
      'wi-fi',
      'slow',
      'buffer',
      'crash',
      'password',
      'login',
      'signal',
      'sim',
      'data',
      'appointment',
      'claim',
      'prescription',
      'order',
      'delivery',
      'return',
      'refund',
      'payment failed',
      'declined',
      'how to',
      'not working',
      'router',
      'modem',
      'app',
      'virus',
      'malware',
      'security',
      'alert',
      'popup',
      'pop-up',
      'upgrade',
      'plan',
      'denied',
      'file',
      'deleted',
      'missing',
      'reset',
      'backup',
      'scan',
      'antivirus',
      'boot',
      'blue screen',
      'email',
      'bill',
      'roaming',
      'port',
      'portal',
      'copay',
      'eob',
      'statement',
      'card declined',
      'locked',
      'damaged',
      'wrong item',
      'cancel order',
      'tracking',
      'package',
      'loan',
      'hardship',
      'restructure',
      'charge',
      'internet',
      'outage',
      'connection',
      'offline',
      'no service',
      'down for',
      'no signal',
      'dropped call',
      'line is dead',
      'can\'t connect',
      'service fee',
      'unexpected fee',
      'unexpected charge',
    ];
    for (final k in known) {
      if (p.contains(k)) return false;
    }
    return true;
  }

  static bool requiresEscalationFromStart(
    String problem, {
    String sector = '',
  }) {
    final p = problem.toLowerCase();
    return p.contains('restructure') ||
        p.contains('loan modification') ||
        p.contains('hardship') ||
        p.contains('can\'t keep up') ||
        p.contains('cannot keep up') ||
        p.contains('fraud investigation') ||
        p.contains('identity theft') ||
        p.contains('lawsuit') ||
        p.contains('legal') ||
        p.contains('attorney') ||
        p.contains('manager') ||
        p.contains('supervisor') ||
        p.contains('not accredited') ||
        p.contains('accreditation') ||
        p.contains('denied because') ||
        p.contains('policy exception') ||
        p.contains('chargeback investigation') ||
        p.contains('underwriting') ||
        p.contains('collections agency');
  }

  static bool customerWantsMoreDetail(String lastCustomerMessage) {
    final t = lastCustomerMessage.toLowerCase();
    return t.contains('specific') ||
        t.contains('what change') ||
        t.contains('what was') ||
        t.contains('clarify what') ||
        t.contains('what did you') ||
        t.contains('what action') ||
        t.contains('exactly') ||
        t.contains('more detail') ||
        t.contains('doesn\'t tell me') ||
        t.contains('does not tell me') ||
        t.contains('can you clarify') ||
        t.contains('what was corrected') ||
        t.contains('what was fixed');
  }

  static bool looksLikeEscalation(String text) {
    final t = text.toLowerCase().trim();
    if (t.isEmpty) return false;
    if ((t.contains('if ') ||
            t.contains('in case ') ||
            t.contains('might need')) &&
        (t.contains('escalat') || t.contains('specialist')) &&
        !t.contains('i am escalat') &&
        !t.contains("i'm escalat") &&
        !t.contains('i will escalat') &&
        !t.contains("i'll escalat")) {
      return false;
    }
    return t.contains('i am escalating') ||
        t.contains("i'm escalating") ||
        t.contains('i will escalate') ||
        t.contains("i'll escalate") ||
        t.contains('escalating this now') ||
        t.contains('escalating your case') ||
        t.contains('escalating your case to') ||
        t.contains('i am escalating your case') ||
        t.contains('transferring you to') ||
        t.contains('transfer you to') ||
        t.contains('transfer this to') ||
        t.contains('specialist can continue') ||
        t.contains('raise a ticket') ||
        t.contains('open a ticket') ||
        t.contains('creating a ticket') ||
        t.contains('case number is') ||
        t.contains('reference number is') ||
        t.contains('handed this to') ||
        t.contains('handing this to');
  }

  static String? tipForState({
    required bool customerConfirmed,
    required bool awaitingClosing,
    required bool hasTraineeSpoken,
    required bool hasCustomerSpoken,
    String problem = '',
    String sector = '',
    int elapsedSeconds = 0,
    int traineeTurnCount = 0,
    bool toolWorkDone = false,
    bool identityVerified = false,
    bool accountSelected = false,
    bool isEscalating = false,
    String lastCustomerMessage = '',
    String lastTraineeMessage = '',
    bool isChatChannel = true,
  }) {
    if (!hasCustomerSpoken) {
      return isChatChannel
          ? 'Customer may message first in chat. Read their issue carefully before you reply.'
          : 'Wait for the line to connect, then open with your name and company.';
    }
    if (!hasTraineeSpoken) {
      if (hasCustomerSpoken && isChatChannel) {
        return 'They already stated the issue. Open with your name, acknowledge that specific problem, and do not ask what you can help with as if you did not read it.';
      }
      return 'Open with your name and company, then invite them to share the issue.';
    }

    // Account vs non-account focus after opening
    final pLow = problem.toLowerCase();
    final likelyAccount =
        pLow.contains('account') ||
        pLow.contains('bill') ||
        pLow.contains('payment') ||
        pLow.contains('claim') ||
        pLow.contains('login') ||
        pLow.contains('password') ||
        pLow.contains('card') ||
        pLow.contains('member');
    final planDenied =
        pLow.contains('upgrade') &&
            (pLow.contains('denied') || pLow.contains('reject')) ||
        (pLow.contains('plan') && pLow.contains('denied')) ||
        (pLow.contains('blocked') && pLow.contains('plan'));
    final loginLock =
        pLow.contains('password') ||
        pLow.contains('locked out') ||
        pLow.contains('sign in') ||
        pLow.contains('reset email') ||
        pLow.contains('cannot sign');
    final appointmentPrep =
        pLow.contains('appointment') &&
        (pLow.contains('prepare') ||
            pLow.contains('preparation') ||
            pLow.contains('what to do'));
    final transferDelay =
        pLow.contains('transfer') ||
        (pLow.contains('fund') && pLow.contains('arriv'));
    final claimStatus =
        pLow.contains('claim') &&
        (pLow.contains('status') ||
            pLow.contains('update') ||
            pLow.contains('submitted') ||
            pLow.contains('pending'));
    final billSurprise =
        (pLow.contains('bill') &&
            (pLow.contains('higher') ||
                pLow.contains('more than') ||
                pLow.contains('extra') ||
                pLow.contains('surprise'))) ||
        (pLow.contains('charge') && pLow.contains('bill'));

    if (hasTraineeSpoken && traineeTurnCount >= 1) {
      if (planDenied) {
        return 'This is a plan upgrade or eligibility issue, not a network outage. Confirm the plan they wanted and when it was denied, then explain the block or the review path.';
      }
      if (loginLock && traineeTurnCount == 1) {
        return 'Confirm the exact username or email they use to sign in. Then guide only the official reset path. Use Account Lookup if you need to verify the account on file.';
      }
      if (loginLock && traineeTurnCount >= 2 && !toolWorkDone) {
        return 'Guide the official password reset or unlock steps one at a time. Confirm whether the reset email arrives. Do not ask for their full password.';
      }
      if (appointmentPrep) {
        return 'Confirm the appointment details, then give clear preparation steps and what to expect. Do not invent clinical advice beyond standard prep guidance.';
      }
      if (transferDelay && traineeTurnCount == 1 && !identityVerified) {
        return 'This is a delayed fund transfer. Verify identity, then check status timing with the customer. Do not re-ask whether it is a charge, loan, or access issue.';
      }
      if (transferDelay && (identityVerified || traineeTurnCount >= 2)) {
        return 'Confirm transfer amount, send time, and whether either side shows pending. Explain normal timing, then file a review request if it is past the promised window.';
      }
      if (claimStatus) {
        return 'Explain claim status in plain words. Ask for claim number or service date if needed, list any missing documents, and do not promise payment outcomes.';
      }
      if (pLow.contains('prescription') || pLow.contains('refill')) {
        return 'Explain the refill path and expected timing. Confirm pharmacy and request date. Do not prescribe or change medication.';
      }
      if (billSurprise) {
        return 'This is a billing review, not a network outage. Confirm the bill period, list unusual charges in plain words, and explain what changed versus last month.';
      }
    }

    if (hasTraineeSpoken &&
        traineeTurnCount == 1 &&
        likelyAccount &&
        !toolWorkDone &&
        !planDenied &&
        !loginLock &&
        !appointmentPrep &&
        !transferDelay) {
      return 'Acknowledge the issue, then verify identity before any account action. Use Account Lookup when you are ready to act.';
    }
    if (hasTraineeSpoken &&
        traineeTurnCount == 1 &&
        !likelyAccount &&
        !planDenied &&
        !loginLock &&
        !appointmentPrep) {
      return 'Acknowledge what they need, clarify one detail if required, then give a clear next step. Account Lookup is not required for this type of case.';
    }
    if (likelyAccount &&
        accountSelected &&
        !identityVerified &&
        !toolWorkDone) {
      return 'Account selected. Confirm one detail from the record with the customer (name, last transaction, or similar), then choose Confirm identity on file in Account Lookup.';
    }
    if (likelyAccount && identityVerified && !toolWorkDone) {
      return 'Identity confirmed. Explain what you found in plain words, then file a service request, schedule a callback, or open a review ticket. Frontline cannot force an instant system fix.';
    }
    if (lastTraineeMessage.isNotEmpty) {
      if (isNegativeAgentReply(lastTraineeMessage) ||
          isOffTopicReply(lastTraineeMessage, problem)) {
        return 'Stay with their concern. Confirm one detail or state the next helpful step clearly.';
      }
      if (looksLikeClosing(lastTraineeMessage) &&
          (customerConfirmed || isEscalating)) {
        return 'Solid close pattern. Make sure the customer has a clear ending and no open question left hanging.';
      }
      if (looksLikeEscalation(lastTraineeMessage)) {
        return 'Good escalation intent. Finish collecting handoff details, then confirm the transfer without calling it fully resolved.';
      }
    }
    final lc = lastCustomerMessage.toLowerCase();
    final lp = problem.toLowerCase();
    if ((lp.contains('virus') ||
            lp.contains('malware') ||
            lp.contains('security') ||
            lc.contains('virus') ||
            lc.contains('malware') ||
            lc.contains('alert')) &&
        (lc.contains('still') ||
            lc.contains('worried') ||
            lc.contains('what do i need') ||
            lc.contains('first'))) {
      if (lc.contains('still') || traineeTurnCount >= 3) {
        return 'Alert is still present. Guide a trusted scan next, then escalate with alert text and steps already tried if it remains.';
      }
      return 'Keep them calm. Confirm device and exact alert text, then one safe check at a time. Avoid any pay or password pop-ups.';
    }
    if (isEscalating && (customerConfirmed || awaitingClosing)) {
      return 'Finish the handoff cleanly. Confirm what happens next and thank them without a resolved-case spiel.';
    }
    if (isEscalating) {
      return 'Stay on handoff quality: department, impact, callback, and what was already tried. Use the Escalation tab to submit.';
    }
    if (customerConfirmed && awaitingClosing) {
      return 'They are ready to close. Give a full closing spiel and offer further help before after-work.';
    }
    if (customerConfirmed) {
      return null;
    }

    final kind = _classify(problem: problem, sector: sector);
    if (looksUnlistedNonAccount(problem, sector) &&
        hasTraineeSpoken &&
        traineeTurnCount >= 4) {
      return 'If frontline steps are not enough, confirm details and prepare a clear escalation handoff.';
    }

    final mustEscalate =
        requiresEscalationFromStart(problem, sector: sector) ||
        kind == _CoachIssueKind.escalation;

    if (mustEscalate &&
        !toolWorkDone &&
        hasTraineeSpoken &&
        traineeTurnCount >= 2) {
      return 'This case needs escalation. Do not invent a system fix. Collect required details and escalate with a clear reference.';
    }

    if (toolWorkDone && customerWantsMoreDetail(lastCustomerMessage)) {
      return 'The customer needs a clearer explanation or a real next step. Be specific, or escalate if this is beyond frontline tools.';
    }

    if (toolWorkDone) {
      return 'You recorded a service action. Tell the customer what was submitted, the expected next step or timeline, and ask if that answers their need.';
    }

    final stalled = elapsedSeconds >= 480 && traineeTurnCount >= 6;
    final longHandle = elapsedSeconds >= 720;

    if (longHandle &&
        traineeTurnCount >= 9 &&
        kind == _CoachIssueKind.escalation) {
      return 'This case type usually needs a specialist path. Summarize what was tried, then escalate with complete handoff details.';
    }

    if (longHandle && traineeTurnCount >= 10) {
      return 'You have been on this customer a while. Confirm one clear next step, or escalate only if you truly cannot progress.';
    }

    if (stalled) {
      final stallTip = _stallTip(kind);
      if (stallTip != null) return stallTip;
    }

    return _activeTip(kind, sector: sector, problem: problem);
  }

  static String? _stallTip(_CoachIssueKind kind) {
    switch (kind) {
      case _CoachIssueKind.connectivity:
        return 'Stop repeating the same reboot. Ask for speed-test numbers, when it started, wired vs Wi-Fi, then try one new step or escalate.';
      case _CoachIssueKind.accountBilling:
        return 'Move forward: verify identity or account, state the finding in plain words, then propose a fix, credit, or escalation.';
      case _CoachIssueKind.healthcare:
        return 'Summarize what the customer needs, confirm any required details, then give one clear next step (schedule, claim status, or transfer).';
      case _CoachIssueKind.finance:
        return 'Recap the money issue, confirm what you verified, then state the outcome of your review request or the next step while it is pending.';
      case _CoachIssueKind.telco:
        return 'Avoid looping the same network check. Confirm plan or outage status, try one new diagnostic, or escalate with ticket details.';
      case _CoachIssueKind.techSupport:
        return 'Do not repeat the same click-path. Restate the error, try an alternate fix, or escalate with device and version details.';
      case _CoachIssueKind.irate:
        return 'Acknowledge the frustration again briefly, then commit to one concrete action and a time expectation.';
      case _CoachIssueKind.escalation:
        return 'You have enough to escalate. Confirm details, explain where it goes next, and give a reference or timeline.';
      case _CoachIssueKind.nonAccountGuide:
        return 'Simplify: give one instruction, wait for the result, then continue. Do not dump many steps at once.';
      case _CoachIssueKind.general:
        return 'The talk may be looping. Summarize the issue, choose one next action, and confirm it with the customer.';
    }
  }

  static String _activeTip(
    _CoachIssueKind kind, {
    required String sector,
    required String problem,
  }) {
    switch (kind) {
      case _CoachIssueKind.connectivity:
        return 'Ask what they already tried. Guide one clear step, wait for the result, then decide the next step.';
      case _CoachIssueKind.accountBilling:
        return 'Use Account Lookup when needed, verify you have the right account, then explain findings before any change.';
      case _CoachIssueKind.healthcare:
        if (problem.toLowerCase().contains('claim')) {
          return 'Explain claim status in plain words, confirm any missing documents, and avoid promising payment. Identity check only if sharing protected details.';
        }
        return 'Be precise and calm. Confirm who you are helping, clarify appointment, claim, or care need, and follow process before promising outcomes.';
      case _CoachIssueKind.finance:
        return 'Verify identity before sensitive account actions. Explain charges or balances simply, then confirm the action the customer wants.';
      case _CoachIssueKind.telco:
        if (problem.toLowerCase().contains('upgrade') ||
            problem.toLowerCase().contains('plan') &&
                (problem.toLowerCase().contains('denied') ||
                    problem.toLowerCase().contains('reject'))) {
          return 'Focus on the denied plan change: confirm the plan, when it failed, and any eligibility message. This is not a signal or outage check.';
        }
        return 'Confirm service type and symptoms first (calls, data, SMS, outage). Then guide checks or review the plan before changing anything.';
      case _CoachIssueKind.techSupport:
        if (problem.toLowerCase().contains('password') ||
            problem.toLowerCase().contains('locked') ||
            problem.toLowerCase().contains('sign in')) {
          return 'Confirm the login email or username, then guide the official reset path one step at a time. Check whether the reset email arrives.';
        }
        return 'Reproduce the issue in words: device, app, and error. Give one fix path at a time and confirm each result.';
      case _CoachIssueKind.irate:
        return 'Lead with empathy, avoid blame, and own the next step. Solve if you can; otherwise escalate with a clear plan.';
      case _CoachIssueKind.escalation:
        return 'Capture name, issue summary, and impact. Explain escalation, set expectation, and confirm the customer agrees.';
      case _CoachIssueKind.nonAccountGuide:
        return 'No account lookup needed. Coach the customer with short steps and check understanding after each one.';
      case _CoachIssueKind.general:
        if (_looksAccountRelated(problem, sector)) {
          return 'Check whether account details are needed. If yes, verify first; if not, guide the fix and confirm progress.';
        }
        return 'Clarify the goal, work one step at a time, and only the customer can confirm it is resolved.';
    }
  }

  static bool looksLikeClosing(String text) {
    final t = text.toLowerCase();
    if (t.contains('how may i help') ||
        t.contains('how can i help') ||
        t.contains('i will help you with') ||
        (t.contains('i understand') && !t.contains('great day'))) {
      return false;
    }
    final hasDayClose =
        t.contains('have a great day') ||
        t.contains('have a good day') ||
        t.contains('goodbye');
    final hasOnceAgain =
        t.contains('once again this is') || t.contains('once again, this is');
    final hasClosingThank =
        t.contains('thank you for contacting trainix') && hasDayClose;
    return hasDayClose ||
        hasOnceAgain ||
        hasClosingThank ||
        t.contains('glad i could help') ||
        t.contains('has been escalated') ||
        t.contains('take care');
  }

  static bool looksLikeAgentSpeech(String text) {
    final t = text.toLowerCase();
    if (t.contains('thank you for contacting')) return true;
    if (t.contains('trainix support. this is')) return true;
    if (t.contains('i will file a') || t.contains('i can file a')) return true;
    if (t.contains('for security, can you confirm')) return true;
    if (t.contains('i cannot prescribe')) return true;
    return false;
  }

  static String stripInternalFields(String text) {
    var cleaned = text;
    // Strip structured labels even when the model puts them on one line.
    cleaned = cleaned.replaceAll(
      RegExp(
        r'\s*(EMOTION|ACCOUNT_PROVIDED|ACCOUNT_ID|PROBLEM_STATUS|CALL_STATUS)\s*:\s*[^\n]*',
        caseSensitive: false,
      ),
      '',
    );
    final lines = cleaned.split('\n');
    final kept = <String>[];
    for (final line in lines) {
      final t = line.trim();
      if (t.isEmpty) continue;
      final upper = t.toUpperCase();
      if (upper.startsWith('EMOTION:') ||
          upper.startsWith('ACCOUNT_PROVIDED:') ||
          upper.startsWith('ACCOUNT_ID:') ||
          upper.startsWith('PROBLEM_STATUS:') ||
          upper.startsWith('CALL_STATUS:') ||
          upper.startsWith('REPLY:')) {
        if (upper.startsWith('REPLY:')) {
          kept.add(t.substring(6).trim());
        }
        continue;
      }
      kept.add(line);
    }
    return kept.join('\n').trim();
  }

  static bool customerIsChecking(String text) {
    final t = text.toLowerCase();
    return t.contains("i'll check") ||
        t.contains('i will check') ||
        t.contains('let you know') ||
        t.contains('get back to you') ||
        t.contains('one moment') ||
        t.contains('give me a second') ||
        t.contains('give me a minute') ||
        t.contains('looking at') ||
        t.contains('checking now') ||
        t.contains('check my statement') ||
        t.contains("i'll look") ||
        t.contains('hold on while');
  }

  static bool isNegativeAgentReply(String text) {
    var t = text.toLowerCase().trim();
    if (t.isEmpty) return false;
    t = t.replaceAll("'", '').replaceAll("'", '');
    const patterns = [
      'i dont know',
      'i do not know',
      'i cant help',
      'i cannot help',
      'not my problem',
      'not my job',
      'deal with it',
      'figure it out',
      'whatever',
      'idk',
      'no idea',
      'impossible',
      'nothing i can do',
      'you have to fix it yourself',
      'dunno',
      'no clue',
      'shut up',
      'go away',
      'leave me alone',
      'stop calling',
      'i hate',
      'you are stupid',
      'youre stupid',
      'dumb customer',
      'idiot',
      'moron',
      'useless',
      'waste of time',
      'get lost',
      'who cares',
      'not my concern',
      'fix it yourself',
      'call someone else',
      'i quit',
      'this is dumb',
      'this is stupid',
      'screw you',
      'fuck you',
      'f you',
      'damn you',
      'bitch',
      'asshole',
      'bastard',
      'shut your',
    ];
    for (final p in patterns) {
      if (t.contains(p)) return true;
    }
    return false;
  }

  static bool isInsultingAgentReply(String text) {
    var t = text.toLowerCase().trim();
    if (t.isEmpty) return false;
    t = t.replaceAll("'", '').replaceAll("'", '');
    const insults = [
      'stupid',
      'idiot',
      'moron',
      'dumb',
      'useless',
      'shut up',
      'go away',
      'get lost',
      'screw you',
      'fuck you',
      'f you',
      'bitch',
      'asshole',
      'bastard',
      'hate you',
      'you suck',
      'waste of time',
      'worthless',
      'pathetic',
      'loser',
    ];
    for (final p in insults) {
      if (t.contains(p)) return true;
    }
    return false;
  }

  /// Customer reaction when the agent is off-script, rude, or nonsensical.
  /// Does not advance mission steps. Used so the customer does not go silent.
  static String offTrackCustomerReaction({
    required String agentText,
    required String problem,
    required String emotion,
    required String customerName,
  }) {
    final rude = isInsultingAgentReply(agentText) || isNegativeAgentReply(agentText);
    final noise = isOffTopicReply(agentText, problem);
    final issue = problem.trim().isEmpty ? 'my issue' : problem.trim();
    final shortIssue = issue.length > 60 ? 'this issue' : issue;

    if (rude) {
      const rudePool = [
        'Excuse me? That is not how I expect to be treated. Can we stay professional and focus on my issue?',
        'I am not okay with that tone. I called for help, not to be dismissed. Please help me with my concern.',
        'That was unprofessional. I still need help with my problem. Can you assist me properly?',
        'Please do not speak to me that way. I need someone who will actually help with this.',
        'I will need a supervisor if this continues. For now, can you help me with my issue the right way?',
      ];
      return rudePool[agentText.hashCode.abs() % rudePool.length];
    }

    if (noise) {
      const noisePool = [
        'Sorry, I did not understand that. Can you help me with my issue?',
        'I am not sure what you mean. Can we go back to my concern?',
        'That did not make sense to me. I still need help with this.',
        'Could you clarify? I am here about my problem and need a clear next step.',
        'I think we got off track. Can you help me resolve my issue?',
      ];
      return noisePool[agentText.hashCode.abs() % noisePool.length];
    }

    final emo = emotion.toLowerCase();
    if (emo.contains('frustrat') || emo.contains('angry') || emo.contains('impatient')) {
      const pushPool = [
        'That does not address what I asked. I need a clear answer on my issue.',
        'I am still waiting for help on this. Can you focus on my concern?',
        'Please stay on my issue. What is the next step to fix it?',
        'I need you to work on my problem, not something else. Can you help with that?',
      ];
      return pushPool[agentText.hashCode.abs() % pushPool.length]
          .replaceAll('my issue', shortIssue)
          .replaceAll('my problem', shortIssue)
          .replaceAll('my concern', shortIssue);
    }

    const mildPool = [
      'I am not sure that answers my question. Can you help me with my issue?',
      'Could we focus on my concern? I still need help with that.',
      'Sorry, that did not seem related. What can you do about my issue?',
      'I need guidance on my problem. Can you walk me through the next step?',
    ];
    return mildPool[agentText.hashCode.abs() % mildPool.length]
        .replaceAll('my issue', shortIssue)
        .replaceAll('my problem', shortIssue)
        .replaceAll('my concern', shortIssue);
  }

  /// True when agent text is weak vs current step examples/pass phrases.
  /// Expanded replies that still cover the step intent are not weak.
  static bool isWeakStepAlignment({
    required String agentText,
    required List<String> examples,
    required List<String> passPhrases,
  }) {
    final t = agentText.toLowerCase().trim();
    if (t.isEmpty) return true;
    if (isInsultingAgentReply(t) || isNegativeAgentReply(t)) return true;
    if (passPhrases.isEmpty && examples.isEmpty) return false;
    var phraseHits = 0;
    for (final p in passPhrases) {
      final needle = p.toLowerCase().trim();
      if (needle.isEmpty) continue;
      if (t.contains(needle)) phraseHits++;
    }
    if (phraseHits >= 1) return false;
    for (final ex in examples) {
      if (SoftTextMatch.typingMatches(agentText, ex)) return false;
      final words = SoftTextMatch.contentWords(SoftTextMatch.normalize(ex));
      if (words.isEmpty) continue;
      final norm = SoftTextMatch.normalize(agentText);
      var hits = 0;
      for (final w in words) {
        if (norm.contains(w)) hits++;
      }
      if (words.isNotEmpty && hits / words.length >= 0.35) return false;
    }
    return true;
  }

  static String suggestionForNegative(String text) {
    final t = text.toLowerCase();
    if (t.contains("don't know") ||
        t.contains('do not know') ||
        t.contains('idk') ||
        t.contains('no idea')) {
      return 'Try: "Let me look into that for you right now. I will check the details and guide you through the next step."';
    }
    if (t.contains("can't help") ||
        t.contains('cannot help') ||
        t.contains('nothing i can do')) {
      return 'Try: "I may need to escalate this, but I will stay with you and make sure the right team has everything they need."';
    }
    if (t.contains('not my') ||
        t.contains('deal with') ||
        t.contains('whatever')) {
      return 'Try: "I understand this is frustrating. I am here to help, and here is what I can do next..."';
    }
    return 'Stay professional: acknowledge the concern, take ownership, and offer a clear next step or escalation.';
  }

  static String get agentName => ScriptPersonalization.agentFullName;
  static String get companyName => ScriptPersonalization.companyName;

  static String _shortIssue(String problem) {
    final p = problem.trim();
    if (p.isEmpty) return 'this issue';
    if (p.length > 48) return 'this issue';
    return p;
  }

  static List<ScriptLine> scriptLines({
    required String sector,
    required String problem,
    required String emotion,
    required String customerName,
    String? accountId,
    required bool customerConfirmed,
    required bool awaitingClosing,
    required bool hasTraineeSpoken,
    required String? coachTip,
    bool toolWorkDone = false,
    bool hasCustomerSpoken = true,
    bool isEscalating = false,
  }) {
    final who = customerName.isEmpty ? 'the customer' : customerName;
    final issue = _shortIssue(problem);
    final accountBit = (accountId == null || accountId.isEmpty)
        ? 'your account details'
        : 'account $accountId';
    final tip = (coachTip ?? '').toLowerCase();
    final kind = _classify(problem: problem, sector: sector);
    final needsAccount =
        kind == _CoachIssueKind.accountBilling ||
        kind == _CoachIssueKind.finance ||
        (kind == _CoachIssueKind.healthcare &&
            (problem.toLowerCase().contains('claim') ||
                problem.toLowerCase().contains('billing') ||
                problem.toLowerCase().contains('insurance')));

    if (!hasCustomerSpoken) {
      return [
        ScriptLine(
          category: 'opening',
          choiceNumber: 1,
          title: 'Opening spiel',
          text:
              'Wait for the customer to speak first, then greet them professionally.',
        ),
      ];
    }

    if (!hasTraineeSpoken) {
      if (hasCustomerSpoken) {
        return [
          ScriptLine(
            category: 'opening',
            choiceNumber: 1,
            title: 'Opening + empathy',
            text:
                'Thank you for contacting $companyName. This is $agentName. I am sorry you are dealing with $issue, $who. I will help you with this.',
          ),
          ScriptLine(
            category: 'opening',
            choiceNumber: 2,
            title: 'Opening + empathy',
            text:
                'Hi $who, this is $agentName from $companyName. Thank you for reaching out about $issue. I understand this is frustrating, and I am here to help.',
          ),
        ];
      }
      return [
        ScriptLine(
          category: 'opening',
          choiceNumber: 1,
          title: 'Opening spiel',
          text:
              'Thank you for contacting $companyName. This is $agentName, how may I help you today?',
        ),
        ScriptLine(
          category: 'opening',
          choiceNumber: 2,
          title: 'Opening spiel',
          text:
              'Thank you for contacting $companyName. This is $agentName. Hi $who, I am happy to help you today. How can I assist you?',
        ),
      ];
    }

    if (isEscalating || tip.contains('escalat') || tip.contains('handoff')) {
      if (customerConfirmed || awaitingClosing) {
        return [
          ScriptLine(
            category: 'escalate',
            choiceNumber: 1,
            title: 'Confirm escalation close',
            text:
                'Your case is being escalated to the specialist team with a full summary. You will receive a reference for follow-up. Is there anything else to include before we end this chat?',
          ),
          ScriptLine(
            category: 'escalate',
            choiceNumber: 2,
            title: 'Escalation closing',
            text:
                'Thank you for your patience, $who. This is $agentName with $companyName. Your issue has been escalated and is not fully resolved on this chat. Have a good day.',
          ),
        ];
      }
      return escalationScriptLines(
        customerName: who,
        accountId: accountId,
        problem: problem,
      );
    }

    if (customerConfirmed || awaitingClosing) {
      return [
        ScriptLine(
          category: 'confirm',
          choiceNumber: 1,
          title: 'Confirm resolution',
          text:
              'Before we close, can you confirm that everything is resolved to your satisfaction?',
        ),
        ScriptLine(
          category: 'closing',
          choiceNumber: 1,
          title: 'Closing spiel',
          text:
              'Thank you for choosing $companyName, $who. This is $agentName. Is there anything else I can help you with today? Have a great day.',
        ),
      ];
    }

    final mustEscalate =
        requiresEscalationFromStart(problem, sector: sector) ||
        kind == _CoachIssueKind.escalation ||
        tip.contains('escalat');

    final revealEscalation =
        tip.contains('escalat') ||
        tip.contains('handoff') ||
        tip.contains('specialist') ||
        tip.contains('collect required');

    if (mustEscalate && !customerConfirmed && revealEscalation) {
      return escalationScriptLines(
        customerName: who,
        accountId: accountId,
        problem: problem,
      );
    }

    if (toolWorkDone &&
        (tip.contains('clearer') ||
            tip.contains('specific') ||
            tip.contains('beyond frontline') ||
            tip.contains('real next step'))) {
      return [
        ScriptLine(
          category: 'explain',
          choiceNumber: 1,
          title: 'Clarify the action',
          text:
              'Here is the specific change: I updated the record related to your case and submitted it for processing. You should see the result after the system refreshes. If it does not match what you need, I can escalate this to a specialist.',
        ),
        ScriptLine(
          category: 'escalate',
          choiceNumber: 1,
          title: 'Offer escalation',
          text:
              'If this still does not address the full request, I can escalate it to the team that handles this case type and send them a complete summary.',
        ),
      ];
    }

    if (toolWorkDone) {
      return [
        ScriptLine(
          category: 'explain',
          choiceNumber: 1,
          title: 'Explain what was filed',
          text:
              'I submitted the review on my end. In simple terms, your case is now in the queue. It may take a short moment to update on your side. Does that address your concern?',
        ),
        ScriptLine(
          category: 'explain',
          choiceNumber: 2,
          title: 'Confirm next step',
          text:
              'The request is filed in our system. Please check again shortly, and let me know if you still see the same problem.',
        ),
      ];
    }

    if (tip.contains('explain the block') ||
        tip.contains('explain the reason') ||
        tip.contains('eligibility') ||
        tip.contains('plan upgrade')) {
      return [
        ScriptLine(
          category: 'clarify',
          choiceNumber: 1,
          title: 'Confirm plan details',
          text:
              'Just to confirm, which plan did you try to move to, and when did the app deny the change?',
        ),
        ScriptLine(
          category: 'guide',
          choiceNumber: 1,
          title: 'Next check',
          text:
              'I will check what blocked the upgrade and explain the reason in plain words, then we can look at the review path.',
        ),
      ];
    }

    if (tip.contains('escalat') || tip.contains('handoff')) {
      return escalationScriptLines(
        customerName: who,
        accountId: accountId,
        problem: problem,
      );
    }

    if (tip.contains('wait') ||
        tip.contains('looking') ||
        tip.contains('check my')) {
      return [
        ScriptLine(
          category: 'wait',
          choiceNumber: 1,
          title: 'While customer checks',
          text:
              'Of course, take your time. I will stay here. Please let me know what you see.',
        ),
      ];
    }

    if (needsAccount &&
        (tip.contains('account') ||
            tip.contains('verify') ||
            tip.contains('identity') ||
            tip.contains('billing') ||
            tip.contains('payment'))) {
      return [
        ScriptLine(
          category: 'verify',
          choiceNumber: 1,
          title: 'Verify account',
          text:
              'For your security, may I please verify $accountBit before we continue?',
        ),
        ScriptLine(
          category: 'clarify',
          choiceNumber: 1,
          title: 'Clarify',
          text:
              'Just to make sure I understand, you need help with $issue. Is that correct?',
        ),
      ];
    }

    if (!needsAccount ||
        kind == _CoachIssueKind.connectivity ||
        kind == _CoachIssueKind.techSupport ||
        kind == _CoachIssueKind.nonAccountGuide ||
        tip.contains('step') ||
        tip.contains('guide') ||
        tip.contains('troubleshoot')) {
      return [
        ScriptLine(
          category: 'empathy',
          choiceNumber: 1,
          title: 'Empathy',
          text:
              'I understand this is frustrating for you, $who. Thank you for explaining what is going on.',
        ),
        ScriptLine(
          category: 'guide',
          choiceNumber: 1,
          title: 'Guide next step',
          text:
              'Let us work through this one step at a time. First, please tell me what you have already tried.',
        ),
        ScriptLine(
          category: 'guide',
          choiceNumber: 2,
          title: 'Guide next step',
          text:
              'Here is the next step. Please try it, then tell me the result before we move on.',
        ),
      ];
    }

    if (kind == _CoachIssueKind.healthcare) {
      return [
        ScriptLine(
          category: 'healthcare',
          choiceNumber: 1,
          title: 'Healthcare care',
          text:
              'I will handle this carefully and follow our process so your information stays protected.',
        ),
        ScriptLine(
          category: 'clarify',
          choiceNumber: 1,
          title: 'Clarify',
          text: 'Just to confirm, you need help with $issue. Is that correct?',
        ),
        ScriptLine(
          category: 'guide',
          choiceNumber: 1,
          title: 'Guide next step',
          text:
              'Here is what we can do next. I will walk you through it one step at a time.',
        ),
      ];
    }

    if (kind == _CoachIssueKind.irate ||
        tip.contains('empathy') ||
        tip.contains('frustrat')) {
      return [
        ScriptLine(
          category: 'empathy',
          choiceNumber: 1,
          title: 'Empathy',
          text:
              'I understand this is hard for you, $who. I am sorry for the trouble, and I will take ownership of the next step.',
        ),
        ScriptLine(
          category: 'guide',
          choiceNumber: 1,
          title: 'Guide next step',
          text: 'Here is what I can do for you right now.',
        ),
      ];
    }

    if (kind == _CoachIssueKind.escalation || tip.contains('escalat')) {
      return [
        ScriptLine(
          category: 'escalate',
          choiceNumber: 1,
          title: 'Escalation',
          text:
              'I will escalate this with a clear summary and make sure the next team has what they need. You will receive a reference for follow-up.',
        ),
      ];
    }

    if (tip.contains('password reset') ||
        tip.contains('unlock steps') ||
        tip.contains('reset email')) {
      return [
        ScriptLine(
          category: 'guide',
          choiceNumber: 1,
          title: 'Next reset step',
          text:
              'Since the reset email is not arriving, try the forgot-password link again and check spam and promotions. Tell me if a new email appears within a few minutes.',
        ),
        ScriptLine(
          category: 'clarify',
          choiceNumber: 1,
          title: 'Confirm login id',
          text:
              'Please confirm the exact email or username on the account so we are resetting the right login.',
        ),
        ScriptLine(
          category: 'guide',
          choiceNumber: 2,
          title: 'Alternate path',
          text:
              'If no email arrives after one more try, I will open a secure account review so access can be restored without you sharing your password.',
        ),
      ];
    }
    if (tip.contains('refill') || tip.contains('prescription')) {
      return [
        ScriptLine(
          category: 'explain',
          choiceNumber: 1,
          title: 'Refill path',
          text:
              'I can explain the refill path and typical timing. I cannot prescribe or change the medication itself.',
        ),
        ScriptLine(
          category: 'clarify',
          choiceNumber: 1,
          title: 'Pharmacy details',
          text:
              'Which pharmacy is handling the refill, and when was the request submitted?',
        ),
        ScriptLine(
          category: 'guide',
          choiceNumber: 1,
          title: 'Timeline',
          text:
              'Based on the refill process, here is the expected processing time and what to do if it stays delayed.',
        ),
      ];
    }
    if (tip.contains('claim status') || tip.contains('missing documents')) {
      return [
        ScriptLine(
          category: 'guide',
          choiceNumber: 1,
          title: 'Explain status',
          text:
              'I can check the claim path with you. Please share the claim number or the date of service if you have it.',
        ),
        ScriptLine(
          category: 'explain',
          choiceNumber: 1,
          title: 'Process',
          text:
              'Claims usually move from received, to review, then to paid or denied. I will explain where yours stands in plain words.',
        ),
        ScriptLine(
          category: 'guide',
          choiceNumber: 2,
          title: 'Documents',
          text:
              'If anything is missing, I will list the documents still needed so the claim can continue.',
        ),
      ];
    }
    if (tip.contains('billing review') || tip.contains('unusual charges')) {
      return [
        ScriptLine(
          category: 'clarify',
          choiceNumber: 1,
          title: 'Bill period',
          text:
              'I will review this bill with you. Which billing period is higher than you expected?',
        ),
        ScriptLine(
          category: 'explain',
          choiceNumber: 1,
          title: 'Explain charges',
          text:
              'I will list each unusual charge in plain words and compare it with a typical month.',
        ),
        ScriptLine(
          category: 'guide',
          choiceNumber: 1,
          title: 'Next step',
          text:
              'After we identify the extra items, we can correct a billing error or explain a valid charge.',
        ),
      ];
    }
    if (tip.contains('verify') ||
        tip.contains('identity') ||
        tip.contains('account selected') ||
        tip.contains('confirm one detail')) {
      return [
        ScriptLine(
          category: 'verify',
          choiceNumber: 1,
          title: 'Confirm a detail',
          text:
              'For security, the last transaction I see is on file. Does that match what you expect?',
        ),
        ScriptLine(
          category: 'verify',
          choiceNumber: 2,
          title: 'Confirm name',
          text:
              'Thank you. May I confirm the name on the account before we continue?',
        ),
        ScriptLine(
          category: 'guide',
          choiceNumber: 1,
          title: 'Next tool step',
          text:
              'I will mark identity confirmed in Account Lookup, then explain what I found about $issue.',
        ),
      ];
    }
    if (tip.contains('recorded a service action') ||
        tip.contains('expected next step') ||
        tip.contains('while it is pending')) {
      return [
        ScriptLine(
          category: 'explain',
          choiceNumber: 1,
          title: 'Explain pending review',
          text:
              'I submitted a review for this charge. While it is pending, no further payment is required from you for this fee unless we confirm it is valid.',
        ),
        ScriptLine(
          category: 'confirm',
          choiceNumber: 1,
          title: 'Timeline',
          text:
              'The review team will examine it and you will get an update through your account contact channel. Is there anything else you need while that is in progress?',
        ),
        ScriptLine(
          category: 'guide',
          choiceNumber: 1,
          title: 'Next step',
          text:
              'If the fee is an error it can be corrected after review. If it is valid, they will explain why it applied.',
        ),
      ];
    }
    if (tip.contains('service request') ||
        tip.contains('review ticket') ||
        tip.contains('cannot force') ||
        tip.contains('file a service')) {
      return [
        ScriptLine(
          category: 'explain',
          choiceNumber: 1,
          title: 'Explain finding',
          text:
              'From the account, this looks related to $issue. I will explain it in plain words.',
        ),
        ScriptLine(
          category: 'guide',
          choiceNumber: 1,
          title: 'File request',
          text:
              'I cannot force an instant system change from here, but I can file a service request or review ticket for you now.',
        ),
        ScriptLine(
          category: 'confirm',
          choiceNumber: 1,
          title: 'Confirm path',
          text:
              'Would you like me to file that request now, or schedule a callback instead?',
        ),
      ];
    }
    if (tip.contains('stay with their concern') ||
        tip.contains('next helpful step') ||
        hasTraineeSpoken &&
            tip.contains('acknowledge') &&
            !tip.contains('open with')) {
      return [
        ScriptLine(
          category: 'guide',
          choiceNumber: 1,
          title: 'Next helpful step',
          text:
              'Here is the next step I recommend so we can move this forward on $issue.',
        ),
        ScriptLine(
          category: 'clarify',
          choiceNumber: 1,
          title: 'Clarify one point',
          text: 'Before I continue, can I confirm one detail about $issue?',
        ),
      ];
    }
    return [
      ScriptLine(
        category: 'empathy',
        choiceNumber: 1,
        title: 'Empathy',
        text:
            'I understand this is frustrating for you, $who. Thank you for explaining the situation.',
      ),
      ScriptLine(
        category: 'clarify',
        choiceNumber: 1,
        title: 'Clarify',
        text:
            'Just to make sure I understand, you need help with $issue. Is that correct?',
      ),
      ScriptLine(
        category: 'guide',
        choiceNumber: 1,
        title: 'Guide next step',
        text:
            'Here is what we can do next. I will walk you through it one step at a time.',
      ),
    ];
  }

  static String highlightTagForTip(String? tip) {
    if (tip == null || tip.isEmpty) return '';
    final t = tip.toLowerCase();
    if (t.contains('closing')) return 'closing';
    if (t.contains('opening') ||
        t.contains('greeting') ||
        t.contains('spiel') ||
        t.contains('open with your name') ||
        t.contains('already stated the issue') ||
        t.contains('acknowledge that specific')) {
      return 'opening';
    }
    if (t.contains('empathy') ||
        t.contains('frustrat') ||
        t.contains('acknowledge')) {
      return 'empathy';
    }
    if (t.contains('account') ||
        t.contains('verify') ||
        t.contains('identity')) {
      return 'verify';
    }
    if (t.contains('step') ||
        t.contains('guide') ||
        t.contains('troubleshoot')) {
      return 'guide';
    }
    if (t.contains('check') || t.contains('wait') || t.contains('looking')) {
      return 'wait';
    }
    if (t.contains('escalat') ||
        t.contains('handoff') ||
        t.contains('specialist'))
      return 'escalate';
    if (t.contains('explain') ||
        t.contains('system action') ||
        t.contains('what you did')) {
      return 'explain';
    }
    if (t.contains('escalat') ||
        t.contains('handoff') ||
        t.contains('specialist'))
      return 'escalate';
    if (t.contains('confirm') || t.contains('satisfied')) return 'confirm';
    return 'guide';
  }

  static bool isOffTopicReply(String text, String problem) {
    final t = text.toLowerCase().trim();
    if (t.isEmpty) return false;
    if (isNegativeAgentReply(t)) return false;
    if (t.length < 3) return true;
    // Identity / account verification is on-track for account cases.
    final verifyHints = [
      'verify',
      'identity',
      'security',
      'last transaction',
      'on file',
      'account number',
      'last four',
      'last 4',
      'date of birth',
      'full name',
      'correct?',
      'is that correct',
      'can you confirm',
      'please confirm',
    ];
    if (verifyHints.any((h) => t.contains(h))) return false;
    final noiseExact = {
      'asdf',
      'qwer',
      'test',
      'testing',
      'lorem',
      'hahaha',
      'lol',
      'idk',
      'idk random',
      '...',
      '???',
    };
    final tokensNoise = t
        .split(RegExp(r'[^a-z0-9]+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (tokensNoise.isNotEmpty &&
        tokensNoise.every((w) => noiseExact.contains(w))) {
      return true;
    }
    for (final n in ['asdf', 'qwer', 'lorem', 'hahaha', 'idk random']) {
      if (t.contains(n)) return true;
    }
    final supportHints = [
      'help',
      'account',
      'sorry',
      'thank',
      'please',
      'check',
      'verify',
      'identity',
      'security',
      'resolve',
      'issue',
      'problem',
      'step',
      'try',
      'can you',
      'let me',
      'i will',
      'i can',
      'understand',
      'confirm',
      'correct',
      'closing',
      'anything else',
      'support',
      'claim',
      'payment',
      'billing',
      'charge',
      'fee',
      'balance',
      'transaction',
      'statement',
      'card',
      'internet',
      'router',
      'password',
      'appointment',
      'escalate',
      'transfer',
      'contacting',
      'calling',
      'dealing',
      'how may',
      'how can',
      'trainix',
      'upgrade',
      'plan',
      'denied',
      'explain',
      'lookup',
      'on file',
      'last four',
      'last 4',
      'member',
      'name on',
    ];
    if (t.contains('thank you for contacting') ||
        t.contains('thank you for calling') ||
        t.contains('how may i help') ||
        t.contains('how can i help')) {
      return false;
    }
    for (final h in supportHints) {
      if (t.contains(h)) return false;
    }
    final tokens = t.split(RegExp(r'\s+')).where((w) => w.length > 2).toList();
    if (tokens.length <= 2 && !t.contains('?')) return true;
    return tokens.length >= 4 && !supportHints.any((h) => t.contains(h));
  }

  static List<Map<String, String>> escalationDepartments(String sector) {
    final s = sector.toLowerCase();
    final base = <Map<String, String>>[
      {
        'id': 'tier2',
        'label': 'Tier 2 Support',
        'when': 'Frontline steps failed or tools cannot complete the fix.',
        'means': 'Deeper product or account specialists who continue the case.',
      },
      {
        'id': 'retention',
        'label': 'Retention / Care',
        'when': 'Customer hardship, cancellation risk, or goodwill requests.',
        'means': 'Team that reviews exceptions, offers, and save options.',
      },
      {
        'id': 'fraud',
        'label': 'Fraud / Security',
        'when': 'Unauthorized access, stolen identity, or suspected fraud.',
        'means': 'Investigates security events and account takeover risk.',
      },
      {
        'id': 'billing',
        'label': 'Billing Operations',
        'when': 'Complex charges, refunds beyond policy, or invoice disputes.',
        'means': 'Handles billing corrections that need elevated authority.',
      },
    ];
    if (s.contains('tech') || s.contains('it')) {
      base.insert(0, {
        'id': 'data_recovery',
        'label': 'Data Recovery',
        'when':
            'Missing files, failed restores, or backup recovery beyond frontline.',
        'means': 'Specialists for recovery tooling and advanced restore paths.',
      });
    }
    if (s.contains('health')) {
      base.insert(0, {
        'id': 'claims',
        'label': 'Claims Review',
        'when': 'Denied claims, appeals, or accreditation exceptions.',
        'means': 'Reviews claim decisions and required documentation.',
      });
    }
    if (s.contains('telco') || s.contains('telecom')) {
      base.insert(0, {
        'id': 'network',
        'label': 'Network Operations',
        'when':
            'Area outages, persistent signal issues, or network-side faults.',
        'means': 'Checks tower, network, and provisioning issues.',
      });
    }
    return base;
  }

  static String buildEscalationMessage({
    required String departmentLabel,
    required String problemType,
    required String customerName,
    required String problem,
    String? accountId,
    String impact = '',
    String tried = '',
    String callback = '',
  }) {
    final who = customerName.isEmpty ? 'the customer' : customerName;
    final parts = <String>[
      'I am escalating your case to $departmentLabel regarding $problemType so a specialist can continue helping you.',
      'I have shared a summary of your issue about ${_shortIssue(problem)} under the name $who.',
    ];
    if (accountId != null && accountId.trim().isNotEmpty) {
      parts.add('I included account $accountId for the next agent.');
    }
    if (impact.trim().isNotEmpty) {
      parts.add('I noted the impact as: ${impact.trim()}.');
    }
    if (tried.trim().isNotEmpty) {
      parts.add('I also noted what was already tried: ${tried.trim()}.');
    }
    if (callback.trim().isNotEmpty) {
      parts.add('The best callback contact on file is ${callback.trim()}.');
    }
    parts.add(
      'You should receive a reference for follow-up. Is there anything else you want me to include before we end this chat?',
    );
    return parts.join(' ');
  }

  static List<ScriptLine> escalationScriptLines({
    required String customerName,
    String? accountId,
    required String problem,
  }) {
    final who = customerName.isEmpty ? 'you' : customerName;
    final issue = _shortIssue(problem);
    return [
      ScriptLine(
        category: 'escalate',
        choiceNumber: 1,
        title: 'Explain escalation',
        text:
            'This needs a specialist team. I cannot complete the full resolution at my level, but I will escalate it with a clear summary so the next agent can continue without making you repeat everything.',
      ),
      ScriptLine(
        category: 'escalate',
        choiceNumber: 2,
        title: 'Collect handoff details',
        text:
            'Before I escalate, I need a few details for the next agent: the best callback number, the main impact on you, and anything already tried on $issue.',
      ),
      ScriptLine(
        category: 'escalate',
        choiceNumber: 3,
        title: 'Confirm escalation',
        text:
            'Thank you, $who. I am escalating this now with your details and a case summary. You will receive a reference for follow-up. Is there anything else to include for the next agent?',
      ),
    ];
  }

  static List<ScriptLine> fallbackGuidanceLines({
    required String sector,
    required String problem,
    required String emotion,
    required String customerName,
    String lastCustomerMessage = '',
    String lastTraineeMessage = '',
  }) {
    final who = customerName.isEmpty ? 'there' : customerName;
    final issue = _shortIssue(problem);
    final s = sector.toLowerCase();
    final p = problem.toLowerCase();
    final lastCust = lastCustomerMessage.toLowerCase();
    final context = '$p $lastCust';

    final lines = <ScriptLine>[];

    lines.add(
      ScriptLine(
        category: 'say',
        choiceNumber: 1,
        title: 'What to say',
        text:
            'I am sorry this has been difficult for you, $who. Thank you for explaining the situation with $issue. I am here to help.',
      ),
    );

    final isPlanUpgrade =
        context.contains('upgrade') ||
        context.contains('plan change') ||
        context.contains('change my plan') ||
        (context.contains('denied') && context.contains('plan')) ||
        (context.contains('blocked') && context.contains('plan'));
    final isSignal =
        context.contains('signal') ||
        context.contains('dropped') ||
        context.contains('no service') ||
        context.contains('bars') ||
        context.contains('coverage') ||
        context.contains('mobile data') ||
        context.contains('no data') ||
        (context.contains('sim') && !context.contains('simple'));
    final isBill =
        context.contains('bill') ||
        context.contains('overcharged') ||
        context.contains('roaming') ||
        context.contains('invoice');
    final isPort =
        context.contains('porting') ||
        context.contains('port my') ||
        context.contains('sim swap') ||
        context.contains('activate sim');
    final isFiles =
        context.contains('file') ||
        context.contains('missing') ||
        context.contains('deleted') ||
        context.contains('documents') ||
        (context.contains('reset') && context.contains('file'));
    final isVirus =
        context.contains('virus') ||
        context.contains('malware') ||
        context.contains('security alert') ||
        (context.contains('security') && context.contains('alert')) ||
        context.contains('pop-up') ||
        context.contains('popup') ||
        context.contains('infected');
    final isBoot =
        context.contains('will not start') ||
        context.contains("won't start") ||
        context.contains('wont start') ||
        context.contains('blue screen') ||
        context.contains('black screen') ||
        context.contains('boot');
    final isEmail =
        context.contains('email') ||
        context.contains('outlook') ||
        context.contains('mailbox');
    final isPayment =
        context.contains('payment') ||
        context.contains('charge') ||
        context.contains('loan') ||
        context.contains('restructure') ||
        context.contains('hardship') ||
        context.contains('billing') ||
        context.contains('card declined') ||
        context.contains('declined');
    final isLocked =
        context.contains('locked') ||
        context.contains('locked out') ||
        context.contains('cannot sign in');
    final isRetailDamage =
        context.contains('damaged') ||
        context.contains('wrong item') ||
        context.contains('broken item') ||
        context.contains('incorrect item');
    final isRetailShip =
        context.contains('tracking') ||
        context.contains('delivery') ||
        context.contains('missing package') ||
        context.contains('cancel order') ||
        context.contains('never arrived');
    final isHealthPortal =
        context.contains('portal') ||
        context.contains('health app') ||
        context.contains('cannot login');
    final isHealthBill =
        context.contains('medical bill') ||
        context.contains('statement') ||
        context.contains('copay') ||
        context.contains('eob');

    if (isPlanUpgrade || (s.contains('telco') && context.contains('denied'))) {
      lines.addAll([
        ScriptLine(
          category: 'clarify',
          choiceNumber: 1,
          title: 'Clarify',
          text:
              'Just to confirm, you tried to upgrade or change your plan online and it was denied without a clear reason. Is that right?',
        ),
        ScriptLine(
          category: 'step',
          choiceNumber: 1,
          title: 'Current step',
          text:
              'Ask which plan they wanted, when they tried, and any error or message shown on screen.',
        ),
        ScriptLine(
          category: 'step',
          choiceNumber: 2,
          title: 'Next step',
          text:
              'Check eligibility factors you can see in tools, then explain the blocker in plain words or escalate if the denial is system-side.',
        ),
        ScriptLine(
          category: 'say',
          choiceNumber: 2,
          title: 'What to say',
          text:
              'I understand this is about a denied plan upgrade, not a network or signal issue. Let me check what blocked the change.',
        ),
      ]);
    } else if (isBill) {
      lines.addAll([
        ScriptLine(
          category: 'clarify',
          choiceNumber: 1,
          title: 'Clarify',
          text:
              'Which billing period looks wrong, and which charge amount is unexpected?',
        ),
        ScriptLine(
          category: 'step',
          choiceNumber: 1,
          title: 'Current step',
          text:
              'Review plan, add-ons, and roaming or overage lines, then explain each unusual item simply.',
        ),
        ScriptLine(
          category: 'step',
          choiceNumber: 2,
          title: 'Next step',
          text:
              'If a correction needs elevated authority, prepare a billing handoff with the disputed lines.',
        ),
      ]);
    } else if (isPort) {
      lines.addAll([
        ScriptLine(
          category: 'clarify',
          choiceNumber: 1,
          title: 'Clarify',
          text:
              'Is this a number port, a SIM activation, or a SIM swap, and what error appeared?',
        ),
        ScriptLine(
          category: 'step',
          choiceNumber: 1,
          title: 'Current step',
          text:
              'Verify identity, then confirm where the port or activation stopped.',
        ),
        ScriptLine(
          category: 'step',
          choiceNumber: 2,
          title: 'Next step',
          text:
              'Escalate provisioning if the process is stuck system-side after basic checks.',
        ),
      ]);
    } else if (isSignal) {
      lines.addAll([
        ScriptLine(
          category: 'clarify',
          choiceNumber: 1,
          title: 'Clarify',
          text:
              'Are you seeing this on calls, mobile data, or both, and does it happen only in certain locations?',
        ),
        ScriptLine(
          category: 'step',
          choiceNumber: 1,
          title: 'Current step',
          text:
              'Confirm whether the issue is signal, data, SIM, or a specific service feature.',
        ),
        ScriptLine(
          category: 'step',
          choiceNumber: 2,
          title: 'Next step',
          text:
              'Walk them through one network reset step, then retest before escalating.',
        ),
      ]);
    } else if (isVirus) {
      lines.addAll([
        ScriptLine(
          category: 'clarify',
          choiceNumber: 1,
          title: 'Clarify',
          text:
              'Is this on a phone or computer, and what exact wording does the security alert show?',
        ),
        ScriptLine(
          category: 'step',
          choiceNumber: 1,
          title: 'Current step',
          text:
              'Do not enter passwords or pay any pop-up. Close the alert and note the exact message text.',
        ),
        ScriptLine(
          category: 'step',
          choiceNumber: 2,
          title: 'Next step',
          text:
              'Run a scan with the built-in security app or trusted antivirus, then restart the device and check if the alert returns.',
        ),
        ScriptLine(
          category: 'step',
          choiceNumber: 3,
          title: 'Next step',
          text:
              'If the alert remains after uninstalling the suspected app and scanning, escalate with device type, alert text, and steps already tried.',
        ),
        ScriptLine(
          category: 'say',
          choiceNumber: 2,
          title: 'What to say',
          text:
              'Thanks for checking. Since the alert is still showing after uninstalling, let us run a trusted security scan next and avoid any pop-up that asks for payment.',
        ),
      ]);
    } else if (isBoot) {
      lines.addAll([
        ScriptLine(
          category: 'clarify',
          choiceNumber: 1,
          title: 'Clarify',
          text:
              'Does the device power on at all, and is there any exact error text on screen?',
        ),
        ScriptLine(
          category: 'step',
          choiceNumber: 1,
          title: 'Current step',
          text:
              'Try only a forced restart first and report what appears afterward.',
        ),
        ScriptLine(
          category: 'step',
          choiceNumber: 2,
          title: 'Next step',
          text:
              'If it still will not boot, escalate with device model and the error text.',
        ),
      ]);
    } else if (isEmail) {
      lines.addAll([
        ScriptLine(
          category: 'clarify',
          choiceNumber: 1,
          title: 'Clarify',
          text:
              'Which email app or site is affected, and what exact error do you see?',
        ),
        ScriptLine(
          category: 'step',
          choiceNumber: 1,
          title: 'Current step',
          text:
              'Confirm network works, then use only the official sign-in or reset path.',
        ),
        ScriptLine(
          category: 'step',
          choiceNumber: 2,
          title: 'Next step',
          text:
              'Escalate with the error text if access stays blocked after the official reset.',
        ),
      ]);
    } else if (isFiles) {
      lines.addAll([
        ScriptLine(
          category: 'clarify',
          choiceNumber: 1,
          title: 'Clarify',
          text:
              'Which device is affected, and did this start right after an update, reset, or install?',
        ),
        ScriptLine(
          category: 'step',
          choiceNumber: 1,
          title: 'Current step',
          text:
              'Identify what changed right before the problem and what is missing now.',
        ),
        ScriptLine(
          category: 'step',
          choiceNumber: 2,
          title: 'Next step',
          text:
              'Guide one recovery check at a time, then escalate if files cannot be restored.',
        ),
      ]);
    } else if (s.contains('tech') || s.contains('it')) {
      lines.addAll([
        ScriptLine(
          category: 'clarify',
          choiceNumber: 1,
          title: 'Clarify',
          text:
              'Which device or app is affected, and what happens when the issue appears?',
        ),
        ScriptLine(
          category: 'step',
          choiceNumber: 1,
          title: 'Current step',
          text:
              'Confirm the exact error or behavior, then try one basic safe step and report the result.',
        ),
        ScriptLine(
          category: 'step',
          choiceNumber: 2,
          title: 'Next step',
          text:
              'If the issue continues after basic checks, escalate with device details and what was already tried.',
        ),
      ]);
    } else if (isPayment || s.contains('finance')) {
      lines.addAll([
        ScriptLine(
          category: 'clarify',
          choiceNumber: 1,
          title: 'Clarify',
          text:
              'Is this about a charge, payment, account access, or a loan concern?',
        ),
        ScriptLine(
          category: 'step',
          choiceNumber: 1,
          title: 'Current step',
          text:
              'Verify identity when needed, then confirm amount, date, or product involved.',
        ),
        ScriptLine(
          category: 'step',
          choiceNumber: 2,
          title: 'Next step',
          text:
              'Explain what you can do at frontline level, or prepare a specialist handoff if approval is required.',
        ),
      ]);
    } else if (isHealthPortal || isHealthBill || s.contains('health')) {
      if (isHealthPortal) {
        lines.addAll([
          ScriptLine(
            category: 'clarify',
            choiceNumber: 1,
            title: 'Clarify',
            text:
                'Which portal or app is blocked, and what exact error appears at sign-in?',
          ),
          ScriptLine(
            category: 'step',
            choiceNumber: 1,
            title: 'Current step',
            text:
                'Guide the official password reset only. Do not ask for the full password in chat.',
          ),
          ScriptLine(
            category: 'step',
            choiceNumber: 2,
            title: 'Next step',
            text:
                'Escalate if the account remains locked after the official reset path.',
          ),
        ]);
      } else if (isHealthBill) {
        lines.addAll([
          ScriptLine(
            category: 'clarify',
            choiceNumber: 1,
            title: 'Clarify',
            text:
                'What date of service and amount on the statement looks wrong?',
          ),
          ScriptLine(
            category: 'step',
            choiceNumber: 1,
            title: 'Current step',
            text:
                'Verify identity, then explain patient share versus insurance share in plain words.',
          ),
          ScriptLine(
            category: 'step',
            choiceNumber: 2,
            title: 'Next step',
            text:
                'Escalate billing or claims review when an adjustment or appeal is required.',
          ),
        ]);
      } else {
        lines.addAll([
          ScriptLine(
            category: 'clarify',
            choiceNumber: 1,
            title: 'Clarify',
            text:
                'Is this about an appointment, claim, billing, or account access, and do you have any reference numbers?',
          ),
          ScriptLine(
            category: 'step',
            choiceNumber: 1,
            title: 'Current step',
            text:
                'Verify identity when required, then confirm the exact request in plain words.',
          ),
          ScriptLine(
            category: 'step',
            choiceNumber: 2,
            title: 'Next step',
            text:
                'Explain the next policy-safe step, or escalate appeals and exceptions.',
          ),
        ]);
      }
    } else if (isRetailDamage ||
        isRetailShip ||
        s.contains('retail') ||
        s.contains('ecommerce')) {
      lines.addAll([
        ScriptLine(
          category: 'clarify',
          choiceNumber: 1,
          title: 'Clarify',
          text: isRetailDamage
              ? 'Do you have the order number, and is the item damaged or the wrong product?'
              : 'Do you have the order number, and is this about tracking, a missing package, or a cancellation?',
        ),
        ScriptLine(
          category: 'step',
          choiceNumber: 1,
          title: 'Current step',
          text:
              'Confirm order status in plain words and the next policy-safe option.',
        ),
        ScriptLine(
          category: 'step',
          choiceNumber: 2,
          title: 'Next step',
          text:
              'Escalate fulfillment or carrier exceptions when tools cannot complete the fix.',
        ),
      ]);
    } else if (isLocked) {
      lines.addAll([
        ScriptLine(
          category: 'clarify',
          choiceNumber: 1,
          title: 'Clarify',
          text:
              'Is the account locked after failed sign-in, a fraud alert, or a password reset issue?',
        ),
        ScriptLine(
          category: 'step',
          choiceNumber: 1,
          title: 'Current step',
          text:
              'Verify identity with approved checks, then use only the official unlock path.',
        ),
        ScriptLine(
          category: 'step',
          choiceNumber: 2,
          title: 'Next step',
          text:
              'Escalate security if the account stays locked after official steps.',
        ),
      ]);
    } else {
      lines.addAll([
        ScriptLine(
          category: 'clarify',
          choiceNumber: 1,
          title: 'Clarify',
          text:
              'So I can help correctly, when did this start and what exactly are you seeing right now?',
        ),
        ScriptLine(
          category: 'step',
          choiceNumber: 1,
          title: 'Current step',
          text:
              'Restate their goal in one short sentence, then take only the first safe check.',
        ),
        ScriptLine(
          category: 'step',
          choiceNumber: 2,
          title: 'Next step',
          text:
              'If frontline steps cannot fix it, collect details and escalate with a clear summary.',
        ),
      ]);
    }

    return lines;
  }

  static List<ScriptLine> filterAlreadyUsedLines(
    List<ScriptLine> lines,
    String lastTraineeMessage, {
    List<String> allTraineeMessages = const [],
  }) {
    final corpus = <String>[];
    for (final m in allTraineeMessages) {
      var s = m.toLowerCase().trim();
      if (s.startsWith('[agent]:')) {
        s = s.replaceFirst('[agent]:', '').trim();
      }
      if (s.isNotEmpty) corpus.add(s);
    }
    var last = lastTraineeMessage.toLowerCase().trim();
    if (last.startsWith('[agent]:')) {
      last = last.replaceFirst('[agent]:', '').trim();
    }
    if (last.isNotEmpty) corpus.add(last);
    if (corpus.isEmpty) return lines;
    final kept = <ScriptLine>[];
    for (final line in lines) {
      final text = line.text.toLowerCase().trim();
      if (text.isEmpty) continue;
      var used = false;
      for (final said in corpus) {
        if (said.contains(text) || text.contains(said)) {
          used = true;
          break;
        }
        if (_roughOverlap(said, text) >= 0.35) {
          used = true;
          break;
        }
        // Shared long phrase (first 40 chars)
        final preview = text.length > 40 ? text.substring(0, 40) : text;
        if (preview.length > 12 && said.contains(preview)) {
          used = true;
          break;
        }
      }
      if (used) continue;
      kept.add(line);
    }
    if (kept.isNotEmpty) return kept;
    // Never re-show the same used bank; fall back empty so checklist can supply alternates
    return const [];
  }

  static double roughOverlapPublic(String a, String b) => _roughOverlap(a, b);

  static double _roughOverlap(String a, String b) {
    final wa = a.split(RegExp(r'\s+')).where((w) => w.length > 3).toSet();
    final wb = b.split(RegExp(r'\s+')).where((w) => w.length > 3).toSet();
    if (wa.isEmpty || wb.isEmpty) return 0;
    final inter = wa.intersection(wb).length;
    return inter / (wa.length < wb.length ? wa.length : wb.length);
  }

  static String suggestionForOffTopic() {
    return 'Stay on the customer issue. Acknowledge their concern, ask a clarifying question, or take the next helpful step.';
  }

  static List<ScriptLine> guardExamples(
    List<ScriptLine> xs, {
    required SimulationStage stage,
    required bool toolWorkDone,
  }) {
    final filtered = filterExamplesForStage(
      lines: xs,
      stage: stage.key,
      toolWorkDone: toolWorkDone,
    );
    if (filtered.isNotEmpty) return filtered;
    return fallbackFor(stage);
  }

  static List<ScriptLine> fallbackFor(SimulationStage stage) {
    switch (stage) {
      case SimulationStage.opening:
        return [
          const ScriptLine(
            category: 'opening',
            choiceNumber: 1,
            title: 'Opening',
            text:
                'Thank you for contacting Trainix Support. I understand the issue you described, and I am here to help.',
          ),
        ];
      case SimulationStage.exploring:
        return [
          const ScriptLine(
            category: 'clarify',
            choiceNumber: 1,
            title: 'Clarify',
            text: 'Could you tell me a little more about what happened?',
          ),
        ];
      case SimulationStage.acting:
        return [
          const ScriptLine(
            category: 'guide',
            choiceNumber: 1,
            title: 'Next step',
            text:
                'Here is what I found, in simple terms. The next step I can take is to file a request for you.',
          ),
        ];
      case SimulationStage.escalating:
        return [
          const ScriptLine(
            category: 'escalate',
            choiceNumber: 1,
            title: 'Handoff',
            text: 'I am handing this to a senior colleague with these details.',
          ),
        ];
      case SimulationStage.closing:
        return [
          const ScriptLine(
            category: 'closing',
            choiceNumber: 1,
            title: 'Closing',
            text:
                'Is there anything else I can help you with today? Thank you for calling.',
          ),
        ];
      default:
        return const [];
    }
  }

  static bool claimsActionTaken(String text) {
    final t = text.toLowerCase();
    if (t.contains('i finished the needed action')) return true;
    if (t.contains('i have processed the fix')) return true;
    if (t.contains('i applied the correction')) return true;
    if (t.contains('i have processed')) return true;
    if (t.contains('processed the fix')) return true;
    if (t.contains('finished the needed')) return true;
    if (RegExp(
      r"\bi (have |'ve |already )?(finished|completed|processed|applied|fixed|resolved)\b",
    ).hasMatch(t)) {
      return true;
    }
    if (RegExp(
      r'\bhas been (processed|applied|fixed|resolved|completed)\b',
    ).hasMatch(t)) {
      return true;
    }
    return false;
  }

  static List<ScriptLine> filterExamplesForStage({
    required List<ScriptLine> lines,
    required String stage,
    required bool toolWorkDone,
  }) {
    final allowedCats = <String>{};
    switch (stage) {
      case 'wait':
        return const [];
      case 'open':
        allowedCats.addAll(['opening', 'empathy', 'say']);
        break;
      case 'explore':
        allowedCats.addAll([
          'opening',
          'empathy',
          'clarify',
          'verify',
          'say',
          'guide',
        ]);
        break;
      case 'act':
        allowedCats.addAll([
          'explain',
          'guide',
          'clarify',
          'verify',
          'say',
          'request',
          'confirm',
        ]);
        break;
      case 'escalate':
        allowedCats.addAll(['escalate', 'handoff', 'guide']);
        break;
      case 'close':
        allowedCats.addAll(['closing', 'confirm', 'say']);
        break;
      default:
        allowedCats.addAll([
          'opening',
          'empathy',
          'clarify',
          'verify',
          'guide',
          'explain',
          'say',
        ]);
    }
    final out = <ScriptLine>[];
    for (final line in lines) {
      if (!toolWorkDone && claimsActionTaken(line.text)) continue;
      if (allowedCats.isNotEmpty && !allowedCats.contains(line.category)) {
        // allow say/guide when exploring or acting with soft match
        if (stage == 'explore' &&
            (line.category == 'say' || line.category == 'guide')) {
          out.add(line);
        } else if (stage == 'act') {
          out.add(line);
        }
        continue;
      }
      out.add(line);
    }
    if (out.isEmpty) {
      switch (stage) {
        case 'open':
          return [
            const ScriptLine(
              category: 'opening',
              choiceNumber: 1,
              title: 'Opening',
              text:
                  'Thank you for contacting Trainix Support. I understand the issue you described, and I am here to help.',
            ),
          ];
        case 'explore':
          return [
            const ScriptLine(
              category: 'clarify',
              choiceNumber: 1,
              title: 'Clarify',
              text:
                  'Could you tell me a little more about what happened so I can help with the next step?',
            ),
          ];
        case 'act':
          return [
            const ScriptLine(
              category: 'guide',
              choiceNumber: 1,
              title: 'Next step',
              text:
                  'Here is what I can do next. I will explain it in plain words and confirm it works for you.',
            ),
          ];
        default:
          return lines;
      }
    }
    return out;
  }
}

class ScriptLine {
  final String category;
  final int choiceNumber;
  final String title;
  final String text;

  String get tag => category;

  const ScriptLine({
    required this.category,
    required this.choiceNumber,
    required this.title,
    required this.text,
  });
}
