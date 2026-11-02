part of '../training_categories.dart';

final TrainingCategoryData solutionDeliveryCategory = TrainingCategoryData(
  name: "Solution Delivery",
  lessons: [
      Lesson(
        id: "sd_1",
        title: "What is Solution Delivery?",
        order: 1,
        content: """## What is Solution Delivery?
Solution delivery is explaining and applying the fix in a clear and helpful way.

## Goal
Help the customer understand what will happen and what they need to do, if anything.

## Key Elements
- Clear explanation
- Simple steps
- Realistic expectations
- Confirmation that the issue is addressed

## Key Takeaway
A good solution is not only correct. It is also easy for the customer to follow.

### Example
> Example: I understand how this is affecting you. Let me help with that right now, step by step.

### Use case
> Use case: A customer is worried or confused. Acknowledge the feeling first, then give one clear next step so they feel heard.
""",
        isUnlocked: true,
        assessments: [
          Assessment(
            id: "sd_1_quiz",
            type: AssessmentType.quiz,
            title: "Quick Check",
            instructions: "Answer all questions. Perfect score required.",
            quizQuestions: [
              QuizQuestion(
          question: "Solution delivery is about:",
          options: [
                  "Hiding steps",
                  "Explaining and applying the fix clearly",
                  "Avoiding confirmation",
                ],
          correctIndex: 1,
          explanation: "Explain and apply the fix in a clear, helpful way.",
        ),
              QuizQuestion(
          question: "A key element is:",
          options: [
                  "Unclear jargon",
                  "Simple steps",
                  "No expectations",
                ],
          correctIndex: 1,
          explanation: "Simple steps make the solution easier to follow.",
        ),
              QuizQuestion(
          question: "A good solution should be:",
          options: [
                  "Correct and easy to follow",
                  "Long and complex",
                  "Secret",
                ],
          correctIndex: 0,
          explanation: "It should be correct and easy for the customer to follow.",
        ),
            ],
          ),
        ],
      ),
      Lesson(
        id: "sd_2",
        title: "Explaining Solutions Clearly",
        order: 2,
        content: """## Explaining Solutions Clearly
Customers should never feel lost while you explain the fix.

### Example
> Example: I will reset the service on your line now. This usually takes about two minutes, then we will test together.

### Use case
> Use case: Explain the action, the expected time, and what the customer should see when it works.

## Best Practices
- Use simple language
- Break steps into small parts
- Check understanding after key steps
- Avoid unnecessary jargon

## Example
I will walk you through two short steps. First we will verify the account. Then we will apply the update.

## Key Takeaway
Clear explanations reduce confusion and repeat contacts.""",
        isUnlocked: false,
        assessments: [
          Assessment(
            id: "sd_2_quiz",
            type: AssessmentType.quiz,
            title: "Clarity Check",
            instructions: "Choose the best answers.",
            quizQuestions: [
              QuizQuestion(
          question: "When explaining a solution you should:",
          options: [
                  "Use heavy jargon",
                  "Break steps into small parts",
                  "Skip checks",
                ],
          correctIndex: 1,
          explanation: "Break the fix into small clear parts.",
        ),
              QuizQuestion(
          question: "Checking understanding helps:",
          options: [
                  "Confuse the customer",
                  "Keep the customer aligned",
                  "Avoid resolution",
                ],
          correctIndex: 1,
          explanation: "It keeps the customer aligned during the explanation.",
        ),
            ],
          ),
          Assessment(
            id: "sd_2_typing",
            type: AssessmentType.typing,
            title: "Typing Practice",
            instructions: "Type the explanation exactly.",
            typingTargetText: "I will walk you through two short steps. First we will verify the account. Then we will apply the update.",
          ),
        ],
      ),
      Lesson(
        id: "sd_3",
        title: "Confirming the Resolution",
        order: 3,
        content: """## Confirming the Resolution
After providing the solution, confirm that it worked or that the next steps are clear.

## Useful Closing Checks
- Does that resolve the issue for you?
- Are the next steps clear?
- Is there anything else related to this that you need help with?

## Key Takeaway
Confirmation closes the loop and shows ownership of the result.

### Example
> Example: I understand how this is affecting you. Let me help with that right now, step by step.

### Use case
> Use case: A customer is worried or confused. Acknowledge the feeling first, then give one clear next step so they feel heard.
""",
        isUnlocked: false,
        assessments: [
          Assessment(
            id: "sd_3_quiz",
            type: AssessmentType.quiz,
            title: "Resolution Check",
            instructions: "Answer the questions.",
            quizQuestions: [
              QuizQuestion(
          question: "After delivering a solution you should:",
          options: [
                  "Hang up immediately",
                  "Confirm resolution or next steps",
                  "Avoid questions",
                ],
          correctIndex: 1,
          explanation: "Confirm resolution or that next steps are clear.",
        ),
              QuizQuestion(
          question: "Confirmation shows:",
          options: [
                  "Ownership of the result",
                  "That you are unsure",
                  "That the call failed",
                ],
          correctIndex: 0,
          explanation: "It shows ownership of the result.",
        ),
            ],
          ),
          Assessment(
            id: "sd_3_voice",
            type: AssessmentType.voice,
            title: "Voice Practice",
            instructions: "Practice this check.",
            voiceTargetScript: "Does that resolve the issue for you? Are the next steps clear?",
          ),
        ],
      ),
  ],
  finalAssessments: [
        Assessment(
      id: "sd_final_quiz",
      type: AssessmentType.quiz,
      title: "Solution Delivery Final Assessment",
      instructions: "Includes knowledge and situation items. Perfect score required.",
      quizQuestions: [
        QuizQuestion(
          question: "You have a two-step fix. Best delivery?",
          options: [
            "Do everything silently",
            "Explain the steps in simple order and check understanding",
            "Use heavy jargon quickly",
          ],
          correctIndex: 1,
          explanation: "Explain solutions clearly and confirm the outcome. Correct choice: Explain the steps in simple order and check understanding",
        ),
        QuizQuestion(
          question: "Customer seems lost during your explanation. You should:",
          options: [
            "Talk faster",
            "Pause and check understanding",
            "Skip the rest",
          ],
          correctIndex: 1,
          explanation: "The correct answer is: Pause and check understanding",
        ),
        QuizQuestion(
          question: "After applying a fix, you should:",
          options: [
            "Hang up immediately",
            "Confirm whether the issue is resolved or next steps are clear",
            "Avoid questions",
          ],
          correctIndex: 1,
          explanation: "The correct answer is: Confirm whether the issue is resolved or next steps are clear",
        ),
        QuizQuestion(
          question: "Clear solution delivery reduces:",
          options: [
            "Repeat contacts and confusion",
            "Customer trust",
            "Accuracy",
          ],
          correctIndex: 0,
          explanation: "Explain solutions clearly and confirm the outcome. Correct choice: Repeat contacts and confusion",
        ),
        QuizQuestion(
          question: "Best explanation style?",
          options: [
            "First we will verify the account. Then we will apply the update.",
            "Do the thing then the other thing somehow.",
            "It is complicated.",
          ],
          correctIndex: 0,
          explanation: "The correct answer is: First we will verify the account. Then we will apply the update.",
        ),
      ],
    ),
    Assessment(
      id: "sd_final_typing",
      type: AssessmentType.typing,
      title: "Final Typing Practice",
      instructions: "Type the key phrase exactly.",
      typingTargetText: "I will walk you through two short steps. First we will verify the account. Then we will apply the update.",
    ),
    Assessment(
      id: "sd_final_voice",
      type: AssessmentType.voice,
      title: "Final Voice Practice",
      instructions: "Practice the key phrase clearly.",
      voiceTargetScript: "Does that resolve the issue for you? Are the next steps clear?",
    ),
  ],
);
