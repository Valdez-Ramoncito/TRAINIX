import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/models/training/scenarios/scenario_models.dart';

class ScenarioBriefingView extends StatelessWidget {
  final ScenarioDefinition scenario;
  final VoidCallback onStart;

  const ScenarioBriefingView({
    super.key,
    required this.scenario,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        title: const Text('Scenario Briefing'),
        backgroundColor: const Color(0xFF0F1419),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          scenario.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                            color: Colors.white,
                          ),
                        ),
                        const Gap(8),
                        Text(
                          scenario.isGuided
                              ? 'Guided practice · follow the prompts'
                              : 'Independent practice · soft matching allowed',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 13,
                          ),
                        ),
                        const Gap(22),
                        _card(
                          title: 'Customer brief',
                          icon: Icons.person_outline,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _infoLine('Sector', scenario.sector),
                              _infoLine('Customer', scenario.customerName),
                              _infoLine('Problem', scenario.problem),
                              _infoLine('Emotion', scenario.emotion),
                            ],
                          ),
                        ),
                        const Gap(14),
                        _card(
                          title: 'Target skills',
                          icon: Icons.flag_outlined,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: scenario.targetSkills
                                .map(
                                  (s) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF15201A),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFF2E4A38),
                                      ),
                                    ),
                                    child: Text(
                                      s,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFFD7E8DB),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const Gap(14),
                        _card(
                          title: 'How this scenario works',
                          icon: Icons.route_outlined,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _step('1', 'Read the coach guidance at the top.'),
                              _step(
                                '2',
                                'Type, speak, or choose the response when asked.',
                              ),
                              _step(
                                '3',
                                'Use Account Lookup only when the scenario requires it.',
                              ),
                              _step(
                                '4',
                                scenario.isGuided
                                    ? 'Guided mode shows target lines. Soft matching is allowed.'
                                    : 'Independent mode scores meaning, not exact wording.',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onStart,
                    child: const Text(
                      'Start Scenario',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _step(String n, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF1F3A2A),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              n,
              style: const TextStyle(
                color: Color(0xFF70BD8A),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Gap(10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Color(0xFFD1D5DB),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required String title, required Widget child, IconData? icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A313A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: const Color(0xFF70BD8A)),
                const Gap(8),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Gap(12),
          child,
        ],
      ),
    );
  }

  Widget _infoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, height: 1.4),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
