import 'package:trainixprogram/models/training/scenarios/scenario_models.dart';

const hybridScenario4 = ScenarioDefinition(
  id: 'hybrid_4',
  title: 'Hybrid Scenario #4 - Cross-Channel Mix-Up Risk',
  channel: 'hybrid',
  sector: 'Healthcare',
  customerName: 'Voice: Dr. Patient Liaison call from Nora',
  problem: 'Voice: reschedule surgery consult | Chat: different patient asks for lab results',
  emotion: 'Anxious / Impatient',
  targetSkills: [
    'Sector Knowledge',
    'Multitasking',
    'Privacy',
    'Communication Clarity',
  ],
  maxMistakes: 3,
  isGuided: false,
  order: 4,
  secondaryCustomerName: 'Gabe Molina',
  secondarySector: 'Healthcare',
  secondaryProblem: 'Wants lab results released on chat',
  secondaryEmotion: 'Impatient',
  missionSteps: [
    ScenarioMissionStep(id: 'separate', label: 'Keep patient identities separate'),
    ScenarioMissionStep(id: 'voice_scope', label: 'Handle voice scheduling only'),
    ScenarioMissionStep(id: 'chat_privacy', label: 'Refuse improper lab disclosure on chat'),
    ScenarioMissionStep(id: 'close_safe', label: 'Close both without data mixing'),
  ],
  turns: [
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'Unique hybrid risk: two healthcare contacts at once. Never share one patient context into the other channel.',
      lane: 'both',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'This is Nora. I need to move my surgery consult to next week, please.',
      lane: 'voice',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Chat: Gabe Molina. Send my lab results here right now.',
      lane: 'chat',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Voice schedule',
      missionStepId: 'voice_scope',
      lane: 'voice',
      coachPrompt: 'Help Nora with scheduling only. Say:',
      targetText:
          'I can help reschedule your consult, Nora. I will request the next available opening next week and confirm once it is set.',
      successReply: 'Voice stayed on scheduling.',
      failReply: 'Keep voice on scheduling only.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Chat privacy',
      missionStepId: 'chat_privacy',
      lane: 'chat',
      coachPrompt: 'Protect privacy on chat. Do not release labs in plain chat:',
      targetText:
          'Gabe, I cannot release lab results over standard chat. Please use the patient portal or verify for a secure clinical channel.',
      successReply: 'Privacy protected under multitasking pressure.',
      failReply: 'Do not release labs on chat. Use the guided privacy line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Fine. Just do not mix me up with someone else.',
      lane: 'chat',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Separate',
      missionStepId: 'separate',
      lane: 'chat',
      coachPrompt: 'Reassure separation without mentioning the other caller:',
      targetText:
          'Your chat is handled as its own case. I will not share or blend your information with any other contact.',
      successReply: 'Identity separation confirmed.',
      failReply: 'Reassure separation without leaking the other channel.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Thanks. Text me when the new consult time is set.',
      lane: 'voice',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Close voice',
      missionStepId: 'close_safe',
      lane: 'voice',
      coachPrompt: 'Close voice safely. Say:',
      targetText:
          'I will confirm the new consult time through your registered contact method. Is there anything else on this call?',
      successReply: 'Voice closed without cross-talk.',
      failReply: 'Speak the safe voice close.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Close chat',
      missionStepId: 'close_safe',
      lane: 'chat',
      coachPrompt: 'Close chat safely:',
      targetText:
          'Understood. Use the portal for labs, and reply here if you need portal access help only. Thank you for messaging Horizon Health.',
      successReply: 'Hybrid privacy scenario complete.',
      failReply: 'Type the full safe chat close.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'Complete. Hybrid skill unique to dual channels: strict identity firewall between contacts.',
      lane: 'both',
    ),
  ],
);
