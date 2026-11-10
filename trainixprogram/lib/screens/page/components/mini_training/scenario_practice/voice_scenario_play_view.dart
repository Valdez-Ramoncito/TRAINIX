import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/models/training/scenarios/scenario_models.dart';
import 'package:trainixprogram/screens/page/components/mini_training/scenario_practice/scenario_account_lookup_panel.dart';
import 'package:trainixprogram/screens/page/components/mini_training/scenario_practice/scenario_chat_bubble.dart';
import 'package:trainixprogram/screens/page/components/mini_training/scenario_practice/scenario_feedback_banner.dart';

class VoiceScenarioPlayView extends StatelessWidget {
  final ScenarioDefinition scenario;
  final int mistakes;
  final String? hudText;
  final bool canNext;
  final ScenarioFeedbackKind? feedbackKind;
  final String feedbackTitle;
  final String feedbackMessage;
  final Set<String> completedMissionIds;
  final String? currentMissionStepId;
  final List<ScenarioChatBubbleData> bubbles;
  final ScrollController scrollController;
  final ScrollController accountScrollController;
  final TextEditingController searchController;
  final String searchQuery;
  final String? selectedAccountId;
  final bool issueResolved;
  final bool accountsRevealed;
  final String? coachPrompt;
  final String? coachTarget;
  final String? lastTranscript;
  final bool recording;
  final bool processing;
  final bool isAccountTurn;
  final ScenarioTurnType? turnType;
  final bool inputFlashError;
  final bool inputFlashSuccess;
  final VoidCallback onHudNext;
  final VoidCallback onToggleRecord;
  final VoidCallback? onPlayLastTake;
  final bool canPlayLastTake;
  final VoidCallback? onPlayExample;
  final bool canPlayExample;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSelectAccount;
  final VoidCallback onConfirmSearch;
  final VoidCallback onConfirmSelect;
  final VoidCallback onResolve;

