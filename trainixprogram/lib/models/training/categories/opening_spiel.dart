part of '../training_categories.dart';

final TrainingCategoryData openingSpielCategory = TrainingCategoryData(
    name: "Opening Spiel",
    lessons: [
      Lesson(
        id: "os_1",
        title: "What is an Opening Spiel?",
        order: 1,
        content: """## What is an Opening Spiel?
The Opening Spiel is the short greeting you say the moment you answer a customer's call.
It is the very first thing the customer hears from you.

## What is it used for?
It is used to:
- Welcome the customer
- Confirm they reached the right company
- Introduce yourself by name
- Show that you are ready and willing to help

A clear opening spiel makes the customer feel acknowledged right away.

## When is it used?
You use the Opening Spiel every time you answer a call before anything else happens.
It is always the first step of the conversation.

## Why is it needed?
A good opening spiel:
- Creates a positive first impression
- Builds trust quickly
- Sets a professional and helpful tone
- Makes the rest of the call smoother

A weak or missing opening can make the customer feel ignored or unsure from the start.

## Key Takeaway
The Opening Spiel is short (about 8 to 12 seconds), but it is one of the most important parts of the call.
Get this right, and you start every conversation on the right foot.

### Example
> Example: Thank you for calling Trainix Support. This is [Your Name]. How may I help you today?

### Use case
> Use case: A customer dials in about a billing question. Your opening still comes first. Welcome them, name the company, say your name, then invite their concern.

### Common pattern
> Pattern: Thank the customer, name the company, say your name, offer help. Keep it under about 12 seconds.""",
        isUnlocked: true,
        assessments: [
          Assessment(
            id: "os_1_quiz",
            type: AssessmentType.quiz,
            title: "Quick Check",
            instructions: "Answer all questions. Score 75% or higher to pass. Retake is optional after you pass.",
            quizQuestions: [
              QuizQuestion(
                question: "What is an Opening Spiel?",
                options: [
                  "The closing statement at the end of a call",
                  "The short greeting used when answering a customer call",
                  "A long product explanation",
                ],
                correctIndex: 1,
          explanation: "An Opening Spiel is the short greeting used at the start of a customer call.",
        ),
              QuizQuestion(
                question: "When do you use the Opening Spiel?",
                options: [
                  "Only when the customer is angry",
                  "Only at the end of the call",
                  "Every time you answer a call, before anything else",
                ],
                correctIndex: 2,
          explanation: "It is used every time you answer a call, before anything else.",
        ),
              QuizQuestion(
                question: "Why is the Opening Spiel needed?",
                options: [
                  "It creates a positive first impression and sets the tone",
                  "It replaces the need to solve the customer's problem",
                  "It is only required during training sessions",
                ],
                correctIndex: 0,
          explanation: "It creates a positive first impression and sets a professional tone.",
        ),
              QuizQuestion(
                question: "How long should a typical Opening Spiel be?",
                options: [
                  "About 30 to 45 seconds",
                  "About 8 to 12 seconds",
                  "About 1 to 2 minutes",
                ],
                correctIndex: 1,
          explanation: "A good Opening Spiel is short, usually about 8 to 12 seconds.",
        ),
            ],
          ),
        ],
      ),
      Lesson(
        id: "os_2",
        title: "The Standard Formula",
        order: 2,
        content: """## The Standard Formula
A professional opening spiel follows four clear parts in order.

## The Four Parts
- Thank the customer for calling
- Say the company name
- Introduce yourself by name
- Offer help with a clear question

## Core Version
Thank you for calling [Company Name]. This is [Your Name]. How may I help you today?

## Warmer Version
Good morning, thank you for calling [Company Name]. My name is [Your Name]. How can I assist you today?

## Key Rules
- Keep it under 12 seconds
- Always include your name
- End with an open question
- Sound natural, not robotic

## Key Takeaway
Master the four parts first. Once they feel automatic, you can adjust the wording slightly while keeping the same structure.

### Example
> Example: I understand how this is affecting you. Let me help with that right now, step by step.

### Use case
> Use case: A customer is worried or confused. Acknowledge the feeling first, then give one clear next step so they feel heard.
""",
        isUnlocked: false,
        assessments: [
          Assessment(
            id: "os_2_quiz",
            type: AssessmentType.quiz,
            title: "Formula Check",
            instructions: "Check your understanding of the four-part formula.",
            quizQuestions: [
              QuizQuestion(
                question: "Which is the correct order of the four parts?",
                options: [
                  "Name, company, thank you, offer help",
                  "Thank you, company name, your name, offer help",
                  "Offer help, your name, company name, thank you",
                ],
                correctIndex: 1,
          explanation: "The standard order is thank you, company name, your name, then offer help.",
        ),
              QuizQuestion(
                question: "What should the Opening Spiel end with?",
                options: [
                  "A long company slogan",
                  "An open question offering help",
                  "A full solution to the problem",
                ],
                correctIndex: 1,
          explanation: "It should end with an open question offering help.",
        ),
            ],
          ),
          Assessment(
            id: "os_2_typing",
            type: AssessmentType.typing,
            title: "Typing Practice",
            instructions: "Type the core opening spiel exactly.",
            typingTargetText:
                "Thank you for calling [Company Name]. This is [Your Name]. How may I help you today?",
          ),
        ],
      ),
      Lesson(
        id: "os_3",
        title: "How to Deliver It Well",
        order: 3,
        content: """## How to Deliver It Well
Knowing the words is not enough. How you say them matters just as much.

## Tone
Speak with a warm and professional tone.
Smile while you speak. The customer can hear it in your voice.

## Pace
Speak at a calm and steady speed.
Do not rush. Do not speak too slowly.

## Clarity
Pronounce each word clearly.
Avoid mumbling or trailing off at the end of the sentence.

## Natural Delivery
Practice until the spiel feels natural.
It should sound like a real person greeting someone, not like reading from a script.

## Key Takeaway
A clear structure plus good delivery creates a strong first impression every time.

### Example
> Example: I understand how this is affecting you. Let me help with that right now, step by step.

### Use case
> Use case: A customer is worried or confused. Acknowledge the feeling first, then give one clear next step so they feel heard.
""",
        isUnlocked: false,
        assessments: [
          Assessment(
            id: "os_3_quiz",
            type: AssessmentType.quiz,
            title: "Delivery Check",
            instructions: "Answer the questions about delivery.",
            quizQuestions: [
              QuizQuestion(
                question: "Why should you smile while delivering the Opening Spiel?",
                options: [
                  "It is required by company policy only",
                  "The customer can hear warmth in your voice",
                  "It makes the call longer",
                ],
                correctIndex: 1,
          explanation: "Customers can hear warmth in your voice when you smile.",
        ),
              QuizQuestion(
                question: "What pace should you use?",
                options: [
                  "As fast as possible",
                  "Very slow and hesitant",
                  "Calm and steady",
                ],
                correctIndex: 2,
          explanation: "Use a calm and steady pace so the greeting is clear.",
        ),
            ],
          ),
          Assessment(
            id: "os_3_voice",
            type: AssessmentType.voice,
            title: "Voice Practice",
            instructions: "Practice saying the opening spiel clearly.",
            voiceTargetScript:
                "Thank you for calling Horizon Support. This is Alex. How may I help you today?",
          ),
        ],
      ),
      Lesson(
        id: "os_4",
        title: "Common Mistakes to Avoid",
        order: 4,
        content: """## Common Mistakes to Avoid
Even small errors at the start of the call can hurt the customer's experience.

## What Not to Do
- Do not rush or speak too fast
- Do not skip your name
- Do not use fillers like um or ah at the beginning
- Do not sound bored or robotic
- Do not add long company slogans
- Do not start solving the problem before the customer has spoken

## Better Habits
- Pause briefly after answering
- Deliver the spiel cleanly
- Wait for the customer to respond
- Listen carefully to what they say next

## Key Takeaway
Avoiding these mistakes keeps the opening professional and customer focused.

### Example
> Example: I understand how this is affecting you. Let me help with that right now, step by step.

### Use case
> Use case: A customer is worried or confused. Acknowledge the feeling first, then give one clear next step so they feel heard.
""",
        isUnlocked: false,
        assessments: [
          Assessment(
            id: "os_4_quiz",
            type: AssessmentType.quiz,
            title: "Mistakes Check",
            instructions: "Identify the correct practices.",
            quizQuestions: [
              QuizQuestion(
                question: "Which is a common Opening Spiel mistake?",
                options: [
                  "Including your name",
                  "Skipping your name",
                  "Ending with an open question",
                ],
                correctIndex: 1,
          explanation: "Skipping your name is a common opening mistake.",
        ),
              QuizQuestion(
                question: "What should you do after the Opening Spiel?",
                options: [
                  "Immediately start solving without listening",
                  "Wait for the customer to respond and listen",
                  "Hang up if they do not speak right away",
                ],
                correctIndex: 1,
          explanation: "Wait for the customer to respond and listen carefully.",
        ),
              QuizQuestion(
                question: "Which habit is better at the start of the call?",
                options: [
                  "Using fillers like um and ah",
                  "Rushing through the greeting",
                  "Delivering the spiel cleanly and clearly",
                ],
                correctIndex: 2,
          explanation: "Deliver the spiel cleanly and clearly without fillers or rushing.",
        ),
            ],
          ),
        ],
      ),
    ],
    finalAssessments: [
        Assessment(
      id: "os_final",
      type: AssessmentType.quiz,
      title: "Opening Spiel Final Assessment",
      instructions: "Includes knowledge and situation items. Perfect score required.",
      quizQuestions: [
        QuizQuestion(
          question: "A customer just connected. What should you do first?",
          options: [
            "Ask for their account number immediately",
            "Deliver a clear Opening Spiel",
            "Transfer them without greeting",
          ],
          correctIndex: 1,
          explanation: "Always start with a clear Opening Spiel before account questions or transfers.",
        ),
        QuizQuestion(
          question: "You answered a call and said only Hello. What is missing?",
          options: [
            "Nothing, that is enough",
            "Company name, your name, and offer of help",
            "A full solution",
          ],
          correctIndex: 1,
          explanation: "A full Opening Spiel includes company name, your name, and an offer of help.",
        ),
        QuizQuestion(
          question: "A trainee rushes the Opening Spiel and skips their name. What should they fix?",
          options: [
            "Speak even faster",
            "Include their name and slow to a clear pace",
            "Remove the offer of help",
          ],
          correctIndex: 1,
          explanation: "Include your name and slow down so the greeting is clear.",
        ),
        QuizQuestion(
          question: "After the Opening Spiel, the best next action is to:",
          options: [
            "Talk over the customer",
            "Wait and listen to the customer's response",
            "End the call",
          ],
          correctIndex: 1,
          explanation: "Pause and listen so the customer can state their concern.",
        ),
        QuizQuestion(
          question: "Which Opening Spiel is strongest?",
          options: [
            "Yeah what do you need?",
            "Thank you for calling Horizon Support. This is Alex. How may I help you today?",
            "Hold please",
          ],
          correctIndex: 1,
          explanation: "The strongest version includes thanks, company name, agent name, and an offer of help.",
        ),
      ],
    ),
    Assessment(
      id: "os_final_typing",
      type: AssessmentType.typing,
      title: "Final Typing Practice",
      instructions: "Type the core opening spiel exactly.",
      typingTargetText:
          "Thank you for calling [Company Name]. This is [Your Name]. How may I help you today?",
    ),
    Assessment(
      id: "os_final_voice",
      type: AssessmentType.voice,
      title: "Final Voice Practice",
      instructions: "Practice the opening spiel clearly.",
      voiceTargetScript:
          "Thank you for calling Horizon Support. This is Alex. How may I help you today?",
    ),
  ],
  );
