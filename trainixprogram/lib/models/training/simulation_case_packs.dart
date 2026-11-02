import 'dart:math';

class SimulationCasePack {
  final String id;
  final String sector;
  final String name;
  final String emotion;
  final String problem;
  final String openingReply;
  final bool needsAccount;
  final List<String> acknowledgeReplies;
  final List<String> verifyReplies;
  final List<String> fixReplies;
  final List<String> escalateReplies;
  final List<String> closeReplies;
  final List<String> otherReplies;

  const SimulationCasePack({
    required this.id,
    required this.sector,
    required this.name,
    required this.emotion,
    required this.problem,
    required this.openingReply,
    this.needsAccount = true,
    required this.acknowledgeReplies,
    required this.verifyReplies,
    required this.fixReplies,
    required this.escalateReplies,
    required this.closeReplies,
    required this.otherReplies,
  });
}

class SimulationCaseLibrary {
  static final _random = Random();
  static final Map<String, String> _lastPackIdBySector = {};
  static final List<String> _recentPackIds = [];

  static const packs = <SimulationCasePack>[
    SimulationCasePack(
      id: 'telco_upgrade_denied',
      sector: 'Telco',
      name: 'Bryan Custodio',
      emotion: 'Frustrated',
      problem: 'Plan upgrade was denied in the app with no clear explanation.',
      openingReply:
          'Hi, my plan upgrade was denied in the app with no explanation. I need to know why and what I can do next.',
      acknowledgeReplies: [
        'Thanks. Yes, the upgrade failed yesterday and I still do not know why.',
        'Okay. I just want a clear reason and the next step to fix it.',
      ],
      verifyReplies: [
        'My account is under Bryan Custodio. I can confirm the last four digits if needed.',
        'Yes, that is my account. The denial showed up after I submitted the upgrade request.',
      ],
      fixReplies: [
        'If you can submit a review or tell me the eligibility issue, that helps. What happens next?',
        'Alright. Please confirm whether the upgrade can be reprocessed or if I need a different plan.',
      ],
      escalateReplies: [
        'If this needs another team, please escalate and tell me what to expect.',
      ],
      closeReplies: [
        'That helps for now. Thank you.',
        'Okay, I will wait for that update. Thanks for the help.',
      ],
      otherReplies: ['Can you stay on this upgrade denial with me?'],
    ),
    SimulationCasePack(
      id: 'telco_outage',
      sector: 'Telco',
      name: 'Grace Villanueva',
      emotion: 'Impatient',
      problem: 'Home internet is down while neighbors still have service.',
      openingReply:
          'My home internet has been down for hours while my neighbors still have service.',
      acknowledgeReplies: [
        'Yes, it dropped this morning and has not come back.',
        'Thanks. I already restarted the modem twice.',
      ],
      verifyReplies: [
        'Service address is under Grace Villanueva. Modem lights are red on internet.',
        'Yes, that is my account. Outage map shows clear but I am still offline.',
      ],
      fixReplies: [
        'If you can run a line test or open a ticket, please do that.',
        'Okay, what should I check on the modem next?',
      ],
      escalateReplies: [
        'Please escalate to field support if remote checks fail.',
      ],
      closeReplies: ['Alright, I will wait for the ticket update. Thanks.'],
      otherReplies: ['I still need my internet restored.'],
    ),
    SimulationCasePack(
      id: 'telco_bill_spike',
      sector: 'Telco',
      name: 'Ramon Aquino',
      emotion: 'Confused',
      problem: 'This month bill is higher than usual with no clear add-on.',
      openingReply:
          'Hi, my bill jumped this month and I do not see why. Can you explain the charges?',
      acknowledgeReplies: [
        'Yes, it is higher than last month and nothing looks different on my plan.',
        'Thanks. I mainly need the extra charge explained.',
      ],
      verifyReplies: [
        'Account is under Ramon Aquino. I can confirm the mobile number on the bill.',
        'Yes, that is my line. The spike started on this billing cycle.',
      ],
      fixReplies: [
        'If there was a one-time charge, please remove or credit it if it is wrong.',
        'Okay, please walk me through each extra line item.',
      ],
      escalateReplies: [
        'Please escalate billing review if the charge cannot be explained here.',
      ],
      closeReplies: ['That clears it up. Thank you.'],
      otherReplies: ['I still need the bill increase explained.'],
    ),
    SimulationCasePack(
      id: 'tech_virus_alert',
      sector: 'Tech Support',
      name: 'Rafael Ocampo',
      emotion: 'Concerned',
      problem: 'Security alert about a possible virus on the customer device.',
      openingReply:
          'Hi, I just got a security alert about a possible virus on my device. I am concerned and need help figuring out what is going on.',
      acknowledgeReplies: [
        'Yes, the alert keeps showing and I am not sure if it is real.',
        'Thanks. I have not clicked anything odd that I know of, but the warning is still there.',
      ],
      verifyReplies: [
        'It is my personal laptop. The alert mentions a threat and asks me to scan.',
        'Account is under Rafael Ocampo. The alert appeared this morning after I opened the browser.',
      ],
      fixReplies: [
        'I can try those steps. Should I run the built-in scan first?',
        'Okay, I will avoid unknown pop-ups and run the scan. What should I look for after?',
      ],
      escalateReplies: [
        'If this needs a specialist, please escalate and tell me what details they need.',
      ],
      closeReplies: ['That makes sense. I will follow those steps. Thank you.'],
      otherReplies: ['I still need help with the security alert on my device.'],
    ),
    SimulationCasePack(
      id: 'tech_password_lock',
      sector: 'Tech Support',
      name: 'Michelle Gonzales',
      emotion: 'Frustrated',
      problem: 'Cannot sign in after a password reset email failed.',
      openingReply:
          'I cannot sign in. The password reset email never arrived and I am locked out.',
      acknowledgeReplies: [
        'Yes, I already tried resending the email twice.',
        'Thanks. I still cannot get into the account.',
      ],
      verifyReplies: [
        'The account is under Michelle Gonzales. I can confirm the email on file.',
        'Yes, that is my username. The reset link never showed up.',
      ],
      fixReplies: [
        'If you can trigger a fresh reset or unlock the account, please do that.',
        'Okay, I will try the new steps. How long should the email take?',
      ],
      escalateReplies: ['Please escalate if unlock needs another team.'],
      closeReplies: ['That helps. I will try again now. Thank you.'],
      otherReplies: ['I still need help signing in.'],
    ),
    SimulationCasePack(
      id: 'tech_slow_app',
      sector: 'Tech Support',
      name: 'Jerome Aguilar',
      emotion: 'Impatient',
      problem: 'App keeps freezing when opening recent files.',
      openingReply:
          'The app freezes every time I open recent files. I need this working today.',
      acknowledgeReplies: [
        'Yes, it hangs and then I have to force close it.',
        'Thanks. It started after the last update.',
      ],
      verifyReplies: [
        'Account is under Jerome Aguilar. I am on the desktop app.',
        'Yes, that is my workspace. Recent files is the only screen that freezes.',
      ],
      fixReplies: [
        'I can clear cache if that helps. What should I try first?',
        'Okay, I will try that step and tell you what happens.',
      ],
      escalateReplies: [
        'Please escalate if this is a known bug beyond basic fixes.',
      ],
      closeReplies: [
        'Alright, I will try that and follow up if it fails. Thanks.',
      ],
      otherReplies: ['I still need the freeze fixed.'],
    ),
    SimulationCasePack(
      id: 'finance_pending_card',
      sector: 'Finance',
      name: 'Daniel Cruz',
      emotion: 'Worried',
      problem:
          'Card payment shows pending and customer worries about a double charge.',
      openingReply:
          'Hello, my card payment is still pending and I am worried I might get charged twice.',
      acknowledgeReplies: [
        'Yes, it has been pending since yesterday and the amount still looks held.',
        'Thanks. I just want to know if I will be charged twice.',
      ],
      verifyReplies: [
        'I can confirm the last four digits of the card if you need them.',
        'The payment was for my monthly bill. It still shows pending in the app.',
        'Account is under Daniel Cruz. Last four digits are fine to verify.',
      ],
      fixReplies: [
        'If you can check the transaction status, that would help. Should I wait or retry?',
        'Okay. Please tell me whether the pending charge will clear or post once.',
      ],
      escalateReplies: [
        'If this needs payments review, please escalate and share what happens next.',
      ],
      closeReplies: [
        'Understood. I will monitor it as you said. Thank you.',
        'That clears it up for now. Thanks for checking.',
      ],
      otherReplies: ['I still need help with the pending card payment.'],
    ),
    SimulationCasePack(
      id: 'finance_wrong_fee',
      sector: 'Finance',
      name: 'Bianca Fernandez',
      emotion: 'Frustrated',
      problem: 'Unexpected service fee appeared on the statement.',
      openingReply:
          'There is an unexpected service fee on my statement and I did not approve any extra service.',
      acknowledgeReplies: [
        'Yes, the fee is new and I do not recognize it.',
        'Thanks. I want it explained or removed if it is wrong.',
      ],
      verifyReplies: [
        'Account is under Bianca Fernandez. I can confirm the statement date.',
        'Yes, that is my account. The fee posted this cycle.',
      ],
      fixReplies: [
        'If it is an error, please reverse it. If it is valid, explain why it applied.',
        'Okay, what is the next step while the fee is under review?',
      ],
      escalateReplies: [
        'Please escalate fee disputes if you cannot adjust it here.',
      ],
      closeReplies: ['That explanation helps. Thank you.'],
      otherReplies: ['I still need the unexpected fee handled.'],
    ),
    SimulationCasePack(
      id: 'finance_transfer_delay',
      sector: 'Finance',
      name: 'Vincent Navarro',
      emotion: 'Anxious',
      problem: 'Fund transfer has not arrived after the stated timeline.',
      openingReply:
          'I sent a transfer that should have arrived already, but the money is still not there.',
      acknowledgeReplies: [
        'Yes, the expected time already passed and neither side shows completion.',
        'Thanks. I need to know where the funds are.',
      ],
      verifyReplies: [
        'Account is under Vincent Navarro. I can share the transfer reference.',
        'Yes, that is my account. The amount and date match what I sent.',
      ],
      fixReplies: [
        'Please trace the transfer and tell me if it is still processing or failed.',
        'Okay, what should I do while we wait for the update?',
      ],
      escalateReplies: [
        'Please escalate to payments operations if the transfer is stuck.',
      ],
      closeReplies: ['I will wait for that status. Thank you.'],
      otherReplies: ['I still need the transfer status.'],
    ),
    SimulationCasePack(
      id: 'health_appointment',
      sector: 'Healthcare',
      name: 'Angela Reyes',
      emotion: 'Anxious',
      problem:
          'Customer needs to confirm an appointment and is unsure about preparation steps.',
      openingReply:
          'Hi, I need help confirming my appointment and what I should prepare before I arrive.',
      acknowledgeReplies: [
        'Yes, I am not sure if the appointment is still confirmed.',
        'Thanks. I mainly need the schedule and any prep instructions.',
      ],
      verifyReplies: [
        'The appointment is under Angela Reyes. I can verify my date of birth if needed.',
        'Yes, that is my record. I booked it last week.',
      ],
      fixReplies: [
        'If you can confirm the time and what to bring, that would help.',
        'Okay, please tell me the preparation steps clearly.',
      ],
      escalateReplies: [
        'If scheduling has to handle this, please transfer me and tell me what to expect.',
      ],
      closeReplies: [
        'That is all I needed. Thank you.',
        'Great, I will follow those instructions. Thanks.',
      ],
      otherReplies: ['I still need the appointment confirmation details.'],
    ),
    SimulationCasePack(
      id: 'health_claim_status',
      sector: 'Healthcare',
      name: 'Paolo Mendoza',
      emotion: 'Concerned',
      problem: 'Customer needs an update on a submitted claim status.',
      openingReply:
          'Hi, I submitted a claim last week and I still do not see an update. Can you check the status?',
      acknowledgeReplies: [
        'Yes, it was submitted online and I have the reference saved.',
        'Thanks. I mainly need to know if it is processing or if something is missing.',
      ],
      verifyReplies: [
        'The claim is under Paolo Mendoza. I can confirm the reference number.',
        'Yes, that is my member record. The claim was for a clinic visit.',
      ],
      fixReplies: [
        'If you can share the current status and any missing document, that helps.',
        'Okay, please tell me the next step while we wait for the update.',
      ],
      escalateReplies: [
        'Please escalate to claims review if the status is stuck.',
      ],
      closeReplies: ['That is the update I needed. Thank you.'],
      otherReplies: ['I still need the claim status update.'],
    ),
    SimulationCasePack(
      id: 'health_rx_refill',
      sector: 'Healthcare',
      name: 'Katrina Domingo',
      emotion: 'Worried',
      problem: 'Prescription refill is delayed and customer needs guidance.',
      openingReply:
          'My prescription refill is delayed and I am not sure what to do next.',
      acknowledgeReplies: [
        'Yes, the pharmacy said it is still pending authorization.',
        'Thanks. I need a clear next step so I do not run out.',
      ],
      verifyReplies: [
        'The record is under Katrina Domingo. I can confirm the medication name.',
        'Yes, that is my member profile. The refill was requested three days ago.',
      ],
      fixReplies: [
        'Please check authorization status and tell me if the doctor still needs to act.',
        'Okay, what should I do while waiting for the pharmacy?',
      ],
      escalateReplies: [
        'Please escalate if authorization is stuck beyond normal time.',
      ],
      closeReplies: ['I understand the next step. Thank you.'],
      otherReplies: ['I still need help with the delayed refill.'],
    ),
  ];

