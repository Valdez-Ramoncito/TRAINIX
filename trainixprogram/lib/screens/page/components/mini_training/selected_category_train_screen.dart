import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';
import 'package:trainixprogram/components/layout/content_bounds.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/models/trainix_debug.dart';
import 'package:trainixprogram/models/training/training_categories.dart';
import 'package:trainixprogram/models/training/notifications/training_notification.dart';
import 'package:trainixprogram/screens/page/components/mini_training/category_final_assessment_screen.dart';
import 'package:trainixprogram/screens/page/components/mini_training/selected_training_module.dart';

class CategoryTrain extends StatefulWidget {
  final String categoryChosen;
  final String categoryDescription;

  const CategoryTrain({
    super.key,
    required this.categoryChosen,
    required this.categoryDescription,
  });

  @override
  State<CategoryTrain> createState() => _CategoryTrainState();
}

class _CategoryTrainState extends State<CategoryTrain> {
  void _refresh() {
    setState(() {
      trainingData[widget.categoryChosen]?.refreshLessonLocks();
    });
  }

  Widget _statusChip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  String? _nextCategoryName() {
    final currentIndex = categories.indexWhere(
      (c) => c.name == widget.categoryChosen,
    );
    if (currentIndex == -1 || currentIndex >= categories.length - 1) {
      return null;
    }
    return categories[currentIndex + 1].name;
  }