  const VoiceScenarioPlayView({
    super.key,
    required this.scenario,
    required this.mistakes,
    required this.hudText,
    required this.canNext,
    required this.feedbackKind,
    required this.feedbackTitle,
    required this.feedbackMessage,
    required this.completedMissionIds,
    required this.currentMissionStepId,
    required this.bubbles,
    required this.scrollController,
    required this.accountScrollController,
    required this.searchController,
    required this.searchQuery,
    required this.selectedAccountId,
    required this.issueResolved,
    required this.accountsRevealed,
    required this.coachPrompt,
    required this.coachTarget,
    required this.lastTranscript,
    required this.recording,
    required this.processing,
    required this.isAccountTurn,
    required this.turnType,
    required this.inputFlashError,
    required this.inputFlashSuccess,
    required this.onHudNext,
    required this.onToggleRecord,
    this.onPlayLastTake,
    this.canPlayLastTake = false,
    this.onPlayExample,
    this.canPlayExample = false,
    required this.onSearchChanged,
    required this.onSelectAccount,
    required this.onConfirmSearch,
    required this.onConfirmSelect,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Column(
        children: [
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF141414),
              border: Border(
                bottom: BorderSide(color: Color(0xFF2A2A2A), width: 0.5),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                  color: Colors.white70,
                ),
                const Text(
                  'Voice Session',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const Gap(10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A5F),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF3B82F6)),
                  ),
                  child: Text(
                    scenario.sector.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF93C5FD),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  scenario.customerName,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 62,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: scenario.usesAccountLookup ? 900 : 640,
                        ),
                        child: Column(
                          children: [
                            _guideHud(),
                            if (feedbackKind != null) ...[
                              const Gap(10),
                              ScenarioFeedbackBanner(
                                kind: feedbackKind!,
                                title: feedbackTitle,
                                message: feedbackMessage,
                              ),
                            ],
                            const Gap(12),
                            if (scenario.usesAccountLookup)
                              Expanded(child: _tabbedBody())
                            else ...[
                              Expanded(child: _conversationArea()),
                              if (coachPrompt != null && !isAccountTurn) ...[
                                const Gap(12),
                                _coachPanel(),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const VerticalDivider(
                    width: 1,
                    thickness: 0.5,
                    color: Color(0xFF2A2A2A),
                  ),
                  SizedBox(
                    width: 300,
                    child: Container(
                      color: const Color(0xFF121212),
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF166534),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'Script Guide',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Gap(12),
                          if (scenario.missionSteps.isNotEmpty)
                            Expanded(
                              child: ListView(
                                children: scenario.missionSteps.map((step) {
                                  final done = completedMissionIds.contains(
                                    step.id,
                                  );
                                  final current =
                                      currentMissionStepId == step.id;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      '${done
                                          ? "Done"
                                          : current
                                          ? "Now"
                                          : "Todo"} · ${step.label}',
                                      style: TextStyle(
                                        color: done
                                            ? const Color(0xFF70BD8A)
                                            : Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            )
                          else
                            const Spacer(),
                          const Text(
                            'Coach note',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const Gap(6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3A5F),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF3B82F6),
                              ),
                            ),
                            child: Text(
                              coachPrompt ??
                                  hudText ??
                                  'Follow the guided voice steps for this scenario.',
                              style: const TextStyle(
                                color: Color(0xFF93C5FD),
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ),
                          if (coachTarget != null) ...[
                            const Gap(10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 12, 67, 30),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFF70BD8A),
                                ),
                              ),
                              child: Text(
                                coachTarget!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
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
        ],
      ),
    );
  }

  Widget _tabbedBody() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              indicatorColor: Colors.green,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              tabs: [
                const Tab(text: 'Conversation'),
                Tab(
                  text: isAccountTurn ? 'Account Lookup *' : 'Account Lookup',
                ),
              ],
            ),
          ),
          const Gap(10),
          Expanded(
            child: TabBarView(
              children: [
                Column(
                  children: [
                    Expanded(child: _conversationArea()),
                    if (coachPrompt != null && !isAccountTurn) ...[
                      const Gap(12),
                      _coachPanel(),
                    ],
                    if (isAccountTurn && coachPrompt != null) ...[
                      const Gap(10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A2E1A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          coachPrompt!,
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ],
                ),
                ScenarioAccountLookupPanel(
                  accounts: scenario.accounts,
                  searchQuery: searchQuery,
                  selectedAccountId: selectedAccountId,
                  issueResolved: issueResolved,
                  accountsRevealed: accountsRevealed,
                  allowSearch: turnType == ScenarioTurnType.accountSearch,
                  allowSelect: turnType == ScenarioTurnType.accountSelect,
                  allowResolve: turnType == ScenarioTurnType.accountResolve,
                  searchController: searchController,
                  scrollController: accountScrollController,
                  onSearchChanged: onSearchChanged,
                  onSelectAccount: onSelectAccount,
                  onConfirmSearch: onConfirmSearch,
                  onConfirmSelect: onConfirmSelect,
                  onResolve: onResolve,
                  sector: scenario.sector,
                  flashError: inputFlashError,
                  flashSuccess: inputFlashSuccess,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _guideHud() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2233),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A3A55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'GUIDE',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1,
                  color: Colors.white54,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (!scenario.isGuided) ...[
                const Spacer(),
                Text(
                  'Mistakes: $mistakes / ${scenario.maxMistakes}',
                  style: TextStyle(
                    fontSize: 12,
                    color: mistakes > 0 ? Colors.redAccent : Colors.white54,
                  ),
                ),
              ],
            ],
          ),
          const Gap(8),
          Text(
            hudText ?? 'Follow the guided steps.',
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          if (canNext) ...[
            const Gap(12),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: 36,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: onHudNext,
                  child: const Text('Next'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _conversationArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: bubbles.isEmpty
          ? const Center(
              child: Text(
                'Customer lines will appear here.',
                style: TextStyle(color: Colors.white38),
              ),
            )
          : ListView.builder(
              key: const PageStorageKey('voice_scenario_chat'),
              controller: scrollController,
              itemCount: bubbles.length,
              itemBuilder: (context, index) {
                return ScenarioChatBubble(
                  bubble: bubbles[index],
                  customerName: scenario.customerName,
                );
              },
            ),
    );
  }

  Widget _coachPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2E1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'COACH',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1,
              color: Colors.white54,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(8),
          Text(
            coachPrompt!,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (coachTarget != null) ...[
            const Gap(10),
            const Text(
              'Say this:',
              style: TextStyle(fontSize: 12, color: Colors.white54),
            ),
            if (canPlayExample && onPlayExample != null) ...[
              const Gap(6),
              TextButton.icon(
                onPressed: processing || recording ? null : onPlayExample,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF70BD8A),
                ),
                icon: const Icon(Icons.volume_up, size: 18),
                label: const Text('Hear example'),
              ),
            ],
            const Gap(4),
            Text(
              coachTarget!,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ],
          if (lastTranscript != null) ...[
            const Gap(10),
            const Text(
              'Your transcript:',
              style: TextStyle(fontSize: 12, color: Colors.white54),
            ),
            if (canPlayLastTake && onPlayLastTake != null) ...[
              const Gap(6),
              TextButton.icon(
                onPressed: processing || recording ? null : onPlayLastTake,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF70BD8A),
                ),
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('Play my last take'),
              ),
            ],
            const Gap(4),
            Text(
              lastTranscript!,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
          const Gap(12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: recording ? Colors.redAccent : Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: processing ? null : onToggleRecord,
              icon: Icon(recording ? Icons.stop : Icons.mic),
              label: Text(
                processing
                    ? 'Checking...'
                    : (recording ? 'Stop and Check' : 'Start Recording'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
