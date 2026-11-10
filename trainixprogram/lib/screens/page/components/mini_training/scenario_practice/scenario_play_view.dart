import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/models/training/scenarios/scenario_models.dart';
import 'package:trainixprogram/screens/page/components/mini_training/scenario_practice/scenario_account_lookup_panel.dart';
import 'package:trainixprogram/screens/page/components/mini_training/scenario_practice/scenario_feedback_banner.dart';
import 'package:trainixprogram/screens/page/components/mini_training/scenario_practice/scenario_chat_bubble.dart';

class ScenarioPlayView extends StatelessWidget {
  final ScenarioDefinition scenario;
  final int mistakes;
  final String? hudText;
  final List<ScenarioChatBubbleData> bubbles;
  final ScrollController scrollController;
  final ScrollController accountScrollController;
  final String? coachPrompt;
  final String? coachTarget;
  final int turnIndex;
  final int? selectedChoice;
  final TextEditingController inputController;
  final TextEditingController searchController;
  final String searchQuery;
  final bool waitingCustomer;
  final String? selectedAccountId;
  final List<ScenarioAccount> visibleAccounts;
  final bool issueResolved;
  final bool accountsRevealed;
  final String? inlineFeedback;
  final VoidCallback onHudNext;
  final VoidCallback onSubmitTyped;
  final VoidCallback onSubmitChoice;
  final VoidCallback onSubmitAccountSearch;
  final VoidCallback onSubmitAccountSelect;
  final VoidCallback onSubmitAccountResolve;
  final ValueChanged<int> onSelectChoice;
  final ValueChanged<String> onSelectAccount;
  final ValueChanged<String> onSearchChanged;
  final ScenarioFeedbackKind? feedbackKind;
  final String feedbackTitle;
  final String feedbackMessage;
  final bool inputFlashError;
  final bool inputFlashSuccess;
  final Set<String> completedMissionIds;
  final String? currentMissionStepId;

  const ScenarioPlayView({
    super.key,
    required this.scenario,
    required this.mistakes,
    required this.hudText,
    required this.bubbles,
    required this.scrollController,
    required this.accountScrollController,
    required this.coachPrompt,
    required this.coachTarget,
    required this.turnIndex,
    required this.selectedChoice,
    required this.inputController,
    required this.searchController,
    required this.searchQuery,
    required this.waitingCustomer,
    required this.selectedAccountId,
    required this.visibleAccounts,
    required this.issueResolved,
    required this.accountsRevealed,
    required this.inlineFeedback,
    required this.onHudNext,
    required this.onSubmitTyped,
    required this.onSubmitChoice,
    required this.onSubmitAccountSearch,
    required this.onSubmitAccountSelect,
    required this.onSubmitAccountResolve,
    required this.onSelectChoice,
    required this.onSelectAccount,
    required this.onSearchChanged,
    required this.feedbackKind,
    required this.feedbackTitle,
    required this.feedbackMessage,
    required this.inputFlashError,
    required this.inputFlashSuccess,
    required this.completedMissionIds,
    required this.currentMissionStepId,
  });

  bool get _isAccountTurn {
    if (turnIndex >= scenario.turns.length) return false;
    final t = scenario.turns[turnIndex].type;
    return t == ScenarioTurnType.accountSearch ||
        t == ScenarioTurnType.accountSelect ||
        t == ScenarioTurnType.accountResolve;
  }

