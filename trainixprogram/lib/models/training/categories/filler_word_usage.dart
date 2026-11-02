part of '../training_categories.dart';

final TrainingCategoryData fillerWordUsageCategory = TrainingCategoryData(
  name: "Filler Word Usage",
  lessons: [
      Lesson(
        id: "fw_1",
        title: "What are Filler Words?",
        order: 1,
        content: """## What are Filler Words?
Filler words are sounds or words used while thinking, such as um, uh, like, or you know.

## Why they matter
Too many fillers make speech sound unsure or unprofessional.

## Common Fillers
- um
- uh
- like
- you know
- basically

## Key Takeaway
Reducing fillers makes your speech sound more confident and clear.

### Example
> Example: I understand how this is affecting you. Let me help with that right now, step by step.

### Use case
> Use case: A customer is worried or confused. Acknowledge the feeling first, then give one clear next step so they feel heard.
""",
        isUnlocked: true,
        assessments: [
          Assessment(
            id: "fw_1_quiz",
            type: AssessmentType.quiz,
            title: "Quick Check",
            instructions: "Answer all questions. Perfect score required.",
            quizQuestions: [
              QuizQuestion(
          question: "Filler words are:",
          options: [
                  "Required policy terms",
                  "Sounds or words used while thinking",
                  "Customer account numbers",
                ],
          correctIndex: 1,
          explanation: "They are sounds or words used while thinking, like um or uh.",
        ),
              QuizQuestion(
          question: "Too many fillers can make speech sound:",
          options: [
                  "More confident",
                  "Unsure or unprofessional",
                  "Clearer",
                ],
          correctIndex: 1,
          explanation: "They can make speech sound unsure or unprofessional.",
        ),
              QuizQuestion(
          question: "An example filler is:",
          options: [
                  "um",
                  "account",
                  "refund",
                ],
          correctIndex: 0,
          explanation: "um is a common filler.",
        ),
            ],
          ),
        ],
      ),
      Lesson(
        id: "fw_2",
        title: "How to Reduce Fillers",
        order: 2,
        content: """## How to Reduce Fillers
You can replace fillers with short pauses.

### Example
> Example: Prefer a short pause over "um" or "like" while you look up the account.

### Use case
> Use case: If you need a moment, say "One moment while I check that" instead of filling silence with fillers.

## Practical Approach
- Notice when you use fillers
- Pause silently instead of filling the space
- Prepare key phrases in advance
- Practice short responses out loud

## Key Takeaway
A short clean pause sounds more professional than a string of filler words.""",
        isUnlocked: false,
        assessments: [
          Assessment(
            id: "fw_2_quiz",
            type: AssessmentType.quiz,
            title: "Reduction Check",
            instructions: "Choose the best answers.",
            quizQuestions: [
              QuizQuestion(
          question: "A better replacement for fillers is:",
          options: [
                  "More fillers",
                  "A short silent pause",
                  "Longer rambling",
                ],
          correctIndex: 1,
          explanation: "A short silent pause sounds cleaner.",
        ),
              QuizQuestion(
          question: "Preparing key phrases helps you:",
          options: [
                  "Use more fillers",
                  "Reduce hesitation fillers",
                  "Avoid all speech",
                ],
          correctIndex: 1,
          explanation: "Prepared phrases reduce hesitation fillers.",
        ),
            ],
          ),
          Assessment(
            id: "fw_2_voice",
            type: AssessmentType.voice,
            title: "Voice Practice",
            instructions: "Say this without fillers.",
            voiceTargetScript: "Let me check that for you right away.",
          ),
        ],
      ),
  ],
  finalAssessments: [
        Assessment(
      id: "fw_final_quiz",
      type: AssessmentType.quiz,
      title: "Filler Word Usage Final Assessment",
      instructions: "Includes knowledge and situation items. Perfect score required.",
      quizQuestions: [
        QuizQuestion(
          question: "You need a second to check a screen. Better choice?",
          options: [
            "um um um",
            "A short silent pause, then respond",
            "you know like basically",
          ],
          correctIndex: 1,
          explanation: "The correct answer is: A short silent pause, then respond",
        ),
        QuizQuestion(
          question: "Customer hears many fillers in your greeting. Likely effect?",
          options: [
            "You sound more unsure",
            "You sound more confident",
            "No effect",
          ],
          correctIndex: 0,
          explanation: "A professional opening uses a clear greeting structure. Correct choice: You sound more unsure",
        ),
        QuizQuestion(
          question: "Best way to reduce fillers?",
          options: [
            "Prepare key phrases and pause instead of filling silence",
            "Use more fillers",
            "Avoid all pauses forever",
          ],
          correctIndex: 0,
          explanation: "Replace fillers with short pauses to sound more confident. Correct choice: Prepare key phrases and pause instead of filling silence",
        ),
        QuizQuestion(
          question: "Which is a filler?",
          options: [
            "um",
            "account number",
            "refund",
          ],
          correctIndex: 0,
          explanation: "Replace fillers with short pauses to sound more confident. Correct choice: um",
        ),
        QuizQuestion(
          question: "During a live call, replacing fillers with pauses usually sounds:",
          options: [
            "More professional",
            "Less professional",
            "Rude by default",
          ],
          correctIndex: 0,
          explanation: "Replace fillers with short pauses to sound more confident. Correct choice: More professional",
        ),
      ],
    ),
    Assessment(
      id: "fw_final_voice",
      type: AssessmentType.voice,
      title: "Final Voice Practice",
      instructions: "Practice the key phrase clearly without fillers.",
      voiceTargetScript: "Let me check that for you right away.",
    ),
  ],
);
