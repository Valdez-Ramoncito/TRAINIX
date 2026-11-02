import 'package:trainixprogram/models/training/scenarios/scenario_models.dart';

const voiceScenario1 = ScenarioDefinition(
  id: 'voice_1',
  title: 'Voice Scenario #1 - Slow Data After Plan Change',
  channel: 'voice',
  sector: 'Telco',
  customerName: 'Priya Nair',
  problem: 'Mobile data became very slow right after a plan change',
  emotion: 'Annoyed',
  targetSkills: [
    'Opening Spiel',
    'Empathy',
    'Active Listening',
    'Solution Delivery',
    'Closing Spiel',
  ],
  maxMistakes: 3,
  isGuided: true,
  order: 1,
  missionSteps: [
    ScenarioMissionStep(id: 'open', label: 'Open the call clearly'),
    ScenarioMissionStep(id: 'empathy', label: 'Acknowledge the annoyance'),
    ScenarioMissionStep(id: 'confirm', label: 'Confirm the slow-data issue'),
    ScenarioMissionStep(id: 'solve', label: 'Offer a simple network check'),
    ScenarioMissionStep(id: 'close', label: 'Close the call cleanly'),
  ],
  turns: [
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'This is your first guided voice call. Speak naturally, but stay close to each coached line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'On voice, keep sentences short and steady. Record, speak, then stop for a transcript check.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text:
          'My data has been crawling since you changed my plan yesterday. Streaming barely works.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Opening',
      missionStepId: 'open',
      coachPrompt:
          'Open the call with a clear spoken greeting. Press record and say:',
      targetText:
          'Thank you for calling Horizon Mobile. This is Alex speaking. How can I help you today?',
      successReply: 'Solid voice opening. Short and clear.',
      failReply: 'Try again. Speak the full opening line at a steady pace.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text:
          'I already said it. After the plan change, my data is almost unusable.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Empathy',
      missionStepId: 'empathy',
      coachPrompt: 'Show you heard the frustration. Say:',
      targetText:
          'I hear how annoying slow data is, especially right after a plan change.',
      successReply: 'Good spoken empathy.',
      failReply: 'Try again. Keep the empathy line clear and complete.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Yes. I need this working before tonight.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Confirm',
      missionStepId: 'confirm',
      coachPrompt: 'Confirm the issue in one clean sentence. Say:',
      targetText:
          'So your mobile data slowed down right after yesterday plan change. Is that right?',
      successReply: 'Clear confirmation. Nice pacing.',
      failReply: 'Try again. Confirm the slow-data timing in full.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'That is right. What can you do?',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Solution',
      missionStepId: 'solve',
      coachPrompt: 'Give one simple next step the customer can do now. Say:',
      targetText:
          'Please turn airplane mode on for ten seconds, then off, and test a short video. I will stay on the line.',
      successReply: 'Practical spoken solution.',
      failReply: 'Try again. Speak the full next-step instruction.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Okay, that helped. Speed looks normal again.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Closing',
      missionStepId: 'close',
      coachPrompt: 'Close the call with help offer and sign-off. Say:',
      targetText:
          'Glad that helped. Is there anything else I can assist with today? Thank you for calling Horizon Mobile.',
      successReply: 'Clean voice close. Guided call complete.',
      failReply: 'Try again. Speak the full closing line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'No, that is all. Thanks.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'Complete. You practiced a short, spoken service path built for voice, not chat typing.',
    ),
  ],
);
