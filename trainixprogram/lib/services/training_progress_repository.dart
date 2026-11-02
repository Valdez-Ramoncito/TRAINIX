import 'package:flutter/foundation.dart';
import 'package:trainixprogram/models/training/training_categories.dart';
import 'package:trainixprogram/services/supabase_service.dart';

class TrainingProgressRepository {
  TrainingProgressRepository._();
  static final TrainingProgressRepository instance =
      TrainingProgressRepository._();

  static const _table = 'training_progress';
  static String? lastError;

  Future<bool> save() async {
    lastError = null;
    if (!SupabaseService.isReady) return false;
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return false;

    try {
      await SupabaseService.client.from(_table).upsert({
        'user_id': user.id,
        'is_profile_complete': MiniTrainingProgress.isProfileComplete,
        'grand_final_unlocked': MiniTrainingProgress.grandFinalUnlocked,
        'grand_final_passed': MiniTrainingProgress.grandFinalPassed,
        'scenario_stage': MiniTrainingProgress.scenarioStage.name,
        'completed_chat_scenarios': MiniTrainingProgress.completedChatScenarios
            .toList(),
        'completed_voice_scenarios': MiniTrainingProgress
            .completedVoiceScenarios
            .toList(),
        'completed_hybrid_scenarios': MiniTrainingProgress
            .completedHybridScenarios
            .toList(),
        'category_completion': {
          for (final e in trainingData.entries)
            e.key: {
              'isCompleted': e.value.isCompleted,
              'lessons': {for (final l in e.value.lessons) l.id: l.isCompleted},
            },
        },
        'onboarding_flags': MiniTrainingProgress.onboardingFlagsToJson(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      debugPrint('training_progress save ok');
      return true;
    } catch (e) {
      lastError = e.toString();
      debugPrint('training_progress save failed: $lastError');
      return false;
    }
  }

  Future<bool> load() async {
    lastError = null;
    if (!SupabaseService.isReady) return false;
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return false;

    try {
      MiniTrainingProgress.resetAll();

      final row = await SupabaseService.client
          .from(_table)
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      if (row == null) {
        debugPrint('training_progress load: no row, defaults for user');
        return true;
      }

      MiniTrainingProgress.isProfileComplete =
          row['is_profile_complete'] as bool? ?? false;
      MiniTrainingProgress.grandFinalUnlocked =
          row['grand_final_unlocked'] as bool? ?? false;
      MiniTrainingProgress.grandFinalPassed =
          row['grand_final_passed'] as bool? ?? false;

      final stage = row['scenario_stage'] as String? ?? 'locked';
      for (final s in ScenarioStage.values) {
        if (s.name == stage) {
          MiniTrainingProgress.scenarioStage = s;
          break;
        }
      }
      if (MiniTrainingProgress.scenarioStage == ScenarioStage.hybrid) {
        MiniTrainingProgress.scenarioStage = ScenarioStage.completed;
      }

      void loadSet(dynamic raw, Set<String> target) {
        target.clear();
        if (raw is List) {
          for (final e in raw) {
            target.add('$e');
          }
        }
      }

      loadSet(
        row['completed_chat_scenarios'],
        MiniTrainingProgress.completedChatScenarios,
      );
      loadSet(
        row['completed_voice_scenarios'],
        MiniTrainingProgress.completedVoiceScenarios,
      );
      loadSet(
        row['completed_hybrid_scenarios'],
        MiniTrainingProgress.completedHybridScenarios,
      );

      final catRaw = row['category_completion'];
      if (catRaw is Map) {
        for (final entry in catRaw.entries) {
          final cat = trainingData[entry.key];
          if (cat == null) continue;
          final data = entry.value;
          if (data is! Map) continue;
          final lessonsMap = data['lessons'];
          if (lessonsMap is Map) {
            for (final lesson in cat.lessons) {
              final done = lessonsMap[lesson.id];
              if (done == true) {
                lesson.isCompleted = true;
                lesson.isUnlocked = true;
              }
            }
          }
          if (data['isCompleted'] == true) {
            cat.isCompleted = true;
          }
          cat.syncUnlockState();
        }
      }

      for (final item in categories) {
        final cat = trainingData[item.name];
        if (cat != null && cat.isCompleted) {
          item.isComplete = true;
          item.isNext = false;
        }
      }
      final firstIncomplete = categories.indexWhere((c) => !c.isComplete);
      if (firstIncomplete >= 0) {
        for (var i = 0; i < categories.length; i++) {
          categories[i].isNext = i == firstIncomplete;
        }
      }

      final flagsRaw = row['onboarding_flags'];
      if (flagsRaw is Map) {
        MiniTrainingProgress.applyOnboardingFlags(
          flagsRaw.map((k, v) => MapEntry('$k', v)),
        );
      }

      debugPrint('training_progress load ok');
      return true;
    } catch (e) {
      lastError = e.toString();
      debugPrint('training_progress load failed: $lastError');
      return false;
    }
  }
}
