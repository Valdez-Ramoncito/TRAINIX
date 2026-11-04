import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:trainixprogram/models/messages.dart';
import 'package:trainixprogram/models/simulation_coach.dart';
import 'package:trainixprogram/models/coach_view_model.dart';
import 'package:trainixprogram/widgets/account_lookup_view.dart';
import 'package:trainixprogram/widgets/scenario_guide_view.dart';
import 'package:trainixprogram/widgets/sector_issue_guide_view.dart';

//refer to chat_panel RigthMessage
class RightMessage extends StatelessWidget {
  final String sector;
  final String customerName;
  final String? customerProblem;
  final String? customerEmotion;
  final int selectedTab;
  final ValueChanged<int>? onTabChanged;
  final int? highlightToolTab;
  final TextEditingController inputController;
  final FocusNode? inputFocusNode;
  final VoidCallback? onSendMessage;
  final bool isSending;
  final bool customerHasSpoken;
  final ValueChanged<String>? onInputChanged;
  final Widget? customContent;
  final Widget? chatHeader;
  final String? inputHint;
  final bool waitingForCustomer;
  final String? customerNameForGuide;
  final String? accountId;
  final String? coachTip;
  final bool customerConfirmed;
  final bool awaitingClosing;
  final bool hasTraineeSpoken;
  final List<String> reminders;
  final bool showScriptGuide;
  final bool scriptGuideExpanded;
  final bool toolWorkDone;
  final bool showEscalationTab;
  final bool isEscalating;
  final int traineeTurnCount;
  final String lastCustomerMessage;
  final String lastTraineeMessage;
  final ValueChanged<String>? onEscalationSubmit;
  final CoachViewModel? coachVm;
  final VoidCallback? onSectorGuideIssueOpened;

