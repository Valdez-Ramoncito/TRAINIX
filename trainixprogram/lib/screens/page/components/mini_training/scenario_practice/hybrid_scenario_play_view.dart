import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/models/training/scenarios/scenario_models.dart';
import 'package:trainixprogram/screens/page/components/mini_training/scenario_practice/scenario_account_lookup_panel.dart';
import 'package:trainixprogram/screens/page/components/mini_training/scenario_practice/scenario_chat_bubble.dart';
import 'package:trainixprogram/screens/page/components/mini_training/scenario_practice/scenario_feedback_banner.dart';
import 'package:trainixprogram/screens/page/components/mini_training/scenario_practice/scenario_mission_panel.dart';

class HybridScenarioPlayView extends StatelessWidget {
  final ScenarioDefinition scenario;
  final int mistakes;
  final String? hudText;
  final String? lane;
  final bool canNext;
  final ScenarioFeedbackKind? feedbackKind;
  final String feedbackTitle;
  final String feedbackMessage;
  final Set<String> completedMissionIds;
  final String? currentMissionStepId;
  final List<ScenarioChatBubbleData> voiceBubbles;
  final List<ScenarioChatBubbleData> chatBubbles;
  final ScrollController voiceScroll;
  final ScrollController chatScroll;
  final ScrollController voiceAccountScroll;
  final ScrollController chatAccountScroll;
  final TextEditingController chatInput;
  final FocusNode? chatFocusNode;
  final TextEditingController voiceSearch;
  final TextEditingController chatSearch;
  final String? selectedVoiceAccountId;
  final String? selectedChatAccountId;
  final String voiceSearchQuery;
  final String chatSearchQuery;
  final bool voiceAccountsRevealed;
  final bool chatAccountsRevealed;
  final bool voiceIssueResolved;
  final bool chatIssueResolved;
  final String? coachPrompt;
  final String? coachTarget;
  final String? lastTranscript;
  final bool recording;
  final bool processing;
  final ScenarioTurnType? turnType;
  final VoidCallback onHudNext;
  final VoidCallback onToggleRecord;
  final VoidCallback onSubmitChatTyped;
  final ValueChanged<String> onVoiceSearchChanged;
  final ValueChanged<String> onChatSearchChanged;
  final ValueChanged<String> onSelectVoiceAccount;
  final ValueChanged<String> onSelectChatAccount;
  final VoidCallback onConfirmVoiceSearch;
  final VoidCallback onConfirmChatSearch;
  final VoidCallback onConfirmVoiceSelect;
  final VoidCallback onConfirmChatSelect;
  final VoidCallback onResolveVoice;
  final VoidCallback onResolveChat;

