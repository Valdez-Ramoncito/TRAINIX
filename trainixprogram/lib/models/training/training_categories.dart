import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:trainixprogram/models/training/notifications/training_notification.dart';
import 'package:trainixprogram/services/training_progress_repository.dart';

part 'categories/opening_spiel.dart';
part 'categories/positive_scripting.dart';
part 'categories/empathy.dart';
part 'categories/active_listening.dart';
part 'categories/problem_identification.dart';
part 'categories/solution_delivery.dart';
part 'categories/communication_clarity.dart';
part 'categories/sector_knowledge.dart';
part 'categories/closing_spiel.dart';
part 'categories/pace_and_speed.dart';
part 'categories/pronunciation_and_clarity.dart';
part 'categories/filler_word_usage.dart';
part 'categories/tone_and_inflection.dart';
part 'training_data.dart';
part 'grand_final_data.dart';

class Category {
  final int id;
  final String name;
  final String sub;
  final String trainingType;
  late int completed;
  late bool isComplete;
  late bool isNext;

  Category({
    required this.id,
    required this.name,
    required this.sub,
    required this.trainingType,
    this.completed = 0,
    this.isComplete = false,
    required this.isNext,
  });
}

List<Category> categories = [
  Category(
    id: 1,
    name: 'Opening Spiel',
    sub: 'Standard professional greeting and call opening protocol.',
    trainingType: "both",
    completed: 0,
    isComplete: false,
    isNext: true,
  ),
  Category(
    id: 2,
    name: 'Positive Scripting',
    sub: 'Using optimistic, constructive, and professional phrasing.',
    trainingType: "both",
    completed: 0,
    isComplete: false,
    isNext: false,
  ),
  Category(
    id: 3,
    name: 'Empathy',
    sub: 'Acknowledging customer feelings and showing genuine care.',
    trainingType: "both",
    completed: 0,
    isComplete: false,
    isNext: false,
  ),
  Category(
    id: 4,
    name: 'Active Listening',
    sub: 'Attentive listening without interrupting to understand needs.',
    trainingType: "both",
    completed: 0,
    isComplete: false,
    isNext: false,
  ),
  Category(
    id: 5,
    name: 'Problem Identification',
    sub: 'Accurately discovering the root cause of the customer concern.',
    trainingType: "both",
    completed: 0,
    isComplete: false,
    isNext: false,
  ),
  Category(
    id: 6,
    name: 'Solution Delivery',
    sub: 'Providing efficient, clear, and accurate problem resolution.',
    trainingType: "both",
    completed: 0,
    isComplete: false,
    isNext: false,
  ),
  Category(
    id: 7,
    name: 'Communication Clarity',
    sub: 'Using clear and concise words for clearer context.',
    trainingType: "chat",
    completed: 0,
    isComplete: false,
    isNext: false,
  ),
  Category(
    id: 8,
    name: 'Sector Knowledge',
    sub: 'Demonstrating product, domain, and workflow expertise.',
    trainingType: "both",
    completed: 0,
    isComplete: false,
    isNext: false,
  ),
  Category(
    id: 9,
    name: 'Closing Spiel',
    sub: 'Proper call wrap-up, offering further help, and sign-off.',
    trainingType: "both",
    completed: 0,
    isComplete: false,
    isNext: false,
  ),
  Category(
    id: 10,
    name: 'Pace & Speed',
    sub: 'Maintaining appropriate speaking speed for clear comprehension.',
    trainingType: "voice",
    completed: 0,
    isComplete: false,
    isNext: false,
  ),
  Category(
    id: 11,
    name: 'Pronunciation & Clarity',
    sub: 'Clear enunciation and correct pronunciation of words.',
    trainingType: "voice",
    completed: 0,
    isComplete: false,
    isNext: false,
  ),
  Category(
    id: 12,
    name: 'Filler Word Usage',
    sub: 'Minimizing unnecessary hesitation words like "uhm" and "ah".',
    trainingType: "voice",
    completed: 0,
    isComplete: false,
    isNext: false,
  ),
  Category(
    id: 13,
    name: 'Tone & Inflection',
    sub: 'Using warm, professional pitch and vocal inflection.',
    trainingType: "voice",
    completed: 0,
    isComplete: false,
    isNext: false,
  ),
];

