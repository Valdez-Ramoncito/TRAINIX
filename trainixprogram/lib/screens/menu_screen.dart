import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'TRAINIX',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          //goes to account profile
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            icon: const Icon(Icons.account_circle),
          ),
          //goes to a test screen
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DevTestScreen()),
            ),
            icon: const Icon(Icons.bug_report),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  //for every buildMenuCard, it leads to a new screen
                  Expanded(
                    child: _buildMenuCard(
                      context,
                      'Start Simulation',
                      Icons.phone_in_talk,
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
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    //when clicked, go to dashboard
                    child: _buildMenuCard(
                      context,
                      'Analytics',
                      Icons.bar_chart,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DashboardScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    //when clicked, go to settings
                    child: _buildMenuCard(
                      context,
                      'Settings',
                      Icons.settings,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      ),
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
    );
  }

  //this builds a menu card
  Widget _buildMenuCard(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Card(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48),
              const SizedBox(height: 12),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
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

    //if its empty, return this placeholder
    if (sessions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 16.0),
        child: Row(
          children: [
            Icon(Icons.history),
            SizedBox(width: 8),
            Text('No sessions yet — start your first simulation above.'),
          ],
        ),
      );
    }

    //get the last completed session from the list
    final last = sessions.last;

    //set the date
    final dt = last.completedAt;
    final time =
        '${dt.month}/${dt.day}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    //return the widget with the given data — overallScore is already
    //averaged across every evaluation in that session
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        children: [
          const Icon(Icons.history),
          const SizedBox(width: 8),
          Text(
            'Last session: ${last.sector} · Score ${last.overallScore.toStringAsFixed(1)} · $time',
          ),
        ],
      ),
    );
  }
}
