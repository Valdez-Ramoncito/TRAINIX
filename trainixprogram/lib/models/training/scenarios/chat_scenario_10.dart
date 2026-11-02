import 'package:trainixprogram/models/training/scenarios/scenario_models.dart';

const chatScenario10 = ScenarioDefinition(
  id: 'chat_10',
  title: 'Non-Voice Scenario #10 - After Chat Wrap-Up',
  channel: 'chat',
  sector: 'Tech Support',
  customerName: 'Sam Ortega',
  problem: 'Password reset completed; agent must finish wrap-up notes',
  emotion: 'Calm',
  targetSkills: [
    'Closing Spiel',
    'Solution Delivery',
    'Communication Clarity',
  ],
  maxMistakes: 3,
  isGuided: true,
  order: 10,
  missionSteps: [
    ScenarioMissionStep(id: 'confirm', label: 'Confirm the issue is resolved'),
    ScenarioMissionStep(id: 'close', label: 'Close the chat professionally'),
    ScenarioMissionStep(id: 'disposition', label: 'Choose a clear disposition'),
    ScenarioMissionStep(id: 'note', label: 'Write a short wrap-up note'),
  ],
  turns: [
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'This practice focuses on after-chat work. Real agents log the result before the next customer.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text:
          'The new password works now. Thanks for walking me through it.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Confirm resolution',
      missionStepId: 'confirm',
      coachPrompt:
          'Confirm the fix in plain words and check if they need anything else.',
      targetText:
          'Glad the new password works. Is there anything else I can help you with today?',
      successReply: 'Good confirmation before closing.',
      failReply: 'Confirm the fix and offer further help.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'That is all for now. Thank you.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Close',
      missionStepId: 'close',
      coachPrompt: 'Close with company name and a polite ending.',
      targetText:
          'Thank you for contacting Trainix Support. Have a great day.',
      successReply: 'Solid close.',
      failReply: 'Use a full closing spiel.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'Next comes after-chat work. Pick a disposition and write a short note a teammate could understand.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Disposition',
      missionStepId: 'disposition',
      coachPrompt:
          'State the disposition clearly. Example: Resolved - password reset completed.',
      targetText: 'Disposition: Resolved - password reset completed.',
      successReply: 'Clear disposition.',
      failReply: 'Write a short disposition line starting with Disposition:',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Wrap-up note',
      missionStepId: 'note',
      coachPrompt:
          'Write a brief note: problem, action taken, outcome.',
      targetText:
          'Note: Customer could not log in after reset. Guided password reset completed. Issue resolved. No follow-up needed.',
      successReply:
          'Good wrap-up note. In simulation sessions, use the After Chat Work screen the same way.',
      failReply:
          'Include problem, action, and outcome in one short note.',
    ),
  ],
);
