import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:trainixprogram/models/messages.dart';
import 'package:trainixprogram/widgets/account_lookup_view.dart';
import 'package:trainixprogram/widgets/scenario_guide_view.dart';

//refer to chat_panel RigthMessage
class RightMessage extends StatelessWidget {
  final String sector;
  final String customerName;
  final String? customerProblem;
  final String? customerEmotion;
  final int selectedTab;
  final ValueChanged<int>? onTabChanged;
  final TextEditingController inputController;
  final VoidCallback? onSendMessage;
  final bool isSending;
  final bool customerHasSpoken;
  final ValueChanged<String>? onInputChanged;
  final Widget? customContent;

  const RightMessage({
    super.key,
    required this.sector,
    this.customerName = 'New Customer',
    this.customerProblem,
    this.customerEmotion,
    this.selectedTab = 0,
    this.onTabChanged,
    required this.inputController,
    this.onSendMessage,
    this.isSending = false,
    this.customerHasSpoken = true,
    this.onInputChanged,
    this.customContent,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark
        ? Theme.of(context).colorScheme.surface
        : const Color(0xFF0B0F17);

    return Container(
      color: bgColor,
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: [
          // Top Tab Bar Navigation
          _buildTabBar(),
          const Divider(height: 1, thickness: .5, color: Color(0xFF1E293B)),

          // Main View Content area (Chat, Account Lookup, or Scenario Guide)
          Expanded(
            child:
                customContent ??
                (selectedTab == 1
                    ? AccountLookupView(sector: sector)
                    : selectedTab == 2
                    ? ScenarioGuideView(
                        sector: sector,
                        emotion: customerEmotion,
                        problem: customerProblem,
                      )
                    : _buildChatBody()),
          ),
        ],
      ),
    );
  }

  // Top navigation tabs (Chat, Account Lookup, Scenario Guide) matching the design image
  Widget _buildTabBar() {
    final tabs = ['Chat', 'Account Lookup', 'Scenario Guide'];

    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 14),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = selectedTab == index;
          return GestureDetector(
            onTap: () => onTabChanged?.call(index),
            child: Container(
              margin: const EdgeInsets.only(right: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    tabs[index],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                  const Gap(10),
                  // Active tab bottom underline indicator
                  Container(
                    height: 2,
                    width: tabs[index] == selectedTab ? 36 : 0,
                    color: isSelected
                        ? const Color(0xFF3B82F6)
                        : Colors.transparent,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // Main Chat body combining transcript area and bottom capsule input box
  Widget _buildChatBody() {
    return Column(children: [_buildChatArea(), _buildChatInput()]);
  }

  // Chat transcript list area
  Widget _buildChatArea() {
    return Expanded(
      child: Consumer<MessageProvider>(
        builder: (context, messageProvider, _) {
          final messages = messageProvider.messages;

          if (messages.isEmpty) {
            return Center(
              child: Lottie.asset('assets/animations/loading.json', width: 100),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              final isCustomer = msg.role == 'assistant';

              if (isCustomer) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer Avatar and Header Name
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
                            customerName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const Gap(10),
                      // Customer Message Bubble
                      Container(
                        margin: const EdgeInsets.only(left: 48, right: 32),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 26, 26, 27),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          msg.message,
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
              } else {
                // Agent (User) Message Bubble
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
                        msg.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }

  // Bottom Capsule Message Input Bar
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
                enabled: customerHasSpoken && !isSending,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'Message..',
                  hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 16),
                  border: InputBorder.none,
                ),
                onChanged: onInputChanged,
                onSubmitted: (_) {
                  if (onSendMessage != null &&
                      customerHasSpoken &&
                      !isSending) {
                    onSendMessage!();
                  }
                },
              ),
            ),
            GestureDetector(
              onTap: (customerHasSpoken && !isSending) ? onSendMessage : null,
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