enum AssessmentType { quiz, typing, voice, finalTest }

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String? explanation;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanation,
  });
}

class Assessment {
  final String id;
  final AssessmentType type;
  final String title;
  final String instructions;
  final List<QuizQuestion>? quizQuestions;
  final String? typingTargetText;
  final String? voiceTargetScript;
  bool isCompleted;
  bool isPassed;

  Assessment({
    required this.id,
    required this.type,
    required this.title,
    required this.instructions,
    this.quizQuestions,
    this.typingTargetText,
    this.voiceTargetScript,
    this.isCompleted = false,
    this.isPassed = false,
  });
}

class Lesson {
  final String id;
  final String title;
  final int order;
  final String content;
  final List<Assessment> assessments;
  bool isUnlocked;
  bool isCompleted;
  int? lastScorePercent;

  Lesson({
    required this.id,
    required this.title,
    required this.order,
    required this.content,
    required this.assessments,
    this.isUnlocked = false,
    this.isCompleted = false,
    this.lastScorePercent,
  });

  bool get allAssessmentsCompleted {
    if (assessments.isEmpty) return true;
    return assessments.every((a) => a.isCompleted);
  }
}

class TrainingCategoryData {
  final String name;
  final List<Lesson> lessons;
  final List<Assessment> finalAssessments;
  bool isCompleted;

  TrainingCategoryData({
    required this.name,
    required this.lessons,
    this.finalAssessments = const [],
    this.isCompleted = false,
  });

  bool get allLessonsCompleted {
    return lessons.every((l) => l.isCompleted);
  }

  bool get isFinalTestUnlocked {
    return allLessonsCompleted;
  }

  bool get isFinalTestPassed {
    return isCompleted;
  }

  void refreshLessonLocks() {
    if (lessons.isEmpty) return;
    lessons[0].isUnlocked = true;
    for (int i = 1; i < lessons.length; i++) {
      lessons[i].isUnlocked = lessons[i - 1].isCompleted;
    }
  }

  void markLessonCompleted(String lessonId) {
    for (final lesson in lessons) {
      if (lesson.id == lessonId) {
        lesson.isCompleted = true;
        break;
      }
    }
    refreshLessonLocks();
    for (final lesson in lessons) {
      if (lesson.isUnlocked && !lesson.isCompleted) {
        TrainingNotificationCenter.notifyLessonUnlocked(
          categoryName: name,
          lessonTitle: lesson.title,
        );
        break;
      }
    }
    if (allLessonsCompleted && hasFinalAssessment && !isCompleted) {
      TrainingNotificationCenter.notifyCategoryFinalUnlocked(name);
    }
    TrainingProgressRepository.instance.save();
    MiniTrainingProgress._bumpGuidance();
  }

  void syncUnlockState() {
    for (var i = 0; i < lessons.length; i++) {
      if (i == 0) {
        lessons[i].isUnlocked = true;
      } else {
        lessons[i].isUnlocked =
            lessons[i].isUnlocked || lessons[i - 1].isCompleted;
      }
    }
  }

  void markFinalTestPassed() {
    for (final a in finalAssessments) {
      a.isCompleted = true;
      a.isPassed = true;
    }
    isCompleted = true;
    TrainingProgressRepository.instance.save();
  }

  bool get hasFinalAssessment => finalAssessments.isNotEmpty;
}

enum ScenarioStage { locked, chat, voice, completed }

class MiniTrainingProgress {
  static bool isProfileComplete = false;

  static bool preferMinimalGuidance = false;
  static bool seenHomePath = false;
  static bool seenMiniIntro = false;
  static bool seenScenarioIntro = false;
  static bool seenSimulationIntro = false;
  static bool hasCompletedSimulationSession = false;
  static bool hasReviewedProgressDashboard = false;

