import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:trainixprogram/models/customer_account.dart';
import 'package:trainixprogram/models/messages.dart';
import 'package:trainixprogram/models/session_score.dart';
import 'package:trainixprogram/models/simulation_history.dart';
import 'package:trainixprogram/services/gemini_evaluation_api_service.dart';
import 'package:trainixprogram/services/open_router_api_service.dart';
import 'package:trainixprogram/screens/mock_call_ui/right_message.dart';
import 'package:trainixprogram/widgets/account_lookup_view.dart';
import 'package:trainixprogram/widgets/scenario_guide_view.dart';

//enumeration for the phases of the chat conversation
enum _ChatPhase { active, resolved, afterCallWork, gracePeriod, waitingToEnd }

//handles the text based customer interaction
//runs parallel with the voice channel
//a customer in a voice channel is different from a customer
//in this channel
class ChatPanel extends StatefulWidget {
  //accept a sector that was chosen
  final String sector;

  //adds the evaluation and increments interaction
  final ValueChanged<SessionEvaluation>? onEvaluation;

  //records words per minute typed
  final ValueChanged<double>? onChatTurn;

  //how long did the problem got resolved
  final ValueChanged<double>? onResolutionSeconds;

  //can another chat start?
  final bool Function()? canStartNewCustomer;

  //tells the parent when chat enters/leaves its own after-work-report or
  //grace-period flow, so the session can't end out from under it
  final ValueChanged<bool>? onBusyChanged;

  //tells the parent chat has started serving a customer
  //fired for the first customer and such
  final VoidCallback? onCustomerStarted;

  //constructor
  const ChatPanel({
    super.key,
    required this.sector,
    this.onEvaluation,
    this.onChatTurn,
    this.onResolutionSeconds,
    this.canStartNewCustomer,
    this.onBusyChanged,
    this.onCustomerStarted,
  });
  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  //grace period set
  static const int _graceMinSeconds = 15;
  static const int _graceMaxSeconds = 30;

  //how long the resolved chat stays visible before auto continuing into
  //After Chat Work
  static const int _resolvedPauseSeconds = 5;
  Timer? _resolvedTimer;
  int _remainingResolvedSeconds = 0;

  //starting type timer
  DateTime? _typingStartTime;

  //TESDA telemetry, scoped to the CURRENT customer interaction only

  //total backspace keystrokes across every message typed to this
  //customer so far. Detected as a length decrease in the input field
  //not a true per-keystroke listener
  int _interactionBackspaceCount = 0;

  //total characters actually sent across every
  //message this interaction used with the backspace count above to
  //derive a keystroke-accuracy percentage
  int _interactionCharsTyped = 0;

  //previous input field length, used to detect backspace events in
  //onChanged
  int _previousInputLength = 0;

  //one WPM sample per message sent this interaction, averaged at
  //evaluation time
  final List<double> _interactionWpmSamples = [];

  //whether a send is currently in progress
  //blocks a second send from starting before the first one
  //finishes
  bool _isSending = false;

  //whether the last send or opening fetch attempt failed after every
  //retry, and what to retry if the trainee taps the banner
  //null means it was the opening message that failed, not a specific typed one
  bool _showSendError = false;
  String? _failedMessageText;

  //controller for chat message
  final TextEditingController _inputController = TextEditingController();

  //controller for the after-chat-work report
  final TextEditingController _reportController = TextEditingController();

  //selected tab
  //0 - Chat
  //1 - Account Lookup
  //2 - Scenario Guide
  int _selectedTab = 0;

  //thet phase of the chat
  _ChatPhase _chatPhase = _ChatPhase.active;

  //remaining seconds of the grace period
  int _remainingSeconds = 0;

  //ticker for grace period
  Timer? _graceTimer;

  //declaring an instance of the API
  late final OpenRouterAPIService openRouterAPI;

  //resolution timer
  DateTime? _customerStartTime;

