import 'package:trainixprogram/models/training/scenarios/scenario_models.dart';

const chatScenario8 = ScenarioDefinition(
  id: 'chat_8',
  title: 'Non-Voice Scenario #8 - Needs Escalation',
  channel: 'chat',
  sector: 'Finance',
  customerName: 'Chris Navarro',
  problem: 'Demands permanent fee removal and legal threats',
  emotion: 'Angry',
  targetSkills: [
    'Empathy',
    'Positive Scripting',
    'Sector Knowledge',
    'Escalation',
    'Closing Spiel',
  ],
  maxMistakes: 3,
  isGuided: false,
  order: 8,
  usesAccountLookup: false,
  missionSteps: [
    ScenarioMissionStep(id: 'respond', label: 'Respond with empathy and limits'),
    ScenarioMissionStep(id: 'escalate', label: 'Escalate to a specialist'),
    ScenarioMissionStep(id: 'close', label: 'Close after escalation'),
  ],
  turns: [
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'Some cases cannot be fully solved by a new agent. Stay calm, set limits, and escalate properly.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text:
          'Remove this fee permanently right now or I will sue your company. Do it immediately.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.chooseOne,
      text: 'First response',
      missionStepId: 'respond',
      coachPrompt: 'Choose the strongest first response.',
      options: [
        'Threatening us will not help. Fee stays.',
        'I understand this is upsetting. I cannot authorize a permanent fee removal myself, but I can escalate this to a specialist who can review it under policy.',
        'Okay, permanent removal done. No review needed.',
      ],
      correctIndex: 1,
      successReply: 'Good. Empathy, honest limit, and escalation path.',
      failReply: 'Do not fight the customer or overpromise. Escalate properly.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Then escalate it. I want someone with authority.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Escalate',
      missionStepId: 'escalate',
      coachPrompt:
          'Confirm escalation clearly and set an honest next expectation.',
      targetText:
          'I am escalating your case to a billing specialist now. They will review it under policy and follow up through your registered email.',
      successReply: 'Clear escalation handoff.',
      failReply: 'State the escalation and follow-up path clearly.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Fine. Make sure they contact me.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Close',
      missionStepId: 'close',
      coachPrompt: 'Close after escalation without pretending it is fully solved.',
      targetText:
          'I have completed the escalation request. Is there anything else I can help you with today? Thank you for contacting Horizon Finance Support.',
      successReply: 'Professional close after escalation.',
      failReply: 'Use the guided closing line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'No.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'Complete. Key lesson: when authority is exceeded, escalate instead of forcing a false resolution.',
    ),
  ],
);
