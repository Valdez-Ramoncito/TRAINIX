import 'package:trainixprogram/models/training/scenarios/scenario_models.dart';

const voiceScenario5 = ScenarioDefinition(
  id: 'voice_5',
  title: 'Voice Scenario #5 - Fee Dispute On Call',
  channel: 'voice',
  sector: 'Finance',
  customerName: 'Marcus Hale',
  problem: 'Unexpected service fee and demands immediate removal on the call',
  emotion: 'Angry',
  targetSkills: [
    'Empathy',
    'Positive Scripting',
    'Sector Knowledge',
    'Solution Delivery',
    'Closing Spiel',
  ],
  maxMistakes: 3,
  isGuided: false,
  order: 5,
  missionSteps: [
    ScenarioMissionStep(id: 'open', label: 'Stay calm on opening'),
    ScenarioMissionStep(id: 'limit', label: 'Empathy without overpromising'),
    ScenarioMissionStep(id: 'verify', label: 'Verify before fee details'),
    ScenarioMissionStep(id: 'path', label: 'Explain the review path'),
    ScenarioMissionStep(id: 'close', label: 'Close after next step'),
  ],
  turns: [
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'Angry voice calls need steady tone. Do not match the anger and do not waive outside policy.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text:
          'You charged me a fee I never agreed to. Remove it right now or I am done with this company.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Opening',
      missionStepId: 'open',
      coachPrompt: 'Open calmly and stay ready to help. Say:',
      targetText:
          'Thank you for calling Horizon Finance. This is Alex. I can help review this fee with you.',
      successReply: 'Calm professional open under pressure.',
      failReply: 'Stay professional. Speak the calm opening fully.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Then remove it. I should not have to argue.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Limit',
      missionStepId: 'limit',
      coachPrompt: 'Combine empathy with an honest limit. Say:',
      targetText:
          'I understand this fee is upsetting. I cannot remove it instantly, but I can review the charge and explain the options available under policy.',
      successReply: 'Strong balance of empathy and honesty.',
      failReply: 'Do not waive on the spot. Use the guided limit line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Then review it. Quickly.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Verify',
      missionStepId: 'verify',
      coachPrompt: 'Verify before fee details. Say:',
      targetText:
          'I can review that now. For security, may I verify your full name and the email on the account?',
      successReply: 'Correct verification step.',
      failReply: 'Verify identity before discussing the fee.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Marcus Hale, marcus.hale@email.com.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Path',
      missionStepId: 'path',
      coachPrompt: 'Explain the approved next step. Say:',
      targetText:
          'I found the fee entry. I can explain why it posted and submit a review request if it qualifies under policy.',
      successReply: 'Clear review path. No false promises.',
      failReply: 'Explain the review path fully.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Submit the review then.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.speakExact,
      text: 'Closing',
      missionStepId: 'close',
      coachPrompt: 'Close after the action. Say:',
      targetText:
          'I have submitted the review request. Is there anything else I can help you with today? Thank you for calling Horizon Finance.',
      successReply: 'Steady close under pressure.',
      failReply: 'Speak the full closing line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'That is enough for now.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text: 'Complete. Key voice lesson: steady tone, honest limits, policy path.',
    ),
  ],
);
