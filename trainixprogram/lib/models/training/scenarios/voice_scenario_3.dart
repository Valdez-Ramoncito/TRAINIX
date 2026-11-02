import 'package:trainixprogram/models/training/scenarios/scenario_models.dart';

const voiceScenario3 = ScenarioDefinition(
  id: 'voice_3',
  title: 'Voice Scenario #3 - Clinic Call Scope',
  channel: 'voice',
  sector: 'Healthcare',
  customerName: 'Elena Vargas',
  problem: 'Wants an earlier appointment and asks which medicine is better',
  emotion: 'Anxious',
  targetSkills: [
    'Opening Spiel',
    'Sector Knowledge',
    'Empathy',
    'Positive Scripting',
    'Closing Spiel',
  ],
  maxMistakes: 3,
  isGuided: false,
  order: 3,
  missionSteps: [
    ScenarioMissionStep(id: 'open', label: 'Open the healthcare call'),
    ScenarioMissionStep(id: 'scope', label: 'Stay in support scope'),
    ScenarioMissionStep(id: 'verify', label: 'Verify before schedule changes'),
    ScenarioMissionStep(id: 'help', label: 'Help with scheduling only'),
    ScenarioMissionStep(id: 'close', label: 'Close the call'),
  ],
  turns: [
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'Healthcare voice support protects privacy and stays in scope. Do not recommend medicine.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text:
          'I need an earlier appointment and I also need you to tell me which medicine is safer for me.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Opening',
      missionStepId: 'open',
      coachPrompt: 'Open the healthcare call. Say:',
      targetText:
          'Thank you for calling Horizon Health. This is Alex. How may I help you today?',
      successReply: 'Good healthcare opening.',
      failReply: 'Speak the full healthcare opening.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Just tell me the better medicine. I am anxious and I need an answer.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Scope',
      missionStepId: 'scope',
      coachPrompt: 'Show care, but stay in scope. Say:',
      targetText:
          'I understand this is stressful. I can help with appointments, but I cannot recommend a specific medicine. A licensed provider should guide that choice.',
      successReply: 'Scope-safe and empathetic.',
      failReply: 'Do not recommend medicine. Use the guided scope-safe line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Fine. Can you move me to an earlier slot this week?',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Verify',
      missionStepId: 'verify',
      coachPrompt: 'Verify identity before changing the appointment. Say:',
      targetText:
          'Yes, I can help with scheduling. For privacy, may I verify your full name and date of birth first?',
      successReply: 'Good privacy step.',
      failReply: 'Verify identity before schedule changes.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Elena Vargas, July 9, 1991.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Help',
      missionStepId: 'help',
      coachPrompt: 'Offer a clear scheduling next step. Say:',
      targetText:
          'Thank you. I can request an earlier opening this week and send a confirmation once one is available.',
      successReply: 'Clear scheduling help.',
      failReply: 'Speak the scheduling next step fully.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'That works. Thank you.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Closing',
      missionStepId: 'close',
      coachPrompt: 'Close the call. Say:',
      targetText:
          'You are welcome. Is there anything else I can help you with today? Thank you for calling Horizon Health.',
      successReply: 'Clean healthcare close.',
      failReply: 'Speak the full closing line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'No, that is everything.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text: 'Complete. Key voice lesson: empathy is fine, medical advice is not.',
    ),
  ],
);