  const RightMessage({
    super.key,
    required this.sector,
    this.customerName = 'New Customer',
    this.customerProblem,
    this.customerEmotion,
    this.selectedTab = 0,
    this.onTabChanged,
    this.highlightToolTab,
    this.onSectorGuideIssueOpened,
    required this.inputController,
    this.inputFocusNode,
    this.onSendMessage,
    this.isSending = false,
    this.customerHasSpoken = true,
    this.onInputChanged,
    this.customContent,
    this.chatHeader,
    this.inputHint,
    this.waitingForCustomer = false,
    this.customerNameForGuide,
    this.accountId,
    this.coachTip,
    this.customerConfirmed = false,
    this.awaitingClosing = false,
    this.hasTraineeSpoken = false,
    this.reminders = const [],
    this.showScriptGuide = true,
    this.scriptGuideExpanded = true,
    this.toolWorkDone = false,
    this.showEscalationTab = false,
    this.isEscalating = false,
    this.traineeTurnCount = 0,
    this.lastCustomerMessage = '',
    this.lastTraineeMessage = '',
    this.onEscalationSubmit,
    this.coachVm,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark
        ? Theme.of(context).colorScheme.surface
        : const Color(0xFF0B0F17);

    final mainColumn = Column(
      children: [
        _buildTabBar(),
        const Divider(height: 1, thickness: .5, color: Color(0xFF1E293B)),
        Expanded(child: customContent ?? _buildTabContent()),
      ],
    );

    return Container(
      color: bgColor,
      width: double.infinity,
      height: double.infinity,
      child: showScriptGuide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: mainColumn),
                const VerticalDivider(
                  width: 1,
                  thickness: 0.5,
                  color: Color(0xFF1E293B),
                ),
                CollapsibleScriptGuide(
                  initiallyExpanded: scriptGuideExpanded,
                  notepadBottomInset: 56,
                  child: ScenarioGuideView(
                    sector: sector,
                    emotion: customerEmotion,
                    problem: customerProblem,
                    customerName: customerNameForGuide ?? customerName,
                    accountId: accountId,
                    coachTip: coachVm?.tip ?? coachTip,
                    customerConfirmed: customerConfirmed,
                    awaitingClosing: awaitingClosing,
                    hasTraineeSpoken: hasTraineeSpoken,
                    hasCustomerSpoken: customerHasSpoken,
                    toolWorkDone: toolWorkDone,
                    showEscalationTab:
                        coachVm?.showEscalation ?? showEscalationTab,
                    coachVm: coachVm,
                    isEscalating: isEscalating,
                    traineeTurnCount: traineeTurnCount,
                    lastCustomerMessage: lastCustomerMessage,
                    lastTraineeMessage: lastTraineeMessage,
                    onEscalationSubmit: onEscalationSubmit,
                    reminders: reminders,
                  ),
                ),
              ],
            )
          : mainColumn,
    );
  }

  bool get _showAccountLookup {
    final fromProblem = SimulationCoach.needsAccountLookup(
      customerProblem ?? '',
      sector: sector,
    );
    // Mission packs that require tools must always show Account Lookup
    final fromGuide =
        coachVm != null &&
        (coachVm!.highlightToolTab == 1 ||
            (coachVm!.amberOverride ?? '').toLowerCase().contains(
              'account lookup',
            ));
    return fromProblem || fromGuide;
  }

  bool get _showSectorGuide {
    return SimulationCoach.needsSectorGuide(
      customerProblem ?? '',
      sector: sector,
    );
  }

  int get _effectiveTab {
    if (selectedTab == 1 && !_showAccountLookup) return 0;
    if (selectedTab == 2 && !_showSectorGuide) return 0;
    if (selectedTab > 2) return 0;
    return selectedTab;
  }

  Widget _buildTabContent() {
    final tab = _effectiveTab;
    final hasCustomer =
        (customerProblem != null && customerProblem!.trim().isNotEmpty) ||
        (customerNameForGuide != null &&
            customerNameForGuide!.trim().isNotEmpty) ||
        (customerName.isNotEmpty && customerName != 'Customer');
    if (tab == 1 && _showAccountLookup) {
      if (!hasCustomer) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Waiting for a customer. Account Lookup unlocks once the conversation starts.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
          ),
        );
      }
      return AccountLookupView(sector: sector);
    }
    if (tab == 2 && _showSectorGuide) {
      if (!hasCustomer) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Waiting for a customer. Sector guidance unlocks once their issue is known.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
          ),
        );
      }
      return SectorIssueGuideView(
        sector: sector,
        customerProblem: customerProblem,
        onIssueOpened: onSectorGuideIssueOpened,
      );
    }
    return _buildChatBody();
  }

  Widget _buildTabBar() {
    final items = <Map<String, Object>>[
      {'id': 0, 'label': 'Non-Voice'},
      if (_showAccountLookup) {'id': 1, 'label': 'Account Lookup'},
      if (_showSectorGuide)
        {'id': 2, 'label': SimulationCoach.sectorGuideTabLabel(sector)},
    ];
    final current = _effectiveTab;

    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 14),
      child: Row(
        children: items.map((item) {
          final id = item['id'] as int;
          final label = item['label'] as String;
          final isSelected = current == id;
          final needsAttention =
              highlightToolTab != null && highlightToolTab == id && !isSelected;
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => onTabChanged?.call(id),
              child: Container(
                margin: const EdgeInsets.only(right: 24),
                padding: needsAttention
                    ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
                    : EdgeInsets.zero,
                decoration: needsAttention
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFF59E0B),
                          width: 1.5,
                        ),
                        color: const Color(0x33F59E0B),
                      )
                    : null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected || needsAttention
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? Colors.white
                            : needsAttention
                            ? const Color(0xFFFBBF24)
                            : const Color(0xFFB0B8C4),
                      ),
                    ),
                    const Gap(10),
                    Container(
                      height: 2,
                      width: isSelected || needsAttention ? 36 : 0,
                      color: isSelected
                          ? const Color(0xFF3B82F6)
                          : needsAttention
                          ? const Color(0xFFF59E0B)
                          : Colors.transparent,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChatBody() {
    return Column(
      children: [
        if (chatHeader != null) chatHeader!,
        Expanded(
          child: RepaintBoundary(
            child: _AutoScrollMessageList(customerName: customerName),
          ),
        ),
        RepaintBoundary(child: _buildChatInput()),
      ],
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 26, 26, 27),
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.only(left: 24, right: 8, top: 6, bottom: 6),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: inputController,
                focusNode: inputFocusNode,
                enabled: customerHasSpoken && !isSending && !waitingForCustomer,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: waitingForCustomer
                      ? 'Customer is checking... please wait'
                      : (isSending ? 'Sending...' : (inputHint ?? 'Message..')),
                  hintStyle: const TextStyle(
                    color: Color(0xFFB0B8C4),
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                ),
                textInputAction: TextInputAction.send,
                onChanged: onInputChanged,
                onSubmitted: (_) {
                  if (onSendMessage != null &&
                      customerHasSpoken &&
                      !isSending &&
                      !waitingForCustomer) {
                    onSendMessage!();
                  }
                },
              ),
            ),
            GestureDetector(
              onTap: (customerHasSpoken && !isSending && !waitingForCustomer)
                  ? onSendMessage
                  : null,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF2563EB),
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AutoScrollMessageList extends StatefulWidget {
  final String customerName;

  const _AutoScrollMessageList({required this.customerName});

  @override
  State<_AutoScrollMessageList> createState() => _AutoScrollMessageListState();
}

class _AutoScrollMessageListState extends State<_AutoScrollMessageList> {
  final ScrollController _controller = ScrollController();
  int _lastCount = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_controller.hasClients) return;
      _controller.animateTo(
        _controller.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MessageProvider>(
      builder: (context, messageProvider, _) {
        final messages = messageProvider.messages;
        if (messages.length != _lastCount) {
          _lastCount = messages.length;
          _scrollToLatest();
        }

        if (messages.isEmpty) {
          return Center(
            child: Lottie.asset('assets/animations/loading.json', width: 100),
          );
        }

        return ListView.builder(
          controller: _controller,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index];
            final isCustomer = msg.role == 'assistant';

            if (isCustomer) {
              final display = SimulationCoach.stripInternalFields(msg.message);
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: Color.fromARGB(255, 95, 94, 94),
                          child: Icon(
                            Icons.person,
                            color: Color.fromARGB(255, 239, 240, 242),
                            size: 24,
                          ),
                        ),
                        const Gap(15),
                        Text(
                          widget.customerName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Gap(10),
                    Container(
                      margin: const EdgeInsets.only(left: 48, right: 32),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 26, 26, 27),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        display,
                        style: const TextStyle(
                          color: Color(0xFFE5E7EB),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.35,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    msg.message.replaceFirst('[AGENT]:', ''),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
