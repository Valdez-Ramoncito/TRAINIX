import 'package:flutter/foundation.dart';
import 'package:trainixprogram/models/training/training_categories.dart';
import 'package:trainixprogram/services/profile_directory_service.dart';
import 'package:trainixprogram/services/supabase_service.dart';

class TraineeProgressSnapshot {
  final String userId;
  final String displayName;
  final String email;
  final bool profileComplete;
  final bool grandFinalPassed;
  final bool grandFinalUnlocked;
  final String scenarioStage;
  final int completedCategories;
  final int totalCategories;
  final int completedChatScenarios;
  final int completedVoiceScenarios;
  final Map<String, bool> categoryDone;
  final DateTime? updatedAt;

  const TraineeProgressSnapshot({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.profileComplete,
    required this.grandFinalPassed,
    required this.grandFinalUnlocked,
    required this.scenarioStage,
    required this.completedCategories,
    required this.totalCategories,
    required this.completedChatScenarios,
    required this.completedVoiceScenarios,
    required this.categoryDone,
    this.updatedAt,
  });

  double get knowledgeFraction =>
      totalCategories == 0 ? 0 : completedCategories / totalCategories;

  String get stageLabel {
    switch (scenarioStage) {
      case 'chat':
        return 'Scenario Practice · Non-Voice';
      case 'voice':
        return 'Scenario Practice · Voice';
      case 'completed':
        return 'Scenario Practice complete';
      case 'locked':
      default:
        return grandFinalPassed
            ? 'Grand Final passed'
            : (grandFinalUnlocked
                ? 'Grand Final unlocked'
                : 'Knowledge Path');
    }
  }
}

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
      if (stage == 'hybrid') {
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

  /// Trainer / admin view of trainee Mini Training progress.
  /// Requires RLS that lets trainers read `training_progress` rows.
  Future<List<TraineeProgressSnapshot>> loadTraineeSnapshots({
    bool force = false,
  }) async {
    lastError = null;
    final trainees =
        await ProfileDirectoryService.instance.loadTrainees(force: force);
    if (trainees.isEmpty) return const [];

    final byId = {for (final t in trainees) t.id: t};
    final totalCats = categories.length;
    final catNames = categories.map((c) => c.name).toList();

    if (!SupabaseService.isReady) {
      return trainees
          .map(
            (t) => TraineeProgressSnapshot(
              userId: t.id,
              displayName: t.displayName,
              email: t.email,
              profileComplete: false,
              grandFinalPassed: false,
              grandFinalUnlocked: false,
              scenarioStage: 'locked',
              completedCategories: 0,
              totalCategories: totalCats,
              completedChatScenarios: 0,
              completedVoiceScenarios: 0,
              categoryDone: {for (final n in catNames) n: false},
            ),
          )
          .toList();
    }

    try {
      final rows = await SupabaseService.client.from(_table).select();
      final rowByUser = <String, Map<String, dynamic>>{};
      for (final raw in rows as List) {
        final m = Map<String, dynamic>.from(raw as Map);
        final uid = m['user_id'] as String? ?? '';
        if (uid.isNotEmpty) rowByUser[uid] = m;
      }

      final out = <TraineeProgressSnapshot>[];
      for (final t in trainees) {
        final row = rowByUser[t.id];
        final catDone = <String, bool>{for (final n in catNames) n: false};
        var completedCats = 0;
        final grandPassed = row?['grand_final_passed'] == true;
        if (row != null) {
          final catRaw = row['category_completion'];
          if (catRaw is Map && catRaw.isNotEmpty) {
            final normalized = <String, dynamic>{};
            for (final entry in catRaw.entries) {
              normalized['${entry.key}'.trim().toLowerCase()] = entry.value;
            }
            for (final name in catNames) {
              final data = normalized[name.trim().toLowerCase()] ?? catRaw[name];
              var done = false;
              if (data is Map) {
                if (data['isCompleted'] == true) {
                  done = true;
                } else {
                  final lessonsMap = data['lessons'];
                  if (lessonsMap is Map && lessonsMap.isNotEmpty) {
                    done = lessonsMap.values.every((v) => v == true);
                  }
                }
              } else if (data == true) {
                done = true;
              }
              catDone[name] = done;
              if (done) completedCats++;
            }
          }
          // Seed and older saves often leave category_completion empty even
          // after Grand Final. Treat grand_final_passed as all categories done.
          if (completedCats == 0 && grandPassed) {
            for (final name in catNames) {
              catDone[name] = true;
            }
            completedCats = catNames.length;
          }
        }

        int listLen(dynamic raw) {
          if (raw is List) return raw.length;
          if (raw is Map) return raw.length;
          if (raw is String && raw.trim().isNotEmpty) {
            try {
              final decoded = raw.trim().startsWith('[')
                  ? (raw)
                  : raw;
              if (decoded.startsWith('[')) {
                // Cheap count of quoted ids without full json decode.
                final matches = RegExp(r'"[^"]+"').allMatches(decoded);
                return matches.length;
              }
            } catch (_) {}
          }
          return 0;
        }

        DateTime? updated;
        final updatedRaw = row?['updated_at'] as String?;
        if (updatedRaw != null) {
          updated = DateTime.tryParse(updatedRaw)?.toLocal();
        }

        out.add(
          TraineeProgressSnapshot(
            userId: t.id,
            displayName: t.displayName.isEmpty ? t.email : t.displayName,
            email: t.email,
            profileComplete: row?['is_profile_complete'] == true,
            grandFinalPassed: row?['grand_final_passed'] == true,
            grandFinalUnlocked: row?['grand_final_unlocked'] == true,
            scenarioStage: row?['scenario_stage'] as String? ?? 'locked',
            completedCategories: completedCats,
            totalCategories: totalCats,
            completedChatScenarios: listLen(row?['completed_chat_scenarios']),
            completedVoiceScenarios: listLen(row?['completed_voice_scenarios']),
            categoryDone: catDone,
            updatedAt: updated,
          ),
        );
      }

      out.sort((a, b) {
        final byCats =
            b.completedCategories.compareTo(a.completedCategories);
        if (byCats != 0) return byCats;
        return a.displayName
            .toLowerCase()
            .compareTo(b.displayName.toLowerCase());
      });
      return out;
    } catch (e) {
      lastError = e.toString();
      debugPrint('training_progress loadTraineeSnapshots failed: $lastError');
      return byId.values
          .map(
            (t) => TraineeProgressSnapshot(
              userId: t.id,
              displayName: t.displayName,
              email: t.email,
              profileComplete: false,
              grandFinalPassed: false,
              grandFinalUnlocked: false,
              scenarioStage: 'locked',
              completedCategories: 0,
              totalCategories: totalCats,
              completedChatScenarios: 0,
              completedVoiceScenarios: 0,
              categoryDone: {for (final n in catNames) n: false},
            ),
          )
          .toList();
    }
  }
}
