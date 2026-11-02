import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/models/trainix_debug.dart';
import 'package:trainixprogram/models/training/training_categories.dart';
import 'package:trainixprogram/screens/page/components/mini_training/combined_assessment_screen.dart';
import 'package:trainixprogram/models/training/notifications/training_notification.dart';

class CategoryFinalAssessmentScreen extends StatefulWidget {
  final String categoryName;

  const CategoryFinalAssessmentScreen({super.key, required this.categoryName});

  @override
  State<CategoryFinalAssessmentScreen> createState() =>
      _CategoryFinalAssessmentScreenState();
}

class _CategoryFinalAssessmentScreenState
    extends State<CategoryFinalAssessmentScreen> {
  void _debugSkipFinal() {
    final categoryData = trainingData[widget.categoryName];
    if (categoryData == null) return;

    categoryData.markFinalTestPassed();

    final categoryListItem = categories.firstWhere(
      (c) => c.name == widget.categoryName,
      orElse: () => categories.first,
    );
    categoryListItem.isComplete = true;
    categoryListItem.isNext = false;

    final currentIndex = categories.indexWhere(
      (c) => c.name == widget.categoryName,
    );
    if (currentIndex != -1 && currentIndex < categories.length - 1) {
      categories[currentIndex + 1].isNext = true;
      TrainingNotificationCenter.notifyNextCategory(
        categories[currentIndex + 1].name,
      );
    }

    MiniTrainingProgress.refreshGlobalProgress();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("DEBUG: ${widget.categoryName} final assessment skipped"),
      ),
    );

    Navigator.of(context).pop(true);
  }

  Future<void> _startFinal() async {
    final categoryData = trainingData[widget.categoryName];
    if (categoryData == null) return;

    final finals = categoryData.finalAssessments;
    if (finals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No final assessment content yet.")),
      );
      return;
    }

    final dummyLesson = Lesson(
      id: "${widget.categoryName}_final",
      title: "Final Assessment",
      order: 0,
      content: "",
      assessments: finals,
    );

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CombinedAssessmentScreen(
          categoryName: widget.categoryName,
          lesson: dummyLesson,
          items: finals,
          isCategoryFinal: true,
        ),
      ),
    );

    if (result is Map || result == true) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryData = trainingData[widget.categoryName];
    final alreadyPassed = categoryData?.isCompleted ?? false;
    final hasFinal = categoryData?.hasFinalAssessment ?? false;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("${widget.categoryName} - Final Assessment"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Category Final Assessment",
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Gap(12),
            Text(
              "This assessment checks everything you learned in ${widget.categoryName}. Score 75% or higher to pass. Retake is optional after you pass.",
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
            const Gap(8),
            const Text(
              "It may include quiz, typing, and voice items depending on the category.",
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.white70,
              ),
            ),
            const Gap(40),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: alreadyPassed ? Colors.grey : Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: alreadyPassed || !hasFinal ? null : _startFinal,
                child: Text(
                  alreadyPassed
                      ? "Assessment Already Passed"
                      : hasFinal
                      ? "Start Final Assessment"
                      : "Final Assessment Not Ready",
                ),
              ),
            ),
            if (TrainixDebug.unlocked) ...[
              const Gap(12),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton(
                  onPressed: alreadyPassed ? null : _debugSkipFinal,
                  child: const Text("DEBUG: Skip Final Assessment"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
