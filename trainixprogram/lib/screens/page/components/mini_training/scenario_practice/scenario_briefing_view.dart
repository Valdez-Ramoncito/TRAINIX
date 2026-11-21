import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';
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
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        title: Text('Scenario Briefing'),
        backgroundColor: AppColors.scaffold(context),
        foregroundColor: AppColors.textPrimary(context),
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
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        const Gap(8),
                        Text(
                          scenario.isGuided
                              ? 'Guided practice · follow the prompts'
                              : 'Independent practice · soft matching allowed',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textMuted(context),
                            fontSize: 13,
                          ),
                        ),
                        const Gap(22),
                        _card(
                          context,
                          title: 'Customer brief',
                          icon: Icons.person_outline,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _infoLine(context, 'Sector', scenario.sector),
                              _infoLine(
                                  context, 'Customer', scenario.customerName),
                              _infoLine(context, 'Problem', scenario.problem),
                              _infoLine(context, 'Emotion', scenario.emotion),
                            ],
                          ),
                        ),
                        const Gap(14),
                        _card(
                          context,
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
                                      color: AppColors.nextTint(context),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppColors.nextTint(context),
                                      ),
                                    ),
                                    child: Text(
                                      s,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primaryText(),
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
                          context,
                          title: 'How this scenario works',
                          icon: Icons.route_outlined,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _step(context, '1',
                                  'Read the coach guidance at the top.'),
                              _step(
                                context,
                                '2',
                                'Type, speak, or choose the response when asked.',
                              ),
                              _step(
                                context,
                                '3',
                                'Use Account Lookup only when the scenario requires it.',
                              ),
                              _step(
                                context,
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
                      backgroundColor: AppColors.primaryText(),
                      foregroundColor: AppColors.onPrimary(context),
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

  Widget _step(BuildContext context, String n, String text) {
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
              color: AppColors.nextTint(context),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              n,
              style: TextStyle(
                color: AppColors.primaryText(),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Gap(10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context,
      {required String title, required Widget child, IconData? icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppColors.primaryText()),
                const Gap(8),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted(context),
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

  Widget _infoLine(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 14, height: 1.4),
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                color: AppColors.textMuted(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(color: AppColors.textPrimary(context)),
            ),
          ],
        ),
      ),
    );
  }
}
