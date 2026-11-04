import 'package:trainixprogram/models/case_blueprint.dart';
import 'package:trainixprogram/models/problem_family.dart';
import 'package:trainixprogram/models/sim_mission.dart';

/// Fully scripted simulation packs (scenario-practice style).
/// Customer lines are fixed. Progression does not depend on live AI.
class SimMissionCatalog {
  static SimPack resolve({
    required String sector,
    required String problem,
    required ProblemFamily family,
    bool needsAccount = true,
    bool escalateFromStart = false,
  }) {
    if (escalateFromStart || family == ProblemFamily.trueEscalate) {
      return escalatePack(sector: sector);
    }
    switch (family) {
      case ProblemFamily.billingSurprise:
        return billingPack(sector: sector);
      case ProblemFamily.fundTransfer:
        return fundTransferPack();
      case ProblemFamily.claimStatus:
        return claimPack();
      case ProblemFamily.prescriptionRefill:
        return refillPack();
      case ProblemFamily.loginAccess:
        return loginPack();
      case ProblemFamily.planEligibility:
        return planPack();
      case ProblemFamily.networkConnectivity:
        return networkPack();
      case ProblemFamily.appointmentPrep:
        return appointmentPack(sector: sector);
      case ProblemFamily.genericNonAccount:
        return nonAccountPack(sector: sector, problem: problem);
      case ProblemFamily.genericAccount:
        return needsAccount
            ? accountGenericPack(sector: sector)
            : nonAccountPack(sector: sector, problem: problem);
      case ProblemFamily.trueEscalate:
        return escalatePack(sector: sector);
    }
  }

  static SimPack billingPack({String sector = 'Finance'}) {
    return SimPack(
      id: 'mission_billing',
      title: 'Pending charge concern',
      sector: sector,
      family: ProblemFamily.billingSurprise,
      needsAccount: true,
      customerName: 'Daniel Cruz',
      problemSummary: 'Pending card payment and double-charge worry',
      emotion: 'worried',
      accountDetails: const {
        'Card Ending': '4412',
        'Pending Amount': '\$48.50',
        'Card Status': 'Pending review',
      },
      openingCustomerLine:
          'Hi, I see a card payment still pending on my statement and I am worried it will charge me twice. Can you help?',
      steps: const [
        SimStep(
          id: 'open',
          label: 'Greet and acknowledge the bill concern',
          kind: SimStepKind.speak,
          tip:
              'Give your name and Trainix Support. Acknowledge the pending charge concern.',
          examples: [
            'Thank you for contacting Trainix Support. This is [your name]. I understand there is a pending charge you are worried about, and I will help review it.',
          ],
          passPhrases: ['trainix', 'help', 'charge', 'pending', 'understand'],
          customerLineAfterPass:
              'Thanks. I just do not want to be double-charged. The amount is still showing as pending.',
        ),
        SimStep(
          id: 'ask_id',
          label: 'Ask for identity details',
          kind: SimStepKind.speak,
          tip:
              'Ask for full name or account number. On voice, tell them you will place the call on a brief hold before Account Lookup.',
          examples: [
            'May I have your full name and the account or card ending digits so I can verify identity securely?',
          ],
          passPhrases: [
            'name',
            'account',
            'number',
            'verify',
            'confirm',
            'full',
            'hold',
          ],
          customerLineAfterPass: 'Daniel Cruz. The card ends in 4412.',
        ),
        SimStep(
          id: 'verify',
          label: 'Verify identity in Account Lookup',
          kind: SimStepKind.tool,
          tip:
              'Open Account Lookup, select Daniel Cruz, submit Confirm identity on file.',
          toolEvent: ToolEvent.identityVerified,
          toolHint: 'Account Lookup: Confirm identity on file',
          highlightAccountLookup: true,
          customerLineAfterPass:
              'Okay, thanks for checking the account. What do you see on the pending charge?',
        ),
        SimStep(
          id: 'explain',
          label: 'Explain the pending charge in plain words',
          kind: SimStepKind.speak,
          tip:
              'Use Account Details. Explain the pending charge simply. Do not invent line items that are not on screen.',
          examples: [
            'On your account I see a card payment still showing as pending, which is why it looks like it could post twice. I can file a billing review so the team checks that it does not double-charge you.',
          ],
          passPhrases: ['pending', 'charge', 'double', 'review', 'shows'],
          customerLineAfterPass:
              'Yes, please file that review. I want this checked before anything posts twice.',
        ),
        SimStep(
          id: 'act',
          label: 'File billing review',
          kind: SimStepKind.tool,
          tip: 'File a service request for billing review in Account Lookup.',
          toolEvent: ToolEvent.requestFiled,
          toolHint: 'Account Lookup: File service request',
          highlightAccountLookup: true,
        ),
        SimStep(
          id: 'confirm',
          label: 'Confirm next steps',
          kind: SimStepKind.speak,
          tip:
              'Tell the customer the review is filed, then check if anything else is needed.',
          examples: [
            'The billing review is filed. You should see an update in the usual timeline. Is there anything else on this charge?',
          ],
          passPhrases: ['filed', 'review', 'anything else', 'update'],
          customerLineAfterPass:
              'That is all on the charge. Thank you for your help.',
        ),
        SimStep(
          id: 'close',
          label: 'Close the interaction',
          kind: SimStepKind.speak,
          tip: 'Closing spiel.',
          examples: [
            'You are welcome. Thank you for contacting Trainix Support. Once again, this is [your name]. Have a great day.',
          ],
          passPhrases: ['thank', 'trainix', 'good day', 'welcome'],
        ),
      ],
    );
  }

