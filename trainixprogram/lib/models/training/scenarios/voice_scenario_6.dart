import 'package:trainixprogram/models/training/scenarios/scenario_models.dart';

const voiceScenario6 = ScenarioDefinition(
  id: 'voice_6',
  title: 'Voice Scenario #6 - Needs Specialist Escalation',
  channel: 'voice',
  sector: 'Finance',
  customerName: 'Irene Cole',
  problem: 'Demands permanent fee removal and mentions legal action',
  emotion: 'Hostile',
  targetSkills: [
    'Empathy',
    'Positive Scripting',
    'Sector Knowledge',
    'Escalation',
    'Closing Spiel',
  ],
  maxMistakes: 3,
  isGuided: false,
  order: 6,
  missionSteps: [
    ScenarioMissionStep(id: 'respond', label: 'Respond with empathy and limits'),
    ScenarioMissionStep(id: 'escalate', label: 'Escalate to a specialist'),
    ScenarioMissionStep(id: 'close', label: 'Close after escalation'),
  ],
  turns: [
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'Some voice cases exceed new-agent authority. Stay calm, set limits, and escalate.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text:
          'Remove this fee permanently right now or I will take legal action. Do it immediately.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Respond',
      missionStepId: 'respond',
      coachPrompt: 'Respond with empathy, limit, and escalation path. Say:',
      targetText:
          'I understand this is upsetting. I cannot authorize a permanent fee removal myself, but I can escalate this to a specialist who can review it under policy.',
      successReply: 'Correct first response under pressure.',
      failReply: 'Do not fight or overpromise. Use the guided escalation-ready line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Then escalate it. I want someone with authority.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Escalate',
      missionStepId: 'escalate',
      coachPrompt: 'Confirm the escalation clearly. Say:',
      targetText:
          'I am escalating your case to a billing specialist now. They will review it under policy and follow up through your registered email.',
      successReply: 'Clear escalation handoff.',
      failReply: 'State the escalation and follow-up path fully.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Make sure they contact me.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Closing',
      missionStepId: 'close',
      coachPrompt: 'Close without pretending it is fully solved. Say:',
      targetText:
          'I have completed the escalation request. Is there anything else I can help you with today? Thank you for calling Horizon Finance.',
      successReply: 'Professional close after escalation.',
      failReply: 'Speak the full closing line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'No.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text: 'Complete. Key voice lesson: when authority ends, escalate cleanly.',
    ),
  ],
);
