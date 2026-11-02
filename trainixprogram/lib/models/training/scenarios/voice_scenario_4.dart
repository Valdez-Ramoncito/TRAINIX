import 'package:trainixprogram/models/training/scenarios/scenario_models.dart';

const voiceScenario4 = ScenarioDefinition(
  id: 'voice_4',
  title: 'Voice Scenario #4 - App Keeps Freezing',
  channel: 'voice',
  sector: 'Tech Support',
  customerName: 'Noah Kim',
  problem: 'Mobile app freezes on the home screen after the latest update',
  emotion: 'Impatient',
  targetSkills: [
    'Opening Spiel',
    'Active Listening',
    'Communication Clarity',
    'Solution Delivery',
    'Closing Spiel',
  ],
  maxMistakes: 3,
  isGuided: false,
  order: 4,
  missionSteps: [
    ScenarioMissionStep(id: 'open', label: 'Open the tech call'),
    ScenarioMissionStep(id: 'empathy', label: 'Acknowledge the interruption'),
    ScenarioMissionStep(id: 'confirm', label: 'Confirm the freeze issue'),
    ScenarioMissionStep(id: 'steps', label: 'Give a simple recovery step'),
    ScenarioMissionStep(id: 'close', label: 'Close the call'),
  ],
  turns: [
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'This is a spoken troubleshooting call. Keep instructions short enough to follow while listening.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text:
          'Your app freezes on the home screen every time I open it after the update. Fix it fast.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Opening',
      missionStepId: 'open',
      coachPrompt: 'Open the tech call. Say:',
      targetText:
          'Thank you for calling Horizon Support. This is Alex. How can I help you today?',
      successReply: 'Good tech opening.',
      failReply: 'Speak the full opening line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'I just told you. The app freezes and I cannot get past the home screen.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Empathy',
      missionStepId: 'empathy',
      coachPrompt: 'Acknowledge the disruption. Say:',
      targetText:
          'I know a freezing app is disruptive, and I can walk you through a quick recovery step.',
      successReply: 'Good spoken acknowledgment.',
      failReply: 'Acknowledge the freeze and offer help fully.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Okay. What do I do?',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Confirm',
      missionStepId: 'confirm',
      coachPrompt: 'Confirm the issue before steps. Say:',
      targetText:
          'Just to confirm, the app freezes on the home screen right after the latest update. Is that correct?',
      successReply: 'Clear confirmation.',
      failReply: 'Confirm the freeze issue fully.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Yes. That is exactly it.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Steps',
      missionStepId: 'steps',
      coachPrompt: 'Give one clear recovery step. Say:',
      targetText:
          'Please force close the app, restart your phone, then reopen the app and test the home screen with me.',
      successReply: 'Simple spoken troubleshooting step.',
      failReply: 'Speak the full recovery instruction.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Alright, it opened normally this time.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Closing',
      missionStepId: 'close',
      coachPrompt: 'Close the call. Say:',
      targetText:
          'Glad it is working again. Is there anything else I can help you with today? Thank you for calling Horizon Support.',
      successReply: 'Clean tech close.',
      failReply: 'Speak the full closing line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'No. Thanks.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text: 'Complete. Key voice lesson: confirm first, then give one clear step at a time.',
    ),
  ],
);
