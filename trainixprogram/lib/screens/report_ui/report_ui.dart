import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:trainixprogram/models/session_score.dart';
import 'package:trainixprogram/providers/simulation_provider.dart';
import 'package:trainixprogram/screens/mock_call_screen.dart';
import 'package:trainixprogram/widgets/user_facing_messages.dart';

double displayScore10(double raw) {
  if (raw.isNaN) return 0;
  if (raw > 10 && raw <= 100) return (raw / 10).clamp(0, 10);
  return raw.clamp(0, 10);
}

class TelemetryNoteEntry {
  final String label;
  final String note;
  final String? quote;
  final int flaggedCount;
  final int totalCount;

  const TelemetryNoteEntry({
    required this.label,
    required this.note,
    required this.quote,
    required this.flaggedCount,
    required this.totalCount,
  });
}

class ReportUI extends StatelessWidget {
  final List<SessionEvaluation> evaluations;
  final double? averageWpm;
  final int? fillerWordCount;
  final double? averageTypingWpm;
  final double? multitaskingScore;
  final VoidCallback? onBackToMenu;
  final VoidCallback? onStartAnotherSession;

  const ReportUI({
    super.key,
    this.evaluations = const [],
    this.averageWpm,
    this.fillerWordCount,
    this.averageTypingWpm,
    this.multitaskingScore,
    this.onBackToMenu,
    this.onStartAnotherSession,
  });

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

  double get _averageOverall {
    if (evaluations.isEmpty) return 0;
    return evaluations.map((e) => e.overallScore).reduce((a, b) => a + b) /
        evaluations.length;
  }

  double _averageCategory(double Function(SessionEvaluation) selector) {
    if (evaluations.isEmpty) return 0;
    return evaluations.map(selector).reduce((a, b) => a + b) /
        evaluations.length;
  }

  List<SessionEvaluation> get _chatTesdaEvaluations =>
      evaluations.where((e) => e.typingSpeedScore != null).toList();

