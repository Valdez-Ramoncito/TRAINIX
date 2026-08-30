import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainixprogram/models/session_score.dart';
import 'package:trainixprogram/providers/simulation_provider.dart';
import 'package:trainixprogram/screens/mock_call_screen.dart';

//one collapsed telemetry-note entry. The most significant instance of
//a given category being flagged across this session, plus how many
//interactions also flagged it
class _TelemetryNoteEntry {
  final String label;
  final String note;
  final String? quote;
  final int flaggedCount;
  final int totalCount;

  const _TelemetryNoteEntry({
    required this.label,
    required this.note,
    required this.quote,
    required this.flaggedCount,
    required this.totalCount,
  });
}

//shared renderer for a list of telemetry note entries. Used by both
//the chat and voice telemetry sections below, so the note + quote layout
//only needs to be defined once
List<Widget> _buildTelemetryNoteWidgets(List<_TelemetryNoteEntry> entries) {
  final widgets = <Widget>[];
  for (final entry in entries) {
    final countSuffix = entry.flaggedCount > 1
        ? ' (flagged in ${entry.flaggedCount} of ${entry.totalCount} interactions)'
        : '';
    widgets.add(
      Padding(
        padding: EdgeInsets.only(bottom: entry.quote != null ? 2.0 : 6.0),
        child: Text(
          '• ${entry.label}: ${entry.note}$countSuffix',
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
    if (entry.quote != null) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(left: 14.0, bottom: 8.0),
          child: Text(
            '"${entry.quote}"',
            style: const TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }
  }
  return widgets;
}

//this shows a complete performance summary for the session
//that had just ended
class SessionReportScreen extends StatelessWidget {
  //maps each TESDA telemetry category's human-readable note label back
  //to its numeric score
  //labels here must exactly match the labels SessionEvaluation.fromGeminiTesda
  //or fromGeminiVoiceTesda use as categoryNotes/categoryQuotes keys.
  static final Map<String, double Function(SessionEvaluation)>
  _chatNoteCategoryScores = {
    'Opening Spiel': (e) => e.openingSpielScore,
    'Positive Scripting': (e) => e.positiveScriptingScore,
    'Empathy': (e) => e.empathyScore,
    'Active Listening': (e) => e.activeListeningScore,
    'Problem Identification': (e) => e.problemIdentificationScore,
    'Solution Delivery': (e) => e.solutionDeliveryScore,
    'Typing Speed': (e) => e.typingSpeedScore ?? 10,
    'Error Rate & Accuracy': (e) => e.errorRateAccuracyScore ?? 10,
    'Response Consistency & Pace': (e) => e.responseConsistencyScore ?? 10,
    'Communication Clarity': (e) => e.communicationClarityScore,
    'Sector Knowledge': (e) => e.sectorKnowledgeScore,
    'Closing Spiel': (e) => e.closingSpielScore,
  };

  static final Map<String, double Function(SessionEvaluation)>
  _voiceNoteCategoryScores = {
    'Opening Spiel': (e) => e.openingSpielScore,
    'Positive Scripting': (e) => e.positiveScriptingScore,
    'Empathy': (e) => e.empathyScore,
    'Active Listening': (e) => e.activeListeningScore,
    'Problem Identification': (e) => e.problemIdentificationScore,
    'Solution Delivery': (e) => e.solutionDeliveryScore,
    'Pace & Speed': (e) => e.paceAndSpeedScore ?? 10,
    'Pronunciation & Clarity': (e) => e.pronunciationClarityScore ?? 10,
    'Filler Word Usage': (e) => e.fillerWordUsageScore ?? 10,
    'Tone & Inflection': (e) => e.toneScore,
    'Sector Knowledge': (e) => e.sectorKnowledgeScore,
    'Closing Spiel': (e) => e.closingSpielScore,
  };

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

  //evaluations that carry the new TESDA telemetry fields
  //only chat evaluations populate these
  //voice evaluations leave them null,
  //so this is effectively just the chat evaluations in this session
  List<SessionEvaluation> get _chatTesdaEvaluations =>
      evaluations.where((e) => e.typingSpeedScore != null).toList();

  //averages a nullable-field selector across only the evaluations where
  //it's actually present
  //returns null if none have it
  double? _averageChatTesda(double? Function(SessionEvaluation) selector) {
    final vals = _chatTesdaEvaluations
        .map(selector)
        .whereType<double>()
        .toList();
    if (vals.isEmpty) return null;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  //same idea as _chatTesdaEvaluations, for voice, paceAndSpeedScore is
  //only populated by GeminiVoiceEvaluationApiService
  List<SessionEvaluation> get _voiceTesdaEvaluations =>
      evaluations.where((e) => e.paceAndSpeedScore != null).toList();

  double? _averageVoiceTesda(double? Function(SessionEvaluation) selector) {
    final vals = _voiceTesdaEvaluations
        .map(selector)
        .whereType<double>()
        .toList();
    if (vals.isEmpty) return null;
    return vals.reduce((a, b) => a + b) / vals.length;
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

            //TESDA telemetry + evaluator citations. Chat and voice
            //each render nothing if this session had no evaluations of
            //that type
            _buildTesdaTelemetry(),
            _buildVoiceTesdaTelemetry(),

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
            ? 'Overall Score: '
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
        if (multitaskingScore != null)
          const Padding(
            padding: EdgeInsets.only(top: 2.0, bottom: 4.0),
            child: Text(
              'Balance of avg. resolution time across channels. Closest '
              'documented TESDA analog: Basic Competency 500311107 (Time '
              '& Priority Management)  TESDA NC II has no dedicated '
              'blended-channel competency.',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
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
          const Text('')
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
          const Text('')
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

  //build TESDA Telemetry + Evaluator Notes UI. Chat-only
  Widget _buildTesdaTelemetry() {
    final chatEvals = _chatTesdaEvaluations;
    if (chatEvals.isEmpty) return const SizedBox.shrink();

    final typingSpeed = _averageChatTesda((e) => e.typingSpeedScore);
    final errorRate = _averageChatTesda((e) => e.errorRateAccuracyScore);
    final consistency = _averageChatTesda((e) => e.responseConsistencyScore);

    //collapse every chat evaluation's notes down to one entry per
    //category, Each entry shows the single most significant
    //instance of that category being flagged, most actionable for a
    //trainee, plus how many interactions also flagged it, and, where
    //the evaluator provided one, the agent's own verbatim line as
    //supporting evidence.
    final entries = <_TelemetryNoteEntry>[];
    _chatNoteCategoryScores.forEach((label, scoreOf) {
      SessionEvaluation? worst;
      double worstScore = 11;
      int flaggedCount = 0;
      for (final e in chatEvals) {
        final note = e.categoryNotes?[label];
        if (note == null) continue;
        flaggedCount++;
        final score = scoreOf(e);
        if (score < worstScore) {
          worstScore = score;
          worst = e;
        }
      }
      if (worst == null) return;
      entries.add(
        _TelemetryNoteEntry(
          label: label,
          note: worst.categoryNotes![label]!,
          quote: worst.categoryQuotes?[label],
          flaggedCount: flaggedCount,
          totalCount: chatEvals.length,
        ),
      );
    });

    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'Chat Telemetry (TESDA NC II)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Scored against TESDA Common Unit 2 (ICT311203) keystroke '
            'standards  chat interactions only, voice isn\'t included '
            'in this section.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Text(
            'Typing Speed: '
            '${typingSpeed != null ? '${typingSpeed.toStringAsFixed(1)} / 10' : ''}',
          ),
          Text(
            'Error Rate & Accuracy: '
            '${errorRate != null ? '${errorRate.toStringAsFixed(1)} / 10' : ''}',
          ),
          Text(
            'Response Consistency & Pace: '
            '${consistency != null ? '${consistency.toStringAsFixed(1)} / 10' : ''}',
          ),
          if (entries.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Evaluator Notes',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 2),
            const Text(
              'Each note shows the most significant example from this '
              'session for that category  the score above already '
              'reflects the average across every interaction.',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ..._buildTelemetryNoteWidgets(entries),
          ],
        ],
      ),
    );
  }

  //build Voice TESDA Telemetry + Evaluator Notes UI for voice
  Widget _buildVoiceTesdaTelemetry() {
    final voiceEvals = _voiceTesdaEvaluations;
    if (voiceEvals.isEmpty) return const SizedBox.shrink();

    final pace = _averageVoiceTesda((e) => e.paceAndSpeedScore);
    final pronunciation = _averageVoiceTesda(
      (e) => e.pronunciationClarityScore,
    );
    final fillerWords = _averageVoiceTesda((e) => e.fillerWordUsageScore);

    //same worst-instance + supporting-quote collapse as chat
    final entries = <_TelemetryNoteEntry>[];
    _voiceNoteCategoryScores.forEach((label, scoreOf) {
      SessionEvaluation? worst;
      double worstScore = 11;
      int flaggedCount = 0;
      for (final e in voiceEvals) {
        final note = e.categoryNotes?[label];
        if (note == null) continue;
        flaggedCount++;
        final score = scoreOf(e);
        if (score < worstScore) {
          worstScore = score;
          worst = e;
        }
      }
      if (worst == null) return;
      entries.add(
        _TelemetryNoteEntry(
          label: label,
          note: worst.categoryNotes![label]!,
          quote: worst.categoryQuotes?[label],
          flaggedCount: flaggedCount,
          totalCount: voiceEvals.length,
        ),
      );
    });

    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'Voice Telemetry (TESDA NC II)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Scored from the trainee\'s actual recorded audio against '
            'TESDA Core Unit 1 (ICT313365)  voice interactions only.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Text(
            'Pace & Speed: '
            '${pace != null ? '${pace.toStringAsFixed(1)} / 10' : ''}',
          ),
          Text(
            'Pronunciation & Clarity: '
            '${pronunciation != null ? '${pronunciation.toStringAsFixed(1)} / 10' : ''}',
          ),
          Text(
            'Filler Word Usage: '
            '${fillerWords != null ? '${fillerWords.toStringAsFixed(1)} / 10' : ''}',
          ),
          if (entries.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Evaluator Notes',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 2),
            const Text(
              'Each note shows the most significant example from this '
              'session for that category  the score above already '
              'reflects the average across every interaction.',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ..._buildTelemetryNoteWidgets(entries),
          ],
        ],
      ),
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
