import 'package:trainixprogram/models/training/scenarios/scenario_models.dart';

const voiceScenario2 = ScenarioDefinition(
  id: 'voice_2',
  title: 'Voice Scenario #2 - Missing Card Payment',
  channel: 'voice',
  sector: 'Finance',
  customerName: 'Daniel Cruz',
  problem: 'Card payment shows pending and customer is worried about double charge',
  emotion: 'Worried',
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
    ScenarioMissionStep(id: 'open', label: 'Open the finance call'),
    ScenarioMissionStep(id: 'verify', label: 'Verify identity first'),
    ScenarioMissionStep(id: 'confirm', label: 'Confirm the pending payment concern'),
    ScenarioMissionStep(id: 'update', label: 'Explain pending status clearly'),
    ScenarioMissionStep(id: 'close', label: 'Close the call'),
  ],
  turns: [
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'Finance voice calls need verification before account details. Speak the coached lines.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text:
          'My payment is still pending and I am afraid I will be charged twice. Can you check my card right now?',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Opening',
      missionStepId: 'open',
      coachPrompt: 'Open the finance call. Say:',
      targetText:
          'Thank you for calling Horizon Finance. This is Alex. How may I help you today?',
      successReply: 'Good finance opening.',
      failReply: 'Speak the full finance opening again.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Just look at my account and tell me if I will be charged twice.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Verify',
      missionStepId: 'verify',
      coachPrompt: 'Verify identity before account details. Say:',
      targetText:
          'I can help with that. For security, may I verify your full name and the email on the account?',
      successReply: 'Correct. Verification before account talk.',
      failReply: 'Ask for verification before reviewing the account.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Daniel Cruz, daniel.cruz@email.com.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Confirm',
      missionStepId: 'confirm',
      coachPrompt: 'Confirm the concern. Say:',
      targetText:
          'Thank you. You are concerned a pending card payment might post twice. Is that correct?',
      successReply: 'Clear confirmation.',
      failReply: 'Confirm the pending payment concern fully.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Yes. Please tell me what is happening.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Update',
      missionStepId: 'update',
      coachPrompt: 'Give an honest status update. Say:',
      targetText:
          'The payment is still pending and has not posted twice. Please allow up to one business day for it to complete.',
      successReply: 'Honest and calm finance update.',
      failReply: 'Explain the pending status without overpromising.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Alright. That reduces me a bit.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Closing',
      missionStepId: 'close',
      coachPrompt: 'Close the call. Say:',
      targetText:
          'I am glad that helped. Is there anything else I can assist with today? Thank you for calling Horizon Finance.',
      successReply: 'Strong close.',
      failReply: 'Speak the full closing line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'No, that is all.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text: 'Complete. Key voice lesson: verify first, then explain account status calmly.',
    ),
  ],
);