  static SimulationCasePack? pickForSector(String sector) {
    final key = sector.toLowerCase();
    var matches = packs.where((p) => p.sector.toLowerCase() == key).toList();
    if (matches.isEmpty) {
      matches = packs.where((p) => p.sector == 'Tech Support').toList();
    }
    if (matches.isEmpty) return null;

    final filtered = matches.where((p) {
      if (_lastPackIdBySector[key] == p.id) return false;
      if (_recentPackIds.contains(p.id)) return false;
      return true;
    }).toList();
    final pool = filtered.isNotEmpty
        ? filtered
        : matches.where((p) => p.id != _lastPackIdBySector[key]).toList();
    final finalPool = pool.isNotEmpty ? pool : matches;
    final picked = finalPool[_random.nextInt(finalPool.length)];
    _lastPackIdBySector[key] = picked.id;
    _recentPackIds.add(picked.id);
    while (_recentPackIds.length > 8) {
      _recentPackIds.removeAt(0);
    }
    return picked;
  }

  static String detectIntent(String agentMessage) {
    final t = agentMessage.toLowerCase();
    if (t.contains('anything else') ||
        t.contains('glad I could') ||
        t.contains('glad we could') ||
        t.contains('thank you for calling') ||
        t.contains('have a good') ||
        t.contains('have a great')) {
      return 'close';
    }
    if (t.contains('i am escalating') ||
        t.contains("i'm escalating") ||
        t.contains('i will escalate') ||
        t.contains("i'll escalate") ||
        t.contains('transferring you') ||
        t.contains('transfer you to') ||
        t.contains('specialist team')) {
      return 'escalate';
    }
    if (t.contains('verify') ||
        t.contains('account name') ||
        t.contains('your account') ||
        t.contains('confirm your') ||
        t.contains('last four') ||
        t.contains('date of birth') ||
        t.contains('full name') ||
        t.contains('member id') ||
        t.contains('reference number') ||
        t.contains('preferred date') ||
        t.contains('type of visit') ||
        t.contains('telehealth')) {
      return 'verify';
    }
    if (t.contains('reset') ||
        t.contains('next step') ||
        t.contains('i will') ||
        t.contains('we can') ||
        t.contains('process') ||
        t.contains('schedule') ||
        t.contains('confirm the time') ||
        t.contains('update') ||
        t.contains('scan') ||
        t.contains('review') ||
        t.contains('check the') ||
        t.contains('look into')) {
      return 'fix';
    }
    if (t.contains('sorry') ||
        t.contains('understand') ||
        t.contains('thank you for contacting') ||
        t.contains('thank you for calling') ||
        t.contains('i can help') ||
        t.contains('i will help') ||
        t.contains('happy to help')) {
      return 'acknowledge';
    }
    return 'other';
  }

  static String pickReply(List<String> options, {String? avoid}) {
    if (options.isEmpty) return 'Can you help me with this issue?';
    if (options.length == 1) return options.first;
    final pool = avoid == null || avoid.isEmpty
        ? options
        : options.where((o) => o != avoid).toList();
    final use = pool.isNotEmpty ? pool : options;
    return use[_random.nextInt(use.length)];
  }
}
