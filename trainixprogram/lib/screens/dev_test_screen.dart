import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainixprogram/models/customer_account.dart';
import 'package:trainixprogram/models/session_score.dart';
import 'package:trainixprogram/models/simulation_history.dart';
import 'package:trainixprogram/screens/dashboard.dart';
import 'package:trainixprogram/screens/mock_call_screen.dart';
import 'package:trainixprogram/screens/session_report_screen.dart';

const List<String> _kSectors = [
  'Finance',
  'Healthcare',
  'Telco',
  'Tech Support',
];

class DevTestScreen extends StatelessWidget {
  const DevTestScreen({super.key});

  static const Map<String, double> _demoSectorBaseline = {
    'Healthcare': 8.6,
    'Tech Support': 7.4,
    'Finance': 6.2,
    'Telco': 5.0,
  };

  static const List<String> _strengthPool = [
    'Clear communication',
    'Empathetic tone',
    'Fast resolution',
    'Strong active listening',
    'Confident opening spiel',
    'Accurate problem identification',
  ];

  static const List<String> _improvementPool = [
    'Closing spiel',
    'Sector knowledge',
    'Positive scripting',
    'Solution delivery clarity',
    'Tone consistency',
  ];

  SessionEvaluation _buildFakeEvaluation({
    required String sector,
    required double scoreLevel,
    //'chat' or 'voice' determines which set of TESDA telemetry
    //fields gets populated, matching how a real evaluation only ever
    //comes from GeminiEvaluationApiService (chat) or
    //GeminiVoiceEvaluationApiService (voice), never both at once
    required String channel,
  }) {
    double clamp(double v) => v.clamp(0, 10).toDouble();
    final scores = [
      clamp(scoreLevel + 0.3),
      clamp(scoreLevel - 0.2),
      clamp(scoreLevel + 0.1),
      clamp(scoreLevel - 0.4),
      clamp(scoreLevel + 0.2),
      clamp(scoreLevel - 0.1),
      clamp(scoreLevel + 0.4),
      clamp(scoreLevel - 0.3),
      clamp(scoreLevel + 0.0),
      clamp(scoreLevel + 0.2),
    ];
    final overall = scores.reduce((a, b) => a + b) / scores.length;

    //fake per-category evaluator notes/quotes on two categories only
    //mirrors how the real rubric only ever stores a note for a
    //category that actually took a deduction so Session Report's
    //"Evaluator Notes" list has something realistic to show.
    const categoryNotes = {
      'Closing Spiel': 'TEST DATA  simulated deduction for missing sign-off.',
      'Sector Knowledge':
          'TEST DATA  simulated deduction for incorrect terminology.',
    };
    const categoryQuotes = {
      'Sector Knowledge': 'TEST DATA  simulated agent quote.',
    };

    return SessionEvaluation(
      sector: sector,
      openingSpielScore: scores[0],
      positiveScriptingScore: scores[1],
      empathyScore: scores[2],
      activeListeningScore: scores[3],
      problemIdentificationScore: scores[4],
      solutionDeliveryScore: scores[5],
      communicationClarityScore: scores[6],
      toneScore: scores[7],
      sectorKnowledgeScore: scores[8],
      closingSpielScore: scores[9],
      overallScore: double.parse(overall.toStringAsFixed(1)),
      //chat-only TESDA fields. Only set when channel == 'chat', same
      //as the real GeminiEvaluationApiService path leaves these null
      //for voice evaluations
      typingSpeedScore: channel == 'chat' ? clamp(scoreLevel + 0.1) : null,
      errorRateAccuracyScore: channel == 'chat'
          ? clamp(scoreLevel - 0.2)
          : null,
      responseConsistencyScore: channel == 'chat' ? clamp(scoreLevel) : null,
      //voice-only TESDA fields. Only set when channel == 'voice', same
      //as the real GeminiVoiceEvaluationApiService path
      paceAndSpeedScore: channel == 'voice' ? clamp(scoreLevel + 0.1) : null,
      pronunciationClarityScore: channel == 'voice'
          ? clamp(scoreLevel - 0.2)
          : null,
      fillerWordUsageScore: channel == 'voice' ? clamp(scoreLevel) : null,
      categoryNotes: categoryNotes,
      categoryQuotes: categoryQuotes,
      strengths: const [
        'Clear communication',
        'Empathetic tone',
        'Fast resolution',
      ],
      areasForImprovement: const ['Closing spiel', 'Sector knowledge'],
      feedback:
          'This is a TEST evaluation generated from the Dev Test Screen — '
          'not a real simulation result.',
      evaluatedAt: DateTime.now(),
    );
  }