  static SimPack fundTransferPack() {
    return SimPack(
      id: 'mission_fund_transfer',
      title: 'Fund transfer not arrived',
      sector: 'Finance',
      family: ProblemFamily.fundTransfer,
      needsAccount: true,
      customerName: 'Vincent Navarro',
      problemSummary: 'Outbound transfer still processing past expected window',
      emotion: 'anxious',
      accountDetails: const {
        'Card Ending': '9033',
        'Pending Amount': '\$320.00',
        'Card Status': 'Active',
      },
      openingCustomerLine:
          'Hello, I sent a fund transfer that should have arrived already, but it still shows processing and the money has not moved. Can you help?',
      steps: const [
        SimStep(
          id: 'open',
          label: 'Greet and acknowledge the transfer concern',
          kind: SimStepKind.speak,
          tip: 'Name, Trainix Support, acknowledge the delayed transfer.',
          examples: [
            'Thank you for contacting Trainix Support. This is [your name]. I understand a transfer has not arrived as expected, and I will help you with that.',
          ],
          passPhrases: ['trainix', 'help', 'transfer', 'understand'],
          customerLineAfterPass:
              'It has been past the usual window and I am worried something went wrong with the transfer.',
        ),
        SimStep(
          id: 'ask_id',
          label: 'Ask for identity details',
          kind: SimStepKind.speak,
          tip:
              'Ask for full name or account number before opening Account Lookup.',
          examples: [
            'May I have your full name and the account number so I can verify identity securely?',
          ],
          passPhrases: [
            'name',
            'account',
            'number',
            'verify',
            'confirm',
            'full',
          ],
          customerLineAfterPass: 'Vincent Navarro, account ends 9033.',
        ),
        SimStep(
          id: 'verify',
          label: 'Verify identity in Account Lookup',
          kind: SimStepKind.tool,
          tip: 'Account Lookup: select account, Confirm identity on file.',
          toolEvent: ToolEvent.identityVerified,
          toolHint: 'Account Lookup: Confirm identity on file',
          highlightAccountLookup: true,
          customerLineAfterPass:
              'Thanks. Can you tell me what the account shows for that transfer?',
        ),
        SimStep(
          id: 'explain',
          label: 'Explain timing window in plain words',
          kind: SimStepKind.speak,
          tip:
              'Explain the normal 3 to 5 business day window and that a review is needed when past that window.',
          examples: [
            'Transfers often complete within 3 to 5 business days. Since this one is past that window and still shows processing, the next step is a formal transfer review.',
          ],
          passPhrases: ['business day', 'processing', 'window', 'review'],
          customerLineAfterPass:
              'Please file the review. I need someone to investigate where the money is.',
        ),
        SimStep(
          id: 'act',
          label: 'File transfer review request',
          kind: SimStepKind.tool,
          tip: 'File a transfer review in Account Lookup.',
          toolEvent: ToolEvent.requestFiled,
          toolHint: 'Account Lookup: File service request',
          highlightAccountLookup: true,
        ),
        SimStep(
          id: 'confirm',
          label: 'Confirm next steps',
          kind: SimStepKind.speak,
          tip: 'Tell the customer the review is filed and what happens next.',
          examples: [
            'The transfer review is filed. You should receive an update within the usual review window. Is there anything else on this transfer?',
          ],
          passPhrases: ['filed', 'review', 'anything else', 'update'],
          customerLineAfterPass: 'That is all for now. Thank you.',
        ),
        SimStep(
          id: 'close',
          label: 'Close the interaction',
          kind: SimStepKind.speak,
          tip: 'Closing spiel.',
          examples: [
            'Thank you for contacting Trainix Support. Once again, this is [your name]. Have a great day.',
          ],
          passPhrases: ['thank', 'trainix', 'good day'],
        ),
      ],
    );
  }

  static SimPack claimPack() {
    return SimPack(
      id: 'mission_claim',
      title: 'Claim status',
      sector: 'Healthcare',
      family: ProblemFamily.claimStatus,
      needsAccount: true,
      customerName: 'Maria Santos',
      problemSummary: 'Needs status on a submitted claim',
      emotion: 'concerned',
      accountDetails: const {
        'Member ID': 'ACC-44108',
        'Coverage': 'Claim Pending',
      },
      openingCustomerLine:
          'Hi, I submitted a claim last week and I still do not know the status. Can you check what is on file?',
      steps: const [
        SimStep(
          id: 'open',
          label: 'Greet and acknowledge the claim concern',
          kind: SimStepKind.speak,
          tip: 'Name, company, acknowledge the claim status concern.',
          examples: [
            'Thank you for contacting Trainix Support. This is [your name]. I understand you need an update on a claim, and I will help you with that.',
          ],
          passPhrases: ['trainix', 'help', 'claim', 'understand'],
          customerLineAfterPass:
              'Yes, it was submitted about a week ago. I just need to know if it is still pending.',
        ),
        SimStep(
          id: 'ask_id',
          label: 'Ask for identity details',
          kind: SimStepKind.speak,
          tip:
              'Ask for full name or member ID. On voice, tell them you will place the call on a brief hold before Account Lookup.',
          examples: [
            'May I have your full name and member ID so I can verify identity securely?',
          ],
          passPhrases: [
            'name',
            'member',
            'id',
            'verify',
            'confirm',
            'full',
            'hold',
          ],
          customerLineAfterPass: 'Maria Santos, member ID ACC-44108.',
        ),
        SimStep(
          id: 'verify',
          label: 'Verify identity on the member record',
          kind: SimStepKind.tool,
          tip: 'Account Lookup: Confirm identity before sharing claim status.',
          toolEvent: ToolEvent.identityVerified,
          toolHint: 'Account Lookup: Confirm identity on file',
          highlightAccountLookup: true,
          customerLineAfterPass: 'Thanks. What does the claim show right now?',
        ),
        SimStep(
          id: 'explain',
          label: 'State the on-file status in plain words',
          kind: SimStepKind.speak,
          tip:
              'Read Coverage or Status in Account Lookup and explain that value. Do not promise payment.',
          examples: [
            'Your claim status on file is Claim Pending. That means it is still under review and is not approved or denied yet.',
          ],
          passPhrases: ['pending', 'status', 'review', 'approved', 'denied'],
          customerLineAfterPass:
              'Can you file a follow-up so someone re-checks it?',
        ),
        SimStep(
          id: 'act',
          label: 'File claim follow-up if needed',
          kind: SimStepKind.tool,
          tip: 'File a claim status follow-up in Account Lookup.',
          toolEvent: ToolEvent.requestFiled,
          toolHint: 'Account Lookup: File service request',
          highlightAccountLookup: true,
        ),
        SimStep(
          id: 'confirm',
          label: 'Confirm next steps',
          kind: SimStepKind.speak,
          tip:
              'Tell the customer the follow-up is filed, then check if anything else is needed.',
          examples: [
            'The claim follow-up is filed. Is there anything else on this claim?',
          ],
          passPhrases: ['filed', 'follow', 'anything else'],
          customerLineAfterPass: 'Thank you. That is all I needed today.',
        ),
        SimStep(
          id: 'close',
          label: 'Close the interaction',
          kind: SimStepKind.speak,
          tip: 'Closing spiel.',
          examples: [
            'Thank you for contacting Trainix Support. Once again, this is [your name]. Have a great day.',
          ],
          passPhrases: ['thank', 'trainix', 'good day'],
        ),
      ],
    );
  }

