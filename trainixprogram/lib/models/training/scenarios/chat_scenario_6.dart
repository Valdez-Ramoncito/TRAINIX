import 'package:trainixprogram/models/training/scenarios/scenario_models.dart';

const chatScenario6 = ScenarioDefinition(
  id: 'chat_6',
  title: 'Non-Voice Scenario #6 - Guided Account Lookup',
  channel: 'chat',
  sector: 'Finance',
  customerName: 'Maya Santos',
  problem: 'Wants transfer status checked on the account',
  emotion: 'Anxious',
  targetSkills: [
    'Opening Spiel',
    'Sector Knowledge',
    'Account Lookup',
    'Solution Delivery',
    'Closing Spiel',
  ],
  maxMistakes: 3,
  isGuided: false,
  order: 6,
  usesAccountLookup: true,
  accounts: [
    ScenarioAccount(
      accountId: 'FIN-11802',
      ownerName: 'Morgan Santos',
      details: {
        'Status': 'Active',
        'Last Transfer': 'Completed yesterday',
        'Reference': 'TXN-77410',
        'Email': 'morgan.santos@email.com',
      },
    ),
    ScenarioAccount(
      accountId: 'FIN-33011',
      ownerName: 'Maya Sandoval',
      details: {
        'Status': 'Restricted',
        'Last Transfer': 'None in 30 days',
        'Reference': 'N/A',
        'Email': 'maya.sandoval@email.com',
      },
    ),
    ScenarioAccount(
      accountId: 'FIN-44120',
      ownerName: 'Maria Santos',
      details: {
        'Status': 'Active',
        'Last Transfer': 'Completed 3 days ago',
        'Reference': 'TXN-66102',
        'Email': 'maria.santos@email.com',
      },
    ),
    ScenarioAccount(
      accountId: 'FIN-55233',
      ownerName: 'Maya Cortez',
      details: {
        'Status': 'Active',
        'Last Transfer': 'Failed - retry pending',
        'Reference': 'TXN-55201',
        'Email': 'maya.cortez@email.com',
      },
    ),
    ScenarioAccount(
      accountId: 'FIN-66014',
      ownerName: 'James Rivera',
      details: {
        'Status': 'Active',
        'Last Transfer': 'Completed today',
        'Reference': 'TXN-91002',
        'Email': 'james.rivera@email.com',
      },
    ),
    ScenarioAccount(
      accountId: 'FIN-20418',
      ownerName: 'Maya Santos',
      isTarget: true,
      details: {
        'Status': 'Active',
        'Last Transfer': 'Processing - sent today 9:14 AM',
        'Reference': 'TXN-88921',
        'Email': 'maya.santos@email.com',
      },
    ),
    ScenarioAccount(
      accountId: 'FIN-77109',
      ownerName: 'M. Santos',
      details: {
        'Status': 'Inactive',
        'Last Transfer': 'None',
        'Reference': 'N/A',
        'Email': 'm.santos@email.com',
      },
    ),
    ScenarioAccount(
      accountId: 'FIN-88221',
      ownerName: 'Anya Santos',
      details: {
        'Status': 'Active',
        'Last Transfer': 'Completed last week',
        'Reference': 'TXN-33001',
        'Email': 'anya.santos@email.com',
      },
    ),
    ScenarioAccount(
      accountId: 'FIN-99001',
      ownerName: 'Liam Brooks',
      details: {
        'Status': 'Active',
        'Last Transfer': 'Completed today',
        'Reference': 'TXN-12045',
        'Email': 'liam.brooks@email.com',
      },
    ),
  ],
  missionSteps: [
    ScenarioMissionStep(id: 'open', label: 'Open the chat'),
    ScenarioMissionStep(id: 'verify', label: 'Verify identity'),
    ScenarioMissionStep(id: 'search', label: 'Search Account Lookup'),
    ScenarioMissionStep(id: 'select', label: 'Select the correct account'),
    ScenarioMissionStep(id: 'explain', label: 'Explain account status'),
    ScenarioMissionStep(id: 'resolve', label: 'Mark issue resolved'),
    ScenarioMissionStep(id: 'close', label: 'Close the chat'),
  ],
  turns: [
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'This scenario teaches Account Lookup. You will verify identity, search, select the correct account, explain status, then resolve.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text:
          'Hi. Can you check my transfer? It still has not arrived and I am worried.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Opening',
      missionStepId: 'open',
      coachPrompt: 'Open the finance chat professionally.',
      targetText:
          'Thank you for contacting Horizon Finance Support. This is Alex. How may I help you today?',
      successReply: 'Good opening.',
      failReply: 'Use the full finance opening line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Please check my account now. The transfer is missing.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Verify',
      missionStepId: 'verify',
      coachPrompt:
          'Before Account Lookup, verify identity.',
      targetText:
          'I can help with that. For your security, may I verify your full name and registered email first?',
      successReply: 'Correct. Verification before lookup.',
      failReply: 'Verify identity before opening account details.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Maya Santos, maya.santos@email.com.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.accountSearch,
      text: 'Search account',
      missionStepId: 'search',
      coachPrompt:
          'Open Account Lookup and search for the customer. Type the search text exactly.',
      searchTarget: 'Maya Santos',
      successReply: 'Good search. Matching accounts are shown.',
      failReply: 'Search for Maya Santos exactly.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.accountSelect,
      text: 'Select account',
      missionStepId: 'select',
      coachPrompt:
          'Select the correct account. Choose Maya Santos with account FIN-20418, not similar names.',
      selectAccountId: 'FIN-20418',
      successReply: 'Correct account selected.',
      failReply: 'Select FIN-20418 for Maya Santos.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Explain status',
      missionStepId: 'explain',
      coachPrompt:
          'Use the account details to explain the transfer status clearly.',
      targetText:
          'I found your account. Your transfer TXN-88921 is still processing from this morning. Please allow up to 24 hours for completion.',
      successReply: 'Clear account-based explanation.',
      failReply: 'Explain the processing status using the account details.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Okay. That makes sense. Thank you.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.accountResolve,
      text: 'Resolve',
      missionStepId: 'resolve',
      coachPrompt:
          'The customer is helped. Mark the issue as resolved in Account Lookup.',
      successReply: 'Issue marked resolved. Good tool habit.',
      failReply: 'Mark the issue as resolved to finish the account workflow.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Closing',
      missionStepId: 'close',
      coachPrompt: 'Close the chat properly.',
      targetText:
          'You are welcome. Is there anything else I can help you with today? Thank you for contacting Horizon Finance Support.',
      successReply: 'Strong close after account handling.',
      failReply: 'Use the full closing line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'That is all.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'Complete. You practiced verify → search → select correct account → explain → resolve → close.',
    ),
  ],
);
