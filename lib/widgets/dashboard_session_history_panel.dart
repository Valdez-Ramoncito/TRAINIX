import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainixprogram/models/simulation_history.dart';

//simple table of every completed session
//second tab of the Analytics Dashboard
class SessionHistoryPanel extends StatelessWidget {
  const SessionHistoryPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SimulationHistoryProvider>(
      builder: (context, history, _) {
        if (history.sessions.isEmpty) {
          return const Center(
            child: Text(
              'No sessions yet.\nComplete a simulation to see your history.',
              textAlign: TextAlign.center,
            ),
          );
        }

        //one row per completed session, not per individual evaluation
        final reversed = history.sessions.reversed.toList();

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTableHeader(),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: reversed.length,
                  itemBuilder: (_, index) => _buildSessionRow(
                    reversed.length - index,
                    reversed[index],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  //build a table header UI
  Widget _buildTableHeader() {
    return const Row(
      children: [
        SizedBox(
          width: 36,
          child: Text('#', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          flex: 3,
          child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          flex: 2,
          child: Text('Sector', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          flex: 1,
          child: Text('Score', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          flex: 3,
          child: Text(
            'Top Strength',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  //build a session row UI
  Widget _buildSessionRow(int sessionNumber, PlayedSession session) {
    final dt = session.completedAt;
    final date =
        '${dt.month}/${dt.day}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text('$sessionNumber', style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            flex: 3,
            child: Text(date, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: Chip(
              label: Text(session.sector, style: const TextStyle(fontSize: 11)),
              padding: EdgeInsets.zero,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              session.overallScore.toStringAsFixed(1),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              session.topStrength,
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