  static SimPack refillPack() {
    return SimPack(
      id: 'mission_refill',
      title: 'Prescription refill delay',
      sector: 'Healthcare',
      family: ProblemFamily.prescriptionRefill,
      needsAccount: false,
      customerName: 'Katrina Domingo',
      problemSummary: 'Refill delayed and running low on medication',
      emotion: 'worried',
      openingCustomerLine:
          'Hi, my prescription refill is delayed and I am running low on my medication. Can you tell me what happens next?',
      steps: const [
        SimStep(
          id: 'open',
          label: 'Greet and acknowledge the refill delay',
          kind: SimStepKind.speak,
          tip:
              'Name, company, acknowledge the delay. Do not prescribe or change medication.',
          examples: [
            'Thank you for contacting Trainix Support. This is [your name]. I understand your prescription refill is delayed, and I will help you with the next steps.',
          ],
          passPhrases: ['trainix', 'help', 'refill', 'understand'],
          customerLineAfterPass:
              'I just need to know the usual timing and what I should do with the pharmacy.',
        ),
        SimStep(
          id: 'explain',
          label: 'Explain typical timing and pharmacy check',
          kind: SimStepKind.speak,
          tip:
              'Open Care Guide if needed, then give 24 to 48 hour timing. Ask them to check hold or stock with the pharmacy. Do not prescribe.',
          toolHint: 'Optional: Care Guide for refill timing',
          highlightSectorGuide: true,
          examples: [
            'Typical refill processing is about 24 to 48 hours after the pharmacy receives the request. Please check with the pharmacy first for any hold or stock issue. I cannot prescribe or change the medication itself.',
          ],
          passPhrases: ['24', '48', 'pharmacy', 'hour'],
          customerLineAfterPass:
              'That helps. If the pharmacy still has no update after that, what should I do?',
        ),
        SimStep(
          id: 'guide',
          label: 'Offer follow-up path if still delayed',
          kind: SimStepKind.speak,
          tip: 'Offer a refill follow-up request path if still delayed.',
          examples: [
            'If the pharmacy still has no update after that window, you can start a refill follow-up request and the team will re-check the file.',
          ],
          passPhrases: ['follow', 'pharmacy', 'request', 'update'],
          customerLineAfterPass:
              'Okay. Please confirm the plan so I know what to do next.',
        ),
        SimStep(
          id: 'confirm',
          label: 'Confirm the plan',
          kind: SimStepKind.speak,
          tip: 'Confirm pharmacy check and next step.',
          examples: [
            'To recap: check with the pharmacy on timing first. Is there anything else on the refill?',
          ],
          passPhrases: ['pharmacy', 'anything else', 'recap'],
          customerLineAfterPass: 'Understood. That is all I needed. Thank you.',
        ),
        SimStep(
          id: 'close',
          label: 'Close the interaction',
          kind: SimStepKind.speak,
          tip: 'Closing spiel.',
          examples: [
            'Thank you for contacting Trainix Support. Once again, this is [your name]. Have a great day.',
          ],
          passPhrases: ['thank', 'trainix', 'good day'],
        ),
      ],
    );
  }