  @override
  Widget build(BuildContext context) {
    final canNext =
        !waitingCustomer &&
        coachPrompt == null &&
        turnIndex < scenario.turns.length &&
        scenario.turns[turnIndex].type == ScenarioTurnType.guide;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Column(
        children: [
          _sessionHeader(context),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 62,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
                    child: Column(
                      children: [
                        _objectiveBanner(canNext),
                        if (feedbackKind != null) ...[
                          const Gap(8),
                          ScenarioFeedbackBanner(
                            kind: feedbackKind!,
                            title: feedbackTitle,
                            message: feedbackMessage,
                          ),
                        ],
                        const Gap(10),
                        Expanded(
                          child: scenario.usesAccountLookup
                              ? DefaultTabController(
                                  length: 2,
                                  child: Column(
                                    children: [
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: TabBar(
                                          isScrollable: true,
                                          tabAlignment: TabAlignment.start,
                                          indicatorColor: const Color(
                                            0xFF70BD8A,
                                          ),
                                          labelColor: Colors.white,
                                          unselectedLabelColor: Colors.white54,
                                          tabs: const [
                                            Tab(text: 'Non-Voice'),
                                            Tab(text: 'Account Lookup'),
                                          ],
                                        ),
                                      ),
                                      const Gap(8),
                                      Expanded(
                                        child: TabBarView(
                                          children: [
                                            _chatColumn(),
                                            ScenarioKeepAlive(
                                              child: ScenarioAccountLookupPanel(
                                                accounts: visibleAccounts,
                                                searchQuery: searchQuery,
                                                selectedAccountId:
                                                    selectedAccountId,
                                                issueResolved: issueResolved,
                                                accountsRevealed:
                                                    accountsRevealed,
                                                allowSearch:
                                                    turnIndex <
                                                        scenario.turns.length &&
                                                    scenario
                                                            .turns[turnIndex]
                                                            .type ==
                                                        ScenarioTurnType
                                                            .accountSearch,
                                                allowSelect:
                                                    turnIndex <
                                                        scenario.turns.length &&
                                                    scenario
                                                            .turns[turnIndex]
                                                            .type ==
                                                        ScenarioTurnType
                                                            .accountSelect,
                                                allowResolve:
                                                    turnIndex <
                                                        scenario.turns.length &&
                                                    scenario
                                                            .turns[turnIndex]
                                                            .type ==
                                                        ScenarioTurnType
                                                            .accountResolve,
                                                searchController:
                                                    searchController,
                                                scrollController:
                                                    accountScrollController,
                                                onSearchChanged:
                                                    onSearchChanged,
                                                onSelectAccount:
                                                    onSelectAccount,
                                                onConfirmSearch:
                                                    onSubmitAccountSearch,
                                                onConfirmSelect:
                                                    onSubmitAccountSelect,
                                                onResolve:
                                                    onSubmitAccountResolve,
                                                sector: scenario.sector,
                                                flashError: inputFlashError,
                                                flashSuccess: inputFlashSuccess,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : _chatColumn(),
                        ),
                      ],
                    ),
                  ),
                ),
                const VerticalDivider(
                  width: 1,
                  thickness: 0.5,
                  color: Color(0xFF2A2A2A),
                ),
                SizedBox(width: 320, child: _scriptGuidePanel()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sessionHeader(BuildContext context) {
    return Container(
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
            'Non-Voice Session',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const Gap(10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          const Gap(12),
          if (!scenario.isGuided)
            Text(
              'Mistakes ${mistakes}/${scenario.maxMistakes}',
              style: TextStyle(
                color: mistakes > 0 ? Colors.redAccent : Colors.white38,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _objectiveBanner(bool canNext) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.flag_outlined,
                size: 16,
                color: Color(0xFF70BD8A),
              ),
              const Gap(8),
              const Text(
                'Objective',
                style: TextStyle(
                  color: Color(0xFF70BD8A),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (canNext)
                TextButton(onPressed: onHudNext, child: const Text('Continue')),
            ],
          ),
          const Gap(6),
          Text(
            hudText ?? scenario.title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scriptGuidePanel() {
    return Container(
      color: const Color(0xFF121212),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
            ],
          ),
          const Gap(12),
          if (scenario.missionSteps.isNotEmpty) ...[
            const Text(
              'Missions',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const Gap(8),
            Expanded(
              flex: 2,
              child: ListView(
                children: scenario.missionSteps.map((step) {
                  final done = completedMissionIds.contains(step.id);
                  final current = currentMissionStepId == step.id;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: current
                          ? const Color(0xFF1A2E1A)
                          : const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: done
                            ? const Color(0xFF70BD8A)
                            : current
                            ? const Color(0xFF34D399)
                            : const Color(0xFF333333),
                      ),
                    ),
                    child: Text(
                      '${done
                          ? "Done"
                          : current
                          ? "Now"
                          : "Todo"} · ${step.label}',
                      style: TextStyle(
                        color: done ? const Color(0xFF70BD8A) : Colors.white70,
                        fontSize: 12,
                        fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Gap(12),
          ] else
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
              border: Border.all(color: const Color(0xFF3B82F6)),
            ),
            child: Text(
              coachPrompt ??
                  hudText ??
                  'Follow the guided steps for this ${scenario.sector} scenario.',
              style: const TextStyle(
                color: Color(0xFF93C5FD),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
          if (coachTarget != null) ...[
            const Gap(12),
            const Text(
              'You can type these',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const Gap(6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 12, 67, 30),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF70BD8A)),
              ),
              child: Text(
                coachTarget!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
          ],
          if (inlineFeedback case final feedback?) ...[
            const Gap(10),
            Text(
              feedback,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chatColumn() {
    return Column(
      children: [
        Expanded(
          child: Container(
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
                      'Customer chat will appear here.',
                      style: TextStyle(color: Colors.white38),
                    ),
                  )
                : ListView.builder(
                    key: const PageStorageKey('scenario_chat_list'),
                    controller: scrollController,
                    itemCount: bubbles.length,
                    itemBuilder: (context, index) {
                      return ScenarioChatBubble(
                        bubble: bubbles[index],
                        customerName: scenario.customerName,
                      );
                    },
                  ),
          ),
        ),
        if (coachPrompt != null && !_isAccountTurn) ...[
          const Gap(12),
          Container(
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
                    'Type this exactly:',
                    style: TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                  const Gap(4),
                  Text(
                    coachTarget!,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Colors.white,
                    ),
                  ),
                ],
                if (coachTarget == null &&
                    turnIndex < scenario.turns.length &&
                    scenario.turns[turnIndex].type ==
                        ScenarioTurnType.chooseOne) ...[
                  const Gap(12),
                  const Text(
                    'Choose one of the phrases below:',
                    style: TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                  const Gap(8),
                  ...List.generate(
                    scenario.turns[turnIndex].options?.length ?? 0,
                    (i) {
                      final option = scenario.turns[turnIndex].options![i];
                      final selected = selectedChoice == i;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: selected
                              ? const Color(0xFF1A3A1A)
                              : const Color(0xFF121212),
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => onSelectChoice(i),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selected
                                      ? Colors.green
                                      : const Color(0xFF333333),
                                ),
                              ),
                              child: Text(
                                option,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: selectedChoice == null
                              ? null
                              : onSubmitChoice,
                          child: const Text('Confirm Choice'),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (coachTarget != null) ...[
            const Gap(10),
            Row(
              children: [
                Expanded(
                  child: Focus(
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.enter &&
                          !HardwareKeyboard.instance.isShiftPressed) {
                        onSubmitTyped();
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: TextField(
                      controller: inputController,
                      autofocus: !waitingCustomer,
                      enabled: !waitingCustomer,
                      minLines: 1,
                      maxLines: 3,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => onSubmitTyped(),
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: inputFlashError
                            ? const Color(0xFF3A1515)
                            : inputFlashSuccess
                            ? const Color(0xFF153A22)
                            : const Color(0xFF1A1A1A),
                        hintText: 'Type your reply...',
                        hintStyle: const TextStyle(color: Colors.white30),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: inputFlashError
                                ? Colors.redAccent
                                : inputFlashSuccess
                                ? Colors.green
                                : const Color(0xFF333333),
                            width: (inputFlashError || inputFlashSuccess)
                                ? 2
                                : 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: inputFlashError
                                ? Colors.redAccent
                                : inputFlashSuccess
                                ? Colors.green
                                : const Color(0xFF333333),
                            width: (inputFlashError || inputFlashSuccess)
                                ? 2
                                : 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: inputFlashError
                                ? Colors.redAccent
                                : inputFlashSuccess
                                ? Colors.green
                                : Colors.green,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const Gap(8),
                IconButton(
                  onPressed: waitingCustomer ? null : onSubmitTyped,
                  icon: const Icon(Icons.send, color: Colors.green),
                ),
              ],
            ),
          ],
        ],
        if (_isAccountTurn && coachPrompt != null) ...[
          const Gap(10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2E1A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.withOpacity(0.4)),
            ),
            child: Text(
              coachPrompt!,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
        if (inlineFeedback case final feedback? when coachPrompt == null) ...[
          const Gap(8),
          Text(
            feedback,
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
        ],
      ],
    );
  }
}

class ScenarioKeepAlive extends StatefulWidget {
  final Widget child;

  const ScenarioKeepAlive({super.key, required this.child});

  @override
  State<ScenarioKeepAlive> createState() => _ScenarioKeepAliveState();
}

class _ScenarioKeepAliveState extends State<ScenarioKeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
