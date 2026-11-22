import 'package:flutter/material.dart';
import 'package:trainixprogram/models/scoring_transparency.dart';
import 'package:trainixprogram/models/session_score.dart';
import 'package:trainixprogram/screens/report_ui/report_ui.dart';

class SessionReportScreen extends StatelessWidget {
  final List<SessionEvaluation> evaluations;
  final double? averageWpm;
  final int? fillerWordCount;
  final double? averageTypingWpm;
  final double? multitaskingScore;
  final AttentivenessBreakdown? attentivenessBreakdown;
  final bool guidedMode;

  const SessionReportScreen({
    super.key,
    this.evaluations = const [],
    this.averageWpm,
    this.fillerWordCount,
    this.averageTypingWpm,
    this.multitaskingScore,
    this.attentivenessBreakdown,
    this.guidedMode = true,
  });

  @override
  Widget build(BuildContext context) {
    return ReportUI(
      evaluations: evaluations,
      averageWpm: averageWpm,
      fillerWordCount: fillerWordCount,
      averageTypingWpm: averageTypingWpm,
      multitaskingScore: multitaskingScore,
      attentivenessBreakdown: attentivenessBreakdown,
      guidedMode: guidedMode,
    );
  }
}