  static SimPack loginPack() {
    return SimPack(
      id: 'mission_login',
      title: 'Cannot sign in / reset email',
      sector: 'Tech Support',
      family: ProblemFamily.loginAccess,
      needsAccount: true,
      customerName: 'Michelle Gonzales',
      problemSummary: 'Password reset email never arrived, locked out',
      emotion: 'frustrated',
      accountDetails: const {
        'Email': 'michelle.g@example.com',
        'Device': 'Laptop',
        'OS': 'Windows 11',
      },
      openingCustomerLine:
          'Hi, I am having trouble signing into my account. I requested a password reset, but the email never arrived, so I cannot reset my password and I am locked out.',
      steps: const [
        SimStep(
          id: 'open',
          label: 'Greet and acknowledge the sign-in issue',
          kind: SimStepKind.speak,
          tip:
              'Name, company, acknowledge sign-in problem. Never ask for their full password.',
          examples: [
            'Thank you for contacting Trainix Support. This is [your name]. I understand you cannot sign in, and I will help you with that.',
          ],
          passPhrases: ['trainix', 'help', 'sign', 'login', 'understand'],
          customerLineAfterPass:
              'Hi [name], I am still locked out because I did not receive the password reset email. Can you help me resend it or reset my access?',
        ),
        SimStep(
          id: 'ask_id',
          label: 'Ask for identity details',
          kind: SimStepKind.speak,
          tip:
              'Ask for full name or registered email before Account Lookup. Never ask for the full password.',
          examples: [
            'May I have the full name and registered email on the account so I can verify identity? Please do not share your password.',
          ],
          passPhrases: ['name', 'email', 'verify', 'confirm', 'account'],
          customerLineAfterPass:
              'Michelle Gonzales, email michelle.g@example.com.',
        ),
        SimStep(
          id: 'verify',
          label: 'Verify identity on file',
          kind: SimStepKind.tool,
          tip:
              'Account Lookup: Confirm identity. Never ask for the full password in chat.',
          toolEvent: ToolEvent.identityVerified,
          toolHint: 'Account Lookup: Confirm identity on file',
          highlightAccountLookup: true,
          customerLineAfterPass:
              'Thanks. What should I try next for the reset email?',
        ),
        SimStep(
          id: 'guide',
          label: 'Guide official reset path',
          kind: SimStepKind.speak,
          tip:
              'Guide the official forgot-password path and spam check. Offer secure review if that already failed.',
          examples: [
            'Please use the official forgot-password link again and check spam. If nothing arrives, I can open a secure access review.',
          ],
          passPhrases: ['reset', 'password', 'link', 'spam', 'review'],
          customerLineAfterPass:
              'I already tried that twice. Please open the secure review.',
        ),
        SimStep(
          id: 'act',
          label: 'File secure review',
          kind: SimStepKind.tool,
          tip: 'File a service request for secure access review.',
          toolEvent: ToolEvent.requestFiled,
          toolHint: 'Account Lookup: File service request',
          highlightAccountLookup: true,
        ),
        SimStep(
          id: 'confirm',
          label: 'Confirm next steps',
          kind: SimStepKind.speak,
          tip: 'Tell the customer the review is filed and wait expectations.',
          examples: [
            'The secure access review is filed. You should hear back in the usual review window. Is there anything else on this login issue?',
          ],
          passPhrases: ['review', 'filed', 'anything else'],
          customerLineAfterPass: 'That is all. Thanks for your help.',
        ),
        SimStep(
          id: 'close',
          label: 'Close the interaction',
          kind: SimStepKind.speak,
          tip: 'Closing spiel.',
          examples: [
            'Thank you for contacting Trainix Support. Once again, this is [your name]. Have a great day.',
          ],
          passPhrases: ['thank', 'trainix', 'good day'],
        ),
      ],
    );
  }

  static SimPack planPack() {
    return SimPack(
      id: 'mission_plan',
      title: 'Plan upgrade denied',
      sector: 'Telco',
      family: ProblemFamily.planEligibility,
      needsAccount: true,
      customerName: 'Chris Mendoza',
      problemSummary: 'Plan upgrade denied in the app',
      emotion: 'annoyed',
      accountDetails: const {
        'Mobile Ending': '4821',
        'Plan': 'Premium Plus (blocked)',
        'Service Status': 'Active',
      },
      openingCustomerLine:
          'Hi, I tried to upgrade my plan yesterday and the app denied it. I do not understand why.',
      steps: const [
        SimStep(
          id: 'open',
          label: 'Greet and acknowledge the denied upgrade',
          kind: SimStepKind.speak,
          tip: 'Name, company, acknowledge the denied plan upgrade.',
          examples: [
            'Thank you for contacting Trainix Support. This is [your name]. I understand your plan upgrade was denied, and I will help you with that.',
          ],
          passPhrases: ['trainix', 'help', 'upgrade', 'denied', 'understand'],
          customerLineAfterPass:
              'I wanted Premium Plus. The app just said I was not eligible.',
        ),
        SimStep(
          id: 'ask_id',
          label: 'Ask for identity details',
          kind: SimStepKind.speak,
          tip:
              'Ask for full name or the number on the account before opening Account Lookup.',
          examples: [
            'May I have your full name and the mobile number on the account so I can verify identity securely?',
          ],
          passPhrases: [
            'name',
            'account',
            'number',
            'verify',
            'confirm',
            'full',
          ],
          customerLineAfterPass: 'Sure. Chris Mendoza, number ending 4821.',
        ),
        SimStep(
          id: 'verify',
          label: 'Verify identity in Account Lookup',
          kind: SimStepKind.tool,
          tip:
              'Open Account Lookup, select the matching account, Confirm identity on file.',
          toolEvent: ToolEvent.identityVerified,
          toolHint: 'Account Lookup: Confirm identity on file',
          highlightAccountLookup: true,
          customerLineAfterPass: 'Okay, so what is blocking the upgrade?',
        ),
        SimStep(
          id: 'explain',
          label: 'Explain the block reason in plain words',
          kind: SimStepKind.speak,
          tip: 'Explain the block from Account Details in plain words.',
          examples: [
            'The upgrade is blocked because of an unpaid balance on the line. Once that is cleared, the upgrade can be tried again, or we can file a review.',
          ],
          passPhrases: ['balance', 'unpaid', 'block', 'because'],
          customerLineAfterPass: 'Please file the upgrade review for me.',
        ),
        SimStep(
          id: 'act',
          label: 'File upgrade review',
          kind: SimStepKind.tool,
          tip: 'File an upgrade review request.',
          toolEvent: ToolEvent.requestFiled,
          toolHint: 'Account Lookup: File service request',
          highlightAccountLookup: true,
        ),
        SimStep(
          id: 'confirm',
          label: 'Confirm next steps',
          kind: SimStepKind.speak,
          tip: 'Tell the customer the review is filed.',
          examples: [
            'The review request is filed. You should see an update within the usual review window. Is there anything else?',
          ],
          passPhrases: ['filed', 'review', 'anything else'],
          customerLineAfterPass: 'Thanks. That is all I needed.',
        ),
        SimStep(
          id: 'close',
          label: 'Close the interaction',
          kind: SimStepKind.speak,
          tip: 'Closing spiel.',
          examples: [
            'Thank you for contacting Trainix Support. Once again, this is [your name]. Have a great day.',
          ],
          passPhrases: ['thank', 'trainix', 'good day'],
        ),
      ],
    );
  }

