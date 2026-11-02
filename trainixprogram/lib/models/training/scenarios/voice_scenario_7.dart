import 'package:trainixprogram/models/training/scenarios/scenario_models.dart';

const voiceScenario7 = ScenarioDefinition(
  id: 'voice_7',
  title: 'Voice Scenario #7 - Guided Account Lookup On Call',
  channel: 'voice',
  sector: 'Finance',
  customerName: 'Lena Ortiz',
  problem: 'Wire transfer still not showing and customer wants a live account check',
  emotion: 'Anxious',
  targetSkills: [
    'Opening Spiel',
    'Sector Knowledge',
    'Account Lookup',
    'Solution Delivery',
    'Closing Spiel',
  ],
  maxMistakes: 3,
  isGuided: true,
  order: 7,
  usesAccountLookup: true,
  missionSteps: [
    ScenarioMissionStep(id: 'open', label: 'Open the finance call'),
    ScenarioMissionStep(id: 'verify', label: 'Verify identity'),
    ScenarioMissionStep(id: 'search', label: 'Search Account Lookup'),
    ScenarioMissionStep(id: 'select', label: 'Select the correct account'),
    ScenarioMissionStep(id: 'explain', label: 'Explain account status on the call'),
    ScenarioMissionStep(id: 'resolve', label: 'Mark issue resolved'),
    ScenarioMissionStep(id: 'close', label: 'Close the call'),
  ],
  accounts: [
    ScenarioAccount(
      accountId: 'FIN-21011',
      ownerName: 'Lina Ortega',
      details: {
        'Status': 'Active',
        'Last Wire': 'Completed yesterday',
        'Reference': 'WIRE-44102',
        'Email': 'lina.ortega@email.com',
      },
    ),
    ScenarioAccount(
      accountId: 'FIN-33020',
      ownerName: 'Lena Ortega',
      details: {
        'Status': 'Restricted',
        'Last Wire': 'None in 30 days',
        'Reference': 'N/A',
        'Email': 'lena.ortega@email.com',
      },
    ),
    ScenarioAccount(
      accountId: 'FIN-44130',
      ownerName: 'Elena Ortiz',
      details: {
        'Status': 'Active',
        'Last Wire': 'Completed 2 days ago',
        'Reference': 'WIRE-22011',
        'Email': 'elena.ortiz@email.com',
      },
    ),
    ScenarioAccount(
      accountId: 'FIN-55201',
      ownerName: 'Lena Ortiz',
      isTarget: true,
      details: {
        'Status': 'Active',
        'Last Wire': 'Processing - submitted today 8:42 AM',
        'Reference': 'WIRE-90881',
        'Email': 'lena.ortiz@email.com',
      },
    ),
    ScenarioAccount(
      accountId: 'FIN-66014',
      ownerName: 'Leo Ortiz',
      details: {
        'Status': 'Active',
        'Last Wire': 'Completed today',
        'Reference': 'WIRE-77120',
        'Email': 'leo.ortiz@email.com',
      },
    ),
    ScenarioAccount(
      accountId: 'FIN-77022',
      ownerName: 'Lana Ortiz',
      details: {
        'Status': 'Inactive',
        'Last Wire': 'None',
        'Reference': 'N/A',
        'Email': 'lana.ortiz@email.com',
      },
    ),
    ScenarioAccount(
      accountId: 'FIN-88033',
      ownerName: 'Marcus Hale',
      details: {
        'Status': 'Active',
        'Last Wire': 'Completed last week',
        'Reference': 'WIRE-11002',
        'Email': 'marcus.hale@email.com',
      },
    ),
    ScenarioAccount(
      accountId: 'FIN-99040',
      ownerName: 'Priya Nair',
      details: {
        'Status': 'Active',
        'Last Wire': 'Completed today',
        'Reference': 'WIRE-33001',
        'Email': 'priya.nair@email.com',
      },
    ),
  ],
  turns: [
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'Voice-only simulation still uses Account Lookup. You will speak, then search and resolve in the tool tab.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'Use the Conversation tab for speaking and the Account Lookup tab for search, select, and resolve.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text:
          'I sent a wire this morning and it still is not showing. Can you check my account while we are on the call?',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Opening',
      missionStepId: 'open',
      coachPrompt: 'Open the finance call. Say:',
      targetText:
          'Thank you for calling Horizon Finance. This is Alex. How may I help you today?',
      successReply: 'Good opening. Next verify before account tools.',
      failReply: 'Speak the full opening line again.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Please just check the wire on my account.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Verify',
      missionStepId: 'verify',
      coachPrompt: 'Verify identity before Account Lookup. Say:',
      targetText:
          'I can check that with you. For security, may I verify your full name and the email on the account?',
      successReply: 'Verified. Now open Account Lookup and search.',
      failReply: 'Verify identity before using Account Lookup.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Lena Ortiz, lena.ortiz@email.com.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.accountSearch,
      text: 'Search account',
      missionStepId: 'search',
      coachPrompt:
          'Open the Account Lookup tab. Search for Lena Ortiz, then Confirm Search.',
      searchTarget: 'Lena Ortiz',
      successReply: 'Search complete. Select the correct account from the list.',
      failReply: 'Search using the customer name Lena Ortiz.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.accountSelect,
      text: 'Select account',
      missionStepId: 'select',
      coachPrompt:
          'In Account Lookup, select Lena Ortiz, account FIN-55201, then Confirm Selected Account.',
      selectAccountId: 'FIN-55201',
      successReply: 'Correct account selected.',
      failReply: 'Select Lena Ortiz with account ID FIN-55201.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Explain',
      missionStepId: 'explain',
      coachPrompt: 'Explain the account status on the call. Say:',
      targetText:
          'I can see your wire is still processing from this morning under reference WIRE-90881. It has not failed.',
      successReply: 'Clear spoken status from the account details.',
      failReply: 'Explain the processing status using the guided line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Okay. Please update whatever you need on your side.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.accountResolve,
      text: 'Resolve',
      missionStepId: 'resolve',
      coachPrompt:
          'In Account Lookup, use the resolve action on the correct account.',
      successReply: 'Issue marked resolved in the system.',
      failReply: 'Use resolve on the correct target account only.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Closing',
      missionStepId: 'close',
      coachPrompt: 'Close the call. Say:',
      targetText:
          'I have updated the case on our side. Is there anything else I can help you with today? Thank you for calling Horizon Finance.',
      successReply: 'Strong close after tool use.',
      failReply: 'Speak the full closing line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'That is all for now. Thanks.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'Complete. Voice agents still need Account Lookup: verify, search, select, explain, resolve, close.',
    ),
  ],
);
