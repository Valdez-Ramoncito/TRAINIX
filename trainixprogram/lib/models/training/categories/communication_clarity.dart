part of '../training_categories.dart';

final TrainingCategoryData communicationClarityCategory = TrainingCategoryData(
  name: "Communication Clarity",
  lessons: [
      Lesson(
        id: "cc_1",
        title: "What is Communication Clarity?",
        order: 1,
        content: """## What is Communication Clarity?
Communication clarity means expressing ideas in a way that is easy to understand.

## Why it matters
Unclear messages cause confusion, longer chats, and repeated questions.

## Core Idea
Say exactly what you mean using simple and direct language.

## Key Takeaway
Clear writing and speaking reduce effort for both the agent and the customer.

### Example
> Example: I understand how this is affecting you. Let me help with that right now, step by step.

### Use case
> Use case: A customer is worried or confused. Acknowledge the feeling first, then give one clear next step so they feel heard.
""",
        isUnlocked: true,
        assessments: [
          Assessment(
            id: "cc_1_quiz",
            type: AssessmentType.quiz,
            title: "Quick Check",
            instructions: "Answer all questions. Perfect score required.",
            quizQuestions: [
              QuizQuestion(
          question: "Communication clarity means:",
          options: [
                  "Using complex wording",
                  "Making ideas easy to understand",
                  "Avoiding answers",
                ],
          correctIndex: 1,
          explanation: "Express ideas so they are easy to understand.",
        ),
              QuizQuestion(
          question: "Unclear messages often cause:",
          options: [
                  "Faster resolution",
                  "Confusion and repeated questions",
                  "Fewer contacts",
                ],
          correctIndex: 1,
          explanation: "Confusion leads to longer chats and repeated questions.",
        ),
              QuizQuestion(
          question: "A core idea is:",
          options: [
                  "Simple and direct language",
                  "Long unnecessary detail",
                  "Vague timelines",
                ],
          correctIndex: 0,
          explanation: "Simple, direct language reduces effort for both sides.",
        ),
            ],
          ),
        ],
      ),
      Lesson(
        id: "cc_2",
        title: "Writing Clearly in Chat",
        order: 2,
        content: """## Writing Clearly in Chat
Chat requires extra care because the customer cannot hear your tone.

### Example
> Example: Step one, open Settings. Step two, choose Network. Step three, turn Airplane Mode on, then off.

### Use case
> Use case: Give short numbered steps instead of one long technical paragraph.

## Helpful Habits
- Use short sentences
- One main idea per message when possible
- Avoid slang and heavy jargon
- Confirm important details in writing

## Example
Your refund has been processed. You should see it in 3 to 5 business days.

## Key Takeaway
Clear chat messages prevent misunderstandings and speed up resolution.""",
        isUnlocked: false,
        assessments: [
          Assessment(
            id: "cc_2_quiz",
            type: AssessmentType.quiz,
            title: "Chat Clarity Check",
            instructions: "Choose the best answers.",
            quizQuestions: [
              QuizQuestion(
          question: "In chat you should prefer:",
          options: [
                  "Long mixed ideas",
                  "Short clear sentences",
                  "Slang",
                ],
          correctIndex: 1,
          explanation: "Short clear sentences work better in chat.",
        ),
              QuizQuestion(
          question: "Important details should be:",
          options: [
                  "Assumed",
                  "Confirmed in writing",
                  "Hidden",
                ],
          correctIndex: 1,
          explanation: "Confirm important details in writing so nothing is missed.",
        ),
            ],
          ),
          Assessment(
            id: "cc_2_typing",
            type: AssessmentType.typing,
            title: "Typing Practice",
            instructions: "Type the message exactly.",
            typingTargetText: "Your refund has been processed. You should see it in 3 to 5 business days.",
          ),
        ],
      ),
      Lesson(
        id: "cc_3",
        title: "Avoiding Ambiguous Language",
        order: 3,
        content: """## Avoiding Ambiguous Language
Vague words leave room for confusion.

## Words to Be Careful With
- Soon
- Later
- Maybe
- As soon as possible without a time frame

## Better Approach
Give concrete information whenever you can.
If a time frame is unknown, explain the next checkpoint.

## Key Takeaway
Specific language builds more trust than vague reassurance.

### Example
> Example: I understand how this is affecting you. Let me help with that right now, step by step.

### Use case
> Use case: A customer is worried or confused. Acknowledge the feeling first, then give one clear next step so they feel heard.
""",
        isUnlocked: false,
        assessments: [
          Assessment(
            id: "cc_3_quiz",
            type: AssessmentType.quiz,
            title: "Ambiguity Check",
            instructions: "Answer the questions.",
            quizQuestions: [
              QuizQuestion(
          question: "Which is more ambiguous?",
          options: [
                  "3 to 5 business days",
                  "Soon",
                  "Tomorrow at 2 PM",
                ],
          correctIndex: 1,
          explanation: "Soon is vague; a specific time frame is clearer.",
        ),
              QuizQuestion(
          question: "If timing is unknown you should:",
          options: [
                  "Say soon only",
                  "Explain the next checkpoint",
                  "Avoid answering",
                ],
          correctIndex: 1,
          explanation: "Explain the next checkpoint you can confirm.",
        ),
            ],
          ),
        ],
      ),
  ],
  finalAssessments: [
        Assessment(
      id: "cc_final_quiz",
      type: AssessmentType.quiz,
      title: "Communication Clarity Final Assessment",
      instructions: "Includes knowledge and situation items. Perfect score required.",
      quizQuestions: [
        QuizQuestion(
          question: "In chat, which message is clearer?",
          options: [
            "Soon maybe it will work.",
            "Your refund has been processed. You should see it in 3 to 5 business days.",
            "Later.",
          ],
          correctIndex: 1,
          explanation: "Clear communication uses specific, simple language. Correct choice: Your refund has been processed. You should see it in 3 to 5 business days.",
        ),
        QuizQuestion(
          question: "Customer asks when a change will show. Weak reply?",
          options: [
            "It should reflect within 24 hours.",
            "Soon.",
            "By tomorrow at 5 PM local time.",
          ],
          correctIndex: 1,
          explanation: "The correct answer is: Soon.",
        ),
        QuizQuestion(
          question: "Best chat habit?",
          options: [
            "One main idea per message when possible",
            "Mix many ideas in one long block",
            "Use slang",
          ],
          correctIndex: 0,
          explanation: "Clear communication uses specific, simple language. Correct choice: One main idea per message when possible",
        ),
        QuizQuestion(
          question: "Ambiguous language often causes:",
          options: [
            "Clearer expectations",
            "Confusion and follow-up questions",
            "Faster trust",
          ],
          correctIndex: 1,
          explanation: "Clear communication uses specific, simple language. Correct choice: Confusion and follow-up questions",
        ),
        QuizQuestion(
          question: "If exact timing is unknown, better approach is:",
          options: [
            "Say ASAP only",
            "Explain the next checkpoint you can confirm",
            "Avoid answering",
          ],
          correctIndex: 1,
          explanation: "The correct answer is: Explain the next checkpoint you can confirm",
        ),
      ],
    ),
    Assessment(
      id: "cc_final_typing",
      type: AssessmentType.typing,
      title: "Final Typing Practice",
      instructions: "Type the key phrase exactly.",
      typingTargetText: "Your refund has been processed. You should see it in 3 to 5 business days.",
    ),
  ],
);
