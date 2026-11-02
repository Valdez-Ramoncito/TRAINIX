import 'package:trainixprogram/models/training/scenarios/scenario_models.dart';

const hybridScenario1 = ScenarioDefinition(
  id: 'hybrid_1',
  title: 'Hybrid Scenario #1 - First Dual Queue',
  channel: 'hybrid',
  sector: 'Tech Support',
  customerName: 'Voice: Mina Park',
  problem: 'Voice: password reset email not arriving | Chat: shipping delay question',
  emotion: 'Mixed',
  targetSkills: [
    'Opening Spiel',
    'Multitasking',
    'Active Listening',
    'Communication Clarity',
    'Closing Spiel',
  ],
  maxMistakes: 3,
  isGuided: true,
  order: 1,
  secondaryCustomerName: 'Chris Delgado',
  secondarySector: 'Tech Support',
  secondaryProblem: 'Order status delay for a headset',
  secondaryEmotion: 'Patient',
  missionSteps: [
    ScenarioMissionStep(id: 'voice_open', label: 'Open the voice call first'),
    ScenarioMissionStep(id: 'chat_open', label: 'Open the waiting chat'),
    ScenarioMissionStep(id: 'voice_help', label: 'Give voice a clear next step'),
    ScenarioMissionStep(id: 'chat_help', label: 'Answer the chat order question'),
    ScenarioMissionStep(id: 'close_both', label: 'Close both channels cleanly'),
  ],
  turns: [
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'Hybrid practice trains simultaneous channels. Voice is live; chat can wait briefly but must not be ignored.',
      lane: 'both',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'Priority tip: greet the live voice customer first, then acknowledge the chat so both know you are present.',
      lane: 'both',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Hello? My password reset email never arrived and I am locked out.',
      lane: 'voice',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Voice open',
      missionStepId: 'voice_open',
      lane: 'voice',
      coachPrompt: 'Open the voice call first. Say:',
      targetText:
          'Thank you for calling Horizon Support. This is Alex. How may I help you today?',
      successReply: 'Voice opened. Now acknowledge chat so it is not left hanging.',
      failReply: 'Speak the full voice opening.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Hi, my headset order is late. Can someone check the shipping status?',
      lane: 'chat',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Chat open',
      missionStepId: 'chat_open',
      lane: 'chat',
      coachPrompt: 'Type a short chat acknowledgment while the call stays active:',
      targetText:
          'Hi Chris, this is Alex from Horizon Support. I am with you on chat and will check your order status shortly.',
      successReply: 'Chat acknowledged without dropping the call.',
      failReply: 'Type the guided chat acknowledgment.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Still here. What should I try for the reset email?',
      lane: 'voice',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Voice help',
      missionStepId: 'voice_help',
      lane: 'voice',
      coachPrompt: 'Give the voice customer one clear step. Say:',
      targetText:
          'Please check spam and wait two minutes, then request a new reset link from the login page while I stay with you.',
      successReply: 'Clear voice next step.',
      failReply: 'Speak the full voice next step.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Okay, thanks. Also any update on my order when you can.',
      lane: 'chat',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Chat help',
      missionStepId: 'chat_help',
      lane: 'chat',
      coachPrompt: 'Answer the chat order question clearly:',
      targetText:
          'Your headset order is in transit and the carrier shows delivery by tomorrow evening. I will note your chat for follow-up if it slips.',
      successReply: 'Chat got a concrete update.',
      failReply: 'Type the guided order update.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'The new reset link worked. I am in now.',
      lane: 'voice',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Voice close',
      missionStepId: 'close_both',
      lane: 'voice',
      coachPrompt: 'Close the voice call. Say:',
      targetText:
          'Glad you are back in. Is there anything else I can help you with on this call? Thank you for calling Horizon Support.',
      successReply: 'Voice closed cleanly.',
      failReply: 'Speak the full voice closing.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'That shipping update helps. Thanks.',
      lane: 'chat',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Chat close',
      missionStepId: 'close_both',
      lane: 'chat',
      coachPrompt: 'Close the chat. Type:',
      targetText:
          'You are welcome. If the package does not arrive by tomorrow evening, reply here and we will escalate tracking. Have a great day.',
      successReply: 'Both channels handled. Hybrid basics complete.',
      failReply: 'Type the full chat closing.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'Complete. Hybrid skill: sequence live voice first, keep chat informed, finish both.',
      lane: 'both',
    ),
  ],
);
