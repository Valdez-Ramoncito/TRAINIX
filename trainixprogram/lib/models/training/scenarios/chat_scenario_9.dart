import 'package:trainixprogram/models/training/scenarios/scenario_models.dart';

const chatScenario9 = ScenarioDefinition(
  id: 'chat_9',
  title: 'Non-Voice Scenario #9 - Already Resolved',
  channel: 'chat',
  sector: 'Telco',
  customerName: 'Sam Ortiz',
  problem: 'Thinks internet is still down, but service is already restored',
  emotion: 'Irritated',
  targetSkills: [
    'Empathy',
    'Problem Identification',
    'Sector Knowledge',
    'Communication Clarity',
    'Closing Spiel',
  ],
  maxMistakes: 3,
  isGuided: false,
  order: 9,
  usesAccountLookup: true,
  accounts: [
    ScenarioAccount(
      accountId: 'TEL-55288',
      ownerName: 'Samuel Ortega',
      details: {
        'Service Address': '22 River Road',
        'Line Status': 'Outage',
        'Outage Flag': 'Area cutover',
        'Last Update': 'Ongoing',
      },
    ),
    ScenarioAccount(
      accountId: 'TEL-44112',
      ownerName: 'Samantha Ortiz',
      details: {
        'Service Address': '10 Lake Street',
        'Line Status': 'Active',
        'Outage Flag': 'None',
        'Last Update': 'Stable',
      },
    ),
    ScenarioAccount(
      accountId: 'TEL-33009',
      ownerName: 'Sam Ortega',
      details: {
        'Service Address': '5 River Road',
        'Line Status': 'Active',
        'Outage Flag': 'None',
        'Last Update': 'Stable',
      },
    ),
    ScenarioAccount(
      accountId: 'TEL-55201',
      ownerName: 'Sam Ortiz',
      isTarget: true,
      details: {
        'Service Address': '18 River Road',
        'Line Status': 'Active',
        'Outage Flag': 'None',
        'Last Update': 'Service restored 20 minutes ago',
      },
    ),
    ScenarioAccount(
      accountId: 'TEL-66120',
      ownerName: 'Samuel Ortiz',
      details: {
        'Service Address': '40 Hill Avenue',
        'Line Status': 'Suspended',
        'Outage Flag': 'None',
        'Last Update': 'Payment hold',
      },
    ),
    ScenarioAccount(
      accountId: 'TEL-77015',
      ownerName: 'Sandy Ortiz',
      details: {
        'Service Address': '12 River Road',
        'Line Status': 'Active',
        'Outage Flag': 'None',
        'Last Update': 'Stable',
      },
    ),
    ScenarioAccount(
      accountId: 'TEL-88002',
      ownerName: 'Chris Navarro',
      details: {
        'Service Address': '99 Pine Court',
        'Line Status': 'Active',
        'Outage Flag': 'None',
        'Last Update': 'Stable',
      },
    ),
    ScenarioAccount(
      accountId: 'TEL-99040',
      ownerName: 'Jordan Lee',
      details: {
        'Service Address': '3 Maple Drive',
        'Line Status': 'Outage',
        'Outage Flag': 'Node maintenance',
        'Last Update': 'ETA 2 hours',
      },
    ),
  ],
  missionSteps: [
    ScenarioMissionStep(id: 'open', label: 'Open and acknowledge concern'),
    ScenarioMissionStep(id: 'lookup', label: 'Check live account status'),
    ScenarioMissionStep(id: 'clarify', label: 'Clarify already-restored service'),
    ScenarioMissionStep(id: 'resolve', label: 'Resolve and close'),
  ],
  turns: [
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'Sometimes the customer still feels the problem, but the system already shows restored service. Confirm carefully and avoid over-troubleshooting.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text:
          'My internet is still down. I have been waiting forever. Do something.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Opening + empathy',
      missionStepId: 'open',
      coachPrompt: 'Open and acknowledge the frustration.',
      targetText:
          'Thank you for contacting Horizon Telco Support. This is Alex. I understand how disruptive connection issues can be, and I can help check this now.',
      successReply: 'Good calm start.',
      failReply: 'Use the guided opening and empathy line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Just fix it. 18 River Road.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.accountSearch,
      text: 'Search',
      missionStepId: 'lookup',
      coachPrompt:
          'Search Account Lookup for the customer name to check live status.',
      searchTarget: 'Sam Ortiz',
      successReply: 'Search complete.',
      failReply: 'Search for Sam Ortiz.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.accountSelect,
      text: 'Select',
      missionStepId: 'lookup',
      coachPrompt:
          'Select Sam Ortiz at 18 River Road, not the similar nearby account.',
      selectAccountId: 'TEL-55201',
      successReply: 'Correct account selected.',
      failReply: 'Select TEL-55201 for Sam Ortiz.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.chooseOne,
      text: 'Explain status',
      missionStepId: 'clarify',
      coachPrompt:
          'The account shows service already restored. Choose the best response.',
      options: [
        'Your line is still fully down. There is nothing more we can see.',
        'I checked your account and the line status is already Active. Service was restored about 20 minutes ago. Please restart your modem once and test again.',
        'I will create a fake outage ticket so it looks like action was taken.',
      ],
      correctIndex: 1,
      successReply: 'Clear clarification without denying the customer experience.',
      failReply: 'Explain the restored status and a simple next check.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Oh. Let me restart it. Okay, it is working now.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.accountResolve,
      text: 'Resolve',
      missionStepId: 'resolve',
      coachPrompt:
          'The real issue is cleared. Mark the issue as resolved.',
      successReply: 'Resolved correctly after confirmation.',
      failReply: 'Mark the issue as resolved.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Closing',
      missionStepId: 'resolve',
      coachPrompt: 'Close politely.',
      targetText:
          'I am glad it is working now. Is there anything else I can help you with today? Thank you for contacting Horizon Telco Support.',
      successReply: 'Good close on a false-alarm case.',
      failReply: 'Use the full closing line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'No, thanks.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'Complete. Key lesson: check status first. Not every reported problem is still an active problem.',
    ),
  ],
);
