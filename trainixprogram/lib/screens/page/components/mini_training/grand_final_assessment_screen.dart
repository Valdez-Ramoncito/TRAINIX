import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/models/trainix_debug.dart';
import 'package:trainixprogram/models/training/training_categories.dart';
import 'package:trainixprogram/screens/page/components/mini_training/combined_assessment_screen.dart';

class GrandFinalAssessmentScreen extends StatefulWidget {
  const GrandFinalAssessmentScreen({super.key});

  @override
  State<GrandFinalAssessmentScreen> createState() =>
      _GrandFinalAssessmentScreenState();
}

class _GrandFinalAssessmentScreenState
    extends State<GrandFinalAssessmentScreen> {
  void _debugSkip() {
    MiniTrainingProgress.markGrandFinalPassed();
    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("DEBUG: Grand Final skipped")));
    Navigator.of(context).pop(true);
  }

  Future<void> _startFinal() async {
    if (grandFinalAssessments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No grand final content yet.")),
      );
      return;
    }

    final dummyLesson = Lesson(
      id: "grand_final",
      title: "Grand Final Assessment",
      order: 0,
      content: "",
      assessments: grandFinalAssessments,
    );

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CombinedAssessmentScreen(
          categoryName: "Grand Final",
          lesson: dummyLesson,
          items: grandFinalAssessments,
          isCategoryFinal: false,
        ),
      ),
    );

    if (result == true) {
      MiniTrainingProgress.markGrandFinalPassed();
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final alreadyPassed = MiniTrainingProgress.grandFinalPassed;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Grand Final Assessment"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Grand Final Assessment",
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Gap(12),
            const Text(
              "This assessment covers key skills from all categories. Score 75% or higher to pass. Retake is optional after you pass.",
              style: TextStyle(fontSize: 15, height: 1.4),
            ),
            const Gap(8),
            const Text(
              "It includes quiz, typing, and voice items.",
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
                onPressed: alreadyPassed ? null : _startFinal,
                child: Text(
                  alreadyPassed
                      ? "Grand Final Already Passed"
                      : "Start Grand Final Assessment",
                ),
              ),
            ),
            if (TrainixDebug.unlocked) ...[
              const Gap(12),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton(
                  onPressed: alreadyPassed ? null : _debugSkip,
                  child: const Text("DEBUG: Skip Grand Final"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
