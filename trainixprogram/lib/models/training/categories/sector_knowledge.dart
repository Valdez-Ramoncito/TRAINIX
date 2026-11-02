part of '../training_categories.dart';

final TrainingCategoryData sectorKnowledgeCategory = TrainingCategoryData(
  name: "Sector Knowledge",
  lessons: [
      Lesson(
        id: "sk_1",
        title: "What is Sector Knowledge?",
        order: 1,
        content: """## What is Sector Knowledge?
Sector knowledge means understanding the products, rules, common issues, and language of the industry you support.

## Why it matters for new agents
Customers expect you to understand their situation quickly.
Strong sector knowledge helps you ask better questions, avoid wrong answers, and sound confident.

## Common sectors in contact centers
- Finance
- Tech Support
- Healthcare
- Telco

## Key Takeaway
You do not need to be an expert on day one. You do need the basics of the sector you handle.

### Example
> Example: I understand how this is affecting you. Let me help with that right now, step by step.

### Use case
> Use case: A customer is worried or confused. Acknowledge the feeling first, then give one clear next step so they feel heard.
""",
        isUnlocked: true,
        assessments: [
          Assessment(
            id: "sk_1_quiz",
            type: AssessmentType.quiz,
            title: "Quick Check",
            instructions: "Answer all questions. Perfect score required.",
            quizQuestions: [
              QuizQuestion(
          question: "Sector knowledge means:",
          options: [
                  "Knowing only greetings",
                  "Understanding products, rules, common issues, and sector language",
                  "Ignoring customer context",
                ],
          correctIndex: 1,
          explanation: "Understand products, rules, common issues, and sector language.",
        ),
              QuizQuestion(
          question: "Why does sector knowledge matter?",
          options: [
                  "It helps you ask better questions and avoid wrong answers",
                  "It replaces empathy",
                  "It removes the need to listen",
                ],
          correctIndex: 0,
          explanation: "It helps you ask better questions and avoid wrong answers.",
        ),
              QuizQuestion(
          question: "A common contact center sector is:",
          options: [
                  "Finance",
                  "Unrelated sports trivia",
                  "Random hobbies only",
                ],
          correctIndex: 0,
          explanation: "Finance is a common contact center sector.",
        ),
            ],
          ),
        ],
      ),
      Lesson(
        id: "sk_2",
        title: "Finance Sector Basics",
        order: 2,
        content: """## Finance Sector Basics
Finance support often includes banking, cards, payments, loans, and account issues.

### Example
> Example: For this healthcare request, I need to verify the account holder before I can share appointment details.

### Use case
> Use case: Apply the sector rule first (privacy, fees, outage policy), then continue with the solution.

## Common customer concerns
- Balance and transaction questions
- Failed payments or transfers
- Card blocks, limits, and access issues
- Fees, statements, and account updates

## What new agents must remember
- Always verify identity before sharing account details
- Never guess on rates, approvals, or legal terms
- Use approved tools and scripts for account actions
- Protect sensitive data at all times

## Useful agent habits
- Confirm the exact transaction or date
- Explain next steps in simple language
- Escalate fraud or high-risk cases quickly

## Key Takeaway
In finance, accuracy and privacy matter as much as speed.""",
        isUnlocked: false,
        assessments: [
          Assessment(
            id: "sk_2_quiz",
            type: AssessmentType.quiz,
            title: "Finance Check",
            instructions: "Answer the situation questions.",
            quizQuestions: [
              QuizQuestion(
          question: "Before sharing account details, a finance agent should:",
          options: [
                  "Verify the customer's identity",
                  "Share details immediately",
                  "Ask the customer to guess their own balance",
                ],
          correctIndex: 0,
          explanation: "Always verify identity before sharing account information.",
        ),
              QuizQuestion(
          question: "A customer asks if a loan is approved. You are unsure. Best action?",
          options: [
                  "Guess yes to keep them happy",
                  "Check the approved source or escalate",
                  "Say approval is guaranteed",
                ],
          correctIndex: 1,
          explanation: "Do not guess. Check the approved source or escalate.",
        ),
              QuizQuestion(
          question: "Which is a common finance concern?",
          options: [
                  "Failed payments or transfers",
                  "Printer driver install only",
                  "Clinic appointment triage only",
                ],
          correctIndex: 0,
          explanation: "Failed payments and transfers are common finance issues.",
        ),
            ],
          ),
          Assessment(
            id: "sk_2_typing",
            type: AssessmentType.typing,
            title: "Typing Practice",
            instructions: "Type the line exactly.",
            typingTargetText: "For your security, I need to verify your identity before we review the account.",
          ),
        ],
      ),
      Lesson(
        id: "sk_3",
        title: "Tech Support Basics",
        order: 3,
        content: """## Tech Support Basics
Tech support helps customers with software, devices, apps, logins, and connection issues.

## Common customer concerns
- Cannot log in
- App crashes or errors
- Slow performance
- Setup and configuration problems

## What new agents must remember
- Gather exact error details before solving
- Ask what changed recently
- Follow troubleshooting steps in order
- Do not skip basic checks

## Useful first questions
- What device and app version are you using?
- When did this start?
- What happens when you try the step?
- Are you seeing an error message?

## Key Takeaway
In tech support, clear diagnosis comes before advanced fixes.

### Example
> Example: I understand how this is affecting you. Let me help with that right now, step by step.

### Use case
> Use case: A customer is worried or confused. Acknowledge the feeling first, then give one clear next step so they feel heard.
""",
        isUnlocked: false,
        assessments: [
          Assessment(
            id: "sk_3_quiz",
            type: AssessmentType.quiz,
            title: "Tech Support Check",
            instructions: "Answer the situation questions.",
            quizQuestions: [
              QuizQuestion(
          question: "Customer says the app is broken. Best first move?",
          options: [
                  "Jump to advanced reinstall steps",
                  "Gather exact symptoms and error details",
                  "Close the case as device fault",
                ],
          correctIndex: 1,
          explanation: "Gather exact symptoms and error details before advanced fixes.",
        ),
              QuizQuestion(
          question: "A strong tech support habit is:",
          options: [
                  "Skipping basic checks",
                  "Following troubleshooting steps in order",
                  "Guessing without questions",
                ],
          correctIndex: 1,
          explanation: "Follow troubleshooting steps in order.",
        ),
              QuizQuestion(
          question: "Which question helps diagnosis?",
          options: [
                  "When did this start?",
                  "What is your favorite color?",
                  "Can we skip the details?",
                ],
          correctIndex: 0,
          explanation: "Asking when the issue started helps diagnosis.",
        ),
            ],
          ),
          Assessment(
            id: "sk_3_typing",
            type: AssessmentType.typing,
            title: "Typing Practice",
            instructions: "Type the line exactly.",
            typingTargetText: "When did this start, and what exact error message do you see?",
          ),
        ],
      ),
      Lesson(
        id: "sk_4",
        title: "Healthcare Sector Basics",
        order: 4,
        content: """## Healthcare Sector Basics
Healthcare support may include appointments, billing, insurance status, records access, and general service guidance.

## Common customer concerns
- Appointment scheduling or changes
- Billing and coverage questions
- Portal login and records access
- Follow-up on service requests

## What new agents must remember
- Protect patient privacy at all times
- Verify identity before discussing personal information
- Do not give medical advice unless you are trained and authorized
- Use approved processes for records and escalation

## Important boundary
Agents support service processes.
Clinical decisions belong to qualified healthcare professionals.

## Key Takeaway
In healthcare, privacy and correct process come first.

### Example
> Example: I understand how this is affecting you. Let me help with that right now, step by step.

### Use case
> Use case: A customer is worried or confused. Acknowledge the feeling first, then give one clear next step so they feel heard.
""",
        isUnlocked: false,
        assessments: [
          Assessment(
            id: "sk_4_quiz",
            type: AssessmentType.quiz,
            title: "Healthcare Check",
            instructions: "Answer the situation questions.",
            quizQuestions: [
              QuizQuestion(
          question: "Before discussing personal health account details, you should:",
          options: [
                  "Verify identity",
                  "Share details immediately",
                  "Post details in chat history publicly",
                ],
          correctIndex: 0,
          explanation: "Verify identity to protect privacy.",
        ),
              QuizQuestion(
          question: "A customer asks which treatment they should choose. Best action?",
          options: [
                  "Give personal medical advice",
                  "Stay within approved support scope and direct them to the right channel",
                  "Guess based on online trends",
                ],
          correctIndex: 1,
          explanation: "Stay in approved support scope; do not give unauthorized medical advice.",
        ),
              QuizQuestion(
          question: "A common healthcare support concern is:",
          options: [
                  "Appointment scheduling",
                  "GPU driver overclocking",
                  "Loan interest compounding only",
                ],
          correctIndex: 0,
          explanation: "Appointment scheduling is a common healthcare support request.",
        ),
            ],
          ),
          Assessment(
            id: "sk_4_typing",
            type: AssessmentType.typing,
            title: "Typing Practice",
            instructions: "Type the line exactly.",
            typingTargetText: "For privacy, I need to verify your identity before we discuss account details.",
          ),
        ],
      ),
      Lesson(
        id: "sk_5",
        title: "Telco Sector Basics",
        order: 5,
        content: """## Telco Sector Basics
Telco support covers mobile, internet, billing plans, outages, and service activation issues.

## Common customer concerns
- No signal or slow internet
- Plan, promo, and billing questions
- SIM, device, or account activation
- Outage checks and service restoration

## What new agents must remember
- Confirm the affected number or account first
- Check for known outages before long troubleshooting
- Explain plan details using simple language
- Set clear expectations on restoration timelines

## Useful first checks
- Which number or account is affected?
- Is this mobile data, calls, or home internet?
- When did the issue start?
- Are nearby services also affected?

## Key Takeaway
In telco, identify the service and check known issues early.

### Example
> Example: I understand how this is affecting you. Let me help with that right now, step by step.

### Use case
> Use case: A customer is worried or confused. Acknowledge the feeling first, then give one clear next step so they feel heard.
""",
        isUnlocked: false,
        assessments: [
          Assessment(
            id: "sk_5_quiz",
            type: AssessmentType.quiz,
            title: "Telco Check",
            instructions: "Answer the situation questions.",
            quizQuestions: [
              QuizQuestion(
          question: "Customer reports no internet. Strong first step?",
          options: [
                  "Confirm the account and check for known outages",
                  "Cancel the plan immediately",
                  "Ignore the timeline",
                ],
          correctIndex: 0,
          explanation: "Confirm the account and check for known outages first.",
        ),
              QuizQuestion(
          question: "A common telco concern is:",
          options: [
                  "Slow internet or no signal",
                  "Surgical scheduling only",
                  "Credit card chip manufacturing only",
                ],
          correctIndex: 0,
          explanation: "No signal or slow internet is a common telco issue.",
        ),
              QuizQuestion(
          question: "When explaining plan details, you should:",
          options: [
                  "Use simple clear language",
                  "Use only internal codes",
                  "Avoid confirming the affected number",
                ],
          correctIndex: 0,
          explanation: "Use simple clear language customers can follow.",
        ),
            ],
          ),
          Assessment(
            id: "sk_5_voice",
            type: AssessmentType.voice,
            title: "Voice Practice",
            instructions: "Practice this line clearly.",
            voiceTargetScript: "Let me confirm the affected number and check if there is a known outage in your area.",
          ),
        ],
      ),
      Lesson(
        id: "sk_6",
        title: "Using Knowledge and Knowing Limits",
        order: 6,
        content: """## Using Knowledge and Knowing Limits
Sector knowledge should help the customer, not overwhelm them.

## Good habits
- Explain in simple terms
- Connect knowledge to the customer's exact issue
- Avoid long policy dumps
- Check understanding

## Know your limits
- Do not guess on regulated or high-risk topics
- Use approved tools and knowledge bases
- Escalate when the case is outside your authority
- Protect sensitive information in every sector

## Escalation examples
- Suspected fraud in finance
- Clinical advice requests in healthcare
- Repeated failed technical fixes that need higher tier support
- Network incidents that need specialized teams

## Key Takeaway
Strong agents use knowledge clearly and escalate when required.

### Example
> Example: I understand how this is affecting you. Let me help with that right now, step by step.

### Use case
> Use case: A customer is worried or confused. Acknowledge the feeling first, then give one clear next step so they feel heard.
""",
        isUnlocked: false,
        assessments: [
          Assessment(
            id: "sk_6_quiz",
            type: AssessmentType.quiz,
            title: "Limits Check",
            instructions: "Answer the situation questions.",
            quizQuestions: [
              QuizQuestion(
          question: "You are unsure about a high-risk finance case. Best action?",
          options: [
                  "Guess to avoid escalation",
                  "Use approved sources or escalate",
                  "Invent a policy",
                ],
          correctIndex: 1,
          explanation: "Use approved sources or escalate. Do not invent answers.",
        ),
              QuizQuestion(
          question: "When sharing sector knowledge, avoid:",
          options: [
                  "Simple relevant explanation",
                  "Long unrelated policy dumps",
                  "Checking understanding",
                ],
          correctIndex: 1,
          explanation: "Avoid long unrelated policy dumps.",
        ),
              QuizQuestion(
          question: "A good escalation example is:",
          options: [
                  "Suspected fraud",
                  "A simple greeting question",
                  "Asking for the customer's preferred language only",
                ],
          correctIndex: 0,
          explanation: "Suspected fraud should be escalated.",
        ),
            ],
          ),
          Assessment(
            id: "sk_6_typing",
            type: AssessmentType.typing,
            title: "Typing Practice",
            instructions: "Type the line exactly.",
            typingTargetText: "Based on your account type, here is what applies in this case.",
          ),
          Assessment(
            id: "sk_6_voice",
            type: AssessmentType.voice,
            title: "Voice Practice",
            instructions: "Practice this line clearly.",
            voiceTargetScript: "Based on your account type, here is what applies in this case.",
          ),
        ],
      ),
  ],
  finalAssessments: [
    Assessment(
      id: "sk_final_quiz",
      type: AssessmentType.quiz,
      title: "Sector Knowledge Final Assessment",
      instructions: "Includes sector situations across finance, tech, healthcare, and telco. Perfect score required.",
      quizQuestions: [
        QuizQuestion(
          question: "Finance customer asks for full account details with no verification. You should:",
          options: [
            "Share the details immediately",
            "Verify identity first",
            "Post the details in public chat",
          ],
          correctIndex: 1,
          explanation: "In sensitive sectors, verify first and never guess. Correct choice: Verify identity first",
        ),
        QuizQuestion(
          question: "Tech customer says the app is broken. Best first move?",
          options: [
            "Gather exact symptoms and error details",
            "Reinstall everything with no questions",
            "Close as unsolvable",
          ],
          correctIndex: 0,
          explanation: "Gather symptoms first, then follow troubleshooting in order. Correct choice: Gather exact symptoms and error details",
        ),
        QuizQuestion(
          question: "Healthcare customer asks which treatment to choose. Best response path?",
          options: [
            "Give personal medical advice",
            "Stay in approved support scope and route correctly",
            "Guess based on social media",
          ],
          correctIndex: 1,
          explanation: "Protect privacy and stay within approved support scope. Correct choice: Stay in approved support scope and route correctly",
        ),
        QuizQuestion(
          question: "Telco customer has no internet. Strong early step?",
          options: [
            "Confirm account and check known outages",
            "Ignore the affected number",
            "Cancel service immediately",
          ],
          correctIndex: 0,
          explanation: "Explain solutions clearly and confirm the outcome. Correct choice: Confirm account and check known outages",
        ),
        QuizQuestion(
          question: "You hit a case outside your authority. Best action?",
          options: [
            "Escalate using the approved process",
            "Invent an answer",
            "End the call without help",
          ],
          correctIndex: 0,
          explanation: "The correct answer is: Escalate using the approved process",
        ),
        QuizQuestion(
          question: "Across all sectors, sensitive information should be:",
          options: [
            "Protected and shared only after proper verification",
            "Shared freely",
            "Guessed when missing",
          ],
          correctIndex: 0,
          explanation: "Use sector knowledge clearly and escalate when required. Correct choice: Protected and shared only after proper verification",
        ),
      ],
    ),
    Assessment(
      id: "sk_final_typing",
      type: AssessmentType.typing,
      title: "Final Typing Practice",
      instructions: "Type the key phrase exactly.",
      typingTargetText: "For your security, I need to verify your identity before we review the account.",
    ),
    Assessment(
      id: "sk_final_voice",
      type: AssessmentType.voice,
      title: "Final Voice Practice",
      instructions: "Practice the key phrase clearly.",
      voiceTargetScript: "Let me confirm the affected number and check if there is a known outage in your area.",
    ),
  ],
);
