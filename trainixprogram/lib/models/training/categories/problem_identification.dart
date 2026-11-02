part of '../training_categories.dart';

final TrainingCategoryData problemIdentificationCategory = TrainingCategoryData(
  name: "Problem Identification",
  lessons: [
      Lesson(
        id: "pi_1",
        title: "What is Problem Identification?",
        order: 1,
        content: """## What is Problem Identification?
Problem identification is the process of finding the real issue behind the customer's concern.

## Why it matters
If you solve the wrong problem, the customer will contact you again and remain frustrated.

## Goal
Understand the root cause clearly before offering a solution.

## Key Takeaway
Accurate problem identification is the foundation of effective support.

### Example
> Example: I understand how this is affecting you. Let me help with that right now, step by step.

### Use case
> Use case: A customer is worried or confused. Acknowledge the feeling first, then give one clear next step so they feel heard.
""",
        isUnlocked: true,
        assessments: [
          Assessment(
            id: "pi_1_quiz",
            type: AssessmentType.quiz,
            title: "Quick Check",
            instructions: "Answer all questions. Perfect score required.",
            quizQuestions: [
              QuizQuestion(
          question: "Problem identification is about:",
          options: [
                  "Guessing quickly",
                  "Finding the real issue behind the concern",
                  "Closing the call fast",
                ],
          correctIndex: 1,
          explanation: "Find the real issue behind the customer's concern before solving.",
        ),
              QuizQuestion(
          question: "Why does it matter?",
          options: [
                  "Wrong solutions cause repeat contacts",
                  "It is optional",
                  "It replaces empathy",
                ],
          correctIndex: 0,
          explanation: "Solving the wrong problem causes repeat contacts and frustration.",
        ),
              QuizQuestion(
          question: "You should offer a solution:",
          options: [
                  "Before understanding the issue",
                  "After understanding the root cause",
                  "Without asking questions",
                ],
          correctIndex: 1,
          explanation: "Offer a solution only after the root issue is clear.",
        ),
            ],
          ),
        ],
      ),
      Lesson(
        id: "pi_2",
        title: "How to Identify the Real Issue",
        order: 2,
        content: """## How to Identify the Real Issue
Use questions and confirmation to find the core problem.

### Example
> Example: When did this start, and does it happen on one device or all devices?

### Use case
> Use case: Gather time, scope, and impact facts so you do not guess at a solution too early.

## Useful Steps
- Let the customer explain fully
- Ask clarifying questions
- Separate symptoms from the root cause
- Confirm the issue in your own words

## Example Questions
- When did this start happening?
- What happens when you try that step?
- Is this the first time you experienced this?

## Key Takeaway
Good questions reveal the real problem faster than assumptions.""",
        isUnlocked: false,
        assessments: [
          Assessment(
            id: "pi_2_quiz",
            type: AssessmentType.quiz,
            title: "Process Check",
            instructions: "Choose the best answers.",
            quizQuestions: [
              QuizQuestion(
          question: "A useful step is:",
          options: [
                  "Assume the cause immediately",
                  "Ask clarifying questions",
                  "Skip confirmation",
                ],
          correctIndex: 1,
          explanation: "Clarifying questions help separate symptoms from the real cause.",
        ),
              QuizQuestion(
          question: "Symptoms are different from:",
          options: [
                  "The root cause",
                  "Customer names",
                  "Call times",
                ],
          correctIndex: 0,
          explanation: "Symptoms are what the customer notices; the root cause is why it happens.",
        ),
            ],
          ),
          Assessment(
            id: "pi_2_typing",
            type: AssessmentType.typing,
            title: "Typing Practice",
            instructions: "Type the confirmation line exactly.",
            typingTargetText: "Based on what you shared, the main issue is the payment did not process. Is that correct?",
          ),
        ],
      ),
      Lesson(
        id: "pi_3",
        title: "Confirming Before Solving",
        order: 3,
        content: """## Confirming Before Solving
Always confirm the issue before moving to a solution.

## Why confirmation matters
It shows the customer you listened and prevents solving the wrong thing.

## Simple Confirmation Line
Based on what you shared, the main issue is [brief summary]. Is that correct?

## Key Takeaway
A short confirmation step protects accuracy and builds confidence.

### Example
> Example: I understand how this is affecting you. Let me help with that right now, step by step.

### Use case
> Use case: A customer is worried or confused. Acknowledge the feeling first, then give one clear next step so they feel heard.
""",
        isUnlocked: false,
        assessments: [
          Assessment(
            id: "pi_3_quiz",
            type: AssessmentType.quiz,
            title: "Confirmation Check",
            instructions: "Answer the questions.",
            quizQuestions: [
              QuizQuestion(
          question: "You should confirm the issue:",
          options: [
                  "After solving",
                  "Before solving",
                  "Never",
                ],
          correctIndex: 1,
          explanation: "Confirm before solving so you do not fix the wrong thing.",
        ),
              QuizQuestion(
          question: "Confirmation helps prevent:",
          options: [
                  "Accurate solutions",
                  "Solving the wrong problem",
                  "Listening",
                ],
          correctIndex: 1,
          explanation: "Confirmation prevents solving the wrong problem.",
        ),
            ],
          ),
          Assessment(
            id: "pi_3_voice",
            type: AssessmentType.voice,
            title: "Voice Practice",
            instructions: "Practice the confirmation line.",
            voiceTargetScript: "Based on what you shared, the main issue is the payment did not process. Is that correct?",
          ),
        ],
      ),
  ],
  finalAssessments: [
        Assessment(
      id: "pi_final_quiz",
      type: AssessmentType.quiz,
      title: "Problem Identification Final Assessment",
      instructions: "Includes knowledge and situation items. Perfect score required.",
      quizQuestions: [
        QuizQuestion(
          question: "Customer says the app is broken. Best next step?",
          options: [
            "Close the ticket as device issue",
            "Ask clarifying questions to find what exactly fails",
            "Offer a random workaround",
          ],
          correctIndex: 1,
          explanation: "Explain solutions clearly and confirm the outcome. Correct choice: Ask clarifying questions to find what exactly fails",
        ),
        QuizQuestion(
          question: "A symptom is different from:",
          options: [
            "The root cause",
            "The customer name",
            "The call date",
          ],
          correctIndex: 0,
          explanation: "The correct answer is: The root cause",
        ),
        QuizQuestion(
          question: "Customer lists three issues. Best approach?",
          options: [
            "Solve only the last one mentioned",
            "Confirm which issue is the main priority first",
            "Ignore all details",
          ],
          correctIndex: 1,
          explanation: "The correct answer is: Confirm which issue is the main priority first",
        ),
        QuizQuestion(
          question: "You should confirm the issue:",
          options: [
            "After solving",
            "Before solving",
            "Never",
          ],
          correctIndex: 1,
          explanation: "Confirm before solving so you do not fix the wrong thing.",
        ),
        QuizQuestion(
          question: "Best confirmation style?",
          options: [
            "Based on what you shared, the main issue is X. Is that correct?",
            "I already know what is wrong.",
            "Whatever.",
          ],
          correctIndex: 0,
          explanation: "The correct answer is: Based on what you shared, the main issue is X. Is that correct?",
        ),
      ],
    ),
    Assessment(
      id: "pi_final_typing",
      type: AssessmentType.typing,
      title: "Final Typing Practice",
      instructions: "Type the key phrase exactly.",
      typingTargetText: "Based on what you shared, the main issue is the payment did not process. Is that correct?",
    ),
    Assessment(
      id: "pi_final_voice",
      type: AssessmentType.voice,
      title: "Final Voice Practice",
      instructions: "Practice the key phrase clearly.",
      voiceTargetScript: "Based on what you shared, the main issue is the payment did not process. Is that correct?",
    ),
  ],
);
