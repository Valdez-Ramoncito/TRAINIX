import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/components/animation_effect/hover_button.dart';
import 'package:trainixprogram/components/size.dart';

class ProfileAccount extends StatelessWidget {
  const ProfileAccount({
    super.key,
    required this.tabController,
    required this.indexPage,
  });

  final TabController tabController;
  final int indexPage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          SizedBox(
            height: 310,
            width: double.infinity,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 200,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      image: const DecorationImage(
                        image: AssetImage("assets/images/cover_photo.png"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const Positioned(top: 15, right: 20, child: LogoutButton()),
                Positioned(
                  top: 100,
                  left: 20,
                  right: 20,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: const Color.fromARGB(255, 19, 19, 19),
                                width: 2,
                              ),
                              image: const DecorationImage(
                                image: AssetImage(
                                  'assets/images/defaultProfile.png',
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 15,
                            right: 15,
                            child: ProfileCameraButton(
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),
                      const Gap(20),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Paradox Asure",
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontSize: context.responsiveFont(10),
                                  ),
                            ),
                            Text(
                              "Joined Since: Aug 15, 2026",
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontSize: context.responsiveFont(3),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Gap(20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TabBar(
                    controller: tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: const Color(0xFF222329),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF4A4B54),
                        width: 1,
                      ),
                    ),
                    splashBorderRadius: BorderRadius.circular(10),
                    splashFactory: NoSplash.splashFactory,
                    overlayColor: WidgetStateProperty.all(
                      Colors.white.withValues(alpha: 0.05),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFFA5A6AD),
                    labelStyle: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontSize: 12, fontWeight: FontWeight.w500),
                    unselectedLabelStyle: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(fontSize: 12, fontWeight: FontWeight.w400),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 18),
                    tabs: const [
                      Tab(height: 38, text: "Recommendation"),
                      Tab(height: 38, text: "Strengths"),
                    ],
                  ),
                  const Gap(8),
                  const Divider(
                    height: 1,
                    thickness: 0.8,
                    color: Color.fromARGB(255, 60, 62, 68),
                  ),
                  const Gap(15),
                  Expanded(
                    child: IndexedStack(
                      index: indexPage,
                      children: const [
                        Center(
                          child: Text(
                            "Recommendation Content",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        Center(
                          child: Text(
                            "Strengths Content",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