  SessionEvaluation _buildDemoEvaluation({
    required String sector,
    required double scoreLevel,
    required DateTime evaluatedAt,
    required Random random,
    //optional. 'chat' or 'voice' to populate the matching TESDA
    String? channel,
  }) {
    double clamp(double v) => v.clamp(0, 10).toDouble();
    final scores = [
      clamp(scoreLevel + 0.3),
      clamp(scoreLevel - 0.2),
      clamp(scoreLevel + 0.1),
      clamp(scoreLevel - 0.4),
      clamp(scoreLevel + 0.2),
      clamp(scoreLevel - 0.1),
      clamp(scoreLevel + 0.4),
      clamp(scoreLevel - 0.3),
      clamp(scoreLevel + 0.0),
      clamp(scoreLevel + 0.2),
    ];
    final overall = scores.reduce((a, b) => a + b) / scores.length;

    final shuffledStrengths = List<String>.from(_strengthPool)..shuffle(random);
    final shuffledImprovements = List<String>.from(_improvementPool)
      ..shuffle(random);

    return SessionEvaluation(
      sector: sector,
      openingSpielScore: scores[0],
      positiveScriptingScore: scores[1],
      empathyScore: scores[2],
      activeListeningScore: scores[3],
      problemIdentificationScore: scores[4],
      solutionDeliveryScore: scores[5],
      communicationClarityScore: scores[6],
      toneScore: scores[7],
      sectorKnowledgeScore: scores[8],
      closingSpielScore: scores[9],
      overallScore: double.parse(overall.toStringAsFixed(1)),
      typingSpeedScore: channel == 'chat' ? clamp(scoreLevel + 0.1) : null,
      errorRateAccuracyScore: channel == 'chat'
          ? clamp(scoreLevel - 0.2)
          : null,
      responseConsistencyScore: channel == 'chat' ? clamp(scoreLevel) : null,
      paceAndSpeedScore: channel == 'voice' ? clamp(scoreLevel + 0.1) : null,
      pronunciationClarityScore: channel == 'voice'
          ? clamp(scoreLevel - 0.2)
          : null,
      fillerWordUsageScore: channel == 'voice' ? clamp(scoreLevel) : null,
      strengths: shuffledStrengths.take(3).toList(),
      areasForImprovement: shuffledImprovements.take(2).toList(),
      feedback:
          'This is a TEST evaluation generated from the Dev Test Screen — '
          'not a real simulation result.',
      evaluatedAt: evaluatedAt,
    );
  }