  static SimPack networkPack() {
    return SimPack(
      id: 'mission_network',
      title: 'Home internet down',
      sector: 'Telco',
      family: ProblemFamily.networkConnectivity,
      needsAccount: false,
      customerName: 'Grace Villanueva',
      problemSummary: 'Home internet down, neighbors still have service',
      emotion: 'frustrated',
      openingCustomerLine:
          'Hi, my home internet is completely down. Neighbors still have service but I have no connection. It is really frustrating.',
      steps: const [
        SimStep(
          id: 'open',
          label: 'Greet and acknowledge the outage',
          kind: SimStepKind.speak,
          tip:
              'Name, company, acknowledge no connection. Do not re-ask the whole problem.',
          examples: [
            'Thank you for contacting Trainix Support. This is [your name]. I understand your home internet is down, and I will help you with that.',
          ],
          passPhrases: ['trainix', 'help', 'internet', 'down', 'understand'],
          customerLineAfterPass:
              'I have been without internet for over an hour and it is affecting my work. What should I try first?',
        ),
        SimStep(
          id: 'guide',
          label: 'Give one network check',
          kind: SimStepKind.speak,
          tip:
              'One step: power cycle modem and router. Account Lookup is not required.',
          toolHint: 'Optional: Network Guide for standard checks',
          highlightSectorGuide: true,
          examples: [
            'Please unplug the modem and router for 30 seconds, plug the modem back first, wait for the lights, then reconnect the router and tell me if service returns.',
          ],
          passPhrases: ['modem', 'router', 'unplug', 'please', 'lights'],
          customerLineAfterPass:
              'I tried that. Still no connection. What is the next step?',
        ),
        SimStep(
          id: 'confirm',
          label: 'Confirm service or next path',
          kind: SimStepKind.speak,
          tip:
              'Offer an outage check path. Use Escalation if policy needs elevated handling.',
          examples: [
            'Since it is still down after the power cycle, I can log an outage check for your area. Would you like me to note that for you?',
          ],
          passPhrases: ['outage', 'still', 'area', 'ticket', 'check', 'log'],
          customerLineAfterPass: 'Yes, please log that. Thank you.',
        ),
        SimStep(
          id: 'close',
          label: 'Close the interaction',
          kind: SimStepKind.speak,
          tip: 'Confirm the outage note, then close with your name.',
          examples: [
            'I have noted the outage check. Thank you for contacting Trainix Support. Once again, this is [your name]. Have a great day.',
          ],
          passPhrases: ['thank', 'trainix', 'good day', 'outage', 'noted'],
        ),
      ],
    );
  }

  static SimPack appointmentPack({String sector = 'Healthcare'}) {
    return SimPack(
      id: 'mission_appointment',
      title: 'Appointment preparation',
      sector: sector,
      family: ProblemFamily.appointmentPrep,
      needsAccount: false,
      customerName: 'Angela Reyes',
      problemSummary: 'What to prepare for appointment day',
      emotion: 'anxious',
      openingCustomerLine:
          'Hi, I have an appointment coming up and I am not sure what I need to prepare beforehand. Can you walk me through the preparation steps?',
      steps: const [
        SimStep(
          id: 'open',
          label: 'Greet and acknowledge the appointment question',
          kind: SimStepKind.speak,
          tip: 'Name, company, acknowledge the appointment preparation ask.',
          examples: [
            'Thank you for contacting Trainix Support. This is [your name]. I understand you need help preparing for your appointment, and I will guide you.',
          ],
          passPhrases: ['trainix', 'help', 'appointment', 'understand'],
          customerLineAfterPass:
              'I am a bit anxious and do not want to miss anything important for the day of the visit.',
        ),
        SimStep(
          id: 'guide',
          label: 'Give clear preparation steps',
          kind: SimStepKind.speak,
          tip:
              'Give standard prep steps only. Do not invent clinical advice. Use Care Guide if needed.',
          toolHint: 'Optional: Care Guide for standard prep',
          highlightSectorGuide: true,
          examples: [
            'Please bring a photo ID, your insurance card if you use one, a list of current medications, and arrive a little early to check in. You can also confirm the visit time in the patient portal.',
          ],
          passPhrases: [
            'bring',
            'id',
            'insurance',
            'medication',
            'portal',
            'arrive',
          ],
          customerLineAfterPass:
              'That is clear. I think I can continue from here. Thank you.',
        ),
        SimStep(
          id: 'confirm',
          label: 'Confirm they can continue',
          kind: SimStepKind.speak,
          tip: 'Confirm the plan and ask if anything else is needed.',
          examples: [
            'Glad that helps. Is there anything else about the appointment preparation?',
          ],
          passPhrases: ['anything else', 'help', 'glad'],
        ),
        SimStep(
          id: 'close',
          label: 'Close the interaction',
          kind: SimStepKind.speak,
          tip: 'Closing spiel.',
          examples: [
            'Thank you for contacting Trainix Support. Once again, this is [your name]. Have a great day.',
          ],
          passPhrases: ['thank', 'trainix', 'good day'],
        ),
      ],
    );
  }

