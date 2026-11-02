part of '../training_categories.dart';

final TrainingCategoryData empathyCategory = TrainingCategoryData(
  name: "Empathy",
  lessons: [
      Lesson(
        id: "em_1",
        title: "What is Empathy in Customer Service?",
        order: 1,
        content: """## What is Empathy in Customer Service?
Empathy means recognizing the customer's feelings and showing that you understand them.

## Why it is important
Customers want to feel heard before they want a solution.
Showing empathy builds trust and lowers tension.

## Simple Definition
Empathy is not agreeing with everything the customer says.
It is acknowledging how the situation affects them.

## Key Takeaway
Empathy creates a human connection that makes the rest of the call easier.

### Example
> Example: I understand how this is affecting you. Let me help with that right now, step by step.

### Use case
> Use case: A customer is worried or confused. Acknowledge the feeling first, then give one clear next step so they feel heard.
""",
        isUnlocked: true,
        assessments: [
          Assessment(
            id: "em_1_quiz",
            type: AssessmentType.quiz,
            title: "Quick Check",
            instructions: "Answer all questions. Perfect score required.",
            quizQuestions: [
              QuizQuestion(
          question: "Empathy means:",
          options: [
                  "Agreeing with every complaint",
                  "Recognizing and acknowledging the customer's feelings",
                  "Avoiding emotional topics",
                ],
          correctIndex: 1,
          explanation: "Empathy is recognizing and acknowledging the customer's feelings.",
        ),
              QuizQuestion(
          question: "Why is empathy important?",
          options: [
                  "It replaces solutions",
                  "It builds trust and lowers tension",
                  "It shortens every call automatically",
                ],
          correctIndex: 1,
          explanation: "It builds trust and lowers tension before you solve the issue.",
        ),
              QuizQuestion(
          question: "Empathy is mainly about:",
          options: [
                  "Winning arguments",
                  "Showing you understand the impact on the customer",
                  "Reading a long script",
                ],
          correctIndex: 1,
          explanation: "Show you understand the impact on the customer without needing to agree with everything.",
        ),
            ],
          ),
        ],
      ),
      Lesson(
        id: "em_2",
        title: "How to Show Empathy",
        order: 2,
        content: """## How to Show Empathy
Empathy is shown through words and tone.

### Example
> Example: I understand how frustrating this delay must be. Thank you for telling me what happened.

### Use case
> Use case: A customer is upset about a missed appointment. Acknowledge the feeling before you dig into details or solutions.

## Useful Phrases
- I understand how frustrating that must be
- I can see why this is important to you
- Thank you for explaining the situation
- I am sorry you had to deal with this

## Tips
- Match the seriousness of the situation
- Be specific when possible
- Do not sound scripted
- Move to help after acknowledging the feeling

## Key Takeaway
A short genuine acknowledgment is more effective than a long generic statement.""",
        isUnlocked: false,
        assessments: [
          Assessment(
            id: "em_2_quiz",
            type: AssessmentType.quiz,
            title: "Empathy Phrases Check",
            instructions: "Choose the best answers.",
            quizQuestions: [
              QuizQuestion(
          question: "Which is a useful empathy phrase?",
          options: [
                  "That is not my problem",
                  "I understand how frustrating that must be",
                  "You should have known better",
                ],
          correctIndex: 1,
          explanation: "A clear acknowledgment of frustration shows the customer they are heard.",
        ),
              QuizQuestion(
          question: "After acknowledging the feeling you should:",
          options: [
                  "End the call",
                  "Move toward helping",
                  "Argue the policy first",
                ],
          correctIndex: 1,
          explanation: "Move toward helping once the feeling is acknowledged.",
        ),
            ],
          ),
          Assessment(
            id: "em_2_typing",
            type: AssessmentType.typing,
            title: "Typing Practice",
            instructions: "Type the empathy phrase exactly.",
            typingTargetText: "I understand how frustrating that must be.",
          ),
        ],
      ),
      Lesson(
        id: "em_3",
        title: "Empathy Without Overpromising",
        order: 3,
        content: """## Empathy Without Overpromising
Showing care does not mean promising things you cannot deliver.

## Good Balance
- Acknowledge the feeling
- Stay honest about what you can do
- Offer a clear next step

## Example
I understand this delay has been inconvenient. Here is what I can do right now to move this forward.

## Key Takeaway
Empathy plus honesty builds more trust than empty reassurance.

### Example
> Example: I understand how this is affecting you. Let me help with that right now, step by step.

### Use case
> Use case: A customer is worried or confused. Acknowledge the feeling first, then give one clear next step so they feel heard.
""",
        isUnlocked: false,
        assessments: [
          Assessment(
            id: "em_3_quiz",
            type: AssessmentType.quiz,
            title: "Balance Check",
            instructions: "Answer the questions.",
            quizQuestions: [
              QuizQuestion(
          question: "Empathy without overpromising means:",
          options: [
                  "Promise anything",
                  "Acknowledge feelings and stay honest about next steps",
                  "Avoid empathy entirely",
                ],
          correctIndex: 1,
          explanation: "Be caring and honest about what you can actually do next.",
        ),
              QuizQuestion(
          question: "Empty reassurance is weaker than:",
          options: [
                  "Honesty with a clear next step",
                  "Ignoring the issue",
                  "Blaming another team",
                ],
          correctIndex: 0,
          explanation: "Honesty paired with a clear next step builds more trust.",
        ),
            ],
          ),
          Assessment(
            id: "em_3_voice",
            type: AssessmentType.voice,
            title: "Voice Practice",
            instructions: "Practice this line clearly.",
            voiceTargetScript: "I understand this delay has been inconvenient. Here is what I can do right now to move this forward.",
          ),
        ],
      ),
  ],
  finalAssessments: [
        Assessment(
      id: "em_final_quiz",
      type: AssessmentType.quiz,
      title: "Empathy Final Assessment",
      instructions: "Includes knowledge and situation items. Perfect score required.",
      quizQuestions: [
        QuizQuestion(
          question: "A customer says this delay ruined my day. Best first response?",
          options: [
            "That is not a big deal.",
            "I understand how frustrating that must be.",
            "Anyway, here is the policy.",
          ],
          correctIndex: 1,
          explanation: "The correct answer is: I understand how frustrating that must be.",
        ),
        QuizQuestion(
          question: "Empathy without overpromising means:",
          options: [
            "Promise anything to calm them",
            "Acknowledge feelings and stay honest about next steps",
            "Avoid acknowledging feelings",
          ],
          correctIndex: 1,
          explanation: "Be caring and honest about what you can actually do next.",
        ),
        QuizQuestion(
          question: "Customer is upset about a billing error. Weak response?",
          options: [
            "I am sorry you had to deal with this. Let me review it with you.",
            "Calm down.",
            "Thank you for explaining. I can see why this matters.",
          ],
          correctIndex: 1,
          explanation: "Acknowledge the customer's feelings first, then help. Correct choice: Calm down.",
        ),
        QuizQuestion(
          question: "Best order is:",
          options: [
            "Solution first, empathy never",
            "Acknowledge the feeling, then move to help",
            "Argue first, help later",
          ],
          correctIndex: 1,
          explanation: "The correct answer is: Acknowledge the feeling, then move to help",
        ),
        QuizQuestion(
          question: "Which is stronger empathy?",
          options: [
            "I understand.",
            "I understand how frustrating this delay has been for you.",
            "Okay.",
          ],
          correctIndex: 1,
          explanation: "Acknowledge the customer's feelings first, then help. Correct choice: I understand how frustrating this delay has been for you.",
        ),
      ],
    ),
    Assessment(
      id: "em_final_typing",
      type: AssessmentType.typing,
      title: "Final Typing Practice",
      instructions: "Type the key phrase exactly.",
      typingTargetText: "I understand how frustrating that must be.",
    ),
    Assessment(
      id: "em_final_voice",
      type: AssessmentType.voice,
      title: "Final Voice Practice",
      instructions: "Practice the key phrase clearly.",
      voiceTargetScript: "I understand this delay has been inconvenient. Here is what I can do right now to move this forward.",
    ),
  ],
);
