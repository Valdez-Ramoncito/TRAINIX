import 'dart:math' as math;

import 'package:trainixprogram/models/training/speaking/speaking_prompt.dart';

class SpeakingPromptCatalog {
  SpeakingPromptCatalog._();

  static const List<SpeakingPrompt> all = [
    SpeakingPrompt(
      id: 'ra_short_1',
      pack: SpeakingPack.readAloud,
      difficulty: SpeakingPromptDifficulty.short,
      label: 'Support greeting',
      targetSeconds: 20,
      focus: ['clarity', 'pace'],
      text:
          'Thank you for calling Northwind Support. My name is Marie. How can I help you today?',
    ),
    SpeakingPrompt(
      id: 'ra_short_2',
      pack: SpeakingPack.readAloud,
      difficulty: SpeakingPromptDifficulty.short,
      label: 'Delay acknowledgment',
      targetSeconds: 20,
      focus: ['tone', 'clarity'],
      text:
          'I understand the delay has been frustrating. Let me check the order status now and give you a clear update.',
    ),
    SpeakingPrompt(
      id: 'ra_short_3',
      pack: SpeakingPack.readAloud,
      difficulty: SpeakingPromptDifficulty.short,
      label: 'Hold request',
      targetSeconds: 20,
      focus: ['pace', 'fillers'],
      text:
          'May I place you on a short hold while I confirm the delivery details with the courier?',
    ),
    SpeakingPrompt(
      id: 'ra_medium_1',
      pack: SpeakingPack.readAloud,
      difficulty: SpeakingPromptDifficulty.medium,
      label: 'Delivery update',
      targetSeconds: 35,
      focus: ['clarity', 'structure'],
      text:
          'Thank you for holding. The package left our warehouse on Monday and it is currently with the local courier. I will send the tracking link and a new delivery window to your email in the next few minutes.',
    ),
    SpeakingPrompt(
      id: 'ra_medium_2',
      pack: SpeakingPack.readAloud,
      difficulty: SpeakingPromptDifficulty.medium,
      label: 'Session reset steps',
      targetSeconds: 35,
      focus: ['clarity', 'pronunciation'],
      text:
          'I am sorry the app keeps signing you out. Let us reset the session first. Open Settings, choose Sign out, then sign in again with the same email address and password.',
    ),
    SpeakingPrompt(
      id: 'ra_medium_3',
      pack: SpeakingPack.readAloud,
      difficulty: SpeakingPromptDifficulty.medium,
      label: 'Identity verification',
      targetSeconds: 35,
      focus: ['clarity', 'pace'],
      text:
          'Before we continue, I need to verify the account. Please confirm the email address on the account and the last four digits of the card on file. Once that matches, I can review the charges with you.',
    ),
    SpeakingPrompt(
      id: 'ra_medium_4',
      pack: SpeakingPack.readAloud,
      difficulty: SpeakingPromptDifficulty.medium,
      label: 'Refund expectations',
      targetSeconds: 35,
      focus: ['clarity', 'tone'],
      text:
          'The refund was approved this morning and will post within three to five business days. I have added a note to the case so you will not need to explain the situation again if you call back.',
    ),
    SpeakingPrompt(
      id: 'ra_long_1',
      pack: SpeakingPack.readAloud,
      difficulty: SpeakingPromptDifficulty.long,
      label: 'Duplicate charge summary',
      targetSeconds: 45,
      focus: ['structure', 'clarity'],
      text:
          'Thank you for calling Meridian Bank. My name is Daniel and I will be helping you today. I can see two pending charges from the same merchant on the same day. I will place a temporary hold on the duplicate charge, confirm the amount with you, and send a summary of this call to your email so you have the reference number.',
    ),
    SpeakingPrompt(
      id: 'co_short_1',
      pack: SpeakingPack.callOpenings,
      difficulty: SpeakingPromptDifficulty.short,
      label: 'Mobile support opening',
      targetSeconds: 20,
      focus: ['opening', 'tone'],
      text:
          'Good morning, thank you for calling Apex Mobile. This is Liza. How may I assist you?',
      requiredPoints: ['greeting', 'agent name', 'offer of help'],
    ),
    SpeakingPrompt(
      id: 'co_short_2',
      pack: SpeakingPack.callOpenings,
      difficulty: SpeakingPromptDifficulty.short,
      label: 'Help desk opening',
      targetSeconds: 20,
      focus: ['opening', 'clarity'],
      text:
          'Thank you for contacting the Help Desk. My name is Marco. What can I help you resolve today?',
      requiredPoints: ['greeting', 'agent name', 'offer of help'],
    ),
    SpeakingPrompt(
      id: 'co_short_3',
      pack: SpeakingPack.callOpenings,
      difficulty: SpeakingPromptDifficulty.short,
      label: 'Billing line opening',
      targetSeconds: 20,
      focus: ['opening', 'pace'],
      text:
          'Good afternoon, this is Clearline Billing. My name is Anna. I can help with charges, payments, and account updates.',
      requiredPoints: ['greeting', 'company or team', 'agent name', 'purpose'],
    ),
    SpeakingPrompt(
      id: 'co_medium_1',
      pack: SpeakingPack.callOpenings,
      difficulty: SpeakingPromptDifficulty.medium,
      label: 'Higher than usual bill',
      targetSeconds: 35,
      focus: ['opening', 'structure'],
      text:
          'Good afternoon and thank you for calling Clearline Utilities. My name is Anna. I understand you are calling about a bill that looks higher than usual. I will pull up the account and go through the charges with you.',
      requiredPoints: [
        'greeting',
        'agent name',
        'reason for the call',
        'next step',
      ],
    ),
    SpeakingPrompt(
      id: 'co_medium_2',
      pack: SpeakingPack.callOpenings,
      difficulty: SpeakingPromptDifficulty.medium,
      label: 'Travel booking change',
      targetSeconds: 35,
      focus: ['opening', 'clarity'],
      text:
          'Hello, thank you for reaching out to Harbor Travel. This is Ken. I see you have a booking for Friday. Are you calling to change the date or the passenger details?',
      requiredPoints: [
        'greeting',
        'agent name',
        'context',
        'clarifying question'
      ],
    ),
    SpeakingPrompt(
      id: 'co_medium_3',
      pack: SpeakingPack.callOpenings,
      difficulty: SpeakingPromptDifficulty.medium,
      label: 'Pharmacy opening',
      targetSeconds: 35,
      focus: ['opening', 'tone'],
      text:
          'Thank you for calling Novacare Pharmacy. This is Grace. I can help with refills, delivery status, and account questions. What brings you to us today?',
      requiredPoints: ['greeting', 'agent name', 'scope', 'offer of help'],
    ),
    SpeakingPrompt(
      id: 'co_medium_4',
      pack: SpeakingPack.callOpenings,
      difficulty: SpeakingPromptDifficulty.medium,
      label: 'Insurance claims opening',
      targetSeconds: 35,
      focus: ['opening', 'structure'],
      text:
          'Thank you for calling Bright Path Insurance. This is Elena. I can help with claims, coverage questions, and payments. Before we begin, may I have the policy number?',
      requiredPoints: ['greeting', 'agent name', 'scope', 'verification step'],
    ),
    SpeakingPrompt(
      id: 'co_long_1',
      pack: SpeakingPack.callOpenings,
      difficulty: SpeakingPromptDifficulty.long,
      label: 'Dropping connection opening',
      targetSeconds: 45,
      focus: ['opening', 'structure'],
      text:
          'Good evening, and thank you for calling Summit Home Internet. My name is Paul. I understand your connection has been dropping since yesterday. I will check the line status, confirm the equipment you have, and then walk you through the next step.',
      requiredPoints: [
        'greeting',
        'agent name',
        'statement of the issue',
        'plan for the call',
      ],
    ),
    SpeakingPrompt(
      id: 'gd_short_1',
      pack: SpeakingPack.grammarDrills,
      difficulty: SpeakingPromptDifficulty.short,
      label: 'Articles',
      targetSeconds: 20,
      focus: ['articles'],
      text:
          'I sent the invoice to an address on file. The customer said the address was correct.',
    ),
    SpeakingPrompt(
      id: 'gd_short_2',
      pack: SpeakingPack.grammarDrills,
      difficulty: SpeakingPromptDifficulty.short,
      label: 'Past tense',
      targetSeconds: 20,
      focus: ['tense'],
      text:
          'The agent checked the order and found that the payment had already cleared.',
    ),
    SpeakingPrompt(
      id: 'gd_short_3',
      pack: SpeakingPack.grammarDrills,
      difficulty: SpeakingPromptDifficulty.short,
      label: 'Prepositions',
      targetSeconds: 20,
      focus: ['prepositions'],
      text:
          'Please log in to the portal, open the billing page, and look at the charges from last month.',
    ),
    SpeakingPrompt(
      id: 'gd_medium_1',
      pack: SpeakingPack.grammarDrills,
      difficulty: SpeakingPromptDifficulty.medium,
      label: 'Subject-verb agreement',
      targetSeconds: 35,
      focus: ['agreement'],
      text:
          'The team reviews every ticket, and each agent checks the notes before the case closes.',
    ),
    SpeakingPrompt(
      id: 'gd_medium_2',
      pack: SpeakingPack.grammarDrills,
      difficulty: SpeakingPromptDifficulty.medium,
      label: 'Plurals',
      targetSeconds: 35,
      focus: ['plurals'],
      text:
          'Two customers called about their orders, and both packages arrived with damaged boxes.',
    ),
    SpeakingPrompt(
      id: 'gd_medium_3',
      pack: SpeakingPack.grammarDrills,
      difficulty: SpeakingPromptDifficulty.medium,
      label: 'Modals and requests',
      targetSeconds: 35,
      focus: ['wordChoice'],
      text:
          'Could you please confirm the account number so I can locate the file and update the shipping details for you?',
    ),
    SpeakingPrompt(
      id: 'gd_medium_4',
      pack: SpeakingPack.grammarDrills,
      difficulty: SpeakingPromptDifficulty.medium,
      label: 'Relative clauses',
      targetSeconds: 35,
      focus: ['structure'],
      text:
          'The customer whose account was flagged called again, and the agent who took the first call added a note.',
    ),
    SpeakingPrompt(
      id: 'gd_long_1',
      pack: SpeakingPack.grammarDrills,
      difficulty: SpeakingPromptDifficulty.long,
      label: 'Conditionals',
      targetSeconds: 45,
      focus: ['conditionals', 'structure'],
      text:
          'If the courier has not scanned the parcel by Friday, we will open an investigation, and if the parcel is still missing after five days, we will issue a replacement.',
    ),
    SpeakingPrompt(
      id: 'fr_short_1',
      pack: SpeakingPack.freeResponse,
      difficulty: SpeakingPromptDifficulty.short,
      label: 'App will not open',
      targetSeconds: 30,
      focus: ['structure', 'clarity'],
      text:
          'A customer says the app will not open after the latest update. Acknowledge the problem, give one troubleshooting step, and say when you will follow up.',
      requiredPoints: [
        'acknowledgment of the problem',
        'one troubleshooting step',
        'follow-up time',
      ],
    ),
    SpeakingPrompt(
      id: 'fr_short_2',
      pack: SpeakingPack.freeResponse,
      difficulty: SpeakingPromptDifficulty.short,
      label: 'Late delivery',
      targetSeconds: 30,
      focus: ['tone', 'structure'],
      text:
          'A customer is upset about a late delivery. Apologize, state the current status, and describe the next action you will take.',
      requiredPoints: ['apology', 'current status', 'next action'],
    ),
    SpeakingPrompt(
      id: 'fr_short_3',
      pack: SpeakingPack.freeResponse,
      difficulty: SpeakingPromptDifficulty.short,
      label: 'Password reset email missing',
      targetSeconds: 30,
      focus: ['clarity', 'structure'],
      text:
          'A customer cannot sign in and the reset email never arrived. Explain one alternative reset path and one security reminder.',
      requiredPoints: [
        'alternative reset path',
        'security reminder',
      ],
    ),
    SpeakingPrompt(
      id: 'fr_medium_1',
      pack: SpeakingPack.freeResponse,
      difficulty: SpeakingPromptDifficulty.medium,
      label: 'Refund outside the window',
      targetSeconds: 45,
      focus: ['structure', 'wordChoice'],
      text:
          'A customer wants a refund but the order is outside the return window. State the policy, offer one alternative, and say what you will do next.',
      requiredPoints: ['policy', 'one alternative', 'next step'],
    ),
    SpeakingPrompt(
      id: 'fr_medium_2',
      pack: SpeakingPack.freeResponse,
      difficulty: SpeakingPromptDifficulty.medium,
      label: 'Unrecognized charge',
      targetSeconds: 45,
      focus: ['structure', 'confidence'],
      text:
          'A customer asks about a charge they do not recognize. Confirm the charge details, explain the dispute steps, and give the expected timeline.',
      requiredPoints: [
        'confirmation of the charge',
        'dispute steps',
        'expected timeline',
      ],
    ),
    SpeakingPrompt(
      id: 'fr_medium_3',
      pack: SpeakingPack.freeResponse,
      difficulty: SpeakingPromptDifficulty.medium,
      label: 'Address change before shipping',
      targetSeconds: 45,
      focus: ['structure', 'clarity'],
      text:
          'A customer wants the shipping address changed, but the order is already packed. Explain what can still be changed, what cannot, and the option available after delivery.',
      requiredPoints: [
        'what can change',
        'what cannot change',
        'post-delivery option'
      ],
    ),
    SpeakingPrompt(
      id: 'fr_medium_4',
      pack: SpeakingPack.freeResponse,
      difficulty: SpeakingPromptDifficulty.medium,
      label: 'Repeated connection drops',
      targetSeconds: 45,
      focus: ['structure', 'tone'],
      text:
          'A customer says the connection drops every evening. Ask one diagnostic question, explain the next step, and set the expectation for a technician visit.',
      requiredPoints: [
        'diagnostic question',
        'next step',
        'technician expectation',
      ],
    ),
    SpeakingPrompt(
      id: 'fr_long_1',
      pack: SpeakingPack.freeResponse,
      difficulty: SpeakingPromptDifficulty.long,
      label: 'Duplicate charge and cancellation',
      targetSeconds: 60,
      focus: ['structure', 'completeness'],
      text:
          'A customer says they were charged twice and wants to cancel the subscription. Cover the duplicate charge, the cancellation options, and what happens to the remaining balance.',
      requiredPoints: [
        'duplicate charge outcome',
        'cancellation options',
        'remaining balance',
      ],
    ),
    SpeakingPrompt(
      id: 'fr_long_2',
      pack: SpeakingPack.freeResponse,
      difficulty: SpeakingPromptDifficulty.long,
      label: 'Final bill after switching',
      targetSeconds: 60,
      focus: ['structure', 'completeness'],
      text:
          'A customer is switching providers and asks for the final bill. Cover the final bill date, any remaining balance, and how to keep access to old account records.',
      requiredPoints: [
        'final bill date',
        'remaining balance',
        'record access',
      ],
    ),
  ];

  static List<SpeakingPrompt> byPack(SpeakingPack pack) {
    return all.where((p) => p.pack == pack).toList();
  }

  static List<SpeakingPrompt> byDifficulty(
    SpeakingPromptDifficulty difficulty,
  ) {
    return all.where((p) => p.difficulty == difficulty).toList();
  }

  static List<SpeakingPrompt> forSetup(
    SpeakingPack pack,
    SpeakingPromptDifficulty difficulty,
  ) {
    return all
        .where((p) => p.pack == pack && p.difficulty == difficulty)
        .toList();
  }

  static SpeakingPrompt? byId(String id) {
    for (final prompt in all) {
      if (prompt.id == id) return prompt;
    }
    return null;
  }

  static SpeakingPrompt? randomFor(
    SpeakingPack pack,
    SpeakingPromptDifficulty difficulty, {
    math.Random? random,
  }) {
    final pool = forSetup(pack, difficulty);
    if (pool.isEmpty) return null;
    final rng = random ?? math.Random();
    return pool[rng.nextInt(pool.length)];
  }
}
