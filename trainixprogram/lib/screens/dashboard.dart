import 'package:flutter/material.dart';
import 'package:trainixprogram/widgets/dashboard_performance_stats_panel.dart';
import 'package:trainixprogram/widgets/dashboard_session_history_panel.dart';
import 'package:trainixprogram/widgets/dashboard_sector_match_panel.dart';

//this gives the agent a long term view of their performance across
//many sessions
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Analytics Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              //performance stats - shown where there is at least
              //one evaluation
              Tab(text: 'Performance Stats'),

              //session history - a simple table of every evaluation
              //newest first
              Tab(text: 'Session History'),

              //sector match - shows the recommended sector
              Tab(text: 'Sector Match'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            PerformanceStatsPanel(),
            SessionHistoryPanel(),
            SectorMatchPanel(),
          ],
        ),
      ),
    );
  }
}
