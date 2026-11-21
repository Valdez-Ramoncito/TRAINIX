import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';
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
    final canNext = !waitingCustomer &&
        coachPrompt == null &&
        turnIndex < scenario.turns.length &&
        scenario.turns[turnIndex].type == ScenarioTurnType.guide;

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
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
                        _objectiveBanner(context, canNext),
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
                                          indicatorColor:
                                              AppColors.primaryText(context),
                                          labelColor:
                                              AppColors.textPrimary(context),
                                          unselectedLabelColor:
                                              AppColors.textMuted(context),
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
                                            _chatColumn(context),
                                            ScenarioKeepAlive(
                                              child: ScenarioAccountLookupPanel(
                                                accounts: visibleAccounts,
                                                searchQuery: searchQuery,
                                                selectedAccountId:
                                                    selectedAccountId,
                                                issueResolved: issueResolved,
                                                accountsRevealed:
                                                    accountsRevealed,
                                                allowSearch: turnIndex <
                                                        scenario.turns.length &&
                                                    scenario.turns[turnIndex]
                                                            .type ==
                                                        ScenarioTurnType
                                                            .accountSearch,
                                                allowSelect: turnIndex <
                                                        scenario.turns.length &&
                                                    scenario.turns[turnIndex]
                                                            .type ==
                                                        ScenarioTurnType
                                                            .accountSelect,
                                                allowResolve: turnIndex <
                                                        scenario.turns.length &&
                                                    scenario.turns[turnIndex]
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
                              : _chatColumn(context),
                        ),
                      ],
                    ),
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 0.5,
                  color: AppColors.border(context),
                ),
                SizedBox(width: 320, child: _scriptGuidePanel(context)),
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
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        border: Border(
          bottom: BorderSide(color: AppColors.border(context), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
            color: AppColors.textSecondary(context),
          ),
          Text(
            'Non-Voice Session',
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const Gap(10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.completeTint(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.secondaryText()),
            ),
            child: Text(
              scenario.sector.toUpperCase(),
              style: TextStyle(
                color: AppColors.secondaryText(),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Spacer(),
          Text(
            scenario.customerName,
            style: TextStyle(
                color: AppColors.textSecondary(context), fontSize: 13),
          ),
          const Gap(12),
          if (!scenario.isGuided)
            Text(
              'Mistakes ${mistakes}/${scenario.maxMistakes}',
              style: TextStyle(
                color: mistakes > 0
                    ? AppColors.errorText()
                    : AppColors.textMuted(context),
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _objectiveBanner(BuildContext context, bool canNext) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flag_outlined,
                size: 16,
                color: AppColors.primaryText(),
              ),
              const Gap(8),
              Text(
                'Objective',
                style: TextStyle(
                  color: AppColors.primaryText(),
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
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scriptGuidePanel(BuildContext context) {
    return Container(
      color: AppColors.inputFill(context),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 56),
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
                  color: AppColors.nextTint(context),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Script Guide',
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const Gap(12),
          if (scenario.missionSteps.isNotEmpty) ...[
            Text(
              'Missions',
              style: TextStyle(
                color: AppColors.textSecondary(context),
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
                          ? AppColors.nextTint(context)
                          : AppColors.elevated(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: done
                            ? AppColors.primaryText()
                            : current
                                ? AppColors.successText()
                                : AppColors.border(context),
                      ),
                    ),
                    child: Text(
                      '${done ? "Done" : current ? "Now" : "Todo"} · ${step.label}',
                      style: TextStyle(
                        color: done
                            ? AppColors.primaryText()
                            : AppColors.textSecondary(context),
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
          Row(
            children: [
              Icon(
                Icons.psychology_outlined,
                size: 16,
                color: AppColors.secondaryText(),
              ),
              const Gap(6),
              Text(
                'Coach note',
                style: TextStyle(
                  color: AppColors.textSecondary(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Gap(6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.completeTint(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.secondaryText()),
            ),
            child: Text(
              coachPrompt ??
                  hudText ??
                  'Follow the guided steps for this ${scenario.sector} scenario.',
              style: TextStyle(
                color: AppColors.secondaryText(),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
          if (coachTarget != null) ...[
            const Gap(12),
            Text(
              'You can type these',
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const Gap(6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.nextTint(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primaryText()),
              ),
              child: Text(
                coachTarget!,
                style: TextStyle(
                  color: AppColors.textPrimary(context),
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
              style:
                  TextStyle(color: AppColors.textMuted(context), fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chatColumn(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: bubbles.isEmpty
                ? Center(
                    child: Text(
                      'Customer chat will appear here.',
                      style: TextStyle(color: AppColors.textMuted(context)),
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
              color: AppColors.nextTint(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.primaryText().withValues(alpha: 0.45)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COACH',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1,
                    color: AppColors.textMuted(context),
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
                  Text(
                    'Type this exactly:',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textMuted(context)),
                  ),
                  const Gap(4),
                  Text(
                    coachTarget!,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ],
                if (coachTarget == null &&
                    turnIndex < scenario.turns.length &&
                    scenario.turns[turnIndex].type ==
                        ScenarioTurnType.chooseOne) ...[
                  const Gap(12),
                  Text(
                    'Choose one of the phrases below:',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textMuted(context)),
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
                              ? AppColors.nextTint(context)
                              : AppColors.inputFill(context),
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
                                      ? AppColors.primary(context)
                                      : AppColors.border(context),
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
                            backgroundColor: AppColors.primaryText(),
                            foregroundColor: AppColors.onPrimary(context),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed:
                              selectedChoice == null ? null : onSubmitChoice,
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
                      style: TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: inputFlashError
                            ? AppColors.elevated(context)
                            : inputFlashSuccess
                                ? AppColors.nextTint(context)
                                : AppColors.elevated(context),
                        hintText: 'Type your reply...',
                        hintStyle:
                            TextStyle(color: AppColors.textMuted(context)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: inputFlashError
                                ? AppColors.errorText()
                                : inputFlashSuccess
                                    ? AppColors.primary(context)
                                    : AppColors.border(context),
                            width:
                                (inputFlashError || inputFlashSuccess) ? 2 : 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: inputFlashError
                                ? AppColors.errorText()
                                : inputFlashSuccess
                                    ? AppColors.primary(context)
                                    : AppColors.border(context),
                            width:
                                (inputFlashError || inputFlashSuccess) ? 2 : 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: inputFlashError
                                ? AppColors.errorText()
                                : inputFlashSuccess
                                    ? AppColors.primary(context)
                                    : AppColors.primary(context),
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
                  icon: Icon(Icons.send, color: AppColors.primary(context)),
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
              color: AppColors.nextTint(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.primary(context).withValues(alpha: 0.4)),
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
            style: TextStyle(fontSize: 12, color: AppColors.textMuted(context)),
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
