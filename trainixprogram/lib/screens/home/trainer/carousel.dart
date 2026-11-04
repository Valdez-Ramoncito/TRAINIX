import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/components/button/carousel_button.dart';
import 'package:trainixprogram/components/class/animations.dart';
import 'package:trainixprogram/components/decoration/box_decoration.dart';
import 'package:trainixprogram/components/size.dart';
import 'package:trainixprogram/screens/page/profile.dart';
import 'package:trainixprogram/screens/trainer_page/trainee_session.dart';
import 'package:trainixprogram/screens/trainer_page/log_monitoring_screen.dart';

class Carousel extends StatefulWidget {
  const Carousel({super.key});

  @override
  State<Carousel> createState() => _CarouselState();
}

class _CarouselState extends State<Carousel> {
  late PageController pageController;

  static int? lastFocusedRealIndex;

  static const int _startRealIndex = 1;

  int get _itemCount => animationTrainer.length;

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
    final start = (lastFocusedRealIndex ?? _startRealIndex).clamp(
      0,
      _itemCount > 0 ? _itemCount - 1 : 0,
    );
    _startPage = start;
    pageController = PageController(
      initialPage: _startPage,
      viewportFraction: 0.34,
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

  @override
  Widget build(BuildContext context) {
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
              final data = animationTrainer[index];
              return AnimatedBuilder(
                animation: pageController,
                builder: (_, child) {
                  double page =
                      pageController.hasClients &&
                          pageController.position.haveDimensions
                      ? pageController.page ?? _startPage.toDouble()
                      : _startPage.toDouble();
                  double pageOffset = (page - index).abs();
                  double value = (1 - (pageOffset * 0.22)).clamp(0.78, 1.0);
                  bool isFocused = pageOffset < 0.55;
                  return Center(
                    child: SizedBox(
                      height: 420 * value,
                      width: 320 * value,
                      child: ContainerDecoration(
                        onTap: () {
                          switch (data.id) {
                            case 1:
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const Profile(),
                                ),
                              );
                            case 2:
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TraineeSession(),
                                ),
                              );
                            case 3:
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LogMonitoringScreen(),
                                ),
                              );
                          }
                        },
                        isFocused: isFocused,
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
                              const Gap(12),
                              Text(
                                data.title,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: context.responsiveFont(4.5),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Gap(6),
                              Text(
                                data.subtitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: context.responsiveFont(3.2),
                                  color: Colors.white70,
                                ),
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
  }
}
