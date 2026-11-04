import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/components/button/carousel_button.dart';
import 'package:trainixprogram/components/class/animations.dart';
import 'package:trainixprogram/components/decoration/box_decoration.dart';
import 'package:trainixprogram/components/size.dart';
import 'package:trainixprogram/screens/page/mini_training.dart';
import 'package:trainixprogram/screens/page/profile.dart';
import 'package:trainixprogram/screens/page/training.dart';
import 'package:trainixprogram/screens/page/trainer_session.dart';
import 'package:trainixprogram/models/training/training_categories.dart';
import 'package:trainixprogram/models/training/trainee_next_step.dart';
import 'package:trainixprogram/screens/dashboard.dart';

class Carousel extends StatefulWidget {
  final int? highlightCardId;

  const Carousel({super.key, this.highlightCardId});

  @override
  State<Carousel> createState() => _CarouselState();
}

class _CarouselState extends State<Carousel> {
  late PageController pageController;

  static int? lastFocusedRealIndex;

  static const int _startRealIndex = 3;

  int get _itemCount => animation.length;

  int _indexForCardId(int? cardId) {
    if (cardId == null) return lastFocusedRealIndex ?? _startRealIndex;
    final idx = animation.indexWhere((a) => a.id == cardId);
    if (idx >= 0) return idx;
    return lastFocusedRealIndex ?? _startRealIndex;
  }

  late final int _startPage;

  void _goRelative(int delta) {
    if (!pageController.hasClients || _itemCount == 0) return;
    final current = pageController.page?.round() ?? _startPage;
    final next = (current + delta).clamp(0, _itemCount - 1);
    pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  void initState() {
    super.initState();
    final startReal = _indexForCardId(widget.highlightCardId);
    _startPage = startReal.clamp(0, _itemCount > 0 ? _itemCount - 1 : 0);
    pageController = PageController(
      initialPage: _startPage,
      viewportFraction: 0.36,
    );
    pageController.addListener(() {
      if (!pageController.hasClients) return;
      final page = pageController.page;
      if (page == null) return;
      lastFocusedRealIndex = page.round().clamp(0, _itemCount - 1);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !pageController.hasClients) return;
      pageController.jumpToPage(_startPage);
      setState(() {});
    });
  }

  @override
  void dispose() {
    if (pageController.hasClients) {
      final page = pageController.page;
      if (page != null && _itemCount > 0) {
        lastFocusedRealIndex = page.round().clamp(0, _itemCount - 1);
      }
    }
    pageController.dispose();
    super.dispose();
  }

  void _openCard(BuildContext context, lottieAnimation data) {
    if (!TraineeNextStep.canOpenCarouselCard(data.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TraineeNextStep.lockReasonForCarouselCard(data.id)),
        ),
      );
      return;
    }
    switch (data.id) {
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Profile()),
        );
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TrainerSession()),
        );
      case 3:
        if (!MiniTrainingProgress.isProfileComplete) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Complete your profile first to unlock training modes.',
              ),
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const Profile(requireCompletion: true),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const TrainingSession()),
          );
        }
      case 4:
        if (!MiniTrainingProgress.isProfileComplete) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Complete your profile first to unlock training modes.',
              ),
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const Profile(requireCompletion: true),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MiniTraining()),
          );
        }
      case 5:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: MiniTrainingProgress.guidanceRevision,
      builder: (context, _, __) {
        return Stack(
          children: [
            SizedBox(
              height: 400,
              child: PageView.builder(
                controller: pageController,
                padEnds: true,
                itemCount: _itemCount,
                physics: const PageScrollPhysics(),
                itemBuilder: (_, index) {
                  final data = animation[index];
                  return AnimatedBuilder(
                    animation: pageController,
                    builder: (_, child) {
                      double page;
                      if (pageController.hasClients &&
                          pageController.position.haveDimensions) {
                        page = pageController.page ?? _startPage.toDouble();
                      } else {
                        page = _startPage.toDouble();
                      }
                      double pageOffset = (page - index).abs();
                      double value = (1 - (pageOffset * 0.25)).clamp(0.82, 1.0);
                      bool isFocused = pageOffset < 0.5;
                      final isHighlighted =
                          widget.highlightCardId != null &&
                          data.id == widget.highlightCardId;
                      final isGuideLocked =
                          !TraineeNextStep.canOpenCarouselCard(data.id);
                      return Center(
                        child: SizedBox(
                          height: 420 * value,
                          width: 320 * value,
                          child: ContainerDecoration(
                            onTap: () => _openCard(context, data),
                            isFocused: isFocused,
                            isHighlighted: isHighlighted,
                            isGuideLocked: isGuideLocked,
                            data: data,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 25,
                                vertical: 40,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: RepaintBoundary(
                                      child: Lottie.asset(
                                        data.name,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  const Gap(20),
                                  Text(
                                    data.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontSize: isFocused
                                              ? context.responsiveFont(6)
                                              : context.responsiveFont(4),
                                        ),
                                    textAlign: TextAlign.start,
                                  ),
                                  const Gap(10),
                                  Text(
                                    data.subtitle,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          fontSize: isFocused
                                              ? context.responsiveFont(3)
                                              : context.responsiveFont(2.5),
                                        ),
                                    textAlign: TextAlign.start,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Positioned(
              left: 0,
              top: 170,
              child: CarouselButton(
                onTap: () => _goRelative(-1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
            ),
            Positioned(
              right: 0,
              top: 170,
              child: CarouselButton(
                onTap: () => _goRelative(1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ),
          ],
        );
      },
    );
  }
}
