part of '../training_categories.dart';

final TrainingCategoryData positiveScriptingCategory = TrainingCategoryData(
  name: "Positive Scripting",
  lessons: [
      Lesson(
        id: "ps_1",
        title: "What is Positive Scripting?",
        order: 1,
        content: """## What is Positive Scripting?
Positive scripting means choosing words that sound helpful, constructive, and solution focused.

## Why it matters
The same information can feel negative or positive depending on how you say it.
Positive language reduces tension and keeps the conversation moving forward.

## Simple Example
Negative: We cannot process that request.
Positive: Here is what we can do to help you with that.

## Key Takeaway
Positive scripting is not about being overly cheerful. It is about framing information in a useful and respectful way.

### Example
> Example: I understand how this is affecting you. Let me help with that right now, step by step.

### Use case
> Use case: A customer is worried or confused. Acknowledge the feeling first, then give one clear next step so they feel heard.
""",
        isUnlocked: true,
        assessments: [
          Assessment(
            id: "ps_1_quiz",
            type: AssessmentType.quiz,
            title: "Quick Check",
            instructions: "Answer all questions. Perfect score required.",
            quizQuestions: [
              QuizQuestion(
          question: "What is positive scripting?",
          options: [
                  "Using only long formal scripts",
                  "Choosing helpful and solution focused words",
                  "Avoiding all customer questions",
                ],
          correctIndex: 1,
          explanation: "Positive scripting means choosing helpful, constructive, solution-focused words.",
        ),
              QuizQuestion(
          question: "Why does positive scripting matter?",
          options: [
                  "It makes calls longer",
                  "It reduces tension and keeps the conversation moving",
                  "It replaces the need for solutions",
                ],
          correctIndex: 1,
          explanation: "It reduces tension and keeps the conversation moving forward.",
        ),
              QuizQuestion(
          question: "Positive scripting is mainly about:",
          options: [
                  "Being overly cheerful",
                  "Framing information in a useful way",
                  "Ignoring difficult topics",
                ],
          correctIndex: 1,
          explanation: "It is about framing information in a useful and respectful way, not empty cheerfulness.",
        ),
            ],
          ),
        ],
      ),
      Lesson(
        id: "ps_2",
        title: "Turning Negative Phrases Around",
        order: 2,
        content: """## Turning Negative Phrases Around
Many common phrases can be improved with small changes.

### Example
> Example: I can help review that charge with you. Here is what I can do next.

### Use case
> Use case: Replace negative phrasing like "You have to wait" with clear, helpful next steps the customer can follow.

## Common Changes
- Cannot becomes Here is what we can do
- No becomes Let me check another option
- You have to becomes You can
- That is not possible becomes A better option is

## Practice Idea
Take a negative sentence and rewrite it so it focuses on what is possible.

## Key Takeaway
Small wording changes can make a big difference in how the customer feels.""",
        isUnlocked: false,
        assessments: [
          Assessment(
            id: "ps_2_quiz",
            type: AssessmentType.quiz,
            title: "Phrase Check",
            instructions: "Choose the better wording.",
            quizQuestions: [
              QuizQuestion(
          question: "Which is more positive?",
          options: [
                  "We cannot do that",
                  "Here is what we can do",
                  "That is impossible",
                ],
          correctIndex: 1,
          explanation: "Focus on what you can do, not only on what you cannot do.",
        ),
              QuizQuestion(
          question: "A better version of You have to is:",
          options: [
                  "You must",
                  "You can",
                  "You failed to",
                ],
          correctIndex: 1,
          explanation: "You can is more collaborative and less demanding.",
        ),
            ],
          ),
          Assessment(
            id: "ps_2_typing",
            type: AssessmentType.typing,
            title: "Typing Practice",
            instructions: "Type the positive phrase exactly.",
            typingTargetText: "Here is what we can do to help you with that.",
          ),
        ],
      ),
      Lesson(
        id: "ps_3",
        title: "Positive Language in Difficult Moments",
        order: 3,
        content: """## Positive Language in Difficult Moments
When a customer is upset or the answer is not ideal, positive scripting still helps.

## Useful Approaches
- Acknowledge the situation first
- Focus on the next helpful step
- Offer clear options when possible
- Avoid absolute words like never or impossible

## Example
I understand this has been frustrating. Let me walk you through the fastest way to resolve it.

## Key Takeaway
Positive scripting works best when it is honest and paired with a clear next action.

### Example
> Example: I understand how this is affecting you. Let me help with that right now, step by step.

### Use case
> Use case: A customer is worried or confused. Acknowledge the feeling first, then give one clear next step so they feel heard.
""",
        isUnlocked: false,
        assessments: [
          Assessment(
            id: "ps_3_quiz",
            type: AssessmentType.quiz,
            title: "Difficult Moments Check",
            instructions: "Answer the questions.",
            quizQuestions: [
              QuizQuestion(
          question: "In a difficult moment you should:",
          options: [
                  "Ignore the customer's feelings",
                  "Acknowledge the situation then focus on the next step",
                  "Promise anything to end the call",
                ],
          correctIndex: 1,
          explanation: "Acknowledge the situation first, then focus on the next helpful step.",
        ),
              QuizQuestion(
          question: "Which word is better to avoid when possible?",
          options: [
                  "Option",
                  "Impossible",
                  "Help",
                ],
          correctIndex: 1,
          explanation: "Absolute words like impossible can shut down the conversation.",
        ),
            ],
          ),
          Assessment(
            id: "ps_3_voice",
            type: AssessmentType.voice,
            title: "Voice Practice",
            instructions: "Practice this line clearly.",
            voiceTargetScript: "I understand this has been frustrating. Let me walk you through the fastest way to resolve it.",
          ),
        ],
      ),
  ],
  finalAssessments: [
        Assessment(
      id: "ps_final_quiz",
      type: AssessmentType.quiz,
      title: "Positive Scripting Final Assessment",
      instructions: "Includes knowledge and situation items. Perfect score required.",
      quizQuestions: [
        QuizQuestion(
          question: "A customer asks for a feature you cannot provide. Best response?",
          options: [
            "We cannot do that.",
            "Here is what we can do instead.",
            "That is impossible.",
          ],
          correctIndex: 1,
          explanation: "Positive scripting focuses on helpful, solution-focused wording. Correct choice: Here is what we can do instead.",
        ),
        QuizQuestion(
          question: "Which line is more positive?",
          options: [
            "You have to submit the form again.",
            "You can resubmit the form and I will guide you.",
            "You failed to submit it correctly.",
          ],
          correctIndex: 1,
          explanation: "Positive scripting focuses on helpful, solution-focused wording. Correct choice: You can resubmit the form and I will guide you.",
        ),
        QuizQuestion(
          question: "A customer is told no refund is available. Best framing?",
          options: [
            "No refund. Ever.",
            "A refund is not available, but here are the options we can offer.",
            "There is nothing to discuss.",
          ],
          correctIndex: 1,
          explanation: "The correct answer is: A refund is not available, but here are the options we can offer.",
        ),
        QuizQuestion(
          question: "Positive scripting works best when it is:",
          options: [
            "Honest and paired with a next step",
            "Overly cheerful with no action",
            "Filled with absolute words like never",
          ],
          correctIndex: 0,
          explanation: "Positive scripting focuses on helpful, solution-focused wording. Correct choice: Honest and paired with a next step",
        ),
        QuizQuestion(
          question: "Customer: Can you waive this fee? Policy says no. Best reply?",
          options: [
            "No.",
            "I cannot waive the fee, but I can review related options that may help.",
            "You should have known the policy.",
          ],
          correctIndex: 1,
          explanation: "The correct answer is: I cannot waive the fee, but I can review related options that may help.",
        ),
      ],
    ),
    Assessment(
      id: "ps_final_typing",
      type: AssessmentType.typing,
      title: "Final Typing Practice",
      instructions: "Type the key phrase exactly.",
      typingTargetText: "Here is what we can do to help you with that.",
    ),
    Assessment(
      id: "ps_final_voice",
      type: AssessmentType.voice,
      title: "Final Voice Practice",
      instructions: "Practice the key phrase clearly.",
      voiceTargetScript: "I understand this has been frustrating. Let me walk you through the fastest way to resolve it.",
    ),
  ],
);
