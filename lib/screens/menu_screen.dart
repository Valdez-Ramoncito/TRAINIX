import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:trainixprogram/components/animation_effect/hover_button_homecreen.dart';
import 'package:trainixprogram/components/background.dart';
import 'package:trainixprogram/components/size.dart';
import 'package:trainixprogram/models/simulation_history.dart';
import 'package:trainixprogram/providers/simulation_provider.dart';
import 'package:trainixprogram/screens/dashboard.dart';
import 'package:trainixprogram/screens/dev_test_screen.dart';
import 'package:trainixprogram/screens/mock_call_screen.dart';
import 'package:trainixprogram/screens/profile_screen.dart';
import 'package:trainixprogram/screens/settings_screen.dart';

//the main screen
class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        "Hello, Paradox!",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: context.responsiveFont(7),
                        ),
                      ),
                      const Gap(5),
                      Image.asset('assets/images/hand.png', height: 25),
                    ],
                  ),
                  Row(
                    children: [
                      //file located in components animation effect hover button
                      HoverIconButton(
                        icon: Icons.logout_rounded,
                        tooltip: 'Log out',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      //goes to a test screen
                      HoverIconButton(
                        icon: Icons.bug_report_rounded,
                        tooltip: 'Developer Test Screen',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DevTestScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(
                width: double.infinity,
                height: 500,
                child: Row(
                  children: [
                    //for every buildMenuCard, it leads to a new screen
                    Expanded(
                      //when clicked, go to settings
                      child: _buildMenuCard(
                        context,
                        'Account Profile',
                        'Customize your app preferences and account.',
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        ),
                        'assets/animations/background/card.png',
                        'assets/animations/account.json',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMenuCard(
                        context,
                        'Training Simulation',
                        'Practice live call scenarios and sharpen your skills.',
                        () {
                          //when you start a simulation, pick a sector
                          //pass it, then go to that screen
                          final sector = Provider.of<SimulationProvider>(
                            context,
                            listen: false,
                          ).pickNextSector();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MockCallScreen(sector: sector),
                            ),
                          );
                        },
                        'assets/animations/background/card1.png',
                        'assets/animations/training.json',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      //when clicked, go to dashboard
                      child: _buildMenuCard(
                        context,
                        'Progress Dashboard',
                        'Track your scores, trends, and session history.',
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DashboardScreen(),
                          ),
                        ),
                        'assets/animations/background/card2.png',
                        'assets/animations/progress.json',
                      ),
                    ),
                  ],
                ),
              ),
              //build the last session done by the agent
              _buildLastSessionBar(context),
            ],
          ),
        ),
      ),
    );
  }

  //this builds a menu card
  Widget _buildMenuCard(
    BuildContext context,
    String label,
    String subLabel,
    VoidCallback onTap,
    String background,
    String lottie,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: .5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              Image.asset(background, fit: BoxFit.cover),
              // Dark overlay for readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.25),
                      Colors.black.withOpacity(0.60),
                    ],
                  ),
                ),
              ),
              // Card content — Lottie fills top, text pinned bottom-left
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Lottie takes all available space above the text block
                  Expanded(
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.center,
                        heightFactor: 0.90,
                        child: Lottie.asset(lottie, repeat: true, width: 300),
                      ),
                    ),
                  ),
                  // Text block — fixed height, left-aligned, same bottom position on every card
                  Padding(
                    padding: const EdgeInsets.fromLTRB(30, 0, 30, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontSize: 20, height: 1.2),
                        ),
                        const Gap(10),
                        Text(
                          subLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontSize: 10,
                                color: const Color.fromARGB(255, 220, 219, 219),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  //builds the last session done
  Widget _buildLastSessionBar(BuildContext context) {
    //get the list of completed sessions (not individual evaluations —
    //a session with several resolved customers is still just 1 entry
    //here, same fix as Dashboard's Session History/Score Trend)
    final sessions = Provider.of<SimulationHistoryProvider>(context).sessions;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    //if its empty, return this placeholder
    if (sessions.isEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(Icons.history_outlined, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            'No sessions yet — start your first simulation above.',
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      );
    }

    //get the last completed session from the list
    final last = sessions.last;

    //set the date
    final dt = last.completedAt;
    final time =
        '${dt.month}/${dt.day}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    // small info chip
    Widget chip(IconData icon, String value) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: colorScheme.onSurface.withOpacity(0.5)),
        const SizedBox(width: 4),
        Text(value, style: textTheme.bodySmall),
      ],
    );

    //return the widget with the given data — overallScore is already
    //averaged across every evaluation in that session
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Icon(
          Icons.history_outlined,
          size: 16,
          color: colorScheme.onSurface.withOpacity(0.5),
        ),
        const SizedBox(width: 8),
        Text(
          'Last session',
          style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 12),
        // divider
        Container(
          width: 1,
          height: 14,
          color: colorScheme.outline.withOpacity(0.3),
        ),
        const SizedBox(width: 12),
        chip(Icons.work_outline_rounded, last.sector),
        const SizedBox(width: 12),
        chip(Icons.star_outline_rounded, last.overallScore.toStringAsFixed(1)),
        const SizedBox(width: 12),
        chip(Icons.access_time_rounded, time),
      ],
    );
  }
}