  static bool get isGuideActive => !preferMinimalGuidance;

  static final ValueNotifier<int> guidanceRevision = ValueNotifier<int>(0);

  static void _bumpGuidance() {
    final notifier = guidanceRevision;
    final next = notifier.value + 1;
    final phase = WidgetsBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      notifier.value = next;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.value = next;
      });
    }
  }

  static Map<String, dynamic> onboardingFlagsToJson() {
    return {
      'prefer_minimal_guidance': preferMinimalGuidance,
      'seen_home_path': seenHomePath,
      'seen_mini_intro': seenMiniIntro,
      'seen_scenario_intro': seenScenarioIntro,
      'seen_simulation_intro': seenSimulationIntro,
      'has_completed_simulation_session': hasCompletedSimulationSession,
      'has_reviewed_progress_dashboard': hasReviewedProgressDashboard,
    };
  }

  static void applyOnboardingFlags(Map<String, dynamic>? raw) {
    if (raw == null) return;
    preferMinimalGuidance = raw['prefer_minimal_guidance'] == true;
    seenHomePath = raw['seen_home_path'] == true;
    seenMiniIntro = raw['seen_mini_intro'] == true;
    seenScenarioIntro = raw['seen_scenario_intro'] == true;
    seenSimulationIntro = raw['seen_simulation_intro'] == true;
    hasCompletedSimulationSession =
        raw['has_completed_simulation_session'] == true;
    hasReviewedProgressDashboard =
        raw['has_reviewed_progress_dashboard'] == true;
  }

  static void setPreferMinimalGuidance(bool value) {
    preferMinimalGuidance = value;
    if (value) {
      seenHomePath = true;
      seenMiniIntro = true;
      seenScenarioIntro = true;
      seenSimulationIntro = true;
    }
    TrainingProgressRepository.instance.save();
    _bumpGuidance();
  }

  static void clearSeenIntros() {
    seenHomePath = false;
    seenMiniIntro = false;
    seenScenarioIntro = false;
    seenSimulationIntro = false;
    TrainingProgressRepository.instance.save();
    _bumpGuidance();
  }

  static void markSeen(String key) {
    switch (key) {
      case 'home_path':
        seenHomePath = true;
      case 'mini_intro':
        seenMiniIntro = true;
      case 'scenario_intro':
        seenScenarioIntro = true;
      case 'simulation_intro':
        seenSimulationIntro = true;
      default:
        return;
    }
    TrainingProgressRepository.instance.save();
    _bumpGuidance();
  }

  static void resetAll() {
    isProfileComplete = false;
    grandFinalUnlocked = false;
    grandFinalPassed = false;
    scenarioStage = ScenarioStage.locked;
    completedChatScenarios.clear();
    completedVoiceScenarios.clear();
    preferMinimalGuidance = false;
    seenHomePath = false;
    seenMiniIntro = false;
    seenScenarioIntro = false;
    seenSimulationIntro = false;
    hasCompletedSimulationSession = false;
    hasReviewedProgressDashboard = false;
    for (final cat in trainingData.values) {
      cat.isCompleted = false;
      for (final lesson in cat.lessons) {
        lesson.isCompleted = false;
        lesson.isUnlocked = false;
      }
      if (cat.lessons.isNotEmpty) {
        cat.lessons.first.isUnlocked = true;
      }
      for (final a in cat.finalAssessments) {
        a.isCompleted = false;
        a.isPassed = false;
      }
    }
  }

  static void completeProfile() {
    isProfileComplete = true;
    TrainingProgressRepository.instance.save();
    _bumpGuidance();
  }

  static void debugSkipProfile() {
    isProfileComplete = true;
    _bumpGuidance();
  }

  static bool get allCategoriesCompleted {
    return trainingData.values.every((c) => c.isCompleted);
  }

  static bool grandFinalUnlocked = false;
  static bool grandFinalPassed = false;

  static ScenarioStage scenarioStage = ScenarioStage.locked;

  static void refreshGlobalProgress() {
    final wasGrandUnlocked = grandFinalUnlocked;
    if (allCategoriesCompleted) {
      grandFinalUnlocked = true;
      if (!wasGrandUnlocked) {
        TrainingNotificationCenter.notifyGrandFinalUnlocked();
      }
    }
    TrainingProgressRepository.instance.save();
    if (grandFinalPassed) {
      if (scenarioStage == ScenarioStage.locked) {
        scenarioStage = ScenarioStage.chat;
        TrainingNotificationCenter.notifyScenarioPracticeUnlocked();
      }
    }
    _bumpGuidance();
  }

  static void markGrandFinalPassed() {
    grandFinalPassed = true;
    scenarioStage = ScenarioStage.chat;
    TrainingNotificationCenter.notifyScenarioPracticeUnlocked();
    TrainingProgressRepository.instance.save();
    _bumpGuidance();
  }

  static final Set<String> completedChatScenarios = {};

  static void markChatScenarioCompleted(String scenarioId) {
    completedChatScenarios.add(scenarioId);
    TrainingNotificationCenter.notifyScenarioCompleted(scenarioId);
    TrainingProgressRepository.instance.save();
    const requiredIds = [
      'chat_1',
      'chat_2',
      'chat_3',
      'chat_4',
      'chat_5',
      'chat_6',
      'chat_7',
      'chat_8',
      'chat_9',
    ];
    final allDone = requiredIds.every(completedChatScenarios.contains);
    if (allDone) {
      markChatScenariosCleared();
    } else {
      _bumpGuidance();
    }
  }

  static void markChatScenariosCleared() {
    if (scenarioStage == ScenarioStage.chat) {
      scenarioStage = ScenarioStage.voice;
      TrainingNotificationCenter.notifyVoiceScenariosUnlocked();
      TrainingNotificationCenter.notifySimulationTrainingUnlocked();
      TrainingNotificationCenter.notifyChatSessionUnlocked();
      TrainingProgressRepository.instance.save();
    }
    _bumpGuidance();
  }

  static void _debugCompleteKnowledgePath() {
    for (final c in trainingData.values) {
      for (final lesson in c.lessons) {
        lesson.isCompleted = true;
        lesson.isUnlocked = true;
      }
      c.markFinalTestPassed();
    }
    for (final c in categories) {
      c.isComplete = true;
      c.isNext = false;
      c.completed = c.id;
    }
    if (categories.isNotEmpty) {
      categories.last.isNext = false;
    }
    grandFinalUnlocked = true;
    grandFinalPassed = true;
  }

  static void debugUnlockScenarioPractice() {
    _debugCompleteKnowledgePath();
    scenarioStage = ScenarioStage.chat;
    hasCompletedSimulationSession = false;
    hasReviewedProgressDashboard = false;
    TrainingNotificationCenter.notifyDebugUnlock();
    TrainingProgressRepository.instance.save();
    _bumpGuidance();
  }

  static final Set<String> completedVoiceScenarios = {};

  static void markVoiceScenarioCompleted(String scenarioId) {
    completedVoiceScenarios.add(scenarioId);
    TrainingProgressRepository.instance.save();
    TrainingNotificationCenter.notifyScenarioCompleted(scenarioId);
    const requiredIds = [
      'voice_1',
      'voice_2',
      'voice_3',
      'voice_4',
      'voice_5',
      'voice_6',
      'voice_7',
      'voice_8',
      'voice_9',
    ];
    final allDone = requiredIds.every(completedVoiceScenarios.contains);
    if (allDone) {
      markVoiceScenariosCleared();
    } else {
      _bumpGuidance();
    }
  }

  static void markVoiceScenariosCleared() {
    if (scenarioStage == ScenarioStage.voice) {
      scenarioStage = ScenarioStage.completed;
      TrainingNotificationCenter.notifyVoiceSessionUnlocked();
      TrainingNotificationCenter.push(
        title: 'Scenario Practice complete',
        body:
            'Chat and Voice scenario practice are done. Simulation Training modes stay available from the hub.',
        locationHint: 'Simulation Training',
        type: TrainingNotificationType.success,
      );
      TrainingProgressRepository.instance.save();
    }
    _bumpGuidance();
  }

  static bool get isChatScenariosUnlocked =>
      scenarioStage == ScenarioStage.chat ||
      scenarioStage == ScenarioStage.voice ||
      scenarioStage == ScenarioStage.completed;

  static bool get isVoiceScenariosUnlocked =>
      scenarioStage == ScenarioStage.voice ||
      scenarioStage == ScenarioStage.completed;

  static bool get chatScenariosCleared {
    const requiredIds = [
      'chat_1',
      'chat_2',
      'chat_3',
      'chat_4',
      'chat_5',
      'chat_6',
      'chat_7',
      'chat_8',
      'chat_9',
    ];
    return requiredIds.every(completedChatScenarios.contains);
  }

  static bool get voiceScenariosCleared {
    const requiredIds = [
      'voice_1',
      'voice_2',
      'voice_3',
      'voice_4',
      'voice_5',
      'voice_6',
      'voice_7',
      'voice_8',
      'voice_9',
    ];
    return requiredIds.every(completedVoiceScenarios.contains);
  }

  static bool get isSimulationTrainingUnlocked => chatScenariosCleared;

  static bool get isProgressDashboardUnlocked =>
      isSimulationTrainingUnlocked && hasCompletedSimulationSession;

  static void markSimulationSessionCompleted() {
    if (hasCompletedSimulationSession) {
      _bumpGuidance();
      return;
    }
    hasCompletedSimulationSession = true;
    TrainingProgressRepository.instance.save();
    _bumpGuidance();
  }

  static void markProgressDashboardReviewed() {
    if (hasReviewedProgressDashboard) return;
    hasReviewedProgressDashboard = true;
    TrainingProgressRepository.instance.save();
    _bumpGuidance();
  }

  static bool get isChatSessionUnlocked => chatScenariosCleared;

  static bool get isVoiceSessionUnlocked => voiceScenariosCleared;

  static void debugUnlockChatSession() {
    final wasCleared = chatScenariosCleared;
    _debugCompleteKnowledgePath();
    const ids = [
      'chat_1',
      'chat_2',
      'chat_3',
      'chat_4',
      'chat_5',
      'chat_6',
      'chat_7',
      'chat_8',
      'chat_9',
    ];
    completedChatScenarios.addAll(ids);
    if (scenarioStage == ScenarioStage.locked ||
        scenarioStage == ScenarioStage.chat) {
      scenarioStage = ScenarioStage.voice;
    }
    hasCompletedSimulationSession = false;
    hasReviewedProgressDashboard = false;
    if (!wasCleared) {
      TrainingNotificationCenter.notifySimulationTrainingUnlocked();
      TrainingNotificationCenter.notifyChatSessionUnlocked();
    }
    TrainingProgressRepository.instance.save();
    _bumpGuidance();
  }

  static void debugUnlockVoiceSession() {
    final wasCleared = voiceScenariosCleared;
    debugUnlockChatSession();
    const ids = [
      'voice_1',
      'voice_2',
      'voice_3',
      'voice_4',
      'voice_5',
      'voice_6',
      'voice_7',
      'voice_8',
      'voice_9',
    ];
    completedVoiceScenarios.addAll(ids);
    scenarioStage = ScenarioStage.completed;
    hasCompletedSimulationSession = false;
    hasReviewedProgressDashboard = false;
    if (!wasCleared) {
      TrainingNotificationCenter.notifyVoiceSessionUnlocked();
    }
    TrainingProgressRepository.instance.save();
    _bumpGuidance();
  }

  static void debugUnlockSimulationTraining() {
    debugUnlockChatSession();
  }

  static void debugUnlockAllMiniTraining() {
    debugUnlockVoiceSession();
    TrainingNotificationCenter.notifyDebugUnlock();
    TrainingProgressRepository.instance.save();
    _bumpGuidance();
  }
}

int totalLessons(String categoryName) {
  return trainingData[categoryName]?.lessons.length ?? 0;
}
