import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainixprogram/models/session_score.dart';
import 'package:trainixprogram/providers/simulation_provider.dart';
import 'package:trainixprogram/screens/mock_call_screen.dart';

//this shows a complete performance summary for the session
//that had just ended
class SessionReportScreen extends StatelessWidget {
  final List<SessionEvaluation> evaluations;

  //voice speaking pace
  final double? averageWpm;

  //total fillers in voice call
  final int? fillerWordCount;

  //chat typing pace
  final double? averageTypingWpm;

  //how balanced was the trainee between two channels
  final double? multitaskingScore;

  //constructor
  const SessionReportScreen({
    super.key,
    this.evaluations = const [],
    this.averageWpm,
    this.fillerWordCount,
    this.averageTypingWpm,
    this.multitaskingScore,
  });

  //get the average of all evaluations in that session
  double get _averageOverall {
    if (evaluations.isEmpty) return 0;
    return evaluations.map((e) => e.overallScore).reduce((a, b) => a + b) /
        evaluations.length;
  }

  //the average score for a category
  double _averageCategory(double Function(SessionEvaluation) selector) {
    if (evaluations.isEmpty) return 0;
    return evaluations.map(selector).reduce((a, b) => a + b) /
        evaluations.length;
  }

  //aggregates the strengths and improvements
  List<String> _aggregate(List<String> Function(SessionEvaluation) selector) {
    final seen = <String>{};
    final result = <String>[];
    for (final e in evaluations) {
      for (final s in selector(e)) {
        if (s.isNotEmpty && seen.add(s)) result.add(s);
      }
    }
    //return up to 5 unique items
    return result.take(5).toList();
  }

  //build the UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Session Report',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //build the UI for overall score
            _buildOverallScore(),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //UI for the score breakdown
                Expanded(child: _buildScoreBreakdown()),
                const SizedBox(width: 16),

                //UI for the typing stats
                Expanded(child: _buildTypingStats()),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //UI for displaying strengths
                Expanded(child: _buildStrengths()),
                const SizedBox(width: 16),

                //UI for displaying areas for improvement
                Expanded(child: _buildAreasForImprovement()),
              ],
            ),
            const SizedBox(height: 24),
            //UI for AI Feedback
            _buildAiFeedback(),
            const SizedBox(height: 24),

            //UI for action buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  //build Overall Score UI
  Widget _buildOverallScore() {
    return Center(
      child: Text(
        evaluations.isEmpty
            ? 'Overall Score: —'
            : 'Overall Score: ${_averageOverall.toStringAsFixed(1)} / 10 '
                  '(avg of ${evaluations.length} interaction${evaluations.length == 1 ? '' : 's'})',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
    );
  }

  //build Score Breakdown UI
  Widget _buildScoreBreakdown() {
    if (evaluations.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Score Breakdown',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('No evaluation recorded for this session.'),
        ],
      );
    }
    //get the average of the categories
    final categories = <(String, double)>[
      ('Opening Spiel', _averageCategory((e) => e.openingSpielScore)),
      ('Positive Scripting', _averageCategory((e) => e.positiveScriptingScore)),
      ('Empathy', _averageCategory((e) => e.empathyScore)),
      ('Active Listening', _averageCategory((e) => e.activeListeningScore)),
      (
        'Problem Identification',
        _averageCategory((e) => e.problemIdentificationScore),
      ),
      ('Solution Delivery', _averageCategory((e) => e.solutionDeliveryScore)),
      (
        'Communication Clarity',
        _averageCategory((e) => e.communicationClarityScore),
      ),
      ('Tone', _averageCategory((e) => e.toneScore)),
      ('Sector Knowledge', _averageCategory((e) => e.sectorKnowledgeScore)),
      ('Closing Spiel', _averageCategory((e) => e.closingSpielScore)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Score Breakdown',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        //then map those categories out
        ...categories.map(
          (c) => Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text('${c.$1}: ${c.$2.toStringAsFixed(1)} / 10'),
          ),
        ),
      ],
    );
  }

  //build Typing Stats UI
  Widget _buildTypingStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Interaction Stats',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        //average words per minute in voice call
        Text(
          averageWpm != null
              ? 'Speaking Pace: ${averageWpm!.toStringAsFixed(0)} WPM'
              : 'Speaking Pace: not recorded (no voice turns this session)',
        ),

        //average words per minute in chat channel
        Text(
          averageTypingWpm != null
              ? 'Typing Pace: ${averageTypingWpm!.toStringAsFixed(0)} WPM'
              : 'Typing Pace: not recorded (no chat turns this session)',
        ),

        //Typing accuracy is not yet implemented
        const Text('Typing Accuracy: not yet tracked'),

        //filler word count for voice
        Text(
          fillerWordCount != null
              ? 'Filler Words (voice): $fillerWordCount'
              : 'Filler Words: not recorded',
        ),
        const Text('Tone Rating: see Tone score above'),

        //multitasking score
        Text(
          multitaskingScore != null
              ? 'Multitasking Efficiency: ${multitaskingScore!.toStringAsFixed(0)}%'
              : 'Multitasking Efficiency: not recorded (no turns this session)',
        ),
      ],
    );
  }

  //build Strengths UI
  Widget _buildStrengths() {
    //get the strengths
    final strengths = _aggregate((e) => e.strengths);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Strengths', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (strengths.isEmpty)
          const Text('—')
        else
          //then map them out
          ...strengths.map((s) => Text('• $s')),
      ],
    );
  }

  //build Areas for improvement
  Widget _buildAreasForImprovement() {
    //get areas from improvement
    final improvements = _aggregate((e) => e.areasForImprovement);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Areas for Improvement',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (improvements.isEmpty)
          const Text('—')
        else
          //then map those out
          ...improvements.map((i) => Text('• $i')),
      ],
    );
  }

  //build AI feedback UI
  Widget _buildAiFeedback() {
    //get the latest feedback
    final feedback = evaluations.isNotEmpty ? evaluations.last.feedback : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI Feedback',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          feedback != null && feedback.isNotEmpty
              ? feedback
              : 'No feedback available for this session.',
        ),

        //if there is more than one evaluation
        if (evaluations.length > 1)
          const Padding(
            padding: EdgeInsets.only(top: 4.0),
            child: Text(
              '(Feedback shown is from the most recent interaction this session.)',
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ),
      ],
    );
  }

  //build Action Button UI
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        //back to main menu screen
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Back to Menu'),
        ),
        const SizedBox(width: 12),

        //start another session
        ElevatedButton(
          onPressed: () {
            final sector = Provider.of<SimulationProvider>(
              context,
              listen: false,
            ).pickNextSector();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => MockCallScreen(sector: sector)),
            );
          },
          child: const Text('Start Another Session'),
        ),
      ],
    );
  }
}