  const HybridScenarioPlayView({
    super.key,
    required this.scenario,
    required this.mistakes,
    required this.hudText,
    required this.lane,
    required this.canNext,
    required this.feedbackKind,
    required this.feedbackTitle,
    required this.feedbackMessage,
    required this.completedMissionIds,
    required this.currentMissionStepId,
    required this.voiceBubbles,
    required this.chatBubbles,
    required this.voiceScroll,
    required this.chatScroll,
    required this.voiceAccountScroll,
    required this.chatAccountScroll,
    required this.chatInput,
    this.chatFocusNode,
    required this.voiceSearch,
    required this.chatSearch,
    required this.selectedVoiceAccountId,
    required this.selectedChatAccountId,
    required this.voiceSearchQuery,
    required this.chatSearchQuery,
    required this.voiceAccountsRevealed,
    required this.chatAccountsRevealed,
    required this.voiceIssueResolved,
    required this.chatIssueResolved,
    required this.coachPrompt,
    required this.coachTarget,
    required this.lastTranscript,
    required this.recording,
    required this.processing,
    required this.turnType,
    required this.onHudNext,
    required this.onToggleRecord,
    required this.onSubmitChatTyped,
    required this.onVoiceSearchChanged,
    required this.onChatSearchChanged,
    required this.onSelectVoiceAccount,
    required this.onSelectChatAccount,
    required this.onConfirmVoiceSearch,
    required this.onConfirmChatSearch,
    required this.onConfirmVoiceSelect,
    required this.onConfirmChatSelect,
    required this.onResolveVoice,
    required this.onResolveChat,
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
                  'Hybrid Session',
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
                        const Gap(10),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(child: _channelColumn(isVoice: true)),
                              const Gap(12),
                              Expanded(child: _channelColumn(isVoice: false)),
                            ],
                          ),
                        ),
                        if (coachPrompt != null) ...[
                          const Gap(10),
                          _coachPanel(),
                        ],
                      ],
                    ),
                  ),
                  const VerticalDivider(
                    width: 1,
                    thickness: 0.5,
                    color: Color(0xFF2A2A2A),
                  ),
                  SizedBox(
                    width: 280,
                    child: Container(
                      color: const Color(0xFF121212),
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
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
                          const Gap(10),
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
                                  'Handle chat and voice with the same workstation layout as Hybrid Session.',
                              style: const TextStyle(
                                color: Color(0xFF93C5FD),
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
              const Gap(12),
              if (lane != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF243044),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Active: $lane',
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
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
            hudText ?? 'Handle both channels carefully.',
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

  Widget _channelColumn({required bool isVoice}) {
    final title = isVoice
        ? 'VOICE · ${scenario.customerName.replaceFirst('Voice: ', '')}'
        : 'CHAT · ${scenario.secondaryCustomerName ?? 'Chat customer'}';
    final bubbles = isVoice ? voiceBubbles : chatBubbles;
    final scroll = isVoice ? voiceScroll : chatScroll;
    final useLookup = isVoice
        ? scenario.usesAccountLookup
        : scenario.usesSecondaryAccountLookup;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: DefaultTabController(
        length: useLookup ? 2 : 1,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
            if (useLookup)
              const TabBar(
                indicatorColor: Colors.green,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                tabs: [
                  Tab(text: 'Conversation'),
                  Tab(text: 'Account Lookup'),
                ],
              )
            else
              const Gap(8),
            Expanded(
              child: useLookup
                  ? TabBarView(
                      children: [
                        _bubbleList(bubbles, scroll, isVoice),
                        _accountPanel(isVoice: isVoice),
                      ],
                    )
                  : _bubbleList(bubbles, scroll, isVoice),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubbleList(
    List<ScenarioChatBubbleData> bubbles,
    ScrollController scroll,
    bool isVoice,
  ) {
    final name = isVoice
        ? scenario.customerName.replaceFirst('Voice: ', '')
        : (scenario.secondaryCustomerName ?? 'Customer');
    return Padding(
      padding: const EdgeInsets.all(10),
      child: bubbles.isEmpty
          ? Center(
              child: Text(
                isVoice ? 'Voice conversation' : 'Chat conversation',
                style: const TextStyle(color: Color(0xFFB0B8C4)),
              ),
            )
          : ListView.builder(
              controller: scroll,
              itemCount: bubbles.length,
              itemBuilder: (_, i) =>
                  ScenarioChatBubble(bubble: bubbles[i], customerName: name),
            ),
    );
  }

  Widget _accountPanel({required bool isVoice}) {
    final active = isVoice
        ? (lane == 'tool_voice' || lane == 'voice')
        : (lane == 'tool_chat' || lane == 'chat');

    return ScenarioAccountLookupPanel(
      accounts: isVoice ? scenario.accounts : scenario.secondaryAccounts,
      searchQuery: isVoice ? voiceSearchQuery : chatSearchQuery,
      selectedAccountId: isVoice
          ? selectedVoiceAccountId
          : selectedChatAccountId,
      issueResolved: isVoice ? voiceIssueResolved : chatIssueResolved,
      accountsRevealed: isVoice ? voiceAccountsRevealed : chatAccountsRevealed,
      allowSearch: active && turnType == ScenarioTurnType.accountSearch,
      allowSelect: active && turnType == ScenarioTurnType.accountSelect,
      allowResolve: active && turnType == ScenarioTurnType.accountResolve,
      searchController: isVoice ? voiceSearch : chatSearch,
      scrollController: isVoice ? voiceAccountScroll : chatAccountScroll,
      onSearchChanged: isVoice ? onVoiceSearchChanged : onChatSearchChanged,
      onSelectAccount: isVoice ? onSelectVoiceAccount : onSelectChatAccount,
      onConfirmSearch: isVoice ? onConfirmVoiceSearch : onConfirmChatSearch,
      onConfirmSelect: isVoice ? onConfirmVoiceSelect : onConfirmChatSelect,
      onResolve: isVoice ? onResolveVoice : onResolveChat,
      sector: isVoice
          ? scenario.sector
          : (scenario.secondarySector ?? scenario.sector),
    );
  }

  Widget _coachPanel() {
    final isSpeak = turnType == ScenarioTurnType.speakExact;
    final isType = turnType == ScenarioTurnType.typeExact;

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
            const Gap(8),
            Text(
              isSpeak ? 'Say this:' : 'Type this:',
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
            const Gap(4),
            Text(
              coachTarget!,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ],
          if (isSpeak) ...[
            if (lastTranscript != null) ...[
              const Gap(8),
              Text(
                'Transcript: $lastTranscript',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
            const Gap(10),
            SizedBox(
              width: double.infinity,
              height: 44,
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
          if (isType) ...[
            const Gap(10),
            Row(
              children: [
                Expanded(
                  child: Focus(
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.enter &&
                          !HardwareKeyboard.instance.isShiftPressed) {
                        onSubmitChatTyped();
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: TextField(
                      controller: chatInput,
                      focusNode: chatFocusNode,
                      autofocus: true,
                      minLines: 1,
                      maxLines: 3,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => onSubmitChatTyped(),
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF1A1A1A),
                        hintText: 'Type chat reply...',
                        hintStyle: const TextStyle(color: Color(0xFFB0B8C4)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: Color(0xFF4B5563),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: Color(0xFF4B5563),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: Color(0xFF70BD8A),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const Gap(8),
                IconButton(
                  onPressed: onSubmitChatTyped,
                  icon: const Icon(Icons.send, color: Colors.green),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