  void _generateFullDemoDataset(BuildContext context) {
    final historyProvider = Provider.of<SimulationHistoryProvider>(
      context,
      listen: false,
    );
    final random = Random();
    final now = DateTime.now();

    int daysAgo = 14;
    _demoSectorBaseline.forEach((sector, baseline) {
      for (int i = 0; i < 3; i++) {
        final sessionDate = now.subtract(
          Duration(days: daysAgo, hours: random.nextInt(10)),
        );
        daysAgo = (daysAgo - random.nextInt(3) - 1).clamp(1, 14);

        final evalCount = 1 + random.nextInt(2);
        final sessionEvals = <SessionEvaluation>[];
        for (int e = 0; e < evalCount; e++) {
          final jitter = (random.nextDouble() * 1.2) - 0.6;
          final eval = _buildDemoEvaluation(
            sector: sector,
            scoreLevel: baseline + jitter,
            evaluatedAt: sessionDate,
            random: random,
          );
          sessionEvals.add(eval);
          historyProvider.saveEvaluation(eval);
        }
        final sessionMultitasking = (55 + random.nextInt(40)).toDouble();
        historyProvider.saveMultitaskingScore(sessionMultitasking);
        //also record this as one grouped session
        historyProvider.saveSession(
          evaluations: sessionEvals,
          multitaskingScore: sessionMultitasking,
        );
      }
    });

    const justFinishedSector = 'Healthcare';
    final finalBaseline = _demoSectorBaseline[justFinishedSector]!;
    final eval1 = _buildDemoEvaluation(
      sector: justFinishedSector,
      scoreLevel: finalBaseline + 0.2,
      evaluatedAt: now,
      random: random,
      channel: 'chat',
    );
    final eval2 = _buildDemoEvaluation(
      sector: justFinishedSector,
      scoreLevel: finalBaseline - 0.3,
      evaluatedAt: now,
      random: random,
      channel: 'voice',
    );
    const finalMultitasking = 82.0;
    const finalAvgWpm = 132.0;
    const finalFillerWords = 4;
    const finalAvgTypingWpm = 41.0;

    historyProvider.saveEvaluation(eval1);
    historyProvider.saveEvaluation(eval2);
    historyProvider.saveMultitaskingScore(finalMultitasking);

    historyProvider.saveEvaluation(eval1);
    historyProvider.saveEvaluation(eval2);
    historyProvider.saveMultitaskingScore(finalMultitasking);
    //also record this as one grouped session
    historyProvider.saveSession(
      evaluations: [eval1, eval2],
      multitaskingScore: finalMultitasking,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SessionReportScreen(
          evaluations: [eval1, eval2],
          averageWpm: finalAvgWpm,
          fillerWordCount: finalFillerWords,
          averageTypingWpm: finalAvgTypingWpm,
          multitaskingScore: finalMultitasking,
        ),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Generated a full demo dataset — check Dashboard for Sector '
          'Match, score trends, and averages.',
        ),
      ),
    );
  }

  void _generateTestSession(
    BuildContext context, {
    required String label,
    required double scoreLevel,
  }) {
    const sector = 'Tech Support';

    final eval1 = _buildFakeEvaluation(
      sector: sector,
      scoreLevel: scoreLevel,
      channel: 'chat',
    );
    final eval2 = _buildFakeEvaluation(
      sector: sector,
      scoreLevel: (scoreLevel - 0.7).clamp(0, 10),
      channel: 'voice',
    );
    const multitaskingScore = 72.0;
    const avgWpm = 118.0;
    const fillerWords = 6;
    const avgTypingWpm = 34.0;

    final historyProvider = Provider.of<SimulationHistoryProvider>(
      context,
      listen: false,
    );
    historyProvider.saveEvaluation(eval1);
    historyProvider.saveEvaluation(eval2);
    historyProvider.saveMultitaskingScore(multitaskingScore);
    //Record this as one grouped session
    //otherwise it won't show up correctly in the Session History
    //Score Trend and Total Sessions
    historyProvider.saveSession(
      evaluations: [eval1, eval2],
      multitaskingScore: multitaskingScore,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SessionReportScreen(
          evaluations: [eval1, eval2],
          averageWpm: avgWpm,
          fillerWordCount: fillerWords,
          averageTypingWpm: avgTypingWpm,
          multitaskingScore: multitaskingScore,
        ),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generated "$label" test session and saved to history.'),
      ),
    );
  }

  void _generateFakeAccount(BuildContext context) {
    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );
    final n = accountProvider.accounts.length + 1;
    accountProvider.generateAccounts(
      sector: 'Tech Support',
      targetAccountId: 'TEST-$n',
      problem: 'Test problem generated from Dev Test Screen',
      targetOwnerName: 'Test Customer',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dev Test Screen'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Text(
            'Jump into a live Mock Call',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Uses real mic / STT / AI / TTS — same as a normal run, just '
            'skips Login and Menu.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final sector in _kSectors)
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MockCallScreen(sector: sector),
                    ),
                  ),
                  child: Text(sector),
                ),
            ],
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          const Text(
            'Full Demo Dataset',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'One tap: seeds ~2 weeks of realistic sessions across all four '
            'sectors (so Dashboard trends and Sector Match have something '
            'to show), then opens Session Report for a "just finished" '
            'session — for people who just want to see the end result '
            'without running a full simulation.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () => _generateFullDemoDataset(context),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generate Full Demo Dataset'),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardScreen()),
                ),
                icon: const Icon(Icons.bar_chart),
                label: const Text('Open Dashboard'),
              ),
            ],
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          const Text(
            'Account Generation Check',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Generates a fake account list directly, so you can confirm '
            'an owner name renders correctly without a full call.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(
                onPressed: () => _generateFakeAccount(context),
                child: const Text('Generate Fake Accounts'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => Provider.of<AccountProvider>(
                  context,
                  listen: false,
                ).reset(),
                child: const Text('Clear Accounts'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Consumer<AccountProvider>(
            builder: (context, accountProvider, _) {
              if (accountProvider.accounts.isEmpty) {
                return const Text(
                  'No accounts generated yet.',
                  style: TextStyle(color: Colors.grey),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: accountProvider.accounts
                    .map(
                      (a) => Text(
                        '${a.accountId} — ${a.ownerName}'
                        '${a.isTarget ? '  (target)' : ''}',
                      ),
                    )
                    .toList(),
              );
            },
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          const Text(
            'Generate Single Test Session',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Saves two fake evaluations + a multitasking score into real '
            'history, then opens Session Report with them. For quick, '
            'isolated checks — prefer "Generate Full Demo Dataset" above '
            'if you want Dashboard/Sector Match populated too.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: () => _generateTestSession(
                  context,
                  label: 'Good',
                  scoreLevel: 8.5,
                ),
                child: const Text('Generate Good Score'),
              ),
              ElevatedButton(
                onPressed: () => _generateTestSession(
                  context,
                  label: 'Average',
                  scoreLevel: 6.0,
                ),
                child: const Text('Generate Average Score'),
              ),
              ElevatedButton(
                onPressed: () => _generateTestSession(
                  context,
                  label: 'Poor',
                  scoreLevel: 3.0,
                ),
                child: const Text('Generate Poor Score'),
              ),
            ],
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Provider.of<SimulationHistoryProvider>(
                context,
                listen: false,
              ).clear();
              Provider.of<AccountProvider>(context, listen: false).reset();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cleared all test data.')),
              );
            },
            child: const Text('Clear All Test Data'),
          ),
        ],
      ),
    );
  }
}
