part of '../training_categories.dart';

final TrainingCategoryData closingSpielCategory = TrainingCategoryData(
  name: "Closing Spiel",
  lessons: [
      Lesson(
        id: "cs_1",
        title: "What is a Closing Spiel?",
        order: 1,
        content: """## What is a Closing Spiel?
The Closing Spiel is the final part of the call where you wrap up the conversation properly.

## What it includes
- A short summary of what was done
- An offer of further help
- A polite sign off

## Why it matters
A strong closing leaves a professional final impression and reduces follow up confusion.

## Key Takeaway
The closing is the last memory the customer has of the interaction.

### Example
> Example: I understand how this is affecting you. Let me help with that right now, step by step.

### Use case
> Use case: A customer is worried or confused. Acknowledge the feeling first, then give one clear next step so they feel heard.
""",
        isUnlocked: true,
        assessments: [
          Assessment(
            id: "cs_1_quiz",
            type: AssessmentType.quiz,
            title: "Quick Check",
            instructions: "Answer all questions. Perfect score required.",
            quizQuestions: [
              QuizQuestion(
          question: "The Closing Spiel is used:",
          options: [
                  "At the start only",
                  "To wrap up the conversation properly",
                  "Only in chat",
                ],
          correctIndex: 1,
          explanation: "It wraps up the conversation properly at the end.",
        ),
              QuizQuestion(
          question: "It usually includes:",
          options: [
                  "No summary",
                  "Summary, further help offer, and polite sign off",
                  "Only a transfer",
                ],
          correctIndex: 1,
          explanation: "Summary, further help offer, and polite sign off.",
        ),
              QuizQuestion(
          question: "A strong closing helps:",
          options: [
                  "Increase confusion",
                  "Reduce follow up confusion",
                  "Skip professionalism",
                ],
          correctIndex: 1,
          explanation: "It reduces follow-up confusion and leaves a professional impression.",
        ),
            ],
          ),
        ],
      ),
      Lesson(
        id: "cs_2",
        title: "The Standard Closing Structure",
        order: 2,
        content: """## The Standard Closing Structure
A clear closing usually follows three parts.

### Example
> Example: I summarized the steps we took. Is there anything else I can help you with today? Thank you for calling Trainix Support.

### Use case
> Use case: End with a short summary, offer further help, then a polite close.

## The Three Parts
- Summarize the resolution or next steps
- Ask if there is anything else you can help with
- Thank the customer and end politely

## Example
I have updated your account and the change should reflect within 24 hours. Is there anything else I can help you with today? Thank you for calling. Have a good day.

## Key Takeaway
A consistent structure keeps closings complete and professional.""",
        isUnlocked: false,
        assessments: [
          Assessment(
            id: "cs_2_quiz",
            type: AssessmentType.quiz,
            title: "Structure Check",
            instructions: "Choose the best answers.",
            quizQuestions: [
              QuizQuestion(
          question: "The first part of a closing is usually:",
          options: [
                  "A random joke",
                  "A short summary of resolution or next steps",
                  "Silence",
                ],
          correctIndex: 1,
          explanation: "Start with a short summary of the resolution or next steps.",
        ),
              QuizQuestion(
          question: "Before ending you should:",
          options: [
                  "Ask if anything else is needed",
                  "Hang up immediately",
                  "Skip thanks",
                ],
          correctIndex: 0,
          explanation: "Ask if there is anything else you can help with.",
        ),
            ],
          ),
          Assessment(
            id: "cs_2_typing",
            type: AssessmentType.typing,
            title: "Typing Practice",
            instructions: "Type the closing exactly.",
            typingTargetText: "Is there anything else I can help you with today? Thank you for calling. Have a good day.",
          ),
        ],
      ),
      Lesson(
        id: "cs_3",
        title: "Common Closing Mistakes",
        order: 3,
        content: """## Common Closing Mistakes
Avoid ending the call too abruptly or too vaguely.

## Mistakes to Avoid
- Ending without checking for other concerns
- Forgetting to summarize next steps
- Sounding rushed at the end
- Using an unclear or incomplete sign off

## Better Habit
Slow down slightly at the end and make sure the customer is clear on what happens next.

## Key Takeaway
A careful closing prevents unnecessary follow up contacts.

### Example
> Example: I understand how this is affecting you. Let me help with that right now, step by step.

### Use case
> Use case: A customer is worried or confused. Acknowledge the feeling first, then give one clear next step so they feel heard.
""",
        isUnlocked: false,
        assessments: [
          Assessment(
            id: "cs_3_quiz",
            type: AssessmentType.quiz,
            title: "Mistakes Check",
            instructions: "Answer the questions.",
            quizQuestions: [
              QuizQuestion(
          question: "A common closing mistake is:",
          options: [
                  "Summarizing next steps",
                  "Ending without checking for other concerns",
                  "Thanking the customer",
                ],
          correctIndex: 1,
          explanation: "Ending without checking for other concerns is a common mistake.",
        ),
              QuizQuestion(
          question: "A better habit is:",
          options: [
                  "Rush the ending",
                  "Slow down and confirm clarity",
                  "Skip the sign off",
                ],
          correctIndex: 1,
          explanation: "Slow down at the end and confirm clarity.",
        ),
            ],
          ),
          Assessment(
            id: "cs_3_voice",
            type: AssessmentType.voice,
            title: "Voice Practice",
            instructions: "Practice the closing.",
            voiceTargetScript: "Is there anything else I can help you with today? Thank you for calling. Have a good day.",
          ),
        ],
      ),
  ],
  finalAssessments: [
        Assessment(
      id: "cs_final_quiz",
      type: AssessmentType.quiz,
      title: "Closing Spiel Final Assessment",
      instructions: "Includes knowledge and situation items. Perfect score required.",
      quizQuestions: [
        QuizQuestion(
          question: "Issue resolved. Best close?",
          options: [
            "Bye.",
            "I have updated your account. Is there anything else I can help you with today? Thank you for calling.",
            "I am transferring you for no reason.",
          ],
          correctIndex: 1,
          explanation: "Explain solutions clearly and confirm the outcome. Correct choice: I have updated your account. Is there anything else I can help you with today? Thank you for calling.",
        ),
        QuizQuestion(
          question: "You forget to ask if anything else is needed. Risk?",
          options: [
            "No risk",
            "Missed concerns and possible follow-up contacts",
            "Faster customer loyalty always",
          ],
          correctIndex: 1,
          explanation: "A strong close summarizes, offers further help, and ends politely. Correct choice: Missed concerns and possible follow-up contacts",
        ),
        QuizQuestion(
          question: "A strong closing includes:",
          options: [
            "Summary, further help offer, polite sign off",
            "No summary and abrupt end",
            "Only a transfer code",
          ],
          correctIndex: 0,
          explanation: "A strong close summarizes, offers further help, and ends politely. Correct choice: Summary, further help offer, polite sign off",
        ),
        QuizQuestion(
          question: "Customer still sounds unsure at the end. You should:",
          options: [
            "Hang up faster",
            "Confirm next steps are clear before ending",
            "Ignore it",
          ],
          correctIndex: 1,
          explanation: "The correct answer is: Confirm next steps are clear before ending",
        ),
        QuizQuestion(
          question: "Worst closing habit?",
          options: [
            "Thanking the customer",
            "Ending without checking other concerns",
            "Summarizing the resolution",
          ],
          correctIndex: 1,
          explanation: "A strong close summarizes, offers further help, and ends politely. Correct choice: Ending without checking other concerns",
        ),
      ],
    ),
    Assessment(
      id: "cs_final_typing",
      type: AssessmentType.typing,
      title: "Final Typing Practice",
      instructions: "Type the key phrase exactly.",
      typingTargetText: "Is there anything else I can help you with today? Thank you for calling. Have a good day.",
    ),
    Assessment(
      id: "cs_final_voice",
      type: AssessmentType.voice,
      title: "Final Voice Practice",
      instructions: "Practice the key phrase clearly.",
      voiceTargetScript: "Is there anything else I can help you with today? Thank you for calling. Have a good day.",
    ),
  ],
);
