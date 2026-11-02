import 'package:trainixprogram/models/training/scenarios/scenario_models.dart';

const chatScenario1 = ScenarioDefinition(
  id: 'chat_1',
  title: 'Non-Voice Scenario #1 - A Not-So-Techy Customer',
  channel: 'chat',
  sector: 'Tech Support',
  customerName: 'Jordan Lee',
  problem: 'Cannot log in after a password reset',
  emotion: 'Frustrated',
  targetSkills: [
    'Opening Spiel',
    'Empathy',
    'Problem Identification',
    'Solution Delivery',
    'Closing Spiel',
  ],
  maxMistakes: 3,
  isGuided: true,
  order: 1,
  missionSteps: [
    ScenarioMissionStep(id: 'open', label: 'Open with a full professional greeting'),
    ScenarioMissionStep(id: 'empathy', label: 'Acknowledge the customer frustration'),
    ScenarioMissionStep(id: 'confirm', label: 'Confirm the login problem'),
    ScenarioMissionStep(id: 'solve', label: 'Give a clear next step to try'),
    ScenarioMissionStep(id: 'close', label: 'Close the chat properly'),
  ],
  turns: [
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'Welcome to your first guided chat scenario. I will walk you through each step.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'Handle a frustrated tech customer with opening, empathy, confirmation, solution, and closing.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text:
          'Hi. I reset my password already but I still cannot log in. This is really frustrating.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Opening',
      missionStepId: 'open',
      coachPrompt:
          'Start with a full Opening Spiel so the customer knows who you are and that you can help.',
      targetText:
          'Thank you for contacting Horizon Support. This is Alex. How may I help you today?',
      successReply: 'Good. A complete opening builds trust right away.',
      failReply: 'Use the full guided Opening Spiel line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'I already told you. I cannot log in after resetting my password.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Empathy',
      missionStepId: 'empathy',
      coachPrompt:
          'Acknowledge the frustration before troubleshooting.',
      targetText:
          'I understand how frustrating login issues can be after a password reset.',
      successReply: 'Good empathy. The customer feels heard.',
      failReply: 'Type the guided empathy line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Yeah. I just need this fixed so I can get back into my account.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Confirm problem',
      missionStepId: 'confirm',
      coachPrompt:
          'Confirm the main issue before giving a fix.',
      targetText:
          'Just to make sure I understand, you already reset your password but still cannot log in. Is that correct?',
      successReply: 'Good confirmation.',
      failReply: 'Type the guided confirmation line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Yes. That is exactly the problem.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Solution',
      missionStepId: 'solve',
      coachPrompt: 'Give a clear next step the customer can follow.',
      targetText:
          'Please try signing in with the newest password on a refreshed browser page. I will stay with you while you try that.',
      successReply: 'Clear solution delivery.',
      failReply: 'Type the guided solution line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Okay, that worked. I am in now.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Closing',
      missionStepId: 'close',
      coachPrompt:
          'Close properly: confirm success, offer further help, and sign off.',
      targetText:
          'I am glad that worked. Is there anything else I can help you with today? Thank you for contacting Horizon Support.',
      successReply: 'Strong closing. Guided flow complete.',
      failReply: 'Type the full guided closing line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'No, that is all. Thanks for the help.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'Scenario complete. You practiced the full service path in a guided tech chat.',
    ),
  ],
);
