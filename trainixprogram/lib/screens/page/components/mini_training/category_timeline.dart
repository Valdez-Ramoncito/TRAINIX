import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/components/decoration/box_decoration.dart';
import 'package:trainixprogram/models/training/training_categories.dart';
import 'package:trainixprogram/components/decoration/check.dart';
import 'package:trainixprogram/components/decoration/circle_mini.dart';
import 'package:trainixprogram/components/size.dart';
import 'package:trainixprogram/screens/page/components/mini_training/grand_final_assessment_screen.dart';
import 'package:trainixprogram/screens/page/components/mini_training/selected_category_train_screen.dart';
import 'package:trainixprogram/widgets/screen_help_button.dart';

class CategoryTimeline extends StatefulWidget {
  const CategoryTimeline({super.key});

  @override
  State<CategoryTimeline> createState() => _CategoryTimelineState();
}

class _CategoryTimelineState extends State<CategoryTimeline> {
  void _syncFromTrainingData() {
    for (int i = 0; i < categories.length; i++) {
      final name = categories[i].name;
      final data = trainingData[name];
      if (data == null) continue;

      categories[i].isComplete = data.isCompleted;

      final completedLessons = data.lessons.where((l) => l.isCompleted).length;
      categories[i].completed = completedLessons;
    }

    bool foundNext = false;
    for (int i = 0; i < categories.length; i++) {
      if (categories[i].isComplete) {
        categories[i].isNext = false;
        continue;
      }
      if (!foundNext) {
        categories[i].isNext = true;
        foundNext = true;
      } else {
        categories[i].isNext = false;
      }
    }

    if (!foundNext && categories.isNotEmpty) {
      categories.last.isNext = false;
    }

    MiniTrainingProgress.refreshGlobalProgress();
  }

  @override
  void initState() {
    super.initState();
    _syncFromTrainingData();
  }

  Widget _buildTimelineRow({
    required bool isComplete,
    required bool isNext,
    required bool isLast,
    required Widget child,
  }) {
    final lineColor = isComplete
        ? const Color.fromARGB(255, 21, 44, 76)
        : isNext
        ? const Color.fromARGB(255, 12, 67, 30)
        : const Color.fromARGB(251, 30, 30, 30);

    return IntrinsicHeight(
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (!isLast)
                  Positioned(
                    top: 0,
                    bottom: 0,
                    child: Container(width: 2, color: lineColor),
                  ),
                if (isLast)
                  Positioned(
                    top: 0,
                    bottom: null,
                    height: 50,
                    child: Container(width: 2, color: lineColor),
                  ),
                Positioned(child: node(isComplete, isNext)),
              ],
            ),
          ),
          Gap(30),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 15, top: 2),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allDone = MiniTrainingProgress.allCategoriesCompleted;
    final grandUnlocked = MiniTrainingProgress.grandFinalUnlocked || allDone;
    final grandPassed = MiniTrainingProgress.grandFinalPassed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Knowledge Path',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
            const ScreenHelpButton(
              content: ScreenHelpCatalog.knowledgePath,
              showPathOverview: false,
            ),
          ],
        ),
        const Gap(8),
        const Text(
          'Finish lessons and category finals in order, then the Grand Final.',
          style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.4),
        ),
        const Gap(16),
        Expanded(
          child: ListView.builder(
            itemCount: categories.length + 1,
            itemBuilder: (_, index) {
              if (index < categories.length) {
                var data = categories[index];
                final trainingCategory = trainingData[data.name];
                final total = trainingCategory?.lessons.length ?? 0;
                final done =
                    trainingCategory?.lessons
                        .where((l) => l.isCompleted)
                        .length ??
                    0;

                return _buildTimelineRow(
                  isComplete: data.isComplete,
                  isNext: data.isNext,
                  isLast: false,
                  child: GestureDetector(
                    onTap: () async {
                      if (data.isNext || data.isComplete) {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CategoryTrain(
                              categoryChosen: data.name,
                              categoryDescription: data.sub,
                            ),
                          ),
                        );
                        setState(() {
                          _syncFromTrainingData();
                        });
                      }
                    },
                    child: Container(
                      height: 100,
                      decoration: boxDecoration(data.isComplete, data.isNext),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  data.name,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        fontSize: context.responsiveFont(5.5),
                                      ),
                                ),
                                Gap(10),
                                Text(
                                  data.sub,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        fontSize: context.responsiveFont(3.5),
                                        color: const Color.fromARGB(
                                          255,
                                          210,
                                          210,
                                          210,
                                        ),
                                      ),
                                ),
                              ],
                            ),
                            if (data.isComplete)
                              CheckProgress()
                            else if (!data.isNext)
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2A2A2A),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFF4A4A4A),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.lock_rounded,
                                          size: 14,
                                          color: Color(0xFF9CA3AF),
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Locked',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF9CA3AF),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Gap(6),
                                  Text(
                                    'Finish previous category first',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white38,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    total == 0
                                        ? "0%"
                                        : "${((done / total) * 100).round()}%",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Gap(8),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(total, (
                                      lessonIndex,
                                    ) {
                                      final lesson = trainingCategory
                                          ?.lessons[lessonIndex];
                                      Color dotColor;
                                      if (lesson == null) {
                                        dotColor = const Color(0xFF555555);
                                      } else if (lesson.isCompleted) {
                                        dotColor = const Color(0xFF3B82F6);
                                      } else if (lesson.isUnlocked) {
                                        dotColor = const Color(0xFF22C55E);
                                      } else {
                                        dotColor = const Color(0xFF555555);
                                      }
                                      return Container(
                                        width: 10,
                                        height: 10,
                                        margin: const EdgeInsets.only(left: 4),
                                        decoration: BoxDecoration(
                                          color: dotColor,
                                          shape: BoxShape.circle,
                                        ),
                                      );
                                    }),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              return _buildTimelineRow(
                isComplete: grandPassed,
                isNext: grandUnlocked && !grandPassed,
                isLast: true,
                child: GestureDetector(
                  onTap: () async {
                    if (!grandUnlocked) return;
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const GrandFinalAssessmentScreen(),
                      ),
                    );
                    setState(() {
                      _syncFromTrainingData();
                    });
                  },
                  child: Container(
                    height: 100,
                    decoration: boxDecoration(
                      grandPassed,
                      grandUnlocked && !grandPassed,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Grand Final Assessment",
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontSize: context.responsiveFont(5.5),
                                    ),
                              ),
                              Gap(10),
                              Text(
                                grandPassed
                                    ? "Completed"
                                    : grandUnlocked
                                    ? "Covers everything learned across all categories"
                                    : "Locked - finish all categories first",
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontSize: context.responsiveFont(3.5),
                                      color: const Color.fromARGB(
                                        255,
                                        210,
                                        210,
                                        210,
                                      ),
                                    ),
                              ),
                            ],
                          ),
                          if (grandPassed)
                            CheckProgress()
                          else if (!grandUnlocked)
                            const Icon(
                              Icons.lock,
                              size: 18,
                              color: Colors.white54,
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
      ],
    );
  }
}
