import 'package:trainixprogram/models/training/scenarios/scenario_models.dart';

const chatScenario5 = ScenarioDefinition(
  id: 'chat_5',
  title: 'Non-Voice Scenario #5 - Angry Billing Dispute',
  channel: 'chat',
  sector: 'Finance',
  customerName: 'Chris Navarro',
  problem: 'Unexpected fee and demands an immediate waiver',
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
    ScenarioMissionStep(id: 'open', label: 'Stay professional with an angry customer'),
    ScenarioMissionStep(id: 'limit', label: 'Show empathy without overpromising'),
    ScenarioMissionStep(id: 'verify', label: 'Verify before discussing fees'),
    ScenarioMissionStep(id: 'path', label: 'Explain the approved review path'),
    ScenarioMissionStep(id: 'close', label: 'Close after submitting review'),
  ],
  turns: [
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'This scenario is harder. Some steps use choices. Pick the strongest professional response.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text:
          'I was charged a fee I never agreed to. Waive it right now or I am closing my account.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.chooseOne,
      text: 'Opening choice',
      missionStepId: 'open',
      coachPrompt:
          'Choose the best opening that stays calm and ready to help.',
      options: [
        'Calm down. Fees are in the contract.',
        'Thank you for contacting Horizon Finance Support. This is Alex. I can help review this fee with you.',
        'Okay, I will waive anything you want immediately.',
      ],
      correctIndex: 1,
      successReply: 'Good. Professional and ready to help.',
      failReply: 'Avoid blame and avoid overpromising. Choose the professional opening.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Then remove the fee. I should not have to explain myself.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.chooseOne,
      text: 'Empathy + limit',
      missionStepId: 'limit',
      coachPrompt:
          'Combine empathy with honesty. Do not waive outside policy.',
      options: [
        'No. Policy is policy.',
        'I understand this fee is frustrating. I cannot waive it instantly, but I can review the charge and explain the available options.',
        'Sure, waived. No need to check anything.',
      ],
      correctIndex: 1,
      successReply: 'Strong mix of empathy and policy honesty.',
      failReply: 'Acknowledge the frustration and stay within approved options.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Fine. Review it. But be quick.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Verification',
      missionStepId: 'verify',
      coachPrompt:
          'Before discussing fee details, verify identity.',
      targetText:
          'I can review that now. For security, may I verify your full name and the email on the account?',
      successReply: 'Correct verification before fee review.',
      failReply: 'Verify identity before discussing fee details.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Chris Navarro, chris.navarro@email.com.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.chooseOne,
      text: 'Solution choice',
      missionStepId: 'path',
      coachPrompt:
          'Choose the clearest next step without inventing approvals.',
      options: [
        'It will probably disappear on its own.',
        'I found the fee entry. I can explain why it posted and submit a review request if it qualifies under policy.',
        'I already deleted the fee forever.',
      ],
      correctIndex: 1,
      successReply: 'Clear, honest process next step.',
      failReply: 'Explain and use the approved review path.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'Submit the review then.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.typeExact,
      text: 'Closing',
      missionStepId: 'close',
      coachPrompt: 'Close with confirmation and further help.',
      targetText:
          'I have submitted the review request. Is there anything else I can help you with today? Thank you for contacting Horizon Finance Support.',
      successReply: 'Good close under pressure.',
      failReply: 'Use the full closing line.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.customer,
      text: 'That is enough for now.',
    ),
    ScenarioTurn(
      type: ScenarioTurnType.guide,
      text:
          'Complete. Harder chats need empathy, policy honesty, verification, and no overpromising.',
    ),
  ],
);
