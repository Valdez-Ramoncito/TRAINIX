import 'package:trainixprogram/models/training/scenarios/scenario_models.dart';

const chatScenario4 = ScenarioDefinition(
  id: 'chat_4',
  title: 'Non-Voice Scenario #4 - No Internet Tonight',
  channel: 'chat',
  sector: 'Telco',
  customerName: 'Sam Ortiz',
  problem: 'No internet service and suspects an outage',
  emotion: 'Irritated',
  targetSkills: [
    'Opening Spiel',
    'Empathy',
    'Problem Identification',
    'Sector Knowledge',
    'Solution Delivery',
    'Closing Spiel',
  ],
  maxMistakes: 3,
  isGuided: false,
  order: 4,
  missionSteps: [
    ScenarioMissionStep(id: 'open', label: 'Open calmly under pressure'),
    ScenarioMissionStep(id: 'empathy', label: 'Acknowledge the service disruption'),
    ScenarioMissionStep(id: 'diagnose', label: 'Confirm service details and check outage'),
    ScenarioMissionStep(id: 'update', label: 'Share clear outage status and next step'),
    ScenarioMissionStep(id: 'close', label: 'Close the chat'),
  ],
  turns: [
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'For telco issues, confirm the affected service and check known outages early.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text:
          'My internet has been down all evening. This is unacceptable. Fix it now.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Opening',
      missionStepId: 'open',
      coachPrompt: 'Stay calm and open professionally.',
      targetText:
          'Thank you for contacting Horizon Telco Support. This is Alex. How may I help you today?',
      successReply: 'Good opening under pressure.',
      failReply: 'Use the full telco opening line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'I already said it. No internet. What are you going to do?',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Empathy',
      missionStepId: 'empathy',
      coachPrompt: 'Acknowledge the irritation, then move to diagnosis.',
      targetText:
          'I understand how disruptive a sudden internet outage can be, and I am here to help sort this out.',
      successReply: 'Good tone control with an irritated customer.',
      failReply: 'Acknowledge the disruption first.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Fine. Just tell me if this is an area outage.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Diagnose',
      missionStepId: 'diagnose',
      coachPrompt:
          'Confirm the service and check for known outage as an early step.',
      targetText:
          'I can check that. May I confirm the service address on the account and look for any known outage in your area?',
      successReply: 'Strong early telco diagnosis step.',
      failReply: 'Confirm the service and check for known outages.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Yes. 18 River Road. Please check.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Solution',
      missionStepId: 'update',
      coachPrompt: 'Give a clear status and next step.',
      targetText:
          'There is a known outage in your area. Restoration is in progress, and I can send updates to your registered mobile number.',
      successReply: 'Clear outage update.',
      failReply: 'Use the guided outage update line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Alright. Send the updates.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Closing',
      missionStepId: 'close',
      coachPrompt: 'Close with further help and a polite sign-off.',
      targetText:
          'I have set that up. Is there anything else I can help you with today? Thank you for contacting Horizon Telco Support.',
      successReply: 'Good telco closing.',
      failReply: 'Use the full closing line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'No. That is it.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'Complete. Key lesson: with telco issues, confirm service details and known outages early.',
    ),
  ],
);