  static SimPack techAppPack() {
    return SimPack(
      id: 'mission_tech_app',
      title: 'App freezes on recent files',
      sector: 'Tech Support',
      family: ProblemFamily.genericNonAccount,
      needsAccount: false,
      customerName: 'Jerome Aguilar',
      problemSummary: 'App freezes when opening recent files',
      emotion: 'impatient',
      openingCustomerLine:
          'Hi, my app keeps freezing every time I try to open a recent file. Can you help me fix this?',
      steps: const [
        SimStep(
          id: 'open',
          label: 'Greet and acknowledge the app issue',
          kind: SimStepKind.speak,
          tip:
              'Name, company, acknowledge the freeze. This is not an Account Lookup case.',
          examples: [
            'Thank you for contacting Trainix Support. This is [your name]. I understand the app is freezing, and I will help you with that.',
          ],
          passPhrases: ['trainix', 'help', 'app', 'freeze', 'understand'],
          customerLineAfterPass:
              'It freezes every time on recent files and I have to force close it.',
        ),
        SimStep(
          id: 'guide',
          label: 'Give one fix path',
          kind: SimStepKind.speak,
          tip: 'One fix at a time. Use Tech Guide if needed.',
          toolHint: 'Optional: Tech Guide for standard app steps',
          highlightSectorGuide: true,
          examples: [
            'Please force-close the app fully, reopen it, then try one recent file again and tell me whether it still freezes.',
          ],
          passPhrases: ['force', 'close', 'reopen', 'try', 'please'],
          customerLineAfterPass:
              'I did that. It is stable now when I open recent files.',
        ),
        SimStep(
          id: 'confirm',
          label: 'Confirm they can continue',
          kind: SimStepKind.speak,
          tip: 'Confirm the app works.',
          examples: [
            'Glad it is stable now. Is there anything else on this issue?',
          ],
          passPhrases: ['anything else', 'glad', 'stable', 'working'],
          customerLineAfterPass: 'No, that is all. Thank you.',
        ),
        SimStep(
          id: 'close',
          label: 'Close the interaction',
          kind: SimStepKind.speak,
          tip: 'Closing spiel.',
          examples: [
            'Thank you for contacting Trainix Support. Once again, this is [your name]. Have a great day.',
          ],
          passPhrases: ['thank', 'trainix', 'good day', 'great day'],
        ),
      ],
    );
  }

  static SimPack nonAccountPack({
    required String sector,
    required String problem,
  }) {
    final p = problem.toLowerCase();
    if (p.contains('freeze') || p.contains('app') || p.contains('crash')) {
      return techAppPack();
    }
    final s = sector.toLowerCase();
    if (s.contains('finance')) return _financeHowToPack();
    if (s.contains('health')) return _healthHowToPack();
    if (s.contains('telco')) return _telcoHowToPack();
    return _techHowToPack();
  }

  static SimPack _financeHowToPack() {
    return SimPack(
      id: 'mission_howto_finance',
      title: 'How to read a pending charge',
      sector: 'Finance',
      family: ProblemFamily.genericNonAccount,
      needsAccount: false,
      customerName: 'Taylor Brooks',
      problemSummary:
          'Wants steps to understand a pending charge on the statement',
      emotion: 'curious',
      openingCustomerLine:
          'Hi, I see a pending charge on my statement and I want clear steps to understand it. I do not need account changes, just guidance.',
      steps: const [
        SimStep(
          id: 'open',
          label: 'Greet and acknowledge the pending charge question',
          kind: SimStepKind.speak,
          tip:
              'Name, company, acknowledge the pending charge how-to. Account Lookup is optional here.',
          examples: [
            'Thank you for contacting Trainix Support. This is [your name]. I understand you want clear steps for a pending charge on your statement, and I will walk you through that.',
          ],
          passPhrases: ['trainix', 'help', 'pending', 'understand'],
          customerLineAfterPass:
              'Yes. I just need to know what pending means and what I should check first.',
        ),
        SimStep(
          id: 'guide',
          label: 'Explain pending status in plain words',
          kind: SimStepKind.speak,
          tip: 'One clear explanation. Use sector guide if needed.',
          toolHint: 'Optional: sector guide for pending charge wording',
          highlightSectorGuide: true,
          examples: [
            'Pending means the charge is still processing and has not posted as final. Check the merchant name, amount, and date on the statement first, then wait for the usual processing window before treating it as a completed charge.',
          ],
          passPhrases: ['pending', 'processing', 'statement', 'merchant'],
          customerLineAfterPass:
              'That makes sense. I will check those fields. Thanks for the clear steps.',
        ),
        SimStep(
          id: 'confirm',
          label: 'Confirm they can continue',
          kind: SimStepKind.speak,
          tip: 'Confirm the plan.',
          examples: [
            'Glad that helps. Is there anything else about the pending charge?',
          ],
          passPhrases: ['anything else', 'glad', 'help'],
        ),
        SimStep(
          id: 'close',
          label: 'Close the interaction',
          kind: SimStepKind.speak,
          tip: 'Closing spiel with your name.',
          examples: [
            'Thank you for contacting Trainix Support. Once again, this is [your name]. Have a great day.',
          ],
          passPhrases: ['thank', 'trainix', 'good day'],
        ),
      ],
    );
  }

