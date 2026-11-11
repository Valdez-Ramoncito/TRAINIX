import 'package:trainixprogram/models/training/typing/typing_passage.dart';

class TypingPassageCatalog {
  TypingPassageCatalog._();

  static const List<TypingPassage> all = [
    ...general,
    ...scripts,
    ...chat,
  ];

  static List<TypingPassage> forPack(TypingPack pack) {
    switch (pack) {
      case TypingPack.general:
        return general;
      case TypingPack.scripts:
        return scripts;
      case TypingPack.chat:
        return chat;
    }
  }

  static List<TypingPassage> shuffledForPack(TypingPack pack) {
    final list = List<TypingPassage>.from(forPack(pack));
    list.shuffle();
    return list;
  }

  static const List<TypingPassage> general = [
    TypingPassage(
      id: 'gen_1',
      label: 'Warm-up',
      pack: TypingPack.general,
      difficulty: TypingDifficulty.short,
      text:
          'The quick brown fox jumps over the lazy dog near the river bank every morning.',
    ),
    TypingPassage(
      id: 'gen_2',
      label: 'Focus',
      pack: TypingPack.general,
      difficulty: TypingDifficulty.short,
      text:
          'Clear communication starts with careful listening and precise wording in every reply.',
    ),
    TypingPassage(
      id: 'gen_3',
      label: 'Accuracy',
      pack: TypingPack.general,
      difficulty: TypingDifficulty.medium,
      text:
          'Practice builds speed without losing control. Keep your hands steady, watch each word, and correct mistakes only when needed.',
    ),
    TypingPassage(
      id: 'gen_4',
      label: 'Rhythm',
      pack: TypingPack.general,
      difficulty: TypingDifficulty.medium,
      text:
          'A steady typing rhythm helps agents answer chat queues faster while keeping messages professional and easy to read.',
    ),
    TypingPassage(
      id: 'gen_5',
      label: 'Desktop',
      pack: TypingPack.general,
      difficulty: TypingDifficulty.long,
      text:
          'Desktop keyboards reward consistent posture and light key presses. Aim for accuracy first, then let speed rise as the pattern becomes automatic during long shifts.',
    ),
    TypingPassage(
      id: 'gen_6',
      label: 'Numbers',
      pack: TypingPack.general,
      difficulty: TypingDifficulty.medium,
      text:
          'Account numbers, dates, and reference codes must be typed carefully. Double-check 3 to 5 business days, ticket 48219, and order ID 907364 before sending.',
    ),
  ];

  static const List<TypingPassage> scripts = [
    TypingPassage(
      id: 'scr_1',
      label: 'Opening',
      pack: TypingPack.scripts,
      difficulty: TypingDifficulty.short,
      text:
          'Thank you for contacting support. My name is Alex. How may I help you today?',
    ),
    TypingPassage(
      id: 'scr_2',
      label: 'Empathy',
      pack: TypingPack.scripts,
      difficulty: TypingDifficulty.short,
      text: 'I understand how frustrating that must be. Let me look into this for you right away.',
    ),
    TypingPassage(
      id: 'scr_3',
      label: 'Verify',
      pack: TypingPack.scripts,
      difficulty: TypingDifficulty.medium,
      text:
          'For your security, I need to verify your identity before we review the account. May I have your full name and the email on file?',
    ),
    TypingPassage(
      id: 'scr_4',
      label: 'Active listen',
      pack: TypingPack.scripts,
      difficulty: TypingDifficulty.medium,
      text:
          'Just to make sure I understand, the main issue is that the payment did not go through last night. Is that correct?',
    ),
    TypingPassage(
      id: 'scr_5',
      label: 'Solution',
      pack: TypingPack.scripts,
      difficulty: TypingDifficulty.medium,
      text:
          'I will walk you through two short steps. First we will verify the account. Then we will apply the update and confirm the result together.',
    ),
    TypingPassage(
      id: 'scr_6',
      label: 'Refund',
      pack: TypingPack.scripts,
      difficulty: TypingDifficulty.short,
      text:
          'Your refund has been processed. You should see it in 3 to 5 business days.',
    ),
    TypingPassage(
      id: 'scr_7',
      label: 'Closing',
      pack: TypingPack.scripts,
      difficulty: TypingDifficulty.short,
      text:
          'Is there anything else I can help you with today? Thank you for contacting us. Have a good day.',
    ),
    TypingPassage(
      id: 'scr_8',
      label: 'Hold',
      pack: TypingPack.scripts,
      difficulty: TypingDifficulty.medium,
      text:
          'Thank you for waiting. I have finished reviewing your case and I am ready to share the next steps with you.',
    ),
    TypingPassage(
      id: 'scr_9',
      label: 'Problem ID',
      pack: TypingPack.scripts,
      difficulty: TypingDifficulty.medium,
      text:
          'Based on what you shared, the main issue is the payment did not process. I will confirm the status and outline the options available.',
    ),
    TypingPassage(
      id: 'scr_10',
      label: 'Positive',
      pack: TypingPack.scripts,
      difficulty: TypingDifficulty.medium,
      text:
          'I am happy to help resolve this. We can complete the correction on this chat and I will send a short summary when we are done.',
    ),
  ];

  static const List<TypingPassage> chat = [
    TypingPassage(
      id: 'chat_1',
      label: 'Greeting thread',
      pack: TypingPack.chat,
      difficulty: TypingDifficulty.medium,
      text:
          'Customer: Hi, I need help with my order. Agent: Hello, thank you for chatting with us. I can help with that. May I have your order number?',
    ),
    TypingPassage(
      id: 'chat_2',
      label: 'Billing',
      pack: TypingPack.chat,
      difficulty: TypingDifficulty.medium,
      text:
          'Customer: I was charged twice this month. Agent: I am sorry about the duplicate charge. Let me check your recent payments and confirm what happened.',
    ),
    TypingPassage(
      id: 'chat_3',
      label: 'Password',
      pack: TypingPack.chat,
      difficulty: TypingDifficulty.medium,
      text:
          'Customer: I cannot log in after the reset. Agent: Thanks for telling me. Please try the reset link once more, then reply here with the exact error message you see.',
    ),
    TypingPassage(
      id: 'chat_4',
      label: 'Delivery',
      pack: TypingPack.chat,
      difficulty: TypingDifficulty.long,
      text:
          'Customer: My package still shows in transit. Agent: I checked the tracking update from this morning. The carrier marked a delay. I can open a trace and send you the reference number in this chat.',
    ),
    TypingPassage(
      id: 'chat_5',
      label: 'Escalate',
      pack: TypingPack.chat,
      difficulty: TypingDifficulty.medium,
      text:
          'Customer: This is the third time I am asking. Agent: You are right to follow up. I am escalating this to a specialist now and will stay with you until we have a clear next step.',
    ),
    TypingPassage(
      id: 'chat_6',
      label: 'Close chat',
      pack: TypingPack.chat,
      difficulty: TypingDifficulty.short,
      text:
          'Customer: That fixed it, thanks. Agent: Glad it is resolved. If anything else comes up, start a new chat and we will assist you again.',
    ),
  ];
}
