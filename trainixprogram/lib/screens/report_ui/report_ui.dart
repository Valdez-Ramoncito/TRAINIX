import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:trainixprogram/models/scoring_transparency.dart';
import 'package:trainixprogram/models/session_score.dart';
import 'package:trainixprogram/providers/simulation_provider.dart';
import 'package:trainixprogram/screens/mock_call_screen.dart';
import 'package:trainixprogram/widgets/user_facing_messages.dart';

double displayScore10(double raw) {
  if (raw.isNaN) return 0;
  if (raw > 10 && raw <= 100) return (raw / 10).clamp(0, 10);
  return raw.clamp(0, 10);
}

Widget reportScoreRing({
  required double score,
  required Color color,
  double size = 120,
  double stroke = 10,
}) {
  final value = (score / 10).clamp(0.0, 1.0);
  return SizedBox(
    width: size,
    height: size,
    child: Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            value: value,
            strokeWidth: stroke,
            backgroundColor: const Color(0xFF1F2937),
            color: color,
            strokeCap: StrokeCap.round,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              score.toStringAsFixed(1),
              style: TextStyle(
                color: color,
                fontSize: size * 0.22,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            Text(
              '/ 10',
              style: TextStyle(
                color: const Color(0xFF94A3B8),
                fontSize: size * 0.1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class ReportUI extends StatefulWidget {
  final List<SessionEvaluation> evaluations;
  final double? averageWpm;
  final int? fillerWordCount;
  final double? averageTypingWpm;
  final double? multitaskingScore;
  final AttentivenessBreakdown? attentivenessBreakdown;
  final VoidCallback? onBackToMenu;
  final VoidCallback? onStartAnotherSession;
  final bool guidedMode;

  const ReportUI({
    super.key,
    this.evaluations = const [],
    this.averageWpm,
    this.fillerWordCount,
    this.averageTypingWpm,
    this.multitaskingScore,
    this.attentivenessBreakdown,
    this.onBackToMenu,
    this.onStartAnotherSession,
    this.guidedMode = true,
  });

  @override
  State<ReportUI> createState() => _ReportUIState();
}

class _ReportUIState extends State<ReportUI> {
  bool _openScoringGuide = true;
  bool _openRubric = true;
  bool _openTelemetry = true;
  bool _openCustomers = true;
  bool _openAnalysis = true;

  List<SessionEvaluation> get evaluations => widget.evaluations;
  double? get averageWpm => widget.averageWpm;
  int? get fillerWordCount => widget.fillerWordCount;
  double? get averageTypingWpm => widget.averageTypingWpm;
  double? get multitaskingScore => widget.multitaskingScore;
  AttentivenessBreakdown? get attentivenessBreakdown =>
      widget.attentivenessBreakdown;

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

  Widget _collapsibleSection({
    required String title,
    required IconData icon,
    required Color accent,
    required bool open,
    required ValueChanged<bool> onToggle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 28, 28, 28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromARGB(255, 42, 42, 43)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            mouseCursor: SystemMouseCursors.click,
            onTap: () => onToggle(!open),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: accent, size: 18),
                  ),
                  const Gap(10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    open
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),
          if (open) ...[
            const Divider(height: 1, color: Color(0xFF2A2A2B)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: child,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color bgColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Session Performance Report',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                  ),
                ),
                const Gap(20),
                _buildHeroOverallCard(),
                const Gap(14),
                _buildTopMetricGrid(),
                const Gap(14),
                _collapsibleSection(
                  title: 'Session analysis',
                  icon: Icons.psychology_outlined,
                  accent: const Color(0xFF0EA5E9),
                  open: _openAnalysis,
                  onToggle: (v) => setState(() => _openAnalysis = v),
                  child: _buildSessionAnalysisCard(),
                ),
                const Gap(14),
                _collapsibleSection(
                  title: 'Scoring guide and formula',
                  icon: Icons.rule_folder_outlined,
                  accent: const Color(0xFF60A5FA),
                  open: _openScoringGuide,
                  onToggle: (v) => setState(() => _openScoringGuide = v),
                  child: Column(
                    children: [
                      _buildChannelAveragesCard(),
                      const Gap(12),
                      _buildHowScoringWorksCard(context),
                      const Gap(12),
                      _buildSkillBandDistributionCard(),
                    ],
                  ),
                ),
                const Gap(14),
                _collapsibleSection(
                  title: 'Competency rubric',
                  icon: Icons.grid_view_rounded,
                  accent: const Color(0xFFA78BFA),
                  open: _openRubric,
                  onToggle: (v) => setState(() => _openRubric = v),
                  child: _buildScoreBreakdownCard(),
                ),
                const Gap(14),
                _collapsibleSection(
                  title: 'Telemetry, CSAT, and AHT',
                  icon: Icons.speed_rounded,
                  accent: const Color(0xFF0EA5E9),
                  open: _openTelemetry,
                  onToggle: (v) => setState(() => _openTelemetry = v),
                  child: Column(
                    children: [
                      _buildChannelSkillScoresCard(),
                      const Gap(12),
                      _buildInteractionStatsCard(),
                      const Gap(12),
                      _buildCsatAndAhtCard(),
                    ],
                  ),
                ),
                const Gap(14),
                _collapsibleSection(
                  title: 'Customers in this session',
                  icon: Icons.people_outline_rounded,
                  accent: const Color(0xFF70BD8A),
                  open: _openCustomers,
                  onToggle: (v) => setState(() => _openCustomers = v),
                  child: _buildCustomerLists(context),
                ),
                const Gap(28),
                _buildBottomActionButtons(context),
                const Gap(20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopMetricGrid() {
    final withCsat =
        evaluations.where((e) => e.customerRating != null).toList();
    final avgCsat = withCsat.isEmpty
        ? null
        : withCsat
                .map((e) => e.customerRating!.toDouble())
                .reduce((a, b) => a + b) /
            withCsat.length;
    final withAht =
        evaluations.where((e) => e.ahtHandleSeconds != null).toList();
    final overCount = evaluations.where((e) => e.ahtOverLimit).length;

    Widget tile({
      required IconData icon,
      required Color color,
      required String label,
      required String value,
      required String sub,
    }) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 28, 28, 28),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color.fromARGB(255, 42, 42, 43)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const Gap(10),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Gap(2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(2),
            Text(
              sub,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 720;
        final children = [
          tile(
            icon: Icons.forum_outlined,
            color: const Color(0xFF60A5FA),
            label: 'Interactions',
            value: '${evaluations.length}',
            sub: 'Scored customers',
          ),
          tile(
            icon: Icons.star_rate_rounded,
            color: const Color(0xFFFBBF24),
            label: 'Avg CSAT',
            value: avgCsat == null ? '—' : avgCsat.toStringAsFixed(1),
            sub: 'Out of 5 stars',
          ),
          tile(
            icon: Icons.timer_outlined,
            color: overCount > 0
                ? const Color(0xFFF87171)
                : const Color(0xFF34D399),
            label: 'AHT status',
            value: withAht.isEmpty ? '—' : (overCount > 0 ? '$overCount over' : 'On target'),
            sub: 'Target ${ScoringTransparency.ahtTargetSeconds}s',
          ),
          tile(
            icon: Icons.alt_route_rounded,
            color: const Color(0xFFA78BFA),
            label: 'Attentiveness',
            value: multitaskingScore == null
                ? '—'
                : '${multitaskingScore!.toStringAsFixed(0)}%',
            sub: 'Tools and follow-through',
          ),
        ];
        if (wide) {
          return Row(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const Gap(10),
                Expanded(child: children[i]),
              ],
            ],
          );
        }
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: children[0]),
                const Gap(10),
                Expanded(child: children[1]),
              ],
            ),
            const Gap(10),
            Row(
              children: [
                Expanded(child: children[2]),
                const Gap(10),
                Expanded(child: children[3]),
              ],
            ),
          ],
        );
      },
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
    if (chatAvg == null && voiceAvg == null) return const SizedBox.shrink();

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
          const Row(
            children: [
              Icon(Icons.hub_outlined, color: Color(0xFF60A5FA), size: 20),
              Gap(8),
              Text(
                'Channel averages',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const Gap(14),
          Row(
            children: [
              if (chatAvg != null)
                Expanded(
                  child: _channelAvgTile(
                    'Non-Voice',
                    chatAvg,
                    Icons.chat_bubble_outline,
                    const Color(0xFF3B82F6),
                  ),
                ),
              if (chatAvg != null && voiceAvg != null) const Gap(12),
              if (voiceAvg != null)
                Expanded(
                  child: _channelAvgTile(
                    'Voice',
                    voiceAvg,
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

  Widget _buildHowScoringWorksCard(BuildContext context) {
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
          const Row(
            children: [
              Icon(
                Icons.rule_rounded,
                color: Color.fromARGB(255, 177, 203, 245),
                size: 20,
              ),
              Gap(8),
              Text(
                'Scoring guide',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Gap(14),
          _buildFormulaStrip(),
          if (evaluations.isNotEmpty) ...[
            const Gap(12),
            _buildScoreComputationBlock(),
          ],
          const Gap(14),
          _buildLevelBandRow(),
          const Gap(12),
          Text(
            ScoringTransparency.methodLine,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const Gap(6),
          Text(
            ScoringTransparency.whoScoresLine,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulaStrip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How overall is computed',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const Gap(8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _formulaChip('Start each at 10'),
              const Icon(Icons.arrow_forward, size: 14, color: Color(0xFF64748B)),
              _formulaChip('Deduct for observed gaps only'),
              const Icon(Icons.arrow_forward, size: 14, color: Color(0xFF64748B)),
              _formulaChip('Average the 10 dimensions'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF3B82F6)),
                ),
                child: Text(
                  evaluations.isEmpty
                      ? 'Overall —'
                      : 'Overall ${_averageOverall.toStringAsFixed(1)}',
                  style: const TextStyle(
                    color: Color(0xFF93C5FD),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _formulaChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildScoreComputationBlock() {
    final dims = <(String, double)>[
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
    final sum = dims.fold<double>(0, (a, d) => a + d.$2);
    final fromDims = sum / dims.length;
    final sessionOverall = _averageOverall;
    final n = evaluations.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How your overall was calculated',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const Gap(6),
          Text(
            n == 1
                ? 'Step 1: Each skill starts at 10. Observed gaps are removed.\n'
                    'Step 2: Add the 10 skill scores, then divide by 10. That average is your overall.'
                : 'Step 1: Each skill starts at 10 per customer. Gaps are removed.\n'
                    'Step 2: Average each skill across your $n customers (chips below).\n'
                    'Step 3: Add those 10 averages, divide by 10. Session overall also averages each customer overall.',
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const Gap(10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: dims.map((d) {
              final level = ScoringTransparency.levelFor(d.$2);
              final color = Color(level.colorValue);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.35)),
                ),
                child: Text(
                  '${d.$1}: ${d.$2.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
          const Gap(12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF1E3A5F)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add the chips: ${sum.toStringAsFixed(1)}',
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 12,
                  ),
                ),
                const Gap(4),
                Text(
                  'Divide by 10 skills: ${sum.toStringAsFixed(1)} / 10 = ${fromDims.toStringAsFixed(1)}',
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 12,
                  ),
                ),
                const Gap(6),
                Text(
                  'Your session overall: ${sessionOverall.toStringAsFixed(1)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCsatAndAhtCard() {
    final withCsat = evaluations.where((e) => e.customerRating != null).toList();
    final withAht = evaluations.where((e) => e.ahtHandleSeconds != null).toList();
    final avgCsat = withCsat.isEmpty
        ? null
        : withCsat.map((e) => e.customerRating!.toDouble()).reduce((a, b) => a + b) /
            withCsat.length;
    final avgAht = withAht.isEmpty
        ? null
        : withAht.map((e) => e.ahtHandleSeconds!).reduce((a, b) => a + b) /
            withAht.length;
    final overCount = evaluations.where((e) => e.ahtOverLimit).length;

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
          const Row(
            children: [
              Icon(Icons.star_rate_rounded, color: Color(0xFFFBBF24), size: 20),
              Gap(8),
              Text(
                'CSAT and handle time',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Gap(14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151515),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF2A2A2B)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.sentiment_satisfied_alt_rounded,
                              size: 16, color: Color(0xFFFBBF24)),
                          Gap(6),
                          Text(
                            'CSAT',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const Gap(6),
                      Text(
                        avgCsat == null
                            ? 'Not recorded'
                            : '${avgCsat.toStringAsFixed(1)} / 5',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Gap(4),
                      const Text(
                        'Session average customer stars',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151515),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF2A2A2B)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.timer_outlined,
                              size: 16, color: Color(0xFF60A5FA)),
                          Gap(6),
                          Text(
                            'AHT',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const Gap(6),
                      Text(
                        avgAht == null
                            ? 'Not recorded'
                            : '${avgAht.toStringAsFixed(0)}s avg',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        'Target ${ScoringTransparency.ahtTargetSeconds}s · $overCount over',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Gap(12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF151515),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2A2A2B)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How CSAT is computed',
                  style: TextStyle(
                    color: Color(0xFFFBBF24),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Gap(4),
                Text(
                  ScoringTransparency.csatFormulaLine,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
                const Gap(10),
                const Text(
                  'How AHT is judged',
                  style: TextStyle(
                    color: Color(0xFF60A5FA),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Gap(4),
                Text(
                  ScoringTransparency.ahtFormulaLine,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
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

  Widget _buildSkillBandDistributionCard() {
    if (evaluations.isEmpty) return const SizedBox.shrink();
    final dims = <(String, double)>[
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
    final counts = <String, int>{
      for (final l in ScoringTransparency.levels) l.label: 0,
    };
    for (final d in dims) {
      final level = ScoringTransparency.levelFor(d.$2);
      counts[level.label] = (counts[level.label] ?? 0) + 1;
    }
    final total = dims.length.toDouble();

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
          const Row(
            children: [
              Icon(Icons.pie_chart_outline_rounded,
                  color: Color(0xFFA78BFA), size: 20),
              Gap(8),
              Text(
                'Skill band mix (session averages)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Gap(6),
          const Text(
            'How many of the 10 skills sit in each performance band.',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
          const Gap(14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  for (final level in ScoringTransparency.levels)
                    if ((counts[level.label] ?? 0) > 0)
                      Expanded(
                        flex: counts[level.label]!,
                        child: Container(color: Color(level.colorValue)),
                      ),
                ],
              ),
            ),
          ),
          const Gap(12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: ScoringTransparency.levels.map((level) {
              final n = counts[level.label] ?? 0;
              final pct = total == 0 ? 0.0 : (n / total) * 100;
              final color = Color(level.colorValue);
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '${level.label}: $n (${pct.toStringAsFixed(0)}%)',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelBandRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performance levels',
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const Gap(8),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 640;
            final children = ScoringTransparency.levels.map((level) {
              final color = Color(level.colorValue);
              return Container(
                width: wide ? null : double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.45)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const Gap(6),
                        Text(
                          level.label,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Gap(6),
                        Text(
                          level.rangeLabel,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const Gap(4),
                    Text(
                      level.meaning,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              );
            }).toList();
            if (wide) {
              return Row(
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0) const Gap(8),
                    Expanded(child: children[i]),
                  ],
                ],
              );
            }
            return Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const Gap(8),
                  children[i],
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  List<SessionEvaluation> get _chatEvals =>
      evaluations.where((e) => e.channel == 'chat').toList();
  List<SessionEvaluation> get _voiceEvals =>
      evaluations.where((e) => e.channel == 'voice').toList();

  Widget _buildSessionAnalysisCard() {
    if (evaluations.isEmpty) {
      return const Text(
        'No customer scores available for analysis.',
        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      );
    }

    final cats = <(String, double Function(SessionEvaluation))>[
      ('Opening Spiel', (e) => e.openingSpielScore),
      ('Positive Scripting', (e) => e.positiveScriptingScore),
      ('Empathy', (e) => e.empathyScore),
      ('Active Listening', (e) => e.activeListeningScore),
      ('Problem Identification', (e) => e.problemIdentificationScore),
      ('Solution Delivery', (e) => e.solutionDeliveryScore),
      ('Communication Clarity', (e) => e.communicationClarityScore),
      ('Tone', (e) => e.toneScore),
      ('Sector Knowledge', (e) => e.sectorKnowledgeScore),
      ('Closing Spiel', (e) => e.closingSpielScore),
    ];
    final avgs = <MapEntry<String, double>>[
      for (final c in cats)
        MapEntry(
          c.$1,
          evaluations.map(c.$2).reduce((a, b) => a + b) / evaluations.length,
        ),
    ];
    avgs.sort((a, b) => b.value.compareTo(a.value));
    final strongest = avgs.first;
    final weakest = avgs.last;

    final strengths = <String>{};
    final gaps = <String>{};
    for (final e in evaluations) {
      for (final s in e.strengths) {
        final t = friendlyEvalText(s);
        if (t.isNotEmpty) strengths.add(t);
      }
      for (final s in e.areasForImprovement) {
        final t = friendlyEvalText(s);
        if (t.isNotEmpty) gaps.add(t);
      }
    }

    final passBar = 7.0;
    final passCount =
        evaluations.where((e) => displayScore10(e.overallScore) >= passBar).length;
    final passRate = passCount / evaluations.length;
    final avg = _averageOverall;

    Color levelColor(double s) {
      if (s >= 8.5) return const Color(0xFF70BD8A);
      if (s >= 7) return const Color(0xFF3B82F6);
      if (s >= 5) return const Color(0xFFF59E0B);
      return const Color(0xFFEF4444);
    }

    Widget sideCard({
      required Color accent,
      required IconData icon,
      required String title,
      required List<String> items,
    }) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF151515),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2A2B)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: accent),
                  const Gap(6),
                  Text(
                    title,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const Gap(10),
              if (items.isEmpty)
                const Text(
                  'None logged for this session.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                )
              else
                ...items.take(4).map(
                      (text) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(icon, size: 13, color: accent),
                            ),
                            const Gap(6),
                            Expanded(
                              child: Text(
                                text,
                                style: const TextStyle(
                                  color: Color(0xFFCBD5E1),
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 21, 21, 21),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color.fromARGB(255, 42, 42, 43)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This session averaged ${avg.toStringAsFixed(1)} overall with ${(passRate * 100).toStringAsFixed(0)}% of customers at or above the 7.0 practice pass mark ($passCount of ${evaluations.length}).',
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const Gap(12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151515),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2A2A2B)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        ScoringTransparency.iconFor(strongest.key),
                        color: levelColor(strongest.value),
                        size: 18,
                      ),
                      const Gap(10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Strongest skill',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              strongest.key,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        strongest.value.toStringAsFixed(1),
                        style: TextStyle(
                          color: levelColor(strongest.value),
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151515),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2A2A2B)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        ScoringTransparency.iconFor(weakest.key),
                        color: levelColor(weakest.value),
                        size: 18,
                      ),
                      const Gap(10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Focus skill',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              weakest.key,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        weakest.value.toStringAsFixed(1),
                        style: TextStyle(
                          color: levelColor(weakest.value),
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Gap(12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sideCard(
                accent: const Color(0xFF70BD8A),
                icon: Icons.check_circle_outline_rounded,
                title: 'What went well',
                items: strengths.toList(),
              ),
              const Gap(10),
              sideCard(
                accent: const Color(0xFFF59E0B),
                icon: Icons.flag_outlined,
                title: 'Focus next',
                items: gaps.toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerLists(BuildContext context) {
    final hasMixedChannels = _chatEvals.isNotEmpty && _voiceEvals.isNotEmpty;
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

    if (hasMixedChannels) {
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
    List<SessionEvaluation> items, {
    bool showTitle = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const Gap(10),
        ],
        ...items.asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          final score = displayScore10(e.overallScore);
          final level = score >= 8.5
              ? 'Excellent'
              : score >= 7
                  ? 'Good'
                  : score >= 5
                      ? 'Developing'
                      : 'Needs work';
          final levelColor = score >= 8.5
              ? const Color(0xFF70BD8A)
              : score >= 7
                  ? const Color(0xFF3B82F6)
                  : score >= 5
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFFEF4444);
          final topStrength = e.strengths.isNotEmpty
              ? friendlyEvalText(e.strengths.first)
              : '';
          final topGap = e.areasForImprovement.isNotEmpty
              ? friendlyEvalText(e.areasForImprovement.first)
              : '';
          final displayName = e.customerName.isEmpty
              ? 'Customer ${i + 1}'
              : friendlyCustomerName(e.customerName);
          final initial = displayName.isNotEmpty
              ? displayName.trim()[0].toUpperCase()
              : '?';
          final isVoice = e.channel.toLowerCase() == 'voice';

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              mouseCursor: SystemMouseCursors.click,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        CustomerReportDetailScreen(evaluation: e),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 21, 21, 21),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color.fromARGB(255, 42, 42, 43),
                  ),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: levelColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(13),
                            bottomLeft: Radius.circular(13),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: levelColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color:
                                            levelColor.withValues(alpha: 0.35),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      initial,
                                      style: TextStyle(
                                        color: levelColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  const Gap(12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                        if (e.problem.isNotEmpty) ...[
                                          const Gap(2),
                                          Text(
                                            e.problem,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Color(0xFF94A3B8),
                                              fontSize: 12,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const Gap(10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            score.toStringAsFixed(1),
                                            style: TextStyle(
                                              color: levelColor,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 20,
                                              height: 1,
                                            ),
                                          ),
                                          const Gap(2),
                                          const Text(
                                            '/10',
                                            style: TextStyle(
                                              color: Color(0xFF64748B),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Gap(4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: levelColor.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(color: levelColor),
                                        ),
                                        child: Text(
                                          level,
                                          style: TextStyle(
                                            color: levelColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Gap(6),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Color(0xFF64748B),
                                    size: 20,
                                  ),
                                ],
                              ),
                              const Gap(12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  _iconBadge(
                                    isVoice
                                        ? Icons.mic_rounded
                                        : Icons.chat_bubble_outline_rounded,
                                    isVoice ? 'VOICE' : 'CHAT',
                                    isVoice
                                        ? const Color(0xFF70BD8A)
                                        : const Color(0xFF3B82F6),
                                  ),
                                  if (e.sector.isNotEmpty)
                                    _iconBadge(
                                      Icons.category_outlined,
                                      e.sector,
                                      const Color(0xFF9CA3AF),
                                    ),
                                  if (e.ahtHandleSeconds != null)
                                    _iconBadge(
                                      Icons.timer_outlined,
                                      e.ahtOverLimit ? 'AHT over' : 'AHT ok',
                                      e.ahtOverLimit
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFF70BD8A),
                                    ),
                                  if (e.customerRating != null)
                                    _iconBadge(
                                      Icons.star_rounded,
                                      'CSAT ${e.customerRating}/5',
                                      const Color(0xFFFBBF24),
                                    ),
                                ],
                              ),
                              if (e.customerComment != null &&
                                  e.customerComment!.isNotEmpty) ...[
                                const Gap(10),
                                Text(
                                  '"${e.customerComment}"',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFCBD5E1),
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                              const Gap(12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (score / 10).clamp(0.0, 1.0),
                                  minHeight: 6,
                                  backgroundColor: const Color(0xFF2A2A2A),
                                  color: levelColor,
                                ),
                              ),
                              if (topStrength.isNotEmpty ||
                                  topGap.isNotEmpty) ...[
                                const Gap(10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF151515),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF2A2A2B),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (topStrength.isNotEmpty)
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Icon(
                                              Icons.check_circle_outline,
                                              size: 14,
                                              color: Color(0xFF70BD8A),
                                            ),
                                            const Gap(6),
                                            Expanded(
                                              child: Text.rich(
                                                TextSpan(
                                                  children: [
                                                    const TextSpan(
                                                      text: 'Strength: ',
                                                      style: TextStyle(
                                                        color:
                                                            Color(0xFF70BD8A),
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        height: 1.35,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: topStrength,
                                                      style: const TextStyle(
                                                        color:
                                                            Color(0xFF70BD8A),
                                                        fontSize: 12,
                                                        height: 1.35,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      if (topStrength.isNotEmpty &&
                                          topGap.isNotEmpty)
                                        const Gap(6),
                                      if (topGap.isNotEmpty)
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Icon(
                                              Icons.flag_outlined,
                                              size: 14,
                                              color: Color(0xFFF59E0B),
                                            ),
                                            const Gap(6),
                                            Expanded(
                                              child: Text.rich(
                                                TextSpan(
                                                  children: [
                                                    const TextSpan(
                                                      text: 'Focus next: ',
                                                      style: TextStyle(
                                                        color:
                                                            Color(0xFFF59E0B),
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        height: 1.35,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: topGap,
                                                      style: const TextStyle(
                                                        color:
                                                            Color(0xFFF59E0B),
                                                        fontSize: 12,
                                                        height: 1.35,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _iconBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const Gap(4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreRing({
    required double score,
    required Color color,
    double size = 120,
    double stroke = 10,
  }) {
    return reportScoreRing(
      score: score,
      color: color,
      size: size,
      stroke: stroke,
    );
  }

  Widget _buildHeroOverallCard() {
    final avgScore = _averageOverall;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 28, 28, 28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color.fromARGB(255, 42, 42, 43)),
      ),
      child: Row(
        children: [
          _scoreRing(
            score: evaluations.isEmpty ? 0 : avgScore,
            color: _performanceColor,
            size: 124,
            stroke: 11,
          ),
          const Gap(22),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.guidedMode
                            ? const Color(0xFF3B82F6).withValues(alpha: 0.12)
                            : const Color(0xFFA78BFA).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: widget.guidedMode
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFFA78BFA),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.guidedMode
                                ? Icons.menu_book_outlined
                                : Icons.school_outlined,
                            size: 12,
                            color: widget.guidedMode
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFFA78BFA),
                          ),
                          const Gap(4),
                          Text(
                            widget.guidedMode ? 'Guided' : 'Unguided',
                            style: TextStyle(
                              color: widget.guidedMode
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFFA78BFA),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                  'Mean of the 10 skill averages this session. Open Scoring guide for the full formula.',
                  style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 12,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Each skill starts at 10. Score = 10 minus observed gaps. Open a skill card for deductions, evidence, and a stronger line.',
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12,
            height: 1.35,
          ),
        ),
        const Gap(12),
        if (evaluations.isEmpty)
          const Text(
            'No evaluations recorded for this session.',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 700;
              final cards = categories.map((c) {
                final val = c.$2;
                final level = ScoringTransparency.levelFor(val);
                final dim = ScoringTransparency.byLabel(c.$1);
                final color = Color(level.colorValue);
                final meaning = dim?.criterionForScore(val) ?? level.meaning;
                final evidence = _evidenceForDimension(c.$1);
                final suggestions = _suggestionsForDimension(c.$1);
                return _buildRubricDataRow(
                  label: c.$1,
                  score: val,
                  levelLabel: level.label,
                  meaning: meaning,
                  color: color,
                  gapExamples: dim?.gapExamples,
                  deductionAnchors: dim?.deductionAnchors ?? const [],
                  sourceNote: dim?.sourceNote ?? '',
                  evidenceNotes: evidence,
                  suggestions: suggestions,
                );
              }).toList();
              if (!wide) {
                return Column(children: cards);
              }
              final rows = <Widget>[];
              for (var i = 0; i < cards.length; i += 2) {
                rows.add(
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: cards[i]),
                      const Gap(10),
                      Expanded(
                        child: i + 1 < cards.length
                            ? cards[i + 1]
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                );
                if (i + 2 < cards.length) rows.add(const Gap(10));
              }
              return Column(children: rows);
            },
          ),
      ],
    );
  }

  List<String> _noteKeysFor(String label) {
    switch (label) {
      case 'Tone':
        return ['Tone', 'Tone & Inflection', 'TONE_AND_INFLECTION'];
      case 'Communication Clarity':
        return [
          'Communication Clarity',
          'Spoken Clarity',
          'Pronunciation & Clarity',
          'PRONUNCIATION_AND_CLARITY',
        ];
      case 'Spoken Clarity':
        return ['Spoken Clarity', 'SPOKEN_CLARITY', 'Communication Clarity'];
      case 'Pronunciation':
        return [
          'Pronunciation',
          'PRONUNCIATION',
          'Pronunciation & Clarity',
          'PRONUNCIATION_AND_CLARITY',
        ];
      case 'Diction':
        return ['Diction', 'DICTION'];
      case 'Confidence':
        return ['Confidence', 'CONFIDENCE'];
      case 'Pace & Speed':
        return ['Pace & Speed', 'PACE_AND_SPEED'];
      case 'Filler Word Usage':
        return ['Filler Word Usage', 'FILLER_WORD_USAGE'];
      case 'Grammar':
        return ['Grammar', 'GRAMMAR'];
      case 'Correct Word Use':
        return ['Correct Word Use', 'CORRECT_WORD_USE'];
      case 'Error Rate & Accuracy':
        return ['Error Rate & Accuracy', 'ERROR_RATE_AND_ACCURACY'];
      case 'Typing Speed':
        return ['Typing Speed', 'TYPING_SPEED_WPM'];
      default:
        return [label];
    }
  }

  String? _lookupMap(Map<String, String>? map, String label) {
    if (map == null || map.isEmpty) return null;
    for (final key in _noteKeysFor(label)) {
      final v = map[key];
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  List<String> _evidenceForDimension(String label) {
    final out = <String>[];
    for (final e in evaluations) {
      final note = _lookupMap(e.categoryNotes, label);
      if (note == null) continue;
      if (note.toLowerCase() == 'full marks') continue;
      final quote = _lookupMap(e.categoryQuotes, label);
      final name = e.customerName.isEmpty
          ? 'Customer'
          : friendlyCustomerName(e.customerName);
      final line = quote != null && quote.isNotEmpty
          ? '$name: $note (from: "$quote")'
          : '$name: $note';
      out.add(line);
      if (out.length >= 3) break;
    }
    return out;
  }

  List<String> _suggestionsForDimension(String label) {
    final out = <String>[];
    for (final e in evaluations) {
      final s = _lookupMap(e.categorySuggestions, label);
      if (s == null) continue;
      if (s.toUpperCase() == 'N/A') continue;
      out.add(s);
      if (out.length >= 2) break;
    }
    return out;
  }

  Widget _buildRubricDataRow({
    required String label,
    required double score,
    required String levelLabel,
    required String meaning,
    required Color color,
    String? gapExamples,
    List<String> deductionAnchors = const [],
    String sourceNote = '',
    List<String> evidenceNotes = const [],
    List<String> suggestions = const [],
  }) {
    final deducted = ScoringTransparency.deductedFromTen(score);
    final icon = ScoringTransparency.iconFor(label);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Gap(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Gap(2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withValues(alpha: 0.45)),
                      ),
                      child: Text(
                        levelLabel,
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _scoreRing(score: score, color: color, size: 54, stroke: 5),
            ],
          ),
          const Gap(8),
          Text(
            meaning,
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const Gap(10),
          _buildSegmentedScoreBar(score: score, color: color),
          const Gap(8),
          Text(
            deducted < 0.05
                ? 'Started at 10.0 · no gaps · score ${score.toStringAsFixed(1)}'
                : 'Started at 10.0 · removed ${deducted.toStringAsFixed(1)} for observed gaps · score ${score.toStringAsFixed(1)}',
            style: TextStyle(
              color: deducted < 0.05
                  ? const Color(0xFF10B981)
                  : const Color(0xFFE2E8F0),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (deductionAnchors.isNotEmpty) ...[
            const Gap(8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1F2937)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Possible deductions for this skill',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  const Gap(6),
                  ...deductionAnchors.map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        a,
                        style: const TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 11,
                          height: 1.35,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                  if (sourceNote.isNotEmpty) ...[
                    const Gap(4),
                    Text(
                      'Source: $sourceNote',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                        height: 1.35,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (evidenceNotes.isNotEmpty || suggestions.isNotEmpty) ...[
            const Gap(8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (evidenceNotes.isNotEmpty) ...[
                    const Text(
                      'Why points were removed',
                      style: TextStyle(
                        color: Color(0xFF93C5FD),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Gap(6),
                    ...evidenceNotes.map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          line,
                          style: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (suggestions.isNotEmpty) ...[
                    if (evidenceNotes.isNotEmpty) const Gap(8),
                    const Text(
                      'Try a stronger line',
                      style: TextStyle(
                        color: Color(0xFF34D399),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Gap(6),
                    ...suggestions.map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '"$line"',
                          style: const TextStyle(
                            color: Color(0xFFA7F3D0),
                            fontSize: 12,
                            height: 1.35,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else if (deducted >= 0.05) ...[
            const Gap(8),
            Text(
              gapExamples != null && gapExamples.isNotEmpty
                  ? 'No evaluator note was stored for this skill average. Typical gaps: $gapExamples Run a new session after this update to capture line-level evidence and a suggested rewrite.'
                  : 'No evaluator note was stored for this skill average. Run a new session after this update to capture evidence and a suggested rewrite.',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSegmentedScoreBar({
    required double score,
    required Color color,
  }) {
    final s = score.clamp(0.0, 10.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final markerX = (s / 10.0) * width;
        return Column(
          children: [
            SizedBox(
              height: 22,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 7,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 50,
                          child: Container(
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF7F1D1D),
                              borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(5),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 20,
                          child: Container(
                            height: 10,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                        Expanded(
                          flex: 20,
                          child: Container(
                            height: 10,
                            color: const Color(0xFF1D4ED8),
                          ),
                        ),
                        Expanded(
                          flex: 10,
                          child: Container(
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF047857),
                              borderRadius: BorderRadius.horizontal(
                                right: Radius.circular(5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: (markerX - 1).clamp(0.0, width - 2),
                    top: 0,
                    child: Container(
                      width: 2,
                      height: 22,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  Positioned(
                    left: (markerX - 9).clamp(0.0, width - 18),
                    top: 2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.55),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                          BoxShadow(
                            color: color.withValues(alpha: 0.55),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        s.toStringAsFixed(s == s.roundToDouble() ? 0 : 1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(4),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0', style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                Text('5', style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                Text('7', style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                Text('9', style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                Text('10', style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
              ],
            ),
          ],
        );
      },
    );
  }

  bool get _hasChatChannel =>
      evaluations.any((e) => e.channel.toLowerCase() == 'chat');

  bool get _hasVoiceChannel =>
      evaluations.any((e) => e.channel.toLowerCase() == 'voice');

  double? _avgOptional(double? Function(SessionEvaluation e) pick) {
    final vals = evaluations.map(pick).whereType<double>().toList();
    if (vals.isEmpty) return null;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  Widget _buildChannelSkillScoresCard() {
    final voiceRows = <(String, double?)>[
      ('Tone', _avgOptional((e) => e.channel == 'voice' ? e.toneScore : null)),
      (
        'Confidence',
        _avgOptional((e) => e.channel == 'voice' ? e.confidenceScore : null),
      ),
      (
        'Spoken Clarity',
        _avgOptional(
          (e) => e.channel == 'voice' ? e.communicationClarityScore : null,
        ),
      ),
      (
        'Diction',
        _avgOptional((e) => e.channel == 'voice' ? e.dictionScore : null),
      ),
      (
        'Pronunciation',
        _avgOptional(
          (e) => e.channel == 'voice' ? e.pronunciationClarityScore : null,
        ),
      ),
      (
        'Pace & Speed',
        _avgOptional((e) => e.channel == 'voice' ? e.paceAndSpeedScore : null),
      ),
      (
        'Filler Word Usage',
        _avgOptional(
          (e) => e.channel == 'voice' ? e.fillerWordUsageScore : null,
        ),
      ),
    ];
    final chatRows = <(String, double?)>[
      (
        'Grammar',
        _avgOptional((e) => e.channel == 'chat' ? e.grammarScore : null),
      ),
      (
        'Correct Word Use',
        _avgOptional((e) => e.channel == 'chat' ? e.wordChoiceScore : null),
      ),
      (
        'Communication Clarity',
        _avgOptional(
          (e) => e.channel == 'chat' ? e.communicationClarityScore : null,
        ),
      ),
      (
        'Error Rate & Accuracy',
        _avgOptional(
          (e) => e.channel == 'chat' ? e.errorRateAccuracyScore : null,
        ),
      ),
      (
        'Typing Speed',
        _avgOptional((e) => e.channel == 'chat' ? e.typingSpeedScore : null),
      ),
    ];
    final showVoice = _hasVoiceChannel && voiceRows.any((r) => r.$2 != null);
    final showChat = _hasChatChannel && chatRows.any((r) => r.$2 != null);
    if (!showVoice && !showChat) return const SizedBox.shrink();

    Widget rubricCards(List<(String, double?)> rows) {
      final cards = <Widget>[];
      for (final r in rows) {
        final score = r.$2;
        if (score == null) continue;
        final val = displayScore10(score);
        final level = ScoringTransparency.levelFor(val);
        final dim = ScoringTransparency.byLabel(r.$1);
        final color = Color(level.colorValue);
        final meaning = dim?.criterionForScore(val) ?? level.meaning;
        cards.add(
          _buildRubricDataRow(
            label: r.$1,
            score: val,
            levelLabel: level.label,
            meaning: meaning,
            color: color,
            gapExamples: dim?.gapExamples,
            deductionAnchors: dim?.deductionAnchors ?? const [],
            sourceNote: dim?.sourceNote ?? '',
            evidenceNotes: _evidenceForDimension(r.$1),
            suggestions: _suggestionsForDimension(r.$1),
          ),
        );
      }
      if (cards.isEmpty) return const SizedBox.shrink();
      return LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 700;
          if (!wide) return Column(children: cards);
          final rowsOut = <Widget>[];
          for (var i = 0; i < cards.length; i += 2) {
            rowsOut.add(
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cards[i]),
                  const Gap(10),
                  Expanded(
                    child: i + 1 < cards.length
                        ? cards[i + 1]
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            );
            if (i + 2 < cards.length) rowsOut.add(const Gap(10));
          }
          return Column(children: rowsOut);
        },
      );
    }

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
              Icon(Icons.tune_rounded, color: Color(0xFFA78BFA), size: 20),
              Gap(8),
              Text(
                'Channel skill scores',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Gap(8),
          const Text(
            'Separate from the 10 shared overall dimensions. Each card starts at 10 with deductions for observed gaps. Open a card for criteria, deductions, evidence, and a stronger line.',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          if (showVoice) ...[
            const Gap(16),
            const Row(
              children: [
                Icon(Icons.mic_rounded, size: 16, color: Color(0xFF70BD8A)),
                Gap(6),
                Text(
                  'Voice delivery',
                  style: TextStyle(
                    color: Color(0xFF70BD8A),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const Gap(10),
            rubricCards(voiceRows),
          ],
          if (showChat) ...[
            const Gap(16),
            const Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 16,
                  color: Color(0xFF3B82F6),
                ),
                Gap(6),
                Text(
                  'Non-Voice language',
                  style: TextStyle(
                    color: Color(0xFF3B82F6),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const Gap(10),
            rubricCards(chatRows),
          ],
        ],
      ),
    );
  }

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
            const Gap(8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF151515),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2A2A2B)),
              ),
              child: Text(
                averageWpm == null
                    ? 'Formula: WPM = (words spoken / speaking seconds) x 60, averaged across turns. Recommended band 130-160.'
                    : 'Formula: WPM = (words spoken / speaking seconds) x 60, averaged across turns.\n'
                        'This session average: ${averageWpm!.toStringAsFixed(0)} WPM (recommended 130-160).',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
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
            const Gap(8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF151515),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2A2A2B)),
              ),
              child: Text(
                averageTypingWpm == null
                    ? 'Formula: WPM = (words in message / seconds typing) x 60. Averaged across typed messages. Paste and jumps above 120 WPM are excluded so copy-paste does not inflate the average.'
                    : 'Formula: WPM = (words in message / seconds typing) x 60, then average across typed messages.\n'
                        'This session average: ${averageTypingWpm!.toStringAsFixed(0)} WPM.\n'
                        'Paste and single inserts of 12+ characters are treated as paste; samples above 120 WPM are excluded from the average.',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
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
                'Tool use and follow-through; identity only when the case needs an account',
          ),
          const Gap(8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF151515),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2A2A2B)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AttentivenessBreakdown.formulaLine,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
                if (attentivenessBreakdown != null) ...[
                  const Gap(8),
                  Text(
                    'This session: ${attentivenessBreakdown!.earnedPoints.toStringAsFixed(1)} / ${attentivenessBreakdown!.maxPoints.toStringAsFixed(1)} points = ${attentivenessBreakdown!.percent.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(10),
                  ...attentivenessBreakdown!.items.map((item) {
                    final color = item.earned
                        ? const Color(0xFF34D399)
                        : const Color(0xFFF87171);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            item.earned ? Icons.check_circle : Icons.cancel,
                            size: 16,
                            color: color,
                          ),
                          const Gap(8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.label} (${item.weight} pt${item.weight == 1 ? '' : 's'})',
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  item.detail,
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 11,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ] else if (multitaskingScore != null) ...[
                  const Gap(6),
                  const Text(
                    'Detailed step list was not retained for this session. Percentage still reflects tools, completion, and optional notes.',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
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
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                const Gap(2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color.fromARGB(255, 119, 130, 145),
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Bottom action buttons navigation
  Widget _buildBottomActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            final back = widget.onBackToMenu;
            if (back != null) {
              back();
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
            final startAnother = widget.onStartAnotherSession;
            if (startAnother != null) {
              startAnother();
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

Widget _buildCustomerGeneralAnalysis(SessionEvaluation e) {
  final score = displayScore10(e.overallScore);
  final level = score >= 8.5
      ? 'Excellent'
      : score >= 7
          ? 'Good'
          : score >= 5
              ? 'Developing'
              : 'Needs work';
  final cats = <(String, double)>[
    ('Opening Spiel', e.openingSpielScore),
    ('Positive Scripting', e.positiveScriptingScore),
    ('Empathy', e.empathyScore),
    ('Active Listening', e.activeListeningScore),
    ('Problem Identification', e.problemIdentificationScore),
    ('Solution Delivery', e.solutionDeliveryScore),
    ('Communication Clarity', e.communicationClarityScore),
    ('Tone', e.toneScore),
    ('Sector Knowledge', e.sectorKnowledgeScore),
    ('Closing Spiel', e.closingSpielScore),
  ]..sort((a, b) => b.$2.compareTo(a.$2));
  final strongest = cats.first;
  final weakest = cats.last;
  final summary = score >= 8.5
      ? 'Strong handling overall. Keep the habits that earned $level marks and tighten the weakest skill.'
      : score >= 7
          ? 'Solid practice result. A few skills still sit below the strongest ones; focus those next.'
          : score >= 5
              ? 'Mixed result. Prioritize the focus skill below and re-run a similar customer when ready.'
              : 'Early-stage result. Review the Script Guide for the focus skill, then try another guided customer.';

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color.fromARGB(255, 21, 21, 21),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color.fromARGB(255, 42, 42, 43)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.psychology_outlined, size: 18, color: Color(0xFF0EA5E9)),
            Gap(8),
            Text(
              'General analysis',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const Gap(8),
        Text(
          summary,
          style: const TextStyle(
            color: Color(0xFFCBD5E1),
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const Gap(10),
        Row(
          children: [
            Icon(
              ScoringTransparency.iconFor(strongest.$1),
              size: 16,
              color: const Color(0xFF70BD8A),
            ),
            const Gap(6),
            Expanded(
              child: Text(
                'Strongest: ${strongest.$1} (${strongest.$2.toStringAsFixed(1)})',
                style: const TextStyle(
                  color: Color(0xFF70BD8A),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              ScoringTransparency.iconFor(weakest.$1),
              size: 16,
              color: const Color(0xFFF59E0B),
            ),
            const Gap(6),
            Expanded(
              child: Text(
                'Focus: ${weakest.$1} (${weakest.$2.toStringAsFixed(1)})',
                style: const TextStyle(
                  color: Color(0xFFF59E0B),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildDetailFocusRow(SessionEvaluation e) {
  final strengths = e.strengths
      .map(friendlyEvalText)
      .where((s) => s.isNotEmpty)
      .toList();
  final gaps = e.areasForImprovement
      .map(friendlyEvalText)
      .where((s) => s.isNotEmpty)
      .toList();
  if (strengths.isEmpty && gaps.isEmpty) {
    return const SizedBox.shrink();
  }

  Widget card({
    required Color accent,
    required IconData icon,
    required String title,
    required List<String> items,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 21, 21, 21),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color.fromARGB(255, 42, 42, 43)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: accent),
                ),
                const Gap(8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(10),
            if (items.isEmpty)
              const Text(
                'None highlighted for this customer.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  height: 1.35,
                ),
              )
            else
              ...items.take(4).map(
                    (text) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(
                              icon,
                              size: 13,
                              color: accent.withValues(alpha: 0.85),
                            ),
                          ),
                          const Gap(6),
                          Expanded(
                            child: Text(
                              text,
                              style: const TextStyle(
                                color: Color(0xFFCBD5E1),
                                fontSize: 12,
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
      ),
    );
  }

  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      card(
        accent: const Color(0xFF70BD8A),
        icon: Icons.check_circle_outline_rounded,
        title: 'What went well',
        items: strengths,
      ),
      const Gap(12),
      card(
        accent: const Color(0xFFF59E0B),
        icon: Icons.flag_outlined,
        title: 'Focus next',
        items: gaps,
      ),
    ],
  );
}

class _DetailIconBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _DetailIconBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const Gap(4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
    final suggestions = e.categorySuggestions ?? {};
    String pickNote(String label) {
      if ((notes[label] ?? '').isNotEmpty) return notes[label]!;
      if (label == 'Tone') return notes['Tone & Inflection'] ?? '';
      return '';
    }

    String pickQuote(String label) {
      if ((quotes[label] ?? '').isNotEmpty) return quotes[label]!;
      if (label == 'Tone') return quotes['Tone & Inflection'] ?? '';
      return '';
    }

    String pickSuggest(String label) {
      if ((suggestions[label] ?? '').isNotEmpty) return suggestions[label]!;
      if (label == 'Tone') return suggestions['Tone & Inflection'] ?? '';
      return '';
    }

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
          e.customerName.isEmpty
              ? 'Customer detail'
              : friendlyCustomerName(e.customerName),
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
          Builder(
            builder: (context) {
              final score = displayScore10(e.overallScore);
              final level = score >= 8.5
                  ? 'Excellent'
                  : score >= 7
                      ? 'Good'
                      : score >= 5
                          ? 'Developing'
                          : 'Needs work';
              final levelColor = score >= 8.5
                  ? const Color(0xFF70BD8A)
                  : score >= 7
                      ? const Color(0xFF3B82F6)
                      : score >= 5
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFFEF4444);
              final isVoice = e.channel.toLowerCase() == 'voice';
              return Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 21, 21, 21),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color.fromARGB(255, 42, 42, 43),
                  ),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 5,
                        decoration: BoxDecoration(
                          color: levelColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(15),
                            bottomLeft: Radius.circular(15),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  reportScoreRing(
                                    score: score,
                                    color: levelColor,
                                    size: 72,
                                    stroke: 7,
                                  ),
                                  const Gap(14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: levelColor.withValues(
                                                  alpha: 0.15,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: levelColor,
                                                ),
                                              ),
                                              child: Text(
                                                level.toUpperCase(),
                                                style: TextStyle(
                                                  color: levelColor,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.6,
                                                ),
                                              ),
                                            ),
                                            const Gap(8),
                                            const Text(
                                              'This customer',
                                              style: TextStyle(
                                                color: Color(0xFF64748B),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Gap(8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.analytics_outlined,
                                              size: 18,
                                              color: levelColor,
                                            ),
                                            const Gap(8),
                                            Text(
                                              'Overall',
                                              style: TextStyle(
                                                color: Color(0xFF94A3B8),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const Gap(8),
                                            Text(
                                              score.toStringAsFixed(1),
                                              style: TextStyle(
                                                color: levelColor,
                                                fontSize: 26,
                                                fontWeight: FontWeight.w800,
                                                height: 1,
                                              ),
                                            ),
                                            const Text(
                                              ' / 10',
                                              style: TextStyle(
                                                color: Color(0xFF64748B),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if (e.customerRating != null) ...[
                                              const Gap(14),
                                              Container(
                                                width: 1,
                                                height: 22,
                                                color: const Color(0xFF2A2A2B),
                                              ),
                                              const Gap(14),
                                              const Icon(
                                                Icons.star_rounded,
                                                size: 20,
                                                color: Color(0xFFFBBF24),
                                              ),
                                              const Gap(6),
                                              const Text(
                                                'CSAT',
                                                style: TextStyle(
                                                  color: Color(0xFF94A3B8),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const Gap(6),
                                              Text(
                                                '${e.customerRating}/5',
                                                style: const TextStyle(
                                                  color: Color(0xFFFBBF24),
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w800,
                                                  height: 1,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const Gap(14),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          children: [
                                            _DetailIconBadge(
                                              icon: isVoice
                                                  ? Icons.mic_rounded
                                                  : Icons
                                                      .chat_bubble_outline_rounded,
                                              label: isVoice ? 'VOICE' : 'CHAT',
                                              color: isVoice
                                                  ? const Color(0xFF70BD8A)
                                                  : const Color(0xFF3B82F6),
                                            ),
                                            if (e.sector.isNotEmpty)
                                              _DetailIconBadge(
                                                icon: Icons.category_outlined,
                                                label: e.sector,
                                                color: const Color(0xFF9CA3AF),
                                              ),
                                            if (e.ahtHandleSeconds != null)
                                              _DetailIconBadge(
                                                icon: Icons.timer_outlined,
                                                label: e.ahtOverLimit
                                                    ? 'AHT over'
                                                    : 'AHT ok',
                                                color: e.ahtOverLimit
                                                    ? const Color(0xFFEF4444)
                                                    : const Color(0xFF70BD8A),
                                              ),
                                            if (e.customerRating != null)
                                              _DetailIconBadge(
                                                icon: Icons.star_rounded,
                                                label:
                                                    'CSAT ${e.customerRating}/5',
                                                color: const Color(0xFFFBBF24),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (e.problem.isNotEmpty) ...[
                                const Gap(14),
                                Text(
                                  e.problem,
                                  style: const TextStyle(
                                    color: Color(0xFFCBD5E1),
                                    fontSize: 13,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                              if (e.customerComment != null &&
                                  e.customerComment!.isNotEmpty) ...[
                                const Gap(12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF151515),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF2A2A2B),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.format_quote_rounded,
                                        size: 18,
                                        color: Color(0xFFFBBF24),
                                      ),
                                      const Gap(8),
                                      Expanded(
                                        child: Text(
                                          e.customerComment!,
                                          style: const TextStyle(
                                            color: Color(0xFFFBBF24),
                                            fontSize: 13,
                                            fontStyle: FontStyle.italic,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
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
                              const Gap(14),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF151515),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: const Color(0xFF2A2A2B),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(
                                                Icons.star_rate_rounded,
                                                size: 15,
                                                color: Color(0xFFFBBF24),
                                              ),
                                              Gap(6),
                                              Text(
                                                'CSAT formula',
                                                style: TextStyle(
                                                  color: Color(0xFFFBBF24),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Gap(6),
                                          Text(
                                            ScoringTransparency.csatFormulaLine,
                                            style: const TextStyle(
                                              color: Color(0xFF94A3B8),
                                              fontSize: 11,
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (e.ahtHandleSeconds != null) ...[
                                    const Gap(10),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF151515),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: const Color(0xFF2A2A2B),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.timer_outlined,
                                                  size: 15,
                                                  color: e.ahtOverLimit
                                                      ? const Color(0xFFEF4444)
                                                      : const Color(0xFF60A5FA),
                                                ),
                                                const Gap(6),
                                                Text(
                                                  'AHT for this customer',
                                                  style: TextStyle(
                                                    color: e.ahtOverLimit
                                                        ? const Color(
                                                            0xFFEF4444)
                                                        : const Color(
                                                            0xFF60A5FA),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const Gap(6),
                                            Text(
                                              '${e.ahtHandleSeconds!.toStringAsFixed(0)}s handle time · target ${ScoringTransparency.ahtTargetSeconds}s · ${e.ahtOverLimit ? "over target (can lower CSAT by 1 star)" : "within target"}.\n${ScoringTransparency.ahtFormulaLine}',
                                              style: const TextStyle(
                                                color: Color(0xFF94A3B8),
                                                fontSize: 11,
                                                height: 1.35,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const Gap(14),
          _buildCustomerGeneralAnalysis(e),
          const Gap(12),
          _buildDetailFocusRow(e),
          const Gap(14),
          const Row(
            children: [
              Icon(Icons.grid_view_rounded, color: Color(0xFFA78BFA), size: 18),
              Gap(8),
              Text(
                'Skill scores',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              Gap(8),
              Text(
                'Tap a skill for details',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Gap(8),
          ...categories.map((c) {
            final note = pickNote(c.key);
            final quote = pickQuote(c.key);
            final suggest = pickSuggest(c.key);
            final dim = ScoringTransparency.byLabel(c.key);
            final scoreLevel = ScoringTransparency.levelFor(c.value);
            final color = Color(scoreLevel.colorValue);
            final level = scoreLevel.label;
            final fallback =
                dim?.criterionForScore(c.value) ?? scoreLevel.meaning;
            final hasDetail = note.isNotEmpty ||
                quote.isNotEmpty ||
                suggest.isNotEmpty ||
                (dim != null && dim.deductionAnchors.isNotEmpty);
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 21, 21, 21),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color.fromARGB(255, 42, 42, 43),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Theme(
                  data: ThemeData(
                    dividerColor: Colors.transparent,
                    splashColor: color.withValues(alpha: 0.08),
                    highlightColor: color.withValues(alpha: 0.05),
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    childrenPadding:
                        const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    iconColor: const Color(0xFF64748B),
                    collapsedIconColor: const Color(0xFF64748B),
                    initiallyExpanded: true,
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          ScoringTransparency.iconFor(c.key),
                          color: color,
                          size: 16,
                        ),
                      ),
                      const Gap(10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.key,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const Gap(2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: color),
                              ),
                              child: Text(
                                level,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(8),
                      Text(
                        c.value.toStringAsFixed(1),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const Text(
                        ' /10',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: (c.value / 10).clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: const Color(0xFF2A2A2A),
                        color: color,
                      ),
                    ),
                  ),
                  children: [
                    if (dim != null) ...[
                      Text(
                        dim.short,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                      const Gap(8),
                    ],
                    Text(
                      friendlyEvalText(note.isNotEmpty ? note : fallback),
                      style: const TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    if (dim != null && dim.deductionAnchors.isNotEmpty) ...[
                      const Gap(10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111827),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF1F2937)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Possible deductions for this skill',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                              ),
                            ),
                            const Gap(6),
                            ...dim.deductionAnchors.map(
                              (a) => Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Text(
                                  a,
                                  style: const TextStyle(
                                    color: Color(0xFFCBD5E1),
                                    fontSize: 11,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (quote.isNotEmpty) ...[
                      const Gap(8),
                      Text(
                        'From the conversation: "$quote"',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          height: 1.35,
                        ),
                      ),
                    ],
                    if (suggest.isNotEmpty) ...[
                      const Gap(8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10241A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF166534)),
                        ),
                        child: Text(
                          'Try a stronger line: "$suggest"',
                          style: const TextStyle(
                            color: Color(0xFFA7F3D0),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                    if (!hasDetail && dim == null)
                      const Text(
                        'No extra notes for this skill.',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                ),
              ),
            );
          }),
          const Gap(16),
          const Row(
            children: [
              Icon(Icons.forum_outlined, color: Color(0xFF60A5FA), size: 18),
              Gap(8),
              Text(
                'Conversation',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
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
            ),
          ),
        ],
      ),
    );
  }
}