  static SimPack _healthHowToPack() {
    return SimPack(
      id: 'mission_howto_health',
      title: 'How to prepare for a clinic visit',
      sector: 'Healthcare',
      family: ProblemFamily.genericNonAccount,
      needsAccount: false,
      customerName: 'Taylor Brooks',
      problemSummary: 'Wants preparation steps before a clinic visit',
      emotion: 'curious',
      openingCustomerLine:
          'Hi, I have a clinic visit coming up and I need clear steps on what to prepare. I do not need account changes, just guidance.',
      steps: const [
        SimStep(
          id: 'open',
          label: 'Greet and acknowledge the visit prep request',
          kind: SimStepKind.speak,
          tip:
              'Name, company, acknowledge visit preparation. No Account Lookup required.',
          examples: [
            'Thank you for contacting Trainix Support. This is [your name]. I understand you want clear steps to prepare for your clinic visit, and I will help with that.',
          ],
          passPhrases: ['trainix', 'help', 'visit', 'prepare', 'understand'],
          customerLineAfterPass:
              'Yes. What should I bring or check before I go?',
        ),
        SimStep(
          id: 'guide',
          label: 'Give one clear prep step',
          kind: SimStepKind.speak,
          tip: 'One clear step. Use Care Guide if needed.',
          toolHint: 'Optional: Care Guide for visit prep',
          highlightSectorGuide: true,
          examples: [
            'Bring a photo ID, your member card if you have one, and a short list of current medicines. Arrive a little early so check-in is not rushed.',
          ],
          passPhrases: ['id', 'member', 'medicine', 'early', 'bring'],
          customerLineAfterPass:
              'That is clear. I can continue with that list. Thank you.',
        ),
        SimStep(
          id: 'confirm',
          label: 'Confirm they can continue',
          kind: SimStepKind.speak,
          tip: 'Confirm the plan.',
          examples: [
            'Glad that helps. Is there anything else about the visit preparation?',
          ],
          passPhrases: ['anything else', 'glad', 'help'],
        ),
        SimStep(
          id: 'close',
          label: 'Close the interaction',
          kind: SimStepKind.speak,
          tip: 'Closing spiel with your name.',
          examples: [
            'Thank you for contacting Trainix Support. Once again, this is [your name]. Have a great day.',
          ],
          passPhrases: ['thank', 'trainix', 'good day'],
        ),
      ],
    );
  }

  static SimPack _telcoHowToPack() {
    return SimPack(
      id: 'mission_howto_telco',
      title: 'How to restart the modem safely',
      sector: 'Telco',
      family: ProblemFamily.genericNonAccount,
      needsAccount: false,
      customerName: 'Taylor Brooks',
      problemSummary: 'Wants safe steps to restart the modem',
      emotion: 'curious',
      openingCustomerLine:
          'Hi, my connection is slow and I want clear steps to restart my modem safely. I do not need account changes, just guidance.',
      steps: const [
        SimStep(
          id: 'open',
          label: 'Greet and acknowledge the modem restart request',
          kind: SimStepKind.speak,
          tip:
              'Name, company, acknowledge the restart how-to. No Account Lookup required.',
          examples: [
            'Thank you for contacting Trainix Support. This is [your name]. I understand you want safe steps to restart your modem, and I will walk you through that.',
          ],
          passPhrases: ['trainix', 'help', 'modem', 'restart', 'understand'],
          customerLineAfterPass: 'Yes. What should I do first?',
        ),
        SimStep(
          id: 'guide',
          label: 'Give one clear restart step',
          kind: SimStepKind.speak,
          tip: 'One clear step. Use Network Guide if needed.',
          toolHint: 'Optional: Network Guide for modem restart',
          highlightSectorGuide: true,
          examples: [
            'Unplug the modem power cable, wait a full 30 seconds, plug it back in, and wait until the lights settle before testing the connection again.',
          ],
          passPhrases: ['unplug', '30', 'seconds', 'plug', 'lights'],
          customerLineAfterPass:
              'I did that. The lights look normal and the connection is better. Thanks.',
        ),
        SimStep(
          id: 'confirm',
          label: 'Confirm they can continue',
          kind: SimStepKind.speak,
          tip: 'Confirm the result.',
          examples: [
            'Glad the connection improved. Is there anything else on this issue?',
          ],
          passPhrases: ['anything else', 'glad', 'help'],
        ),
        SimStep(
          id: 'close',
          label: 'Close the interaction',
          kind: SimStepKind.speak,
          tip: 'Closing spiel with your name.',
          examples: [
            'Thank you for contacting Trainix Support. Once again, this is [your name]. Have a great day.',
          ],
          passPhrases: ['thank', 'trainix', 'good day'],
        ),
      ],
    );
  }

  static SimPack _techHowToPack() {
    return SimPack(
      id: 'mission_howto_tech',
      title: 'How to clear app cache safely',
      sector: 'Tech Support',
      family: ProblemFamily.genericNonAccount,
      needsAccount: false,
      customerName: 'Taylor Brooks',
      problemSummary: 'Wants safe steps to clear app cache',
      emotion: 'curious',
      openingCustomerLine:
          'Hi, my app is lagging and I want clear steps to clear the app cache safely. I do not need account changes, just guidance.',
      steps: const [
        SimStep(
          id: 'open',
          label: 'Greet and acknowledge the cache how-to request',
          kind: SimStepKind.speak,
          tip:
              'Name, company, acknowledge the cache how-to. No Account Lookup required.',
          examples: [
            'Thank you for contacting Trainix Support. This is [your name]. I understand you want safe steps to clear the app cache, and I will walk you through that.',
          ],
          passPhrases: ['trainix', 'help', 'cache', 'app', 'understand'],
          customerLineAfterPass: 'Great. What should I do first?',
        ),
        SimStep(
          id: 'guide',
          label: 'Give one clear cache step',
          kind: SimStepKind.speak,
          tip: 'One clear step. Use Tech Guide if needed.',
          toolHint: 'Optional: Tech Guide for cache steps',
          highlightSectorGuide: true,
          examples: [
            'Open the device settings, open Apps, select this app, open Storage, then choose Clear cache only. Do not choose Clear data unless you are ready to sign in again.',
          ],
          passPhrases: ['settings', 'cache', 'storage', 'clear', 'app'],
          customerLineAfterPass:
              'I cleared cache only. The app feels smoother now. Thanks for the clear steps.',
        ),
        SimStep(
          id: 'confirm',
          label: 'Confirm they can continue',
          kind: SimStepKind.speak,
          tip: 'Confirm the result.',
          examples: [
            'Glad it is smoother now. Is there anything else on this issue?',
          ],
          passPhrases: ['anything else', 'glad', 'help'],
        ),
        SimStep(
          id: 'close',
          label: 'Close the interaction',
          kind: SimStepKind.speak,
          tip: 'Closing spiel with your name.',
          examples: [
            'Thank you for contacting Trainix Support. Once again, this is [your name]. Have a great day.',
          ],
          passPhrases: ['thank', 'trainix', 'good day'],
        ),
      ],
    );
  }