  @override
  void initState() {
    super.initState();
    openRouterAPI = OpenRouterAPIService(fixedSector: widget.sector);
    _customerStartTime = DateTime.now();

    //this is the session's first chat customer let the parent know
    //chat now occupies a quota slot, same as every later customer does.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onCustomerStarted?.call();
    });

    //make the customer chat first
    //in a real scenario, customer is the first to reach out
    //their concerncs to the customer support
    _requestOpeningMessage();
  }

  //make the customer in the chat channel to chat first
  Future<void> _requestOpeningMessage() async {
    setState(() {
      _isSending = true;
      _showSendError = false;
    });

    try {
      //wait for the response
      final response = await openRouterAPI.getOpeningMessage(context);
      if (!mounted) return;

      //every retry failed  show the retry banner instead of leaving
      //an empty, unexplained chat with no way to know it's broken
      if (response.isError) {
        setState(() {
          _showSendError = true;
          _failedMessageText = null;
        });
        return;
      }

      //if the account was provided as well as the account id, do this
      if (response.accountProvided && response.accountId != null) {
        //initialize the account provider
        final accountProvider = Provider.of<AccountProvider>(
          context,
          listen: false,
        );

        //if there's no list of accounts yet, generate accounts
        if (accountProvider.accounts.isEmpty) {
          accountProvider.generateAccounts(
            sector: widget.sector,
            targetAccountId: response.accountId!,
            problem: openRouterAPI.chosenSimulation['problem'] ?? '',
            //name the account after the actual customer, so Account
            //Lookup always matches who the agent is chatting with
            targetOwnerName:
                openRouterAPI.chosenSimulation['name'] ?? 'Customer',
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _graceTimer?.cancel();
    _resolvedTimer?.cancel();
    _inputController.dispose();
    _reportController.dispose();
    //release this customer's name/problem back to the shared pool so
    //the other channel isn't blocked from ever picking it again
    openRouterAPI.releaseHeldScenario();
    super.dispose();
  }

  //build the chat panel connect with right_message
  @override
  Widget build(BuildContext context) {
    //non-active phases take over the whole panel, the same way voice's
    //After Call Work, break, wrapping-up screens replace its content
    //entirely instead of showing as a small banner
    if (_chatPhase == _ChatPhase.afterCallWork) {
      return _buildAfterCallWork();
    }
    if (_chatPhase == _ChatPhase.gracePeriod) {
      return _buildGracePeriodScreen();
    }
    if (_chatPhase == _ChatPhase.waitingToEnd) {
      return _buildWaitingToEndScreen();
    }

    final hasCustomerMessage = Provider.of<MessageProvider>(
      context,
      listen: false,
    ).messages.any((m) => m.role == 'assistant');

    return RightMessage(
      sector: openRouterAPI.chosenSimulation['sector'] ?? widget.sector,
      customerName: openRouterAPI.chosenSimulation['name'] ?? 'New Customer',
      customerProblem: openRouterAPI.chosenSimulation['problem'],
      customerEmotion: openRouterAPI.chosenSimulation['emotion'],
      selectedTab: _selectedTab,
      onTabChanged: (index) => setState(() => _selectedTab = index),
      inputController: _inputController,
      onSendMessage: sendChatmessage,
      isSending: _isSending,
      customerHasSpoken: hasCustomerMessage,
    );
  }

  //build Tab Bar UI
  Widget _buildTabBar() {
    return Row(
      children: [
        //Chat UI
        TextButton(
          onPressed: () => setState(() => _selectedTab = 0),
          child: Text(
            'Chat',
            style: TextStyle(
              fontWeight: _selectedTab == 0
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
        //Account Lookup UI, always available in chat
        TextButton(
          onPressed: () => setState(() => _selectedTab = 1),
          child: Text(
            'Account Lookup',
            style: TextStyle(
              fontWeight: _selectedTab == 1
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
        //Scenario Guide
        TextButton(
          onPressed: () => setState(() => _selectedTab = 2),
          child: Text(
            'Scenario Guide',
            style: TextStyle(
              fontWeight: _selectedTab == 2
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  //build the Chat UI
  Widget _buildChatArea() {
    return Consumer<MessageProvider>(
      builder: (context, value, child) {
        if (value.messages.isEmpty) {
          return const Center(child: Text('No messages yet.'));
        }
        return ListView.builder(
          itemCount: value.messages.length,
          itemBuilder: (_, index) {
            final data = value.messages[index];
            //strip the internal "[AGENT]: " tag used to tell the AI
            //who's speaking. It's not meant to be shown to the trainee
            final displayText = data.role == 'user'
                ? data.message.replaceFirst('[AGENT]: ', '')
                : data.message;
            return ListTile(
              title: Text(
                textAlign: data.role != 'user'
                    ? TextAlign.left
                    : TextAlign.right,
                data.role != 'user'
                    ? 'Customer: $displayText'
                    : 'You: $displayText',
              ),
            );
          },
        );
      },
    );
  }

  //after chat work report UI
  Widget _buildAfterCallWork() {
    // final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 25, 25, 25),
              shape: BoxShape.circle,
              border: Border.all(color: Color.fromARGB(255, 48, 48, 48)),
            ),
            child: const Icon(Icons.edit_note, size: 32),
          ),
          Gap(20),
          const Text(
            'After Chat Work',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Conversation ended. Jot down a quick report before your next chat.',
            style: textTheme.bodySmall?.copyWith(
              color: const Color.fromARGB(255, 244, 243, 243),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          Gap(40),
          TextField(
            controller: _reportController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Chat summary, outcome, notes...',
              hintStyle: textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                color: const Color.fromARGB(255, 187, 186, 186),
              ),
              labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                color: Colors.white,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 187, 186, 186),
                  width: .5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(
                  color: Color.fromARGB(255, 255, 255, 255),
                  width: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              _reportController.clear();
              _startGracePeriod();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );
  }

  //grace period UI
  Widget _buildGracePeriodScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Lottie.asset('assets/animations/break_loading.json', width: 80),
        const Text('On Break', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Next chat in $_remainingSeconds seconds...'),
      ],
    );
  }

  //wrapping-up screen UI
  Widget _buildWaitingToEndScreen() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle_outline, size: 56),
        SizedBox(height: 16),
        Text('No More Chats', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text(
          'Session is wrapping up  waiting for the last customer to finish.',
        ),
      ],
    );
  }

  //send error banner UI
  Widget _buildSendErrorBanner() {
    if (!_showSendError) return const SizedBox.shrink();
    final label = _failedMessageText == null
        ? "Couldn't reach the customer  tap to retry."
        : 'Message failed to send  tap to retry.';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: InkWell(
        onTap: _isSending ? null : _retry,
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //retries whatever last failed. A specific typed message, or the
  //opening message fetch
  void _retry() {
    if (_isSending) return;
    final text = _failedMessageText;
    if (text != null) {
      _sendUserMessage(text);
    } else {
      _requestOpeningMessage();
    }
  }

  //evaluate the chat that just finished. The grace period itself now
  //starts separately, once the agent submits the after-chat-work
  void _evaluateResolution() async {
    //initialize message and history providers
    final messageProvider = Provider.of<MessageProvider>(
      context,
      listen: false,
    );
    final historyProvider = Provider.of<SimulationHistoryProvider>(
      context,
      listen: false,
    );

    //compute this interaction's average typing pace
    final avgWpm = _interactionWpmSamples.isEmpty
        ? 0.0
        : _interactionWpmSamples.reduce((a, b) => a + b) /
              _interactionWpmSamples.length;

    //keystroke accuracy - characters that survived to being sent,
    //divided by total keystrokes
    final totalKeystrokes = _interactionCharsTyped + _interactionBackspaceCount;
    final accuracy = totalKeystrokes > 0
        ? (_interactionCharsTyped / totalKeystrokes) * 100
        : 100.0;

    //evaluate the chat that got finished against the TESDA rubric
    final evaluation = await GeminiEvaluationApiService().evaluateChatTesda(
      messages: List.from(messageProvider.messages),
      sector: openRouterAPI.chosenSimulation['sector'] ?? '',
      customerEmotion: openRouterAPI.chosenSimulation['emotion'] ?? '',
      customerProblem: openRouterAPI.chosenSimulation['problem'] ?? '',
      typingWpm: avgWpm,
      typingAccuracy: accuracy,
      backspaceCount: _interactionBackspaceCount,
    );

    //while in this state, save the evaluation and add that evaluation
    //to the list of session evaluations
    if (mounted) {
      historyProvider.saveEvaluation(evaluation);
      widget.onEvaluation?.call(evaluation);
    }
  }

  //keeps the resolved chat visible for a fixed pause, then auto-
  //advances into After Chat Work. No tap needed
  void _startResolvedPause() {
    _resolvedTimer?.cancel();
    setState(() => _remainingResolvedSeconds = _resolvedPauseSeconds);
    _resolvedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingResolvedSeconds--;
        if (_remainingResolvedSeconds <= 0) {
          timer.cancel();
          _chatPhase = _ChatPhase.afterCallWork;
        }
      });
    });
  }

  //start the grace timer
  void _startGracePeriod() {
    //set the seconds for how long the grace timer is
    final seconds =
        _graceMinSeconds +
        Random().nextInt(_graceMaxSeconds - _graceMinSeconds + 1);

    //cancel any previous grace timer first. Without this, two
    //triggers in a row would leave two timers running independently,
    //each clearing the chat and generating a new customer on its own
    //schedule
    _graceTimer?.cancel();

    //set the phase to grace period
    setState(() {
      _chatPhase = _ChatPhase.gracePeriod;
      _remainingSeconds = seconds;
    });

    //start the timer
    _graceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          timer.cancel();
          _startNewCustomer();
        }
      });
    });
  }

  //start a new customer for the chat channel
  void _startNewCustomer() {
    //check if we can start a new chat
    final canStart = widget.canStartNewCustomer?.call() ?? true;

    //if we cannot anymore, set the phase to waiting to end and tell
    //the parent chat is no longer busy. This is what lets the
    //session finish if chat was the last thing blocking it
    if (!canStart) {
      setState(() => _chatPhase = _ChatPhase.waitingToEnd);
      widget.onBusyChanged?.call(false);
      return;
    }

    //this customer is starting for real. Let the parent know chat
    //now occupies a quota slot again
    widget.onCustomerStarted?.call();

    //initialize the message provider
    final messageProvider = Provider.of<MessageProvider>(
      context,
      listen: false,
    );

    //clear the messages for the next chat
    messageProvider.clearMessage();
    Provider.of<AccountProvider>(context, listen: false).reset();
    openRouterAPI.clearMessages(context);

    //reset the starting time again
    _customerStartTime = DateTime.now();

    //reset TESDA telemetry for the new customer. These are per-
    //interaction, not per-session
    _interactionBackspaceCount = 0;
    _interactionCharsTyped = 0;
    _interactionWpmSamples.clear();
    _previousInputLength = 0;

    //clear any leftover error state from the previous customer
    _showSendError = false;
    _failedMessageText = null;

    //set the chat phase to active and tell the parent chat is no
    //longer in its wrap-up flow
    setState(() => _chatPhase = _ChatPhase.active);
    widget.onBusyChanged?.call(false);

    //and make the customer chat first again
    _requestOpeningMessage();
  }

  //send the chat message
  void sendChatmessage() {
    //if the agent sent nothing, isn't in the active chat phase, or a
    //previous message is still being processed, do nothing
    if (_inputController.text.isEmpty ||
        _chatPhase != _ChatPhase.active ||
        _isSending) {
      return;
    }

    //the agent can't speak first. Only allow sending once the
    //customer has actually said something
    final hasCustomerMessage = Provider.of<MessageProvider>(
      context,
      listen: false,
    ).messages.any((m) => m.role == 'assistant');
    if (!hasCustomerMessage) return;

    final text = _inputController.text;
    _inputController.clear();
    _previousInputLength = 0;
    _sendUserMessage(text);
  }

  //does the actual send + response handling
  Future<void> _sendUserMessage(String text) async {
    setState(() {
      _isSending = true;
      _showSendError = false;
    });

    try {
      //get the seconds passed
      final elapsedSeconds = _typingStartTime == null
          ? 0.0
          : DateTime.now().difference(_typingStartTime!).inMilliseconds / 1000;

      //get the word count
      final wordCount = text
          .trim()
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .length;

      //and get the words per minute based on the seconds had passed
      //and the word count
      final wpm = elapsedSeconds > 0 ? (wordCount / elapsedSeconds) * 60 : 0.0;

      //then save that to a list of words per minute
      widget.onChatTurn?.call(wpm);

      //also feed this interaction's own TESDA telemetry
      _interactionWpmSamples.add(wpm);
      _interactionCharsTyped += text.trim().length;

      //then set the date to null
      _typingStartTime = null;

      //wait for the response
      final response = await openRouterAPI.getResponseWithoutTypeCast(
        context,
        text,
      );

      if (!mounted) return;

      //every retry failed. Show the retry banner instead of putting
      //an error message in the customer's mouth
      if (response.isError) {
        setState(() {
          _showSendError = true;
          _failedMessageText = text;
        });
        return;
      }

      _failedMessageText = null;

      //if the account was provided as well as the id, do this
      if (response.accountProvided && response.accountId != null) {
        //initialize account provider
        final accountProvider = Provider.of<AccountProvider>(
          context,
          listen: false,
        );

        //if its empty, then generate a list of accounts
        if (accountProvider.accounts.isEmpty) {
          accountProvider.generateAccounts(
            sector: openRouterAPI.chosenSimulation['sector'] ?? 'Tech Support',
            targetAccountId: response.accountId!,
            problem: openRouterAPI.chosenSimulation['problem'] ?? '',
            //name the account after the actual customer, so Account
            //Lookup always matches who the agent is chatting with
            targetOwnerName:
                openRouterAPI.chosenSimulation['name'] ?? 'Customer',
          );
        }
      }

      //if the problem is already resolved or already ended, and we're
      //still in the active phase, do this
      if ((response.callStatus == 'resolved' ||
              response.callStatus == 'ended') &&
          _chatPhase == _ChatPhase.active) {
        //check first if theres a start time
        //then calculate the seconds had passed
        if (_customerStartTime != null) {
          final seconds = DateTime.now()
              .difference(_customerStartTime!)
              .inSeconds
              .toDouble();

          //then add that to a list of chat resolution
          widget.onResolutionSeconds?.call(seconds);
        }

        //kick off evaluation in the background and tell the parent chat
        //is now busy wrapping up  but don't jump straight into the
        //full-panel After Chat Work screen yet. Land on "resolved" for
        //a fixed 5-second pause first, which keeps the chat visible instead of
        //it vanishing instantly, and switch to the Chat tab in case the
        //agent was on Account Lookup or Scenario Guide when it landed.
        _evaluateResolution();
        widget.onBusyChanged?.call(true);
        setState(() {
          _chatPhase = _ChatPhase.resolved;
          _selectedTab = 0;
        });
        _startResolvedPause();
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  //build the Chat input area
  Widget _buildChatInput() {
    //once resolved, replace the input with a countdown banner instead
    //of auto-advancing into After Chat Work instantly.
    if (_chatPhase == _ChatPhase.resolved) {
      return _buildResolvedBanner();
    }

    return Consumer<MessageProvider>(
      builder: (context, messageProvider, _) {
        //the agent can't speak first, this only becomes true once the
        //customer's opening message has actually arrived
        final customerHasSpoken = messageProvider.messages.any(
          (m) => m.role == 'assistant',
        );
        final canSend = customerHasSpoken && !_isSending;

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!customerHasSpoken && !_showSendError)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Text(
                    'Waiting for the customer to say something first...',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
              _buildSendErrorBanner(),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      enabled: customerHasSpoken,
                      onChanged: (value) {
                        //a drop in length = a backspace/delete event.
                        //Not a true keystroke listener (a cut/select-
                        //delete counts the same as holding backspace),
                        if (value.length < _previousInputLength) {
                          _interactionBackspaceCount +=
                              (_previousInputLength - value.length);
                        }
                        _previousInputLength = value.length;
                        if (value.isNotEmpty && _typingStartTime == null) {
                          _typingStartTime = DateTime.now();
                        } else if (value.isEmpty) {
                          _typingStartTime = null;
                        }
                      },
                      decoration: InputDecoration(
                        hintText: customerHasSpoken
                            ? 'Type a message...'
                            : 'Waiting for customer...',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: canSend ? sendChatmessage : null,
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  //shown in place of the input box for the 5-second pause after
  //resolution. Keeps the transcript on screen and readable instead of
  //cutting straight to After Chat Work
  Widget _buildResolvedBanner() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Issue resolved  continuing in $_remainingResolvedSeconds...',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