  double? _averageChatTesda(double? Function(SessionEvaluation) selector) {
    final vals = _chatTesdaEvaluations
        .map(selector)
        .whereType<double>()
        .toList();
    if (vals.isEmpty) return null;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

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

  List<String> _aggregate(List<String> Function(SessionEvaluation) selector) {
    final seen = <String>{};
    final result = <String>[];
    for (final e in evaluations) {
      for (final s in selector(e)) {
        if (s.isNotEmpty && seen.add(s)) result.add(s);
      }
    }
    return result.take(5).toList();
  }

  String get _performanceLevel {
    final avg = _averageOverall;
    if (avg >= 8.5) return 'Excellent';
    if (avg >= 7.0) return 'Proficient';
    if (avg >= 5.0) return 'Developing';
    return 'Needs Work';
  }

  Color get _performanceColor {
    final avg = _averageOverall;
    if (avg >= 8.5) return const Color(0xFF10B981);
    if (avg >= 7.0) return const Color(0xFF3B82F6);
    if (avg >= 5.0) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark
        ? Theme.of(context).colorScheme.surface
        : const Color(0xFF0B0F17);

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Text(
                    'Session Performance Report',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
                  ),
                ),
                Gap(50),
                _buildHeroOverallCard(),
                const Gap(15),
                _buildChannelAveragesCard(),
                const Gap(15),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 750) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildScoreBreakdownCard()),
                          const Gap(20),
                          Expanded(child: _buildInteractionStatsCard()),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        _buildScoreBreakdownCard(),
                        const Gap(20),
                        _buildInteractionStatsCard(),
                      ],
                    );
                  },
                ),
                const Gap(20),
                _buildCustomerLists(context),
                const Gap(32),
                _buildBottomActionButtons(context),
                const Gap(24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Hero Card displaying overall score gauge & level

  double? _avgForChannel(String channel) {
    final list = evaluations.where((e) => e.channel == channel).toList();
    if (list.isEmpty) return null;
    return list.map((e) => e.overallScore).reduce((a, b) => a + b) /
        list.length;
  }

  Widget _buildChannelAveragesCard() {
    final chatAvg = _avgForChannel('chat');
    final voiceAvg = _avgForChannel('voice');
    final hasChat = chatAvg != null;
    final hasVoice = voiceAvg != null;
    if (!hasChat && !hasVoice) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 28, 28, 28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromARGB(255, 42, 42, 43)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Channel averages',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const Gap(14),
          Row(
            children: [
              if (hasChat)
                Expanded(
                  child: _channelAvgTile(
                    'Non-Voice',
                    chatAvg!,
                    Icons.chat_bubble_outline,
                    const Color(0xFF3B82F6),
                  ),
                ),
              if (hasChat && hasVoice) const Gap(12),
              if (hasVoice)
                Expanded(
                  child: _channelAvgTile(
                    'Voice',
                    voiceAvg!,
                    Icons.call_outlined,
                    const Color(0xFF70BD8A),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _channelAvgTile(
    String label,
    double score,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 21, 21, 21),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const Gap(4),
                Text(
                  '${displayScore10(score).toStringAsFixed(1)} / 10',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const Gap(8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (score / 10).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: const Color(0xFF2A2A2A),
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  List<SessionEvaluation> get _chatEvals =>
      evaluations.where((e) => e.channel == 'chat').toList();
  List<SessionEvaluation> get _voiceEvals =>
      evaluations.where((e) => e.channel == 'voice').toList();

  Widget _buildCustomerLists(BuildContext context) {
    final hasHybridSplit = _chatEvals.isNotEmpty && _voiceEvals.isNotEmpty;
    if (evaluations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 28, 28, 28),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color.fromARGB(255, 42, 42, 43)),
        ),
        child: const Text(
          'No customer evaluations recorded for this session.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    if (hasHybridSplit) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCustomerSection(context, 'Chat customers', _chatEvals),
          const Gap(16),
          _buildCustomerSection(context, 'Voice customers', _voiceEvals),
        ],
      );
    }

    return _buildCustomerSection(
      context,
      'Customers in this session',
      evaluations,
    );
  }

  Widget _buildCustomerSection(
    BuildContext context,
    String title,
    List<SessionEvaluation> items,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 28, 28, 28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromARGB(255, 42, 42, 43)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const Gap(12),
          ...items.asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            final level = e.overallScore >= 8.5
                ? 'Excellent'
                : e.overallScore >= 7
                ? 'Good'
                : e.overallScore >= 5
                ? 'Developing'
                : 'Needs work';
            final levelColor = e.overallScore >= 8.5
                ? const Color(0xFF70BD8A)
                : e.overallScore >= 7
                ? const Color(0xFF3B82F6)
                : e.overallScore >= 5
                ? const Color(0xFFF59E0B)
                : const Color(0xFFEF4444);
            final topStrength = e.strengths.isNotEmpty
                ? friendlyEvalText(e.strengths.first)
                : '';
            final topGap = e.areasForImprovement.isNotEmpty
                ? friendlyEvalText(e.areasForImprovement.first)
                : '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CustomerReportDetailScreen(evaluation: e),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 21, 21, 21),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color.fromARGB(255, 42, 42, 43),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.customerName.isEmpty
                                  ? 'Customer ${i + 1}'
                                  : e.customerName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: levelColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: levelColor),
                            ),
                            child: Text(
                              level,
                              style: TextStyle(
                                color: levelColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Gap(10),
                          Text(
                            displayScore10(e.overallScore).toStringAsFixed(1),
                            style: TextStyle(
                              color: levelColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                            ),
                          ),
                          const Gap(4),
                          const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF9CA3AF),
                          ),
                        ],
                      ),
                      const Gap(8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _miniBadge(
                            e.channel.toUpperCase(),
                            e.channel == 'voice'
                                ? const Color(0xFF70BD8A)
                                : const Color(0xFF3B82F6),
                          ),
                          if (e.sector.isNotEmpty)
                            _miniBadge(e.sector, const Color(0xFF9CA3AF)),
                          if (e.ahtHandleSeconds != null)
                            _miniBadge(
                              e.ahtOverLimit ? 'AHT over' : 'AHT ok',
                              e.ahtOverLimit
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF70BD8A),
                            ),
                          if (e.customerRating != null)
                            _miniBadge(
                              'CSAT ${e.customerRating}/5',
                              const Color(0xFFFBBF24),
                            ),
                        ],
                      ),
                      if (e.customerComment != null &&
                          e.customerComment!.isNotEmpty) ...[
                        const Gap(8),
                        Text(
                          e.customerComment!,
                          style: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            height: 1.35,
                          ),
                        ),
                      ],
                      if (e.problem.isNotEmpty) ...[
                        const Gap(8),
                        Text(
                          e.problem,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                      const Gap(10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (e.overallScore / 10).clamp(0.0, 1.0),
                          minHeight: 7,
                          backgroundColor: const Color(0xFF2A2A2A),
                          color: levelColor,
                        ),
                      ),
                      if (topStrength.isNotEmpty || topGap.isNotEmpty) ...[
                        const Gap(10),
                        if (topStrength.isNotEmpty)
                          Text(
                            'Strength: $topStrength',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF70BD8A),
                              fontSize: 12,
                            ),
                          ),
                        if (topGap.isNotEmpty)
                          Text(
                            'Focus next: $topGap',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFF59E0B),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeroOverallCard() {
    final avgScore = _averageOverall;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 28, 28, 28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color.fromARGB(255, 42, 42, 43)),
      ),
      child: Row(
        children: [
          // Circular Score Gauge Accent
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color.fromARGB(255, 28, 28, 29),
              border: Border.all(color: _performanceColor, width: 2),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    evaluations.isEmpty ? 'N/A' : avgScore.toStringAsFixed(1),
                    style: TextStyle(fontSize: 16),
                  ),
                  const Text(' / 10', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
          const Gap(24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _performanceColor.withAlpha(38),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _performanceColor),
                      ),
                      child: Text(
                        _performanceLevel.toUpperCase(),
                        style: TextStyle(
                          color: _performanceColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const Gap(12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${evaluations.length} Interaction${evaluations.length == 1 ? '' : 's'} Evaluated',
                        style: const TextStyle(
                          color: Color.fromARGB(255, 208, 209, 211),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(10),
                const Text(
                  'Overall Session Rating',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(4),
                const Text(
                  'Overall practice score from this session across greeting, empathy, problem solving, clarity, and close.',
                  style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Score Breakdown Card
  Widget _buildScoreBreakdownCard() {
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

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                color: Color.fromARGB(255, 177, 203, 245),
                size: 20,
              ),
              Gap(8),
              Text(
                'Competency Score Breakdown',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Gap(16),
          const Divider(height: 1, color: Color.fromARGB(255, 75, 75, 75)),
          const Gap(16),
          if (evaluations.isEmpty)
            const Text(
              'No evaluations recorded for this session.',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
            )
          else
            ...categories.map((c) {
              final val = c.$2;
              final pct = (val / 10.0).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          c.$1,
                          style: const TextStyle(
                            color: Color(0xFFE2E8F0),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${val.toStringAsFixed(1)} / 10',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Gap(6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: const Color(0xFF1E293B),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          val >= 8.0
                              ? const Color(0xFF10B981)
                              : val >= 6.0
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  bool get _hasChatChannel =>
      evaluations.any((e) => e.channel.toLowerCase() == 'chat');

  bool get _hasVoiceChannel =>
      evaluations.any((e) => e.channel.toLowerCase() == 'voice');

  // Interaction Stats Card (channel-aware)
  Widget _buildInteractionStatsCard() {
    final showVoicePace = _hasVoiceChannel;
    final showTypingPace = _hasChatChannel;
    final showFillers = _hasVoiceChannel;
    final hasAny =
        showVoicePace ||
        showTypingPace ||
        showFillers ||
        multitaskingScore != null;
    if (!hasAny) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 21, 21, 22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromARGB(255, 47, 47, 47)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.speed_rounded, color: Color(0xFF0EA5E9), size: 20),
              Gap(8),
              Text(
                'Interaction Telemetry Stats',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Gap(16),
          const Divider(height: 1, color: Color.fromARGB(255, 75, 75, 75)),
          const Gap(16),
          if (showVoicePace) ...[
            _buildStatTile(
              icon: Icons.mic_rounded,
              title: 'Speaking Pace',
              value: averageWpm != null
                  ? '${averageWpm!.toStringAsFixed(0)} WPM'
                  : 'Not recorded',
              subtitle: 'Recommended range: 130-160 WPM',
            ),
            const Gap(10),
          ],
          if (showTypingPace) ...[
            _buildStatTile(
              icon: Icons.keyboard_rounded,
              title: 'Typing Pace',
              value: averageTypingWpm != null
                  ? '${averageTypingWpm!.toStringAsFixed(0)} WPM'
                  : 'Not recorded',
              subtitle: 'Target: 40+ words per minute',
            ),
            const Gap(10),
          ],
          if (showFillers) ...[
            _buildStatTile(
              icon: Icons.record_voice_over_rounded,
              title: 'Filler Words',
              value: fillerWordCount != null
                  ? '$fillerWordCount used'
                  : 'Not recorded',
              subtitle: 'Target: minimal fillers ("um", "uh")',
            ),
            const Gap(10),
          ],
          _buildStatTile(
            icon: Icons.alt_route_rounded,
            title: 'Session attentiveness',
            value: multitaskingScore != null
                ? '${multitaskingScore!.toStringAsFixed(0)}%'
                : 'Not recorded',
            subtitle:
                'Identity checks, tool use, and follow-through in this session',
          ),
          if (multitaskingScore != null) ...[
            const Gap(12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withAlpha(128),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: const Text(
                'Based on identity verification, Account Lookup actions, and completing required tool steps. Taking notes is a small bonus, not required.',
                style: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF3B82F6), size: 20),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color.fromARGB(255, 119, 130, 145),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // Strengths Card
  Widget _buildStrengthsCard() {
    final strengths = _aggregate((e) => e.strengths);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 21, 21, 22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromARGB(255, 47, 47, 47)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF10B981),
                size: 20,
              ),
              Gap(8),
              Text(
                'Key Strengths Identified',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Gap(16),
          const Divider(height: .3, color: Color.fromARGB(99, 16, 185, 129)),
          const Gap(16),
          if (strengths.isEmpty)
            const Text(
              'No specific strengths logged for this session.',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
            )
          else
            ...strengths.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFF10B981),
                      size: 16,
                    ),
                    const Gap(10),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontSize: 13,
                          height: 1.4,
                        ),
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

  // Areas for Improvement Card
  Widget _buildImprovementsCard() {
    final improvements = _aggregate((e) => e.areasForImprovement);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 21, 21, 22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromARGB(255, 47, 47, 47)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                color: Color(0xFFF59E0B),
                size: 20,
              ),
              Gap(8),
              Text(
                'Areas for Improvement',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Gap(16),
          const Divider(height: .3, color: Color.fromARGB(127, 245, 159, 11)),
          const Gap(16),
          if (improvements.isEmpty)
            const Text(
              'No improvement areas flagged.',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
            )
          else
            ...improvements.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Color(0xFFF59E0B),
                      size: 16,
                    ),
                    const Gap(10),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontSize: 13,
                          height: 1.4,
                        ),
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

  // AI Feedback Summary Card
  Widget _buildAiFeedbackCard() {
    final feedback = evaluations.isNotEmpty ? evaluations.last.feedback : null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF8B5CF6),
                size: 22,
              ),
              Gap(10),
              Text(
                'AI Evaluator Feedback',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Gap(14),
          Text(
            feedback != null && feedback.isNotEmpty
                ? feedback
                : 'No feedback available for this session.',
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 14,
              height: 1.6,
            ),
          ),
          if (evaluations.length > 1) ...[
            const Gap(12),
            const Text(
              '* Feedback shown is from the most recent interaction in this session.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Chat TESDA Telemetry Card
  Widget _buildChatTesdaCard() {
    final chatEvals = _chatTesdaEvaluations;
    if (chatEvals.isEmpty) return const SizedBox.shrink();

    final typingSpeed = _averageChatTesda((e) => e.typingSpeedScore);
    final errorRate = _averageChatTesda((e) => e.errorRateAccuracyScore);
    final consistency = _averageChatTesda((e) => e.responseConsistencyScore);

    final entries = <TelemetryNoteEntry>[];
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
        TelemetryNoteEntry(
          label: label,
          note: worst.categoryNotes![label]!,
          quote: worst.categoryQuotes?[label],
          flaggedCount: flaggedCount,
          totalCount: chatEvals.length,
        ),
      );
    });

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 21, 21, 22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromARGB(255, 47, 47, 47)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                color: Color(0xFF3B82F6),
                size: 20,
              ),
              Gap(8),
              Text(
                'Chat typing metrics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Gap(4),
          const Text(
            'Measures typing speed and accuracy during the chat interaction.',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
          ),
          const Gap(16),
          Row(
            children: [
              Expanded(
                child: _buildTelemetryScoreBox(
                  'Typing Speed',
                  typingSpeed,
                  Icons.speed_rounded,
                ),
              ),
              const Gap(12),
              Expanded(
                child: _buildTelemetryScoreBox(
                  'Error & Accuracy',
                  errorRate,
                  Icons.spellcheck_rounded,
                ),
              ),
              const Gap(12),
              Expanded(
                child: _buildTelemetryScoreBox(
                  'Response Pace',
                  consistency,
                  Icons.timer_rounded,
                ),
              ),
            ],
          ),
          if (entries.isNotEmpty) ...[
            const Gap(20),
            const Text(
              'Evaluator Detailed Notes & Citations',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const Gap(10),
            ..._buildTelemetryNoteCards(entries),
          ],
        ],
      ),
    );
  }

  // Voice TESDA Telemetry Card
  Widget _buildVoiceTesdaCard() {
    final voiceEvals = _voiceTesdaEvaluations;
    if (voiceEvals.isEmpty) return const SizedBox.shrink();

    final pace = _averageVoiceTesda((e) => e.paceAndSpeedScore);
    final pronunciation = _averageVoiceTesda(
      (e) => e.pronunciationClarityScore,
    );
    final fillerWords = _averageVoiceTesda((e) => e.fillerWordUsageScore);

    final entries = <TelemetryNoteEntry>[];
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
        TelemetryNoteEntry(
          label: label,
          note: worst.categoryNotes![label]!,
          quote: worst.categoryQuotes?[label],
          flaggedCount: flaggedCount,
          totalCount: voiceEvals.length,
        ),
      );
    });

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 21, 21, 22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromARGB(255, 47, 47, 47)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.record_voice_over_rounded,
                color: Color(0xFF0EA5E9),
                size: 20,
              ),
              Gap(8),
              Text(
                'Voice delivery metrics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Gap(4),
          const Text(
            'Measures pace, clarity, and delivery from the recorded voice interaction.',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
          ),
          const Gap(16),
          Row(
            children: [
              Expanded(
                child: _buildTelemetryScoreBox(
                  'Pace & Speed',
                  pace,
                  Icons.equalizer_rounded,
                ),
              ),
              const Gap(12),
              Expanded(
                child: _buildTelemetryScoreBox(
                  'Pronunciation',
                  pronunciation,
                  Icons.record_voice_over_rounded,
                ),
              ),
              const Gap(12),
              Expanded(
                child: _buildTelemetryScoreBox(
                  'Filler Usage',
                  fillerWords,
                  Icons.subtitles_off_rounded,
                ),
              ),
            ],
          ),
          if (entries.isNotEmpty) ...[
            const Gap(20),
            const Text(
              'Voice Evaluator Detailed Notes & Citations',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const Gap(10),
            ..._buildTelemetryNoteCards(entries),
          ],
        ],
      ),
    );
  }

  Widget _buildTelemetryScoreBox(String label, double? score, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color.fromARGB(255, 35, 36, 37)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF3B82F6), size: 20),
          const Gap(6),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
          ),
          const Gap(4),
          Text(
            score != null
                ? '${displayScore10(score).toStringAsFixed(1)} / 10'
                : 'N/A',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTelemetryNoteCards(List<TelemetryNoteEntry> entries) {
    return entries.map((entry) {
      final countSuffix = entry.flaggedCount > 1
          ? ' (flagged in ${entry.flaggedCount} of ${entry.totalCount} interactions)'
          : '';

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color.fromARGB(255, 47, 47, 48)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.label,
                    style: const TextStyle(
                      color: Color(0xFF3B82F6),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (countSuffix.isNotEmpty) ...[
                  const Gap(8),
                  Text(
                    countSuffix,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
            const Gap(8),
            Text(
              entry.note,
              style: const TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            if (entry.quote != null) ...[
              const Gap(8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 32, 32, 33),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Text(
                  '"${entry.quote}"',
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }).toList();
  }

  // Bottom action buttons navigation
  Widget _buildBottomActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            if (onBackToMenu != null) {
              onBackToMenu!();
            } else {
              Navigator.pop(context);
            }
          },
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text('Back to Menu'),
          style: OutlinedButton.styleFrom(
            enabledMouseCursor: SystemMouseCursors.click,
            foregroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFF334155)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const Gap(12),
        ElevatedButton.icon(
          onPressed: () {
            if (onStartAnotherSession != null) {
              onStartAnotherSession!();
            } else {
              final sector = Provider.of<SimulationProvider>(
                context,
                listen: false,
              ).pickNextSector();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => MockCallScreen(sector: sector),
                ),
              );
            }
          },
          icon: const Icon(Icons.play_arrow_rounded, size: 20),
          label: const Text('Start Another Session'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            enabledMouseCursor: SystemMouseCursors.click,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 19),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
      ],
    );
  }
}

class CustomerReportDetailScreen extends StatelessWidget {
  final SessionEvaluation evaluation;

  const CustomerReportDetailScreen({super.key, required this.evaluation});

  @override
  Widget build(BuildContext context) {
    final e = evaluation;
    final notes = e.categoryNotes ?? {};
    final quotes = e.categoryQuotes ?? {};
    final categories = <MapEntry<String, double>>[
      MapEntry('Opening Spiel', e.openingSpielScore),
      MapEntry('Positive Scripting', e.positiveScriptingScore),
      MapEntry('Empathy', e.empathyScore),
      MapEntry('Active Listening', e.activeListeningScore),
      MapEntry('Problem Identification', e.problemIdentificationScore),
      MapEntry('Solution Delivery', e.solutionDeliveryScore),
      MapEntry('Communication Clarity', e.communicationClarityScore),
      MapEntry('Tone', e.toneScore),
      MapEntry('Sector Knowledge', e.sectorKnowledgeScore),
      MapEntry('Closing Spiel', e.closingSpielScore),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F17),
        title: Text(
          e.customerName.isEmpty ? 'Customer detail' : e.customerName,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 28, 28, 28),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color.fromARGB(255, 42, 42, 43)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.customerRating == null
                      ? 'Overall ${displayScore10(e.overallScore).toStringAsFixed(1)}'
                      : 'Overall ${displayScore10(e.overallScore).toStringAsFixed(1)} · CSAT ${e.customerRating}/5',
                  style: const TextStyle(
                    color: Color(0xFF70BD8A),
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Gap(8),
                Text(
                  [
                    e.sector,
                    e.channel,
                    if (e.problem.isNotEmpty) e.problem,
                    if (e.ahtHandleSeconds != null)
                      'AHT ${e.ahtHandleSeconds!.toStringAsFixed(0)}s${e.ahtOverLimit ? " (over target)" : ""}',
                  ].where((s) => s.toString().isNotEmpty).join(' · '),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                if (e.customerComment != null &&
                    e.customerComment!.isNotEmpty) ...[
                  const Gap(10),
                  Text(
                    '"${e.customerComment}"',
                    style: const TextStyle(
                      color: Color(0xFFFBBF24),
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ],
                if (e.feedback.isNotEmpty) ...[
                  const Gap(12),
                  Text(
                    friendlyEvalText(e.feedback),
                    style: const TextStyle(
                      color: Colors.white,
                      height: 1.45,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Gap(16),
          const Text(
            'Skill scores',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const Gap(10),
          ...categories.map((c) {
            final note =
                notes[c.key] ?? notes[c.key.replaceAll(' ', '_')] ?? '';
            final quote = quotes[c.key] ?? '';
            final color = c.value >= 8.5
                ? const Color(0xFF70BD8A)
                : c.value >= 7
                ? const Color(0xFF3B82F6)
                : c.value >= 5
                ? const Color(0xFFF59E0B)
                : const Color(0xFFEF4444);
            final level = c.value >= 8.5
                ? 'Strong'
                : c.value >= 7
                ? 'Solid'
                : c.value >= 5
                ? 'Developing'
                : 'Needs work';
            final fallback = c.value >= 8
                ? 'Strong evidence for this competency in the interaction.'
                : c.value >= 5
                ? 'Partial credit. Some cues were present; review the conversation for gaps.'
                : 'Limited evidence for this competency. Focus practice here next.';
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 28, 28, 28),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color.fromARGB(255, 42, 42, 43),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.key,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: color),
                        ),
                        child: Text(
                          level,
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Gap(10),
                      Text(
                        c.value.toStringAsFixed(1),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const Gap(10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (c.value / 10).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: const Color(0xFF2A2A2A),
                      color: color,
                    ),
                  ),
                  const Gap(10),
                  Text(
                    friendlyEvalText(note.isNotEmpty ? note : fallback),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  if (quote.isNotEmpty) ...[
                    const Gap(8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Text(
                        'From the conversation: "$quote"',
                        style: const TextStyle(
                          color: Color(0xFF93C5FD),
                          fontSize: 12,
                          height: 1.35,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
          if (e.strengths
              .where((s) => friendlyEvalText(s).isNotEmpty)
              .isNotEmpty) ...[
            const Gap(8),
            const Text(
              'What went well',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Gap(8),
            ...e.strengths.map((s) {
              final text = friendlyEvalText(s);
              if (text.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '•  ',
                      style: TextStyle(color: Color(0xFF70BD8A)),
                    ),
                    Expanded(
                      child: Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white70,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          if (e.areasForImprovement
              .where((s) => friendlyEvalText(s).isNotEmpty)
              .isNotEmpty) ...[
            const Gap(12),
            const Text(
              'What to practice next',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Gap(8),
            ...e.areasForImprovement.map((s) {
              final text = friendlyEvalText(s);
              if (text.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '•  ',
                      style: TextStyle(color: Color(0xFFF59E0B)),
                    ),
                    Expanded(
                      child: Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white70,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          const Gap(16),
          const Text(
            'Conversation',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const Gap(10),
          if (e.conversation.isEmpty)
            const Text(
              'No messages were saved for this customer.',
              style: TextStyle(color: Colors.white54),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1419),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1F2937)),
              ),
              child: Column(
                children: e.conversation.map((turn) {
                  final isAgent = turn['role'] == 'agent';
                  final label = isAgent ? 'You' : 'Customer';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: isAgent
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        if (!isAgent) ...[
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: const Color(0xFF374151),
                            child: Text(
                              label[0],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Column(
                            crossAxisAlignment: isAgent
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: const TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isAgent
                                      ? const Color(0xFF1D4ED8)
                                      : const Color(0xFF1F2937),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(12),
                                    topRight: const Radius.circular(12),
                                    bottomLeft: Radius.circular(
                                      isAgent ? 12 : 4,
                                    ),
                                    bottomRight: Radius.circular(
                                      isAgent ? 4 : 12,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  turn['text'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    height: 1.4,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isAgent) ...[
                          const SizedBox(width: 8),
                          const CircleAvatar(
                            radius: 14,
                            backgroundColor: Color(0xFF1D4ED8),
                            child: Text(
                              'Y',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          const Gap(24),
        ],
      ),
    );
  }
}
