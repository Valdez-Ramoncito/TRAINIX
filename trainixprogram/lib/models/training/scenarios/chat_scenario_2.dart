import 'package:trainixprogram/models/training/scenarios/scenario_models.dart';

const chatScenario2 = ScenarioDefinition(
  id: 'chat_2',
  title: 'Non-Voice Scenario #2 - Failed Transfer Worry',
  channel: 'chat',
  sector: 'Finance',
  customerName: 'Maya Santos',
  problem: 'Transfer did not arrive and wants account details checked',
  emotion: 'Anxious',
  targetSkills: [
    'Opening Spiel',
    'Sector Knowledge',
    'Problem Identification',
    'Solution Delivery',
    'Closing Spiel',
  ],
  maxMistakes: 3,
  isGuided: false,
  order: 2,
  missionSteps: [
    ScenarioMissionStep(id: 'open', label: 'Open the finance chat'),
    ScenarioMissionStep(id: 'verify', label: 'Verify identity before account details'),
    ScenarioMissionStep(id: 'confirm', label: 'Confirm the transfer issue'),
    ScenarioMissionStep(id: 'update', label: 'Give an honest transfer status update'),
    ScenarioMissionStep(id: 'close', label: 'Close professionally'),
  ],
  turns: [
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'Finance chats often need identity verification before account details. Follow the coach prompts carefully.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text:
          'Hello. I sent a transfer this morning and it still has not arrived. Can you check my account right now?',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Opening',
      missionStepId: 'open',
      coachPrompt:
          'Open professionally before handling the account request.',
      targetText:
          'Thank you for contacting Horizon Finance Support. This is Alex. How may I help you today?',
      successReply: 'Good opening for a finance chat.',
      failReply: 'Use the full finance opening line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text:
          'I need you to check why my transfer is missing. Here is my full account number if that helps: 1234567890.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Verification',
      missionStepId: 'verify',
      coachPrompt:
          'Do not jump into account details yet. Verify identity first using an approved request.',
      targetText:
          'I can help with that. For your security, may I please verify your full name and registered email before reviewing the transfer?',
      successReply: 'Correct. Verification comes before account review.',
      failReply: 'Ask for verification before reviewing account information.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Sure. My name is Maya Santos and my email is maya.santos@email.com.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Confirm problem',
      missionStepId: 'confirm',
      coachPrompt:
          'After verification, confirm the problem clearly.',
      targetText:
          'Thank you. Just to confirm, you sent a transfer this morning and it has not arrived yet. Is that right?',
      successReply: 'Good confirmation after verification.',
      failReply: 'Confirm the transfer issue clearly.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Yes. Please tell me what happened.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Solution',
      missionStepId: 'update',
      coachPrompt:
          'Give a clear, honest next step without guessing approval outcomes.',
      targetText:
          'I can see the transfer is still processing. Please allow up to 24 hours, and I can also provide a reference number for tracking.',
      successReply: 'Clear finance update without overpromising.',
      failReply: 'Use the guided finance update line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Okay. That helps. Thank you.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Closing',
      missionStepId: 'close',
      coachPrompt: 'Close with further help and a polite sign-off.',
      targetText:
          'You are welcome. Is there anything else I can help you with today? Thank you for contacting Horizon Finance Support.',
      successReply: 'Solid finance closing.',
      failReply: 'Use the full closing line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'That is all for now.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'Complete. Key lesson: in finance, verify identity before discussing account details.',
    ),
  ],
);
