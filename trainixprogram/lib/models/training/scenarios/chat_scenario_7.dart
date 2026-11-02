import 'package:trainixprogram/models/training/scenarios/scenario_models.dart';

const chatScenario7 = ScenarioDefinition(
  id: 'chat_7',
  title: 'Non-Voice Scenario #7 - No Account Lookup Needed',
  channel: 'chat',
  sector: 'Tech Support',
  customerName: 'Avery Cruz',
  problem: 'Wants steps to turn on two-factor authentication',
  emotion: 'Curious',
  targetSkills: [
    'Opening Spiel',
    'Communication Clarity',
    'Solution Delivery',
    'Closing Spiel',
  ],
  maxMistakes: 3,
  isGuided: false,
  order: 7,
  usesAccountLookup: false,
  missionSteps: [
    ScenarioMissionStep(id: 'open', label: 'Open the chat'),
    ScenarioMissionStep(id: 'approach', label: 'Choose guidance without account lookup'),
    ScenarioMissionStep(id: 'steps', label: 'Give clear how-to steps'),
    ScenarioMissionStep(id: 'close', label: 'Close the chat'),
  ],
  turns: [
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'Not every case needs Account Lookup. This is a how-to request. Guide the customer with clear steps only.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text:
          'Hi. How do I turn on two-factor authentication on my app? I do not need account changes, just the steps.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Opening',
      missionStepId: 'open',
      coachPrompt: 'Open the tech chat professionally.',
      targetText:
          'Thank you for contacting Horizon Support. This is Alex. How may I help you today?',
      successReply: 'Good opening.',
      failReply: 'Use the full opening line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Just the 2FA steps please.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.chooseOne,
      text: 'Approach',
      missionStepId: 'approach',
      coachPrompt:
          'Choose the best approach for a non-account how-to question.',
      options: [
        'Sure. First let me open Account Lookup and pull your full profile.',
        'I can guide you through the steps directly. No account lookup is needed for this how-to request.',
        'I cannot help unless you give me your password.',
      ],
      correctIndex: 1,
      successReply: 'Correct. No lookup needed for pure how-to guidance.',
      failReply: 'Do not force Account Lookup for a simple how-to request.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Steps',
      missionStepId: 'steps',
      coachPrompt: 'Give clear step-by-step instructions.',
      targetText:
          'Open Settings, choose Security, select Two-Factor Authentication, then follow the on-screen prompts to finish setup.',
      successReply: 'Clear steps. Easy for the customer to follow.',
      failReply: 'Provide the guided step-by-step line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Got it. That worked.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Closing',
      missionStepId: 'close',
      coachPrompt: 'Close politely.',
      targetText:
          'Glad that helped. Is there anything else I can help you with today? Thank you for contacting Horizon Support.',
      successReply: 'Clean close without unnecessary tools.',
      failReply: 'Use the full closing line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'No, thanks.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'Complete. Key lesson: if the request is pure guidance, solve it without Account Lookup.',
    ),
  ],
);
