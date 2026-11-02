part of 'training_categories.dart';

final List<Assessment> grandFinalAssessments = [
  Assessment(
    id: "gf_quiz",
    type: AssessmentType.quiz,
    title: "Grand Final Quiz",
    instructions:
        "This is a mixed final across all categories. Some items combine more than one skill. Perfect score required.",
    quizQuestions: [
      QuizQuestion(
        question:
            "A customer just connected and sounds rushed. What should you do first?",
        options: [
          "Skip the greeting and ask for the account number",
          "Deliver a clear Opening Spiel, then listen",
          "Transfer immediately without greeting",
        ],
        correctIndex: 1,
        explanation:
            "Every call still starts with a proper Opening Spiel, then you listen to the concern.",
      ),
      QuizQuestion(
        question:
            "A customer wants a feature you cannot provide. Which response best uses positive scripting?",
        options: [
          "We cannot do that.",
          "That is impossible on your plan.",
          "I cannot enable that feature, but here is what we can do instead.",
        ],
        correctIndex: 2,
        explanation:
            "Positive scripting states the limit honestly and offers a helpful alternative.",
      ),
      QuizQuestion(
        question: "A customer says this delay ruined my week. Best first move?",
        options: [
          "Jump straight to policy without acknowledgment",
          "Acknowledge the frustration, then move to help",
          "Tell them it is not a big issue",
        ],
        correctIndex: 1,
        explanation:
            "Empathy comes first. Acknowledge the feeling, then guide the next step.",
      ),
      QuizQuestion(
        question:
            "You already know a likely fix, but the customer is still explaining. What should you do?",
        options: [
          "Interrupt with the solution",
          "Let them finish, then confirm understanding",
          "Change the topic to save time",
        ],
        correctIndex: 1,
        explanation:
            "Active listening means letting them finish and confirming the issue before solving.",
      ),
      QuizQuestion(
        question:
            "Customer says the app is broken. Which action shows strong problem identification?",
        options: [
          "Assume the device is old and close the case",
          "Ask clarifying questions to find what exactly fails",
          "Offer a random workaround with no diagnosis",
        ],
        correctIndex: 1,
        explanation:
            "Gather symptoms and clarify the real failure before choosing a fix.",
      ),
      QuizQuestion(
        question: "You have a two-step fix. How should you deliver it?",
        options: [
          "Explain both steps clearly and check understanding",
          "Do the steps silently without explanation",
          "Use heavy jargon as fast as possible",
        ],
        correctIndex: 0,
        explanation:
            "Clear solution delivery uses simple steps and confirms the customer can follow.",
      ),
      QuizQuestion(
        question:
            "In chat, a customer asks when a refund will appear. Which reply is clearest?",
        options: [
          "Soon.",
          "Later maybe.",
          "Your refund has been processed. You should see it in 3 to 5 business days.",
        ],
        correctIndex: 2,
        explanation:
            "Specific timing is clearer than vague words like soon or later.",
      ),
      QuizQuestion(
        question:
            "A finance customer asks for account details with no verification. Best action?",
        options: [
          "Share the details immediately to be helpful",
          "Verify identity first",
          "Guess the details from memory",
        ],
        correctIndex: 1,
        explanation:
            "In finance, verify identity before sharing sensitive account information.",
      ),
      QuizQuestion(
        question:
            "A healthcare customer asks which treatment to choose. Best response path?",
        options: [
          "Give personal medical advice",
          "Stay within approved support scope and route them correctly",
          "Guess based on online trends",
        ],
        correctIndex: 1,
        explanation:
            "Healthcare support protects privacy and does not give unauthorized clinical advice.",
      ),
      QuizQuestion(
        question: "A telco customer has no internet. Strong early step?",
        options: [
          "Confirm the account and check for known outages",
          "Cancel the plan immediately",
          "Ignore the affected number",
        ],
        correctIndex: 0,
        explanation:
            "Confirm the service and check known outages before long troubleshooting.",
      ),
      QuizQuestion(
        question: "The issue is resolved. Which closing is strongest?",
        options: [
          "Bye.",
          "I have updated your account. Is there anything else I can help you with today? Thank you for calling.",
          "I am transferring you for no reason.",
        ],
        correctIndex: 1,
        explanation:
            "A strong close summarizes, offers further help, and ends politely.",
      ),
      QuizQuestion(
        question:
            "You are explaining refund steps and the customer asks you to slow down. You should:",
        options: [
          "Continue at the same speed",
          "Slow to a calm steady pace and check understanding",
          "Speak faster to finish sooner",
        ],
        correctIndex: 1,
        explanation:
            "Pace should stay calm and steady, especially on important steps.",
      ),
      QuizQuestion(
        question:
            "A customer asks you to repeat a reference number. Best action?",
        options: [
          "Say it faster once",
          "Repeat it slowly and clearly",
          "Refuse to repeat it",
        ],
        correctIndex: 1,
        explanation: "Clear pronunciation reduces repeats and frustration.",
      ),
      QuizQuestion(
        question: "You need a second to check a screen. Best choice?",
        options: [
          "Fill the silence with um and uh",
          "Use a short silent pause, then respond",
          "Say you know like basically while thinking",
        ],
        correctIndex: 1,
        explanation:
            "A short clean pause sounds more professional than filler words.",
      ),
      QuizQuestion(
        question:
            "A customer is upset about a repeated billing error. Best tone?",
        options: [
          "Calm and steady",
          "Sharp and defensive",
          "Playful and casual",
        ],
        correctIndex: 0,
        explanation: "With upset customers, keep a calm professional tone.",
      ),
      QuizQuestion(
        question:
            "An upset customer wants a fee waived, but policy does not allow it. Which response best combines empathy and positive scripting?",
        options: [
          "No. Policy is policy.",
          "I understand this fee is frustrating. I cannot waive it, but I can review the options that are available.",
          "Sure, I will waive anything you want.",
        ],
        correctIndex: 1,
        explanation:
            "Acknowledge the feeling, stay honest about limits, and offer what you can do.",
      ),
      QuizQuestion(
        question:
            "You confirmed the issue, explained the fix, and the customer still sounds unsure. Best next step before ending?",
        options: [
          "Hang up quickly",
          "Confirm the next steps are clear and ask if anything else is needed",
          "Skip the closing to save time",
        ],
        correctIndex: 1,
        explanation:
            "Confirm clarity and offer further help before a professional close.",
      ),
      QuizQuestion(
        question:
            "A case is outside your authority and may involve fraud risk. Best action?",
        options: [
          "Invent an answer to avoid escalation",
          "Use the approved escalation process",
          "Ignore the risk signs",
        ],
        correctIndex: 1,
        explanation:
            "Escalate high-risk or out-of-scope cases through approved channels.",
      ),
    ],
  ),
  Assessment(
    id: "gf_typing_1",
    type: AssessmentType.typing,
    title: "Grand Final Typing - Opening",
    instructions: "Type the professional opening line exactly.",
    typingTargetText:
        "Thank you for calling. This is Alex. How may I help you today?",
  ),
  Assessment(
    id: "gf_typing_2",
    type: AssessmentType.typing,
    title: "Grand Final Typing - Empathy",
    instructions: "Type the empathy line exactly.",
    typingTargetText: "I understand how frustrating that must be.",
  ),
  Assessment(
    id: "gf_voice_1",
    type: AssessmentType.voice,
    title: "Grand Final Voice - Opening",
    instructions: "Practice this opening line clearly.",
    voiceTargetScript:
        "Thank you for calling. This is Alex. How may I help you today?",
  ),
  Assessment(
    id: "gf_voice_2",
    type: AssessmentType.voice,
    title: "Grand Final Voice - Closing",
    instructions: "Practice this closing line clearly.",
    voiceTargetScript:
        "Is there anything else I can help you with today? Thank you for calling.",
  ),
];
