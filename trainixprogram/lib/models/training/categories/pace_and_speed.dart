part of '../training_categories.dart';

final TrainingCategoryData paceSpeedCategory = TrainingCategoryData(
  name: "Pace & Speed",
  lessons: [
      Lesson(
        id: "psp_1",
        title: "Why Pace Matters",
        order: 1,
        content: """## Why Pace Matters
Speaking pace affects how easy it is for the customer to understand you.

## Ideal Pace
Speak at a calm and steady speed.
Not too fast. Not too slow.

## Effects of Poor Pace
- Too fast can sound rushed and hard to follow
- Too slow can sound uncertain or unnatural

## Key Takeaway
A controlled pace improves clarity and professionalism.

### Example
> Example: I understand how this is affecting you. Let me help with that right now, step by step.

### Use case
> Use case: A customer is worried or confused. Acknowledge the feeling first, then give one clear next step so they feel heard.
""",
        isUnlocked: true,
        assessments: [
          Assessment(
            id: "psp_1_quiz",
            type: AssessmentType.quiz,
            title: "Quick Check",
            instructions: "Answer all questions. Perfect score required.",
            quizQuestions: [
              QuizQuestion(
          question: "Ideal speaking pace is:",
          options: [
                  "As fast as possible",
                  "Calm and steady",
                  "Extremely slow always",
                ],
          correctIndex: 1,
          explanation: "Calm and steady pace is easiest to follow.",
        ),
              QuizQuestion(
          question: "Speaking too fast can:",
          options: [
                  "Help understanding",
                  "Sound rushed and hard to follow",
                  "Always build trust",
                ],
          correctIndex: 1,
          explanation: "Fast speech can sound rushed and hard to follow.",
        ),
              QuizQuestion(
          question: "Controlled pace improves:",
          options: [
                  "Clarity and professionalism",
                  "Confusion",
                  "Filler words",
                ],
          correctIndex: 0,
          explanation: "It improves clarity and professionalism.",
        ),
            ],
          ),
        ],
      ),
      Lesson(
        id: "psp_2",
        title: "How to Control Your Pace",
        order: 2,
        content: """## How to Control Your Pace
You can train yourself to speak at a better speed.

### Example
> Example: Speak a little slower on account numbers and addresses so the customer can follow each digit.

### Use case
> Use case: When reading back an ID or amount, slow down; return to a natural pace for normal explanation.

## Practical Tips
- Pause briefly between key points
- Focus on clear pronunciation instead of speed
- Record yourself and listen back
- Slow down when explaining important steps

## Key Takeaway
Pace control is a skill that improves with deliberate practice.""",
        isUnlocked: false,
        assessments: [
          Assessment(
            id: "psp_2_quiz",
            type: AssessmentType.quiz,
            title: "Control Check",
            instructions: "Choose the best answers.",
            quizQuestions: [
              QuizQuestion(
          question: "A practical tip is:",
          options: [
                  "Never pause",
                  "Pause briefly between key points",
                  "Rush important steps",
                ],
          correctIndex: 1,
          explanation: "Pause briefly between key points.",
        ),
              QuizQuestion(
          question: "When explaining important steps you should:",
          options: [
                  "Speed up",
                  "Slow down",
                  "Skip details",
                ],
          correctIndex: 1,
          explanation: "Slow down on important steps.",
        ),
            ],
          ),
          Assessment(
            id: "psp_2_voice",
            type: AssessmentType.voice,
            title: "Voice Practice",
            instructions: "Practice at a calm steady pace.",
            voiceTargetScript: "I will explain this at a calm and steady pace so it is easy to follow.",
          ),
        ],
      ),
  ],
  finalAssessments: [
        Assessment(
      id: "psp_final_quiz",
      type: AssessmentType.quiz,
      title: "Pace and Speed Final Assessment",
      instructions: "Includes knowledge and situation items. Perfect score required.",
      quizQuestions: [
        QuizQuestion(
          question: "Customer asks you to slow down while you explain a refund process. You should:",
          options: [
            "Continue at the same speed",
            "Slow to a calm steady pace and check understanding",
            "Speak even faster",
          ],
          correctIndex: 1,
          explanation: "Use a calm, steady pace so details are easy to follow. Correct choice: Slow to a calm steady pace and check understanding",
        ),
        QuizQuestion(
          question: "You notice you rush when nervous. Best practice?",
          options: [
            "Pause briefly between key points",
            "Add more filler words",
            "Skip important steps",
          ],
          correctIndex: 0,
          explanation: "The correct answer is: Pause briefly between key points",
        ),
        QuizQuestion(
          question: "Too-fast speech often causes:",
          options: [
            "Easier understanding",
            "Customers missing details",
            "Better trust always",
          ],
          correctIndex: 1,
          explanation: "Use a calm, steady pace so details are easy to follow. Correct choice: Customers missing details",
        ),
        QuizQuestion(
          question: "Ideal pace is:",
          options: [
            "Calm and steady",
            "Always maximum speed",
            "Extremely slow in every sentence",
          ],
          correctIndex: 0,
          explanation: "Use a calm, steady pace so details are easy to follow. Correct choice: Calm and steady",
        ),
        QuizQuestion(
          question: "When giving critical steps, you should:",
          options: [
            "Speed through them",
            "Slow down and speak clearly",
            "Mumble to finish faster",
          ],
          correctIndex: 1,
          explanation: "Explain solutions clearly and confirm the outcome. Correct choice: Slow down and speak clearly",
        ),
      ],
    ),
    Assessment(
      id: "psp_final_voice",
      type: AssessmentType.voice,
      title: "Final Voice Practice",
      instructions: "Practice the key phrase clearly.",
      voiceTargetScript: "I will explain this at a calm and steady pace so it is easy to follow.",
    ),
  ],
);
