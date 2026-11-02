import 'package:trainixprogram/models/training/scenarios/scenario_models.dart';

const chatScenario3 = ScenarioDefinition(
  id: 'chat_3',
  title: 'Non-Voice Scenario #3 - Appointment Confusion',
  channel: 'chat',
  sector: 'Healthcare',
  customerName: 'Riley Chen',
  problem: 'Needs to reschedule an appointment and asks for medical advice',
  emotion: 'Worried',
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
    ScenarioMissionStep(id: 'open', label: 'Open the healthcare chat'),
    ScenarioMissionStep(id: 'scope', label: 'Stay in scope and avoid medical advice'),
    ScenarioMissionStep(id: 'verify', label: 'Verify identity before schedule changes'),
    ScenarioMissionStep(id: 'schedule', label: 'Help with appointment scheduling'),
    ScenarioMissionStep(id: 'close', label: 'Close professionally'),
  ],
  turns: [
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'Healthcare support protects privacy and stays within approved scope. Avoid giving medical treatment advice.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text:
          'Hi. I need to move my appointment and also want you to tell me which treatment I should choose.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Opening',
      missionStepId: 'open',
      coachPrompt: 'Open clearly for healthcare support.',
      targetText:
          'Thank you for contacting Horizon Health Support. This is Alex. How may I help you today?',
      successReply: 'Good healthcare opening.',
      failReply: 'Use the full healthcare opening line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text:
          'Can you just tell me the best treatment option? I am worried and I need an answer now.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Scope + empathy',
      coachPrompt:
          'Show empathy, but stay in support scope. Do not choose a treatment for the customer.',
      targetText:
          'I understand this is worrying. I can help with appointment scheduling, but I cannot recommend a specific treatment. A licensed provider can guide that decision.',
      successReply: 'Correct. Empathy without unauthorized medical advice.',
      failReply: 'Do not recommend treatment. Use the guided scope-safe line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Okay. Then can you help me reschedule to Friday afternoon?',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Verification',
      missionStepId: 'verify',
      coachPrompt:
          'Before changing appointment details, verify identity.',
      targetText:
          'Yes, I can help with scheduling. For privacy, may I verify your full name and date of birth first?',
      successReply: 'Good. Privacy verification before account changes.',
      failReply: 'Verify identity before changing appointment details.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Riley Chen, March 12, 1994.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Solution',
      missionStepId: 'schedule',
      coachPrompt: 'Confirm the scheduling action clearly.',
      targetText:
          'Thank you. I can request a Friday afternoon appointment and send a confirmation once it is available.',
      successReply: 'Clear scheduling next step.',
      failReply: 'Use the guided scheduling line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'That works. Thank you.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Closing',
      missionStepId: 'close',
      coachPrompt: 'Close politely and offer further help.',
      targetText:
          'You are welcome. Is there anything else I can help you with today? Thank you for contacting Horizon Health Support.',
      successReply: 'Strong healthcare closing.',
      failReply: 'Use the full closing line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'No, that is everything.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'Complete. Key lesson: protect privacy and stay within approved healthcare support scope.',
    ),
  ],
);