  static SimPack accountGenericPack({String sector = 'Finance'}) {
    return SimPack(
      id: 'mission_account_generic',
      title: 'Account-related issue',
      sector: sector,
      family: ProblemFamily.genericAccount,
      needsAccount: true,
      customerName: 'Jordan Lee',
      problemSummary: 'Needs help with an account-related issue',
      emotion: 'neutral',
      openingCustomerLine:
          'Hi, I need help with something on my account. Can you look into it with me?',
      steps: const [
        SimStep(
          id: 'open',
          label: 'Greet and acknowledge the issue',
          kind: SimStepKind.speak,
          tip: 'Name, company, acknowledge their issue.',
          examples: [
            'Thank you for contacting Trainix Support. This is [your name]. I understand you need help with your account, and I will help you with this.',
          ],
          passPhrases: ['trainix', 'help', 'account', 'understand'],
          customerLineAfterPass:
              'Thanks. Please verify my account and check what is on file.',
        ),
        SimStep(
          id: 'ask_id',
          label: 'Ask for identity details',
          kind: SimStepKind.speak,
          tip:
              'Ask for full name or account number before opening Account Lookup.',
          examples: [
            'May I have your full name and account number so I can verify identity securely?',
          ],
          passPhrases: [
            'name',
            'account',
            'number',
            'verify',
            'confirm',
            'full',
          ],
          customerLineAfterPass: 'Jordan Lee, account 55201.',
        ),
        SimStep(
          id: 'verify',
          label: 'Verify identity on file',
          kind: SimStepKind.tool,
          tip: 'Account Lookup: Confirm identity before account actions.',
          toolEvent: ToolEvent.identityVerified,
          toolHint: 'Account Lookup: Confirm identity on file',
          highlightAccountLookup: true,
          customerLineAfterPass: 'What do you see on the account?',
        ),
        SimStep(
          id: 'explain',
          label: 'Explain findings in plain words',
          kind: SimStepKind.speak,
          tip: 'Explain what Account Details show in plain words.',
          examples: [
            'Here is what I see on the account in plain words. I can file a request next if needed.',
          ],
          passPhrases: ['account', 'see', 'shows', 'plain'],
          customerLineAfterPass:
              'Please file a request so this gets followed up.',
        ),
        SimStep(
          id: 'act',
          label: 'File the service request',
          kind: SimStepKind.tool,
          tip: 'File a service request in Account Lookup.',
          toolEvent: ToolEvent.requestFiled,
          toolHint: 'Account Lookup: File service request',
          highlightAccountLookup: true,
        ),
        SimStep(
          id: 'confirm',
          label: 'Confirm next steps',
          kind: SimStepKind.speak,
          tip: 'Tell the customer the request is filed.',
          examples: [
            'The request is filed. Is there anything else I can help with?',
          ],
          passPhrases: ['filed', 'anything else'],
          customerLineAfterPass: 'Thank you. That is all for today.',
        ),
        SimStep(
          id: 'close',
          label: 'Close the interaction',
          kind: SimStepKind.speak,
          tip: 'Closing spiel.',
          examples: [
            'Thank you for contacting Trainix Support. Once again, this is [your name]. Have a great day.',
          ],
          passPhrases: ['thank', 'trainix', 'good day'],
        ),
      ],
    );
  }

  static SimPack escalatePack({String sector = 'General'}) {
    return SimPack(
      id: 'mission_escalate',
      title: 'Escalation handoff',
      sector: sector,
      family: ProblemFamily.trueEscalate,
      needsAccount: false,
      customerName: 'Sam Ortiz',
      problemSummary: 'Serious issue requiring specialist handoff',
      emotion: 'upset',
      openingCustomerLine:
          'Hi, this is a serious issue and I already tried the basic steps. I need this escalated to a specialist team.',
      steps: const [
        SimStep(
          id: 'open',
          label: 'Greet and acknowledge the concern',
          kind: SimStepKind.speak,
          tip:
              'Name, company, acknowledge the serious concern. Do not invent a self-serve fix.',
          examples: [
            'Thank you for contacting Trainix Support. This is [your name]. I understand how serious this is, and I will make sure the right team has what they need.',
          ],
          passPhrases: ['trainix', 'help', 'understand', 'serious'],
          customerLineAfterPass:
              'Please take a full summary of what I tried and the impact on me.',
        ),
        SimStep(
          id: 'collect',
          label: 'Collect handoff details',
          kind: SimStepKind.speak,
          tip: 'Collect what was tried, impact, and a clear summary.',
          examples: [
            'I am preparing a full summary for the specialist team, including what you already tried and the impact on you.',
          ],
          passPhrases: ['summary', 'tried', 'specialist', 'impact'],
          customerLineAfterPass: 'Yes. Please submit the escalation now.',
        ),
        SimStep(
          id: 'handoff',
          label: 'Submit the escalation',
          kind: SimStepKind.tool,
          tip: 'Submit the escalation handoff in tools when available.',
          toolEvent: ToolEvent.escalationSubmitted,
          toolHint: 'Escalation action / Account Lookup escalate',
          highlightAccountLookup: true,
          customerLineAfterPass:
              'Thank you. I will wait for the specialist team.',
        ),
        SimStep(
          id: 'close',
          label: 'Close without calling it resolved',
          kind: SimStepKind.speak,
          tip: 'Close clearly: specialist team continues. Do not claim fixed.',
          examples: [
            'The specialist team will continue from here. Thank you for contacting Trainix Support.',
          ],
          passPhrases: ['specialist', 'thank', 'team'],
        ),
      ],
    );
  }
}
