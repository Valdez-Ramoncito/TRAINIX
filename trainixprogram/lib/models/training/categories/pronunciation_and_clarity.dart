part of '../training_categories.dart';

final TrainingCategoryData pronunciationClarityCategory = TrainingCategoryData(
  name: "Pronunciation & Clarity",
  lessons: [
      Lesson(
        id: "pc_1",
        title: "Why Pronunciation Matters",
        order: 1,
        content: """## Why Pronunciation Matters
Clear pronunciation helps the customer understand you the first time.

## Goal
Make every important word easy to hear and understand.

## Common Challenges
- Ending sounds that disappear
- Words that blend together
- Speaking too softly at the end of sentences

## Key Takeaway
Clear pronunciation reduces repetition and frustration.

### Example
> Example: I understand how this is affecting you. Let me help with that right now, step by step.

### Use case
> Use case: A customer is worried or confused. Acknowledge the feeling first, then give one clear next step so they feel heard.
""",
        isUnlocked: true,
        assessments: [
          Assessment(
            id: "pc_1_quiz",
            type: AssessmentType.quiz,
            title: "Quick Check",
            instructions: "Answer all questions. Perfect score required.",
            quizQuestions: [
              QuizQuestion(
          question: "Clear pronunciation helps customers:",
          options: [
                  "Mishear details",
                  "Understand you the first time",
                  "Need more repeats",
                ],
          correctIndex: 1,
          explanation: "They understand you the first time.",
        ),
              QuizQuestion(
          question: "A common challenge is:",
          options: [
                  "Ending sounds that disappear",
                  "Speaking too clearly",
                  "Steady volume",
                ],
          correctIndex: 0,
          explanation: "Ending sounds that disappear reduce clarity.",
        ),
              QuizQuestion(
          question: "Clear speech reduces:",
          options: [
                  "Repetition and frustration",
                  "Understanding",
                  "Professionalism",
                ],
          correctIndex: 0,
          explanation: "It reduces repeats and frustration.",
        ),
            ],
          ),
        ],
      ),
      Lesson(
        id: "pc_2",
        title: "Improving Clarity",
        order: 2,
        content: """## Improving Clarity
Small habits improve how clearly you speak.

### Example
> Example: That is account number 4-5-8-2. I will say it once more: 4-5-8-2.

### Use case
> Use case: Enunciate key words and numbers. Offer to repeat when the customer sounds unsure.

## Helpful Habits
- Open your mouth slightly more when speaking
- Finish each word completely
- Emphasize key information
- Keep volume steady

## Practice Idea
Read a short script slowly and clearly, then gradually return to a natural pace while keeping the same clarity.

## Key Takeaway
Clarity is more important than sounding fast or fancy.""",
        isUnlocked: false,
        assessments: [
          Assessment(
            id: "pc_2_quiz",
            type: AssessmentType.quiz,
            title: "Clarity Habits Check",
            instructions: "Choose the best answers.",
            quizQuestions: [
              QuizQuestion(
          question: "A helpful habit is:",
          options: [
                  "Trailing off at the end",
                  "Finishing each word completely",
                  "Swallowing key words",
                ],
          correctIndex: 1,
          explanation: "Finish each word completely.",
        ),
              QuizQuestion(
          question: "Clarity is more important than:",
          options: [
                  "Sounding fast or fancy",
                  "Being understood",
                  "Steady volume",
                ],
          correctIndex: 0,
          explanation: "Being understood matters more than sounding fast.",
        ),
            ],
          ),
          Assessment(
            id: "pc_2_voice",
            type: AssessmentType.voice,
            title: "Voice Practice",
            instructions: "Practice this line clearly.",
            voiceTargetScript: "Please listen carefully while I repeat that information clearly.",
          ),
        ],
      ),
  ],
  finalAssessments: [
        Assessment(
      id: "pc_final_quiz",
      type: AssessmentType.quiz,
      title: "Pronunciation and Clarity Final Assessment",
      instructions: "Includes knowledge and situation items. Perfect score required.",
      quizQuestions: [
        QuizQuestion(
          question: "Customer asks you to repeat a reference number. Best action?",
          options: [
            "Say it faster",
            "Repeat it slowly and clearly, one group at a time",
            "Refuse to repeat",
          ],
          correctIndex: 1,
          explanation: "Clear pronunciation helps customers understand the first time. Correct choice: Repeat it slowly and clearly, one group at a time",
        ),
        QuizQuestion(
          question: "Words are blending together in your speech. Fix?",
          options: [
            "Finish each word completely and steady your pace",
            "Speak softer at the end",
            "Add more fillers",
          ],
          correctIndex: 0,
          explanation: "The correct answer is: Finish each word completely and steady your pace",
        ),
        QuizQuestion(
          question: "Clear pronunciation mainly reduces:",
          options: [
            "The need for repeats",
            "Professionalism",
            "Understanding",
          ],
          correctIndex: 0,
          explanation: "Clear communication uses specific, simple language. Correct choice: The need for repeats",
        ),
        QuizQuestion(
          question: "Important account details should be spoken:",
          options: [
            "Softly and quickly",
            "Clearly with steady volume",
            "As one rushed blur",
          ],
          correctIndex: 1,
          explanation: "The correct answer is: Clearly with steady volume",
        ),
        QuizQuestion(
          question: "Clarity priority is:",
          options: [
            "Being understood the first time",
            "Sounding as fast as possible",
            "Using complex wording",
          ],
          correctIndex: 0,
          explanation: "Clear pronunciation helps customers understand the first time. Correct choice: Being understood the first time",
        ),
      ],
    ),
    Assessment(
      id: "pc_final_voice",
      type: AssessmentType.voice,
      title: "Final Voice Practice",
      instructions: "Practice the key phrase clearly.",
      voiceTargetScript: "Please listen carefully while I repeat that information clearly.",
    ),
  ],
);