  Future<void> _goToNextCategory() async {
    final nextName = _nextCategoryName();
    if (nextName == null) {
      Navigator.of(context).maybePop();
      return;
    }
    final nextCat = categories.where((c) => c.name == nextName).toList();
    final description = nextCat.isNotEmpty ? nextCat.first.sub : '';
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CategoryTrain(
          categoryChosen: nextName,
          categoryDescription: description,
        ),
      ),
    );
  }

  Future<void> _openFinalAssessment() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            CategoryFinalAssessmentScreen(categoryName: widget.categoryChosen),
      ),
    );
    _refresh();
    if (!mounted) return;
    if (result is Map && result['nextCategory'] is String) {
      final nextName = result['nextCategory'] as String;
      final nextCat = categories.where((c) => c.name == nextName).toList();
      final description = nextCat.isNotEmpty ? nextCat.first.sub : '';
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CategoryTrain(
            categoryChosen: nextName,
            categoryDescription: description,
          ),
        ),
      );
    }
  }

  void _debugFinishAllLessons() {
    final categoryData = trainingData[widget.categoryChosen];
    if (categoryData == null) return;

    for (final lesson in categoryData.lessons) {
      lesson.isCompleted = true;
      lesson.isUnlocked = true;
      for (final a in lesson.assessments) {
        a.isCompleted = true;
        a.isPassed = true;
      }
    }
    categoryData.refreshLessonLocks();
    _refresh();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("DEBUG: All lesson assessments finished")),
    );
  }

  void _debugClearCategory() {
    final categoryData = trainingData[widget.categoryChosen];
    if (categoryData == null) return;

    for (final lesson in categoryData.lessons) {
      lesson.isCompleted = true;
      lesson.isUnlocked = true;
      for (final a in lesson.assessments) {
        a.isCompleted = true;
        a.isPassed = true;
      }
    }
    categoryData.markFinalTestPassed();
    TrainingNotificationCenter.notifyCategoryCleared(widget.categoryChosen);

    final categoryListItem = categories.firstWhere(
      (c) => c.name == widget.categoryChosen,
      orElse: () => categories.first,
    );
    categoryListItem.isComplete = true;
    categoryListItem.isNext = false;

    final currentIndex = categories.indexWhere(
      (c) => c.name == widget.categoryChosen,
    );
    if (currentIndex != -1 && currentIndex < categories.length - 1) {
      categories[currentIndex + 1].isNext = true;
    }

    MiniTrainingProgress.refreshGlobalProgress();
    _refresh();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("DEBUG: ${widget.categoryChosen} fully cleared")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryData = trainingData[widget.categoryChosen];
    final lessons = categoryData?.lessons ?? [];
    final completedCount = lessons.where((l) => l.isCompleted).length;
    final finalUnlocked = categoryData?.isFinalTestUnlocked ?? false;
    final categoryCompleted = categoryData?.isCompleted ?? false;

    final progress = lessons.isEmpty ? 0.0 : completedCount / lessons.length;
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.scaffold(context),
        foregroundColor: AppColors.textPrimary(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Mini Training · ${widget.categoryChosen}',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Center(
              child: Text(
                '$completedCount / ${lessons.length}',
                style: TextStyle(
                  color: AppColors.primaryText(),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.categoryDescription.isEmpty
                      ? 'Complete each lesson in order, then take the category final.'
                      : widget.categoryDescription,
                  style: TextStyle(
                    color: AppColors.textMuted(context),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const Gap(12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.card(context),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryText(),
                    ),
                  ),
                ),
                const Gap(12),
                if (TrainixDebug.unlocked)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: _debugFinishAllLessons,
                        child: const Text('DEBUG: Finish all lessons'),
                      ),
                      OutlinedButton(
                        onPressed:
                            categoryCompleted ? null : _debugClearCategory,
                        child: const Text('DEBUG: Clear whole category'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Expanded(
            child: ContentBounds(
              maxWidth: 1100,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: lessons.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    crossAxisCount: 4,
                    mainAxisExtent: 150,
                  ),
                  itemBuilder: (context, index) {
                    var data = lessons[index];
                    final isLocked = !data.isUnlocked;
                    final isDone = data.isCompleted;

                    final Color bg;
                    final Color border;
                    final Color accent;
                    if (isDone) {
                      bg = AppColors.completeTint(context);
                      border = AppColors.secondaryText();
                      accent = AppColors.secondaryText();
                    } else if (isLocked) {
                      bg = AppColors.surface(context);
                      border = AppColors.borderIdle(context);
                      accent = AppColors.textMuted(context);
                    } else {
                      bg = AppColors.nextTint(context);
                      border = AppColors.primaryText();
                      accent = AppColors.successText();
                    }

                    return MouseRegion(
                      cursor: isLocked
                          ? SystemMouseCursors.basic
                          : SystemMouseCursors.click,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: isLocked
                              ? null
                              : () async {
                                  Lesson? open = data;
                                  while (open != null && mounted) {
                                    final result =
                                        await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => CategoryModule(
                                          lesson: open!,
                                          categoryName: widget.categoryChosen,
                                        ),
                                      ),
                                    );
                                    _refresh();
                                    if (result is Lesson) {
                                      open = result;
                                    } else {
                                      open = null;
                                    }
                                  }
                                  if (mounted) _refresh();
                                },
                          child: Container(
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: border.withValues(alpha: 0.85),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: border.withValues(alpha: 0.12),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: accent.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        isDone
                                            ? Icons.check_rounded
                                            : isLocked
                                                ? Icons.lock_outline_rounded
                                                : Icons.play_lesson_outlined,
                                        size: 16,
                                        color: accent,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (isDone)
                                      Icon(
                                        Icons.check_circle_rounded,
                                        size: 20,
                                        color: accent,
                                      )
                                    else if (isLocked)
                                      Icon(
                                        Icons.lock_rounded,
                                        size: 18,
                                        color: accent,
                                      )
                                    else
                                      Icon(
                                        Icons.play_circle_fill_rounded,
                                        size: 22,
                                        color: accent,
                                      ),
                                  ],
                                ),
                                const Gap(12),
                                Text(
                                  data.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isLocked
                                        ? AppColors.textMuted(context)
                                        : AppColors.textPrimary(context),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                                ),
                                const Gap(8),
                                if (isLocked)
                                  _statusChip(
                                    'Locked',
                                    AppColors.border(context),
                                    AppColors.textMuted(context),
                                  )
                                else if (isDone)
                                  _statusChip(
                                    data.lastScorePercent != null
                                        ? 'Completed · ${data.lastScorePercent}%'
                                        : 'Completed',
                                    AppColors.completeTint(context),
                                    AppColors.secondaryText(),
                                  )
                                else
                                  _statusChip(
                                    'Ready',
                                    AppColors.nextTint(context),
                                    AppColors.successText(),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          if (finalUnlocked)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Align(
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: categoryCompleted
                            ? AppColors.completeTint(context)
                            : AppColors.primaryText(),
                        foregroundColor: categoryCompleted
                            ? AppColors.successText()
                            : AppColors.onPrimary(context),
                        disabledBackgroundColor:
                            AppColors.completeTint(context),
                        disabledForegroundColor: AppColors.successText(),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: categoryCompleted
                              ? BorderSide(
                                  color: AppColors.successText()
                                      .withValues(alpha: 0.35),
                                )
                              : BorderSide.none,
                        ),
                      ),
                      onPressed:
                          categoryCompleted ? null : _openFinalAssessment,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (categoryCompleted) ...[
                            Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: AppColors.successText(),
                            ),
                            const Gap(8),
                          ],
                          Flexible(
                            child: Text(
                              categoryCompleted
                                  ? 'Category Final Assessment · Completed'
                                  : 'Take Category Final Assessment',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (categoryCompleted) ...[
            const Gap(10),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Align(
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryText(),
                        foregroundColor: AppColors.onPrimary(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _goToNextCategory,
                      child: Text(
                        _nextCategoryName() != null
                            ? 'Continue to ${_nextCategoryName()}'
                            : 'Back to categories',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
