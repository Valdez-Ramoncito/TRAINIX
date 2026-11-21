import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';
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
  IconData _categoryIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('open')) return Icons.waving_hand_outlined;
    if (n.contains('script')) return Icons.menu_book_outlined;
    if (n.contains('empath')) return Icons.favorite_border_rounded;
    if (n.contains('listen')) return Icons.hearing_rounded;
    if (n.contains('question')) return Icons.help_outline_rounded;
    if (n.contains('hold')) return Icons.pause_circle_outline_rounded;
    if (n.contains('escalat')) return Icons.trending_up_rounded;
    if (n.contains('close') || n.contains('end'))
      return Icons.check_circle_outline_rounded;
    return Icons.school_outlined;
  }

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
        ? AppColors.completeTint(context)
        : isNext
            ? AppColors.nextTint(context)
            : AppColors.card(context);

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
                Positioned(child: node(isComplete, isNext, context)),
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
        Text(
          'Finish lessons and category finals in order, then the Grand Final.',
          style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary(context),
              height: 1.4),
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
                final done = trainingCategory?.lessons
                        .where((l) => l.isCompleted)
                        .length ??
                    0;

                return _buildTimelineRow(
                  isComplete: data.isComplete,
                  isNext: data.isNext,
                  isLast: false,
                  child: MouseRegion(
                    cursor: (data.isNext || data.isComplete)
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.basic,
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
                        decoration: themedBoxDecoration(
                          context,
                          isComplete: data.isComplete,
                          isNext: data.isNext,
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
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _categoryIcon(data.name),
                                        size: 18,
                                        color: data.isComplete
                                            ? AppColors.primaryText()
                                            : AppColors.secondaryText(),
                                      ),
                                      const Gap(8),
                                      Flexible(
                                        child: Text(
                                          data.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontSize:
                                                    context.responsiveFont(5.5),
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Gap(10),
                                  Text(
                                    data.sub,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontSize: context.responsiveFont(3.5),
                                          color:
                                              AppColors.textSecondary(context),
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
                                        color: AppColors.border(context),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color:
                                              AppColors.borderStrong(context),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.lock_rounded,
                                            size: 14,
                                            color: AppColors.textMuted(context),
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'Locked',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  AppColors.textMuted(context),
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
                                        color: AppColors.textMuted(context),
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
                                          dotColor =
                                              AppColors.borderStrong(context);
                                        } else if (lesson.isCompleted) {
                                          dotColor = AppColors.secondaryText();
                                        } else if (lesson.isUnlocked) {
                                          dotColor = AppColors.primaryText();
                                        } else {
                                          dotColor =
                                              AppColors.borderStrong(context);
                                        }
                                        return Container(
                                          width: 10,
                                          height: 10,
                                          margin:
                                              const EdgeInsets.only(left: 4),
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
                  ),
                );
              }

              return _buildTimelineRow(
                isComplete: grandPassed,
                isNext: grandUnlocked && !grandPassed,
                isLast: true,
                child: MouseRegion(
                  cursor: grandUnlocked
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.basic,
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
                      decoration: themedBoxDecoration(
                        context,
                        isComplete: grandPassed,
                        isNext: grandUnlocked && !grandPassed,
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontSize: context.responsiveFont(3.5),
                                        color: AppColors.textSecondary(context),
                                      ),
                                ),
                              ],
                            ),
                            if (grandPassed)
                              CheckProgress()
                            else if (!grandUnlocked)
                              Icon(
                                Icons.lock,
                                size: 18,
                                color: AppColors.textMuted(context),
                              ),
                          ],
                        ),
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
