import 'package:trainixprogram/models/training/scenarios/scenario_models.dart';

const voiceScenario9 = ScenarioDefinition(
  id: 'voice_9',
  title: 'Voice Scenario #9 - Already Restored On Check',
  channel: 'voice',
  sector: 'Telco',
  customerName: 'Owen Blake',
  problem: 'Believes home internet is still down, but system shows restored',
  emotion: 'Frustrated',
  targetSkills: [
    'Opening Spiel',
    'Empathy',
    'Account Lookup',
    'Communication Clarity',
    'Closing Spiel',
  ],
  maxMistakes: 3,
  isGuided: false,
  order: 9,
  usesAccountLookup: true,
  missionSteps: [
    ScenarioMissionStep(id: 'open', label: 'Open and acknowledge concern'),
    ScenarioMissionStep(id: 'lookup', label: 'Check live account status'),
    ScenarioMissionStep(id: 'clarify', label: 'Clarify already-restored service'),
    ScenarioMissionStep(id: 'resolve', label: 'Resolve and close'),
  ],
  accounts: [
    ScenarioAccount(
      accountId: 'TEL-11022',
      ownerName: 'Owen Black',
      details: {
        'Service Address': '9 Oak Lane',
        'Line Status': 'Outage',
        'Outage Flag': 'Node maintenance',
        'Last Update': 'Ongoing',
      },
    ),
    ScenarioAccount(
      accountId: 'TEL-22033',
      ownerName: 'Owen Blake',
      isTarget: true,
      details: {
        'Service Address': '14 Cedar Street',
        'Line Status': 'Active',
        'Outage Flag': 'None',
        'Last Update': 'Service restored 15 minutes ago',
      },
    ),
    ScenarioAccount(
      accountId: 'TEL-33044',
      ownerName: 'Owen Blakely',
      details: {
        'Service Address': '2 Cedar Street',
        'Line Status': 'Active',
        'Outage Flag': 'None',
        'Last Update': 'Stable',
      },
    ),
    ScenarioAccount(
      accountId: 'TEL-44055',
      ownerName: 'Olivia Blake',
      details: {
        'Service Address': '14 Cedar Street',
        'Line Status': 'Suspended',
        'Outage Flag': 'None',
        'Last Update': 'Payment hold',
      },
    ),
    ScenarioAccount(
      accountId: 'TEL-55066',
      ownerName: 'Sam Ortiz',
      details: {
        'Service Address': '18 River Road',
        'Line Status': 'Active',
        'Outage Flag': 'None',
        'Last Update': 'Stable',
      },
    ),
    ScenarioAccount(
      accountId: 'TEL-66077',
      ownerName: 'Jordan Lee',
      details: {
        'Service Address': '3 Maple Drive',
        'Line Status': 'Outage',
        'Outage Flag': 'Area cutover',
        'Last Update': 'ETA 1 hour',
      },
    ),
  ],
  turns: [
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'Some voice problems are already fixed in the system. Check Account Lookup before promising field work.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text:
          'My internet is still down. Send a technician today. I have been offline for hours.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Opening',
      missionStepId: 'open',
      coachPrompt: 'Open and acknowledge. Say:',
      targetText:
          'Thank you for calling Horizon Mobile. This is Alex. I understand service interruptions are frustrating. How can I help?',
      successReply: 'Good open under frustration.',
      failReply: 'Speak the full opening acknowledgment.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Just send someone. My account is Owen Blake.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.accountSearch,
      text: 'Search',
      missionStepId: 'lookup',
      coachPrompt:
          'Open Account Lookup and search for Owen Blake, then Confirm Search.',
      searchTarget: 'Owen Blake',
      successReply: 'Search complete. Select the correct account.',
      failReply: 'Search using Owen Blake.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.accountSelect,
      text: 'Select',
      missionStepId: 'lookup',
      coachPrompt:
          'Select Owen Blake, account TEL-22033, then Confirm Selected Account.',
      selectAccountId: 'TEL-22033',
      successReply: 'Correct account. Note the restored status.',
      failReply: 'Select TEL-22033 for Owen Blake.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Clarify',
      missionStepId: 'clarify',
      coachPrompt: 'Clarify already restored service. Say:',
      targetText:
          'I checked your line and service was restored fifteen minutes ago. Please restart your modem and test a webpage with me.',
      successReply: 'Clear clarification without over-escalating.',
      failReply: 'Explain the restored status fully.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Oh. After the restart it is working. Sorry about that.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.accountResolve,
      text: 'Resolve',
      missionStepId: 'resolve',
      coachPrompt: 'Mark the case resolved on the correct account.',
      successReply: 'Case closed in system.',
      failReply: 'Resolve on the correct target account.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Closing',
      missionStepId: 'resolve',
      coachPrompt: 'Close the call. Say:',
      targetText:
          'No problem at all. Is there anything else I can help you with today? Thank you for calling Horizon Mobile.',
      successReply: 'Strong close after a false-alarm outage.',
      failReply: 'Speak the full closing line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'No, thank you.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'Complete. Key voice lesson: check live status before dispatching or escalating.',
    ),
  ],
);
