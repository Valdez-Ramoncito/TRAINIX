part of '../training_categories.dart';

final TrainingCategoryData activeListeningCategory = TrainingCategoryData(
  name: "Active Listening",
  lessons: [
      Lesson(
        id: "al_1",
        title: "What is Active Listening?",
        order: 1,
        content: """## What is Active Listening?
Active listening means giving full attention to the customer and making sure you understand their message.

## Why it matters
Many call problems happen because the agent starts solving before fully understanding the issue.

## Core Behaviors
- Focus on the customer
- Do not interrupt
- Listen for both facts and feelings
- Confirm what you heard

## Key Takeaway
Active listening prevents misunderstandings and makes customers feel respected.

### Example
> Example: I understand how this is affecting you. Let me help with that right now, step by step.

### Use case
> Use case: A customer is worried or confused. Acknowledge the feeling first, then give one clear next step so they feel heard.
""",
        isUnlocked: true,
        assessments: [
          Assessment(
            id: "al_1_quiz",
            type: AssessmentType.quiz,
            title: "Quick Check",
            instructions: "Answer all questions. Perfect score required.",
            quizQuestions: [
              QuizQuestion(
          question: "Active listening means:",
          options: [
                  "Waiting to speak only",
                  "Giving full attention and confirming understanding",
                  "Solving before the customer finishes",
                ],
          correctIndex: 1,
          explanation: "Give full attention and confirm that you understood the message.",
        ),
              QuizQuestion(
          question: "A core active listening behavior is:",
          options: [
                  "Interrupting often",
                  "Confirming what you heard",
                  "Ignoring feelings",
                ],
          correctIndex: 1,
          explanation: "Confirming what you heard prevents misunderstandings.",
        ),
              QuizQuestion(
          question: "Active listening helps prevent:",
          options: [
                  "All product issues",
                  "Misunderstandings",
                  "The need for notes",
                ],
          correctIndex: 1,
          explanation: "Listening carefully reduces misunderstandings and repeat contacts.",
        ),
            ],
          ),
        ],
      ),
      Lesson(
        id: "al_2",
        title: "Techniques for Active Listening",
        order: 2,
        content: """## Techniques for Active Listening
Use simple techniques to show you are listening.

### Example
> Example: Just to confirm, the internet drops every evening around 8 PM. Is that correct?

### Use case
> Use case: After the customer explains the issue, restate the key points in your own words before you move to a fix.

## Helpful Techniques
- Brief verbal signals such as I see or Go on
- Paraphrasing the main point
- Asking clarifying questions
- Summarizing before offering a solution

## Example
Just to make sure I understand, the main issue is that the payment did not go through last night. Is that correct?

## Key Takeaway
Confirming understanding before solving saves time and reduces repeat contacts.""",
        isUnlocked: false,
        assessments: [
          Assessment(
            id: "al_2_quiz",
            type: AssessmentType.quiz,
            title: "Techniques Check",
            instructions: "Choose the best answers.",
            quizQuestions: [
              QuizQuestion(
          question: "Which is an active listening technique?",
          options: [
                  "Guessing the solution early",
                  "Paraphrasing the main point",
                  "Changing the topic",
                ],
          correctIndex: 1,
          explanation: "Paraphrasing the main point shows you understood the customer.",
        ),
              QuizQuestion(
          question: "Before offering a solution you should:",
          options: [
                  "Summarize and confirm understanding",
                  "Transfer immediately",
                  "End the call",
                ],
          correctIndex: 0,
          explanation: "Summarize and confirm understanding first.",
        ),
            ],
          ),
          Assessment(
            id: "al_2_typing",
            type: AssessmentType.typing,
            title: "Typing Practice",
            instructions: "Type the confirmation line exactly.",
            typingTargetText: "Just to make sure I understand, the main issue is that the payment did not go through last night. Is that correct?",
          ),
        ],
      ),
      Lesson(
        id: "al_3",
        title: "Avoiding Common Listening Mistakes",
        order: 3,
        content: """## Avoiding Common Listening Mistakes
Certain habits break active listening.

## Mistakes to Avoid
- Interrupting the customer
- Assuming you already know the problem
- Thinking about your reply instead of listening
- Jumping to a solution too early

## Better Habit
Let the customer finish. Then confirm the issue. Then respond.

## Key Takeaway
Patience at the listening stage leads to cleaner and faster resolutions.

### Example
> Example: I understand how this is affecting you. Let me help with that right now, step by step.

### Use case
> Use case: A customer is worried or confused. Acknowledge the feeling first, then give one clear next step so they feel heard.
""",
        isUnlocked: false,
        assessments: [
          Assessment(
            id: "al_3_quiz",
            type: AssessmentType.quiz,
            title: "Mistakes Check",
            instructions: "Answer the questions.",
            quizQuestions: [
              QuizQuestion(
          question: "Which is a common listening mistake?",
          options: [
                  "Letting the customer finish",
                  "Interrupting the customer",
                  "Confirming the issue",
                ],
          correctIndex: 1,
          explanation: "Interrupting breaks active listening and can miss key details.",
        ),
              QuizQuestion(
          question: "A better habit is:",
          options: [
                  "Solve first, listen later",
                  "Let the customer finish, then confirm, then respond",
                  "Assume the problem immediately",
                ],
          correctIndex: 1,
          explanation: "Slow down at the end and confirm clarity.",
        ),
            ],
          ),
          Assessment(
            id: "al_3_voice",
            type: AssessmentType.voice,
            title: "Voice Practice",
            instructions: "Practice this confirmation line.",
            voiceTargetScript: "Just to make sure I understand, the main issue is that the payment did not go through last night. Is that correct?",
          ),
        ],
      ),
  ],
  finalAssessments: [
        Assessment(
      id: "al_final_quiz",
      type: AssessmentType.quiz,
      title: "Active Listening Final Assessment",
      instructions: "Includes knowledge and situation items. Perfect score required.",
      quizQuestions: [
        QuizQuestion(
          question: "Customer is mid-explanation and you already know a possible fix. You should:",
          options: [
            "Interrupt with the fix",
            "Let them finish, then confirm understanding",
            "Transfer immediately",
          ],
          correctIndex: 1,
          explanation: "The correct answer is: Let them finish, then confirm understanding",
        ),
        QuizQuestion(
          question: "Customer describes a failed payment. Best next line?",
          options: [
            "Just to make sure I understand, the payment did not go through last night. Is that correct?",
            "Anyway, try again later.",
            "That is your bank's problem.",
          ],
          correctIndex: 0,
          explanation: "The correct answer is: Just to make sure I understand, the payment did not go through last night. Is that correct?",
        ),
        QuizQuestion(
          question: "Which behavior breaks active listening?",
          options: [
            "Paraphrasing",
            "Assuming the problem before they finish",
            "Asking a clarifying question",
          ],
          correctIndex: 1,
          explanation: "Active listening means full attention and confirming understanding. Correct choice: Assuming the problem before they finish",
        ),
        QuizQuestion(
          question: "Active listening is mainly about:",
          options: [
            "Waiting to speak only",
            "Attention, understanding, and confirmation",
            "Speaking as much as possible",
          ],
          correctIndex: 1,
          explanation: "Active listening means full attention and confirming understanding. Correct choice: Attention, understanding, and confirmation",
        ),
        QuizQuestion(
          question: "Before solving, you should:",
          options: [
            "Confirm the issue in your own words",
            "Skip confirmation to save time",
            "Change the topic",
          ],
          correctIndex: 0,
          explanation: "The correct answer is: Confirm the issue in your own words",
        ),
      ],
    ),
    Assessment(
      id: "al_final_typing",
      type: AssessmentType.typing,
      title: "Final Typing Practice",
      instructions: "Type the key phrase exactly.",
      typingTargetText: "Just to make sure I understand, the main issue is that the payment did not go through last night. Is that correct?",
    ),
    Assessment(
      id: "al_final_voice",
      type: AssessmentType.voice,
      title: "Final Voice Practice",
      instructions: "Practice the key phrase clearly.",
      voiceTargetScript: "Just to make sure I understand, the main issue is that the payment did not go through last night. Is that correct?",
    ),
  ],
);
