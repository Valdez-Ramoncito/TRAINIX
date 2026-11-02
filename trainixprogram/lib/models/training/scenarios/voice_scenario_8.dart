import 'package:trainixprogram/models/training/scenarios/scenario_models.dart';

const voiceScenario8 = ScenarioDefinition(
  id: 'voice_8',
  title: 'Voice Scenario #8 - No Account Lookup Needed',
  channel: 'voice',
  sector: 'Tech Support',
  customerName: 'Tara Quinn',
  problem: 'Wants steps to enable two-factor authentication on a new phone',
  emotion: 'Neutral',
  targetSkills: [
    'Opening Spiel',
    'Communication Clarity',
    'Solution Delivery',
    'Closing Spiel',
  ],
  maxMistakes: 3,
  isGuided: false,
  order: 8,
  usesAccountLookup: false,
  missionSteps: [
    ScenarioMissionStep(id: 'open', label: 'Open the call'),
    ScenarioMissionStep(id: 'approach', label: 'Choose guidance without account lookup'),
    ScenarioMissionStep(id: 'steps', label: 'Give clear how-to steps'),
    ScenarioMissionStep(id: 'close', label: 'Close the call'),
  ],
  turns: [
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'Not every voice call needs Account Lookup. This is a pure how-to request.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text:
          'I got a new phone. Can you walk me through turning on two-factor authentication? I do not need account changes.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Opening',
      missionStepId: 'open',
      coachPrompt: 'Open the call. Say:',
      targetText:
          'Thank you for calling Horizon Support. This is Alex. How can I help you today?',
      successReply: 'Good opening.',
      failReply: 'Speak the full opening line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Just the setup steps please. No account lookup needed.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Approach',
      missionStepId: 'approach',
      coachPrompt: 'Confirm you can guide without opening Account Lookup. Say:',
      targetText:
          'I can walk you through two-factor setup on your new phone without opening your account details.',
      successReply: 'Correct. No tool needed for pure how-to.',
      failReply: 'Do not open Account Lookup. Use the guided how-to approach line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Great. What should I do first?',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Steps',
      missionStepId: 'steps',
      coachPrompt: 'Give clear spoken steps. Say:',
      targetText:
          'Open Settings, choose Security, select Two-Factor Authentication, then follow the on-screen prompts to link your new phone.',
      successReply: 'Clear spoken steps.',
      failReply: 'Speak the full setup steps.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'That worked. I am set up now.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Closing',
      missionStepId: 'close',
      coachPrompt: 'Close the call. Say:',
      targetText:
          'Glad that worked. Is there anything else I can help you with today? Thank you for calling Horizon Support.',
      successReply: 'Clean close without unnecessary tools.',
      failReply: 'Speak the full closing line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'No, that is all.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'Complete. Key voice lesson: use Account Lookup only when account data is required.',
    ),
  ],
);
