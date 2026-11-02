part of '../training_categories.dart';

final TrainingCategoryData toneInflectionCategory = TrainingCategoryData(
  name: "Tone & Inflection",
  lessons: [
      Lesson(
        id: "ti_1",
        title: "What is Tone and Inflection?",
        order: 1,
        content: """## What is Tone and Inflection?
Tone is the overall feeling in your voice.
Inflection is how your pitch rises and falls while speaking.

## Why it matters
Customers react strongly to how something sounds, not only to the words.

## Goal
Sound warm, steady, and professional.

## Key Takeaway
Good tone supports empathy and trust even when the message is difficult.

### Example
> Example: I understand how this is affecting you. Let me help with that right now, step by step.

### Use case
> Use case: A customer is worried or confused. Acknowledge the feeling first, then give one clear next step so they feel heard.
""",
        isUnlocked: true,
        assessments: [
          Assessment(
            id: "ti_1_quiz",
            type: AssessmentType.quiz,
            title: "Quick Check",
            instructions: "Answer all questions. Perfect score required.",
            quizQuestions: [
              QuizQuestion(
          question: "Tone is:",
          options: [
                  "Only the words used",
                  "The overall feeling in your voice",
                  "Only typing speed",
                ],
          correctIndex: 1,
          explanation: "Tone is the overall feeling in your voice.",
        ),
              QuizQuestion(
          question: "Inflection refers to:",
          options: [
                  "Pitch rises and falls",
                  "Account balance",
                  "Hold music",
                ],
          correctIndex: 0,
          explanation: "Inflection is how pitch rises and falls.",
        ),
              QuizQuestion(
          question: "Good tone should sound:",
          options: [
                  "Warm, steady, and professional",
                  "Flat and uninterested",
                  "Aggressive",
                ],
          correctIndex: 0,
          explanation: "Warm, steady, and professional.",
        ),
            ],
          ),
        ],
      ),
      Lesson(
        id: "ti_2",
        title: "Using Tone Effectively",
        order: 2,
        content: """## Using Tone Effectively
Match your tone to the situation while staying professional.

### Example
> Example: Keep a steady, warm tone on "I am sorry this happened," then a clear, confident tone on the next step.

### Use case
> Use case: Match seriousness for sensitive issues; stay calm even if the customer is raised.

## Helpful Guidelines
- Use a calm tone with upset customers
- Sound friendly and clear in normal requests
- Avoid sounding flat or monotone
- Avoid sounding overly casual in serious situations

## Practice Idea
Say the same sentence in different tones and notice how the meaning changes.

## Key Takeaway
Controlled tone helps the customer feel guided rather than judged.""",
        isUnlocked: false,
        assessments: [
          Assessment(
            id: "ti_2_quiz",
            type: AssessmentType.quiz,
            title: "Tone Use Check",
            instructions: "Choose the best answers.",
            quizQuestions: [
              QuizQuestion(
          question: "With upset customers, use a tone that is:",
          options: [
                  "Calm",
                  "Mocking",
                  "Rushed and sharp",
                ],
          correctIndex: 0,
          explanation: "Stay calm with upset customers.",
        ),
              QuizQuestion(
          question: "Avoid sounding:",
          options: [
                  "Professional",
                  "Flat or monotone",
                  "Clear",
                ],
          correctIndex: 1,
          explanation: "Avoid flat or monotone delivery.",
        ),
            ],
          ),
          Assessment(
            id: "ti_2_voice",
            type: AssessmentType.voice,
            title: "Voice Practice",
            instructions: "Practice with a warm professional tone.",
            voiceTargetScript: "I am happy to help you with this today.",
          ),
        ],
      ),
  ],
  finalAssessments: [
        Assessment(
      id: "ti_final_quiz",
      type: AssessmentType.quiz,
      title: "Tone and Inflection Final Assessment",
      instructions: "Includes knowledge and situation items. Perfect score required.",
      quizQuestions: [
        QuizQuestion(
          question: "Customer is upset about a repeated billing error. Best tone?",
          options: [
            "Calm and steady",
            "Sharp and defensive",
            "Playful and casual",
          ],
          correctIndex: 0,
          explanation: "Acknowledge the customer's feelings first, then help. Correct choice: Calm and steady",
        ),
        QuizQuestion(
          question: "Your words are correct but tone is flat. Risk?",
          options: [
            "Customer may feel you do not care",
            "No risk",
            "Always better than warmth",
          ],
          correctIndex: 0,
          explanation: "Warm, steady, professional tone supports trust. Correct choice: Customer may feel you do not care",
        ),
        QuizQuestion(
          question: "Normal simple request. Best tone?",
          options: [
            "Friendly and clear",
            "Harsh",
            "Monotone and distant",
          ],
          correctIndex: 0,
          explanation: "Warm, steady, professional tone supports trust. Correct choice: Friendly and clear",
        ),
        QuizQuestion(
          question: "Tone matters because customers respond to:",
          options: [
            "How it sounds as well as the words",
            "Only the exact words",
            "Only chat spelling",
          ],
          correctIndex: 0,
          explanation: "Warm, steady, professional tone supports trust. Correct choice: How it sounds as well as the words",
        ),
        QuizQuestion(
          question: "Serious complaint. Avoid sounding:",
          options: [
            "Overly casual",
            "Professional",
            "Clear",
          ],
          correctIndex: 0,
          explanation: "The correct answer is: Overly casual",
        ),
      ],
    ),
    Assessment(
      id: "ti_final_voice",
      type: AssessmentType.voice,
      title: "Final Voice Practice",
      instructions: "Practice the key phrase with professional tone.",
      voiceTargetScript: "I am happy to help you with this today.",
    ),
  ],
);
