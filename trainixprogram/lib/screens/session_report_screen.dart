import 'package:flutter/material.dart';
import 'package:trainixprogram/models/session_score.dart';
import 'package:trainixprogram/screens/report_ui/report_ui.dart';

//this shows a complete performance summary for the session
//that had just ended, using ReportUI for rendering
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

  @override
  Widget build(BuildContext context) {
    return ReportUI(
      evaluations: evaluations,
      averageWpm: averageWpm,
      fillerWordCount: fillerWordCount,
      averageTypingWpm: averageTypingWpm,
      multitaskingScore: multitaskingScore,
    );
  }
}
