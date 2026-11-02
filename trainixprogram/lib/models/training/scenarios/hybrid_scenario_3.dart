import 'package:trainixprogram/models/training/scenarios/scenario_models.dart';

const hybridScenario3 = ScenarioDefinition(
  id: 'hybrid_3',
  title: 'Hybrid Scenario #3 - Competing Urgency',
  channel: 'hybrid',
  sector: 'Telco',
  customerName: 'Voice: Ruth Campos',
  problem: 'Voice angry outage | Chat quiet billing question',
  emotion: 'Angry / Calm',
  targetSkills: [
    'Empathy',
    'Multitasking',
    'Positive Scripting',
    'Prioritization',
  ],
  maxMistakes: 3,
  isGuided: false,
  order: 3,
  secondaryCustomerName: 'Ian Brooks',
  secondarySector: 'Telco',
  secondaryProblem: 'Wonders why bill is higher this month',
  secondaryEmotion: 'Calm',
  missionSteps: [
    ScenarioMissionStep(id: 'deescalate', label: 'Stabilize the angry voice call'),
    ScenarioMissionStep(id: 'park_chat', label: 'Park chat with a time expectation'),
    ScenarioMissionStep(id: 'voice_path', label: 'Give voice a real outage path'),
    ScenarioMissionStep(id: 'chat_answer', label: 'Return and answer chat billing'),
  ],
  turns: [
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'Competing urgency: angry live voice usually comes before calm chat, but chat still needs a visible hold message.',
      lane: 'both',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'My service is down AGAIN. Fix it or I cancel today!',
      lane: 'voice',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Hi, my bill looks higher this month. Can you explain the extra charge when free?',
      lane: 'chat',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Deescalate',
      missionStepId: 'deescalate',
      lane: 'voice',
      coachPrompt: 'Stabilize the angry voice customer. Say:',
      targetText:
          'I understand repeated outages are unacceptable. I am on this with you now and will check the network path for your area.',
      successReply: 'Voice de-escalation started.',
      failReply: 'Use the guided de-escalation line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Park chat',
      missionStepId: 'park_chat',
      lane: 'chat',
      coachPrompt: 'Park the calm chat with a clear wait expectation:',
      targetText:
          'Hi Ian, I see your billing question. I am handling a live outage call and will return to your chat with a full answer shortly.',
      successReply: 'Chat parked professionally.',
      failReply: 'Type the guided chat hold message.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Well? What is the outage status?',
      lane: 'voice',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Voice path',
      missionStepId: 'voice_path',
      lane: 'voice',
      coachPrompt: 'Give a concrete outage path. Say:',
      targetText:
          'There is an active node issue in your area with an estimated restore in two hours. I can also send a text alert when the node recovers.',
      successReply: 'Concrete voice path given.',
      failReply: 'Speak the full outage path.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Still waiting on the bill explanation when you can.',
      lane: 'chat',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Chat answer',
      missionStepId: 'chat_answer',
      lane: 'chat',
      coachPrompt: 'Return to chat with the billing answer:',
      targetText:
          'Thanks for waiting, Ian. The higher amount is a one-time equipment installment that ends next cycle. I can itemize it in a follow-up email if you want.',
      successReply: 'Chat received a complete answer after the hold.',
      failReply: 'Type the full billing explanation.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'Complete. Hybrid skill: de-escalate live anger, park calm work with expectations, return as promised.',
      lane: 'both',
    ),
  ],
);
