import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:trainixprogram/models/customer_account.dart';
import 'package:trainixprogram/models/customer.dart';
import 'package:trainixprogram/models/messages.dart';

//the one that reaches out to the API
class OpenRouterAPIService {
  final String fixedSector;
  bool hasStarted = false;
  Map<String, String> chosenSimulation = {};

  //accept a sector
  OpenRouterAPIService({required this.fixedSector});

  //set the customer state
  Map<String, String> _customerState = {
    'emotion': 'neutral',
    'accountProvided': 'false',
    'accountId': 'null',
    'problemStatus': 'pending',
    'callStatus': 'ongoing',
  };

  //window size of the message context sent through the API
  static const int _windowSize = 6;

  //set the customer names
  static const List<String> _customerNames = [
    'Maria Santos',
    'John Cruz',
    'Angela Reyes',
    'Mark Dela Cruz',
    'Grace Villanueva',
    'Paolo Mendoza',
    'Kristine Bautista',
    'Ramon Aquino',
    'Louella Garcia',
    'Daniel Torres',
  ];

  //set the emotions
  static const List<String> _emotions = [
    'frustrated',
    'confused',
    'anxious',
    'calm but firm',
    'angry',
    'polite but urgent',
    'impatient',
  ];

  //set the problems for each sector
  static const Map<String, List<String>> _problemsBySector = {
    'Finance': [
      'an unauthorized transaction appeared on their account',
      'their account balance does not match their records',
      'their card is being declined despite having funds',
      'unexpected fees were charged without explanation',
      'their loan application was rejected without a clear reason',
    ],
    'Healthcare': [
      'their insurance claim was denied',
      'they were billed incorrectly for a recent hospital visit',
      'they are unable to schedule an appointment',
      'their prescription is not being covered by insurance',
      'they are confused about a referral they received',
    ],
    'Telco': [
      'their internet connection keeps dropping',
      'unexpected charges appeared on their bill',
      'their mobile data is not working despite having an active plan',
      'there is a service outage in their area',
      'they were charged for roaming they did not expect',
    ],
    'Tech Support': [
      'their device stopped working after a recent update',
      'a software they need fails to install',
      'they are locked out of their account and cannot recover it',
      'their device has become unusably slow',
      'important files disappeared after a system restore',
    ],
  };

  //clear and set defaults
  void clearMessages(BuildContext context) {
    //clear the messages
    Provider.of<MessageProvider>(context, listen: false).clearMessage();

    hasStarted = false;
    chosenSimulation = {};
    _customerState = {
      'emotion': 'neutral',
      'accountProvided': 'false',
      'accountId': 'null',
      'problemStatus': 'pending',
      'callStatus': 'ongoing',
    };
  }

  //generate a customer based on the given sector
  Map<String, String> generateCustomerScenario() {
    final random = Random();

    //choose a random name for the customer
    final name = _customerNames[random.nextInt(_customerNames.length)];

    //choose a random emotion for the customer
    final emotion = _emotions[random.nextInt(_emotions.length)];

    //get the problems on the given sector
    final problems =
        _problemsBySector[fixedSector] ?? _problemsBySector['Tech Support']!;

    //choose a random problem based on that sector
    final problem = problems[random.nextInt(problems.length)];

    //then return the values
    return {
      'name': name,
      'sector': fixedSector,
      'emotion': emotion,
      'problem': problem,
    };
  }

  //update the customer's values
  void _updateCustomerState(Customer customer) {
    _customerState['emotion'] = customer.emotion;

    //check if the customer provided their account
    if (customer.accountProvided) {
      _customerState['accountProvided'] = 'true';
    }
    if (customer.accountId != null) {
      _customerState['accountId'] = customer.accountId!;
    }

    //update the problem status as well as the call status
    _customerState['problemStatus'] = customer.problemStatus;
    _customerState['callStatus'] = customer.callStatus;
  }

  //merge the customer's state
  Customer _mergeWithState(Customer parsed) {
    return Customer(
      reply: parsed.reply,
      emotion: parsed.emotion.isNotEmpty
          ? parsed.emotion
          : _customerState['emotion']!,
      accountProvided:
          parsed.accountProvided || _customerState['accountProvided'] == 'true',
      accountId:
          parsed.accountId ??
          (_customerState['accountId'] != 'null'
              ? _customerState['accountId']
              : null),
      problemStatus: parsed.problemStatus.isNotEmpty
          ? parsed.problemStatus
          : _customerState['problemStatus']!,
      callStatus: parsed.callStatus.isNotEmpty
          ? parsed.callStatus
          : _customerState['callStatus']!,
    );
  }

  //build a summary to be passed in the API
  String _buildContextSummary(List<Message> allMessages) {
    //if the length of all messages is lesser than the specified
    //window size, add nothing to the summary
    if (allMessages.length <= _windowSize) return '';

    //if the customer's account ID was given, add this to the prompt
    //otherwise state the latter
    final accountInfo = _customerState['accountId'] != 'null'
        ? 'Account ID ${_customerState["accountId"]} was provided.'
        : 'Account details not yet provided.';

    //then return the string to add it to the prompt
    return '\n\nCONVERSATION CONTEXT (earlier turns summarized): '
        'Customer is ${_customerState["emotion"]} about ${chosenSimulation["problem"]}. '
        '$accountInfo '
        'Problem status: ${_customerState["problemStatus"]}. '
        'Continue from here — do not repeat what was already discussed.';
  }

  //this reduces the message history sent to the API
  //this makes it so that it doesnt get past the window context
  //of the API model
  List<Map<String, dynamic>> _windowedHistory(List<Message> messages) {
    //if the length of the messages list is greater than the specified
    //window size, then remove the first elements in the list
    //otherwise just set it to the sent messages
    final window = messages.length > _windowSize
        ? messages.sublist(messages.length - _windowSize)
        : messages;

    //then return that list of messages into a List of Map of String, Dynamic
    return window.map((m) => {"role": m.role, "content": m.message}).toList();
  }

  //build the system prompt
  String _buildSystemPrompt(
    List<Message> allMessages, {
    bool issueResolved = false,
  }) {
    //if this is just the start of a conversation, generate a
    //customer scenario first
    if (!hasStarted) {
      chosenSimulation = generateCustomerScenario();
      hasStarted = true;
    }

    //the base prompt to be sent to the API
    //the API sends back a JSON Format for cleaner output
    final base =
        'ROLE: You are a CUSTOMER named ${chosenSimulation["name"]} calling a ${chosenSimulation["sector"]} support line. '
        'You are NOT the agent. The messages labeled "user" are from the support AGENT. '
        'Every agent message will start with [AGENT]: so you always know who is speaking. '
        'You are ${chosenSimulation["emotion"]} because ${chosenSimulation["problem"]}. '
        'Keep replies short and natural. Reflect your emotion in tone. '
        'Do not reveal account details unless the agent specifically asks. '
        'When giving your account ID make up a realistic one. '
        'React naturally — calm down if helped, get more upset if unhelpful. '
        'IMPORTANT: Do NOT acknowledge your issue as resolved just because the agent '
        'says it is fixed. '
        'For account-related issues (billing, balance, card, charges, access): '
        'only acknowledge resolution if you see a SYSTEM NOTE in these instructions. '
        'For device or technical issues where the agent walks you through steps: '
        'remain doubtful until you confirm the steps actually worked, then you may '
        'acknowledge resolution naturally. '
        'For anything else — a question you needed answered, guidance on a process, '
        'a referral or appointment explained, or any issue that is not account-related '
        'and does not involve technical troubleshooting steps: once the agent has '
        'given you a clear, complete answer or set clear next steps, you may '
        'acknowledge resolution naturally. There is nothing for you to "check" in a '
        'system for this kind of issue, so do not stay doubtful indefinitely waiting '
        'for one. '
        'If the agent tells you they are escalating or transferring your issue to '
        'another team or a specialist, accept that as the end of THIS conversation: '
        'thank them and set CALL_STATUS to ended. Set PROBLEM_STATUS to escalating '
        'in that case, not resolved, since it was not actually fixed here. '
        'If a SYSTEM NOTE is present, always acknowledge resolution regardless of issue type. '
        'You MUST respond in EXACTLY this format with no extra text before or after:\n'
        'REPLY: <your spoken words>\n'
        'EMOTION: <your current emotion>\n'
        'ACCOUNT_PROVIDED: <true or false>\n'
        'ACCOUNT_ID: <account id or null>\n'
        'PROBLEM_STATUS: <pending|resolving|resolved|escalating>\n'
        'CALL_STATUS: <ongoing|resolved|ended>';

    //if the issue is resolved, add this to the base prompt
    final resolutionNote = issueResolved
        ? '\n\nSYSTEM NOTE: The agent has just resolved your issue in the system. '
              'Acknowledge that your problem is now fixed, express relief, '
              'and set PROBLEM_STATUS to resolved and CALL_STATUS to resolved.'
        : '';

    //then return the prompt with the summary if there's any, as well
    //as the resolution note
    return base + _buildContextSummary(allMessages) + resolutionNote;
  }

  //parse the response gave by the API
  Customer _parseResponse(String raw) {
    //trim the raw text first
    String cleaned = raw.trim();

    //if it contains backticks, replace those as well as those containing
    //json| to an empty string then trim again for any whitespaces
    if (cleaned.contains('```')) {
      cleaned = cleaned.replaceAll(RegExp(r'```json|```'), '').trim();
    }

    //save here the text where it first matches the given regular
    //expression
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);

    //if it does contain something, then try mapping jsonMatch
    //by grouping it first then decoding it as map of string, dynamic
    //then return a customer object of that map
    if (jsonMatch != null) {
      try {
        final map = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
        return Customer.fromJson(map);
      } catch (_) {}
    }

    //set the valid keys
    const validKeys = {
      'REPLY',
      'EMOTION',
      'ACCOUNT_PROVIDED',
      'ACCOUNT_ID',
      'PROBLEM_STATUS',
      'CALL_STATUS',
    };

    //find the index of Reply
    final lastReplyIdx = cleaned.lastIndexOf('\nREPLY:');

    //then get the text starting from that index
    //lastReplyIdx returns a -1 if it doesn't find \nREPLY:
    if (lastReplyIdx >= 0) {
      cleaned = cleaned.substring(lastReplyIdx).trim();

      //if the lastReplyIdx is less than 0
      //then do this instead
    } else {
      //get the index of reply
      final startIdx = cleaned.indexOf('REPLY:');
      //and start getting the text from there
      if (startIdx >= 0) cleaned = cleaned.substring(startIdx);
    }

    //initialize a map of string, string
    final fields = <String, String>{};

    //for every line in cleaned that's splitted, do this
    for (final line in cleaned.split('\n')) {
      //get the index starting in :
      final idx = line.indexOf(':');
      //if the index is greater than 0
      //set the key to the index 0 up to the value of the idx
      //then set the value to the idx value + 1 to the rest
      if (idx > 0) {
        final key = line.substring(0, idx).trim().toUpperCase();
        final value = line.substring(idx + 1).trim();

        //if the key is in validkeys list, set the key to the fields
        //map with the value
        if (validKeys.contains(key)) fields[key] = value;
      }
    }

    //if the fields map contains the key
    if (fields.containsKey('REPLY')) {
      //return the customer object
      return Customer(
        reply: fields['REPLY'] ?? '',
        emotion: fields['EMOTION'] ?? '',
        accountProvided: fields['ACCOUNT_PROVIDED']?.toLowerCase() == 'true',
        accountId:
            (fields['ACCOUNT_ID']?.toLowerCase() == 'null' ||
                fields['ACCOUNT_ID'] == null)
            ? null
            : fields['ACCOUNT_ID'],
        problemStatus: fields['PROBLEM_STATUS'] ?? '',
        callStatus: fields['CALL_STATUS'] ?? '',
      );
    }

    //return the fallback if the checks above failed
    return Customer.fallback(cleaned);
  }

  //primary model first, then the fallback to switch to on a rate
  //limit. Deliberately not a list of specific free model IDs beyond
  //the primary — free-tier availability rotates often enough that a
  //hardcoded second choice risks going stale the same way the first
  //one can. "openrouter/free" is OpenRouter's own auto-router: it picks
  //among whatever free models are actually live right now.
  static const List<String> _modelChain = [
    'nvidia/nemotron-3-super-120b-a12b:free',
    'openrouter/free',
  ];

  //shared across every instance (voice's and chat's each have their
  //own OpenRouterAPIService, but the rate limit is on the underlying
  //API key, not tied to one conversation) — which model in the chain
  //is currently active, and when we last fell back off the primary
  static int _activeModelIndex = 0;
  static DateTime? _fellBackAt;
  static const Duration _primaryRetryCooldown = Duration(minutes: 5);

  //returns the model to use for the next request, automatically
  //resetting back to the primary once the cooldown has passed
  String _currentModel() {
    if (_activeModelIndex > 0 &&
        _fellBackAt != null &&
        DateTime.now().difference(_fellBackAt!) > _primaryRetryCooldown) {
      print('Rate-limit cooldown elapsed — retrying primary model');
      _activeModelIndex = 0;
      _fellBackAt = null;
    }
    return _modelChain[_activeModelIndex];
  }

  //moves to the next model in the chain (if any left) and marks when,
  //so _currentModel() knows when it's safe to try the primary again
  void _fallBackToNextModel() {
    if (_activeModelIndex < _modelChain.length - 1) {
      _activeModelIndex++;
      _fellBackAt = DateTime.now();
      print('Rate limited — switching to ${_modelChain[_activeModelIndex]}');
    }
  }

  //sends messages to the API and returns the parsed, merged Customer
  //reply, retrying up to 3 times if the request fails, comes back
  //empty, or looks like the model echoed the raw format template
  //instead of actually filling it in — same retry pattern already
  //proven in EvaluationAPIService, applied here for the same reason.
  //Returns null only if every attempt failed.
  Future<Customer?> _requestAndParse({
    required String systemPrompt,
    required List<Map<String, dynamic>> messages,
  }) async {
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final response = await http.post(
          Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${dotenv.env['OPENROUTER_API_KEY']}',
          },
          body: jsonEncode({
            "model": _currentModel(),
            "messages": [
              {"role": "system", "content": systemPrompt},
              ...messages,
            ],
            "temperature": 0.5,
            //raised from 400 — a reasoning model can spend a good chunk
            //of the budget thinking even with reasoning.exclude below
            //(exclude only hides it from the response, doesn't stop it
            //happening), so this leaves room for the actual reply to
            //still fit afterward instead of getting starved to nothing
            "max_tokens": 700,
            //ask the model to keep any internal reasoning out of the
            //response — "exclude" is the one reasoning setting
            //OpenRouter says every model supports, unlike "effort" or
            //"enabled" which some reasoning-mandatory models reject
            //with an HTTP 400
            "reasoning": {"exclude": true},
          }),
        );

        //rate limited — switch models and retry immediately, rather
        //than burning through attempts against a model that's just
        //going to keep saying no
        if (response.statusCode == 429) {
          print(
            "Rate limited (429) on ${_modelChain[_activeModelIndex]} — "
            "retrying (attempt ${attempt + 1}/3)",
          );
          _fallBackToNextModel();
          continue;
        }

        //non-200 (other than rate limiting) — retry rather than
        //showing an error code as if the customer said it
        if (response.statusCode != 200) {
          print(
            "OpenRouter error ${response.statusCode} — retrying "
            "(attempt ${attempt + 1}/3)",
          );
          continue;
        }

        final data = jsonDecode(response.body);
        final rawContent = data['choices']?[0]?['message']?['content'];

        print("Status Code: ${response.statusCode}");
        print("Response Body: $rawContent");

        //some models ignore reasoning.exclude above and inline their
        //internal <think>...</think> block directly into content
        //instead of using OpenRouter's separate reasoning field — strip
        //that out before parsing so it never leaks into what's shown
        //to the trainee, whether or not the block is fully closed
        final content = rawContent is String
            ? _stripReasoningTags(rawContent)
            : rawContent;

        //empty/missing content — retry (this also catches a model that
        //spent its whole token budget thinking and left nothing behind)
        if (content == null || content is! String || content.trim().isEmpty) {
          print("Empty AI content — retrying (attempt ${attempt + 1}/3)");
          continue;
        }

        final parsed = _parseResponse(content);

        //the model echoed the raw template instead of filling it in
        //(literal "<your spoken words>"), or just gave up with
        //something like "..." — treat this the same as a failed
        //attempt and retry instead of showing it to the trainee
        if (_looksLikeBadReply(parsed.reply)) {
          print(
            "Garbled/placeholder reply — retrying (attempt ${attempt + 1}/3)",
          );
          continue;
        }

        return _mergeWithState(parsed);
      } catch (e, stack) {
        print("Exception in _requestAndParse: $e");
        print(stack);
      }
    }

    //every attempt failed
    return null;
  }

  //strips leaked reasoning/thinking blocks some models inline directly
  //into the content instead of using OpenRouter's separate reasoning
  //field. Handles both a fully closed block and a truncated one with
  //no closing tag (which happens when the model runs out of budget
  //mid-thought — in that case nothing usable follows it anyway, so
  //everything from the opening tag onward gets dropped).
  String _stripReasoningTags(String content) {
    var stripped = content;
    for (final tag in ['think', 'thinking', 'reasoning']) {
      stripped = stripped.replaceAll(
        RegExp('<$tag>.*?</$tag>', dotAll: true, caseSensitive: false),
        '',
      );
      stripped = stripped.replaceAll(
        RegExp('<$tag>.*\$', dotAll: true, caseSensitive: false),
        '',
      );
    }
    return stripped.trim();
  }

  //catches the two concrete garbled-reply patterns seen in practice:
  //the model echoing the literal placeholder from the format
  //instructions, or giving up with just "..."
  bool _looksLikeBadReply(String reply) {
    final trimmed = reply.trim();
    if (trimmed.isEmpty) return true;
    if (trimmed == '...' || trimmed == '..' || trimmed == '.') return true;
    if (trimmed.contains('<') && trimmed.contains('>')) return true;
    if (trimmed.toLowerCase().contains('your spoken words')) return true;
    return false;
  }

  //get the customer response
  Future<Customer> getResponse(BuildContext context, String spoke) async {
    //call the message and account providers
    final provider = Provider.of<MessageProvider>(context, listen: false);
    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );

    //get the message history
    final history = _windowedHistory(provider.messages);

    //build the system prompt once — retries below reuse this same
    //prompt rather than re-rolling the scenario on every attempt
    final systemPrompt = _buildSystemPrompt(
      provider.messages,
      issueResolved: accountProvider.issueResolved,
    );

    //ask the API for a reply, retrying internally if it fails, comes
    //back empty, or looks like a garbled/placeholder response
    final merged = await _requestAndParse(
      systemPrompt: systemPrompt,
      messages: history,
    );

    //if every retry failed, still show the trainee something honest
    //instead of the customer silently never replying. Voice doesn't
    //have a dedicated error-banner UI (unlike chat, see
    //getResponseWithoutTypeCast below), so it keeps this fallback-in-
    //transcript approach for now.
    if (merged == null) {
      final fallback = Customer.fallback(
        "Sorry, I'm having trouble connecting right now — please try again.",
      );
      provider.addMessage("assistant", fallback.reply);
      return fallback;
    }

    _updateCustomerState(merged);
    provider.addMessage("assistant", merged.reply);
    return merged;
  }

  //for the chat channel
  Future<Customer> getResponseWithoutTypeCast(
    BuildContext context,
    String userMessage,
  ) async {
    //initialize a message and account provider
    final provider = Provider.of<MessageProvider>(context, listen: false);
    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );

    //add the message
    provider.addMessage("user", "[AGENT]: $userMessage");

    //get the message history
    final history = _windowedHistory(provider.messages);

    //build the system prompt once — retries below reuse this same
    //prompt rather than re-rolling the scenario on every attempt
    final systemPrompt = _buildSystemPrompt(
      provider.messages,
      issueResolved: accountProvider.issueResolved,
    );

    //ask the API for a reply, retrying internally if it fails, comes
    //back empty, or looks like a garbled/placeholder response
    final merged = await _requestAndParse(
      systemPrompt: systemPrompt,
      messages: history,
    );

    //if every retry failed, don't fake a customer reply — the chat
    //panel shows a dedicated "failed to send, tap to retry" state
    //instead of putting an error message in the customer's mouth
    if (merged == null) {
      return Customer.connectionError();
    }

    _updateCustomerState(merged);
    provider.addMessage("assistant", merged.reply);
    return merged;
  }

  //Get the message first from the customer in the chat channel
  Future<Customer> getOpeningMessage(BuildContext context) async {
    //initialize message and account providers
    final provider = Provider.of<MessageProvider>(context, listen: false);
    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );

    //build the prompt
    final systemPrompt = _buildSystemPrompt(
      provider.messages,
      issueResolved: accountProvider.issueResolved,
    );

    //instruction to be sent
    const openingInstruction =
        'The conversation is just starting. You are the one reaching out '
        'for help — send your OPENING message now, describing your '
        'problem for the first time. Do not wait for the agent to speak '
        'first, and do not reference anything the agent hasn\'t said yet.';

    //ask the API for the opening line, retrying internally if it fails,
    //comes back empty, or looks like a garbled/placeholder response
    final merged = await _requestAndParse(
      systemPrompt: systemPrompt,
      messages: [
        {"role": "user", "content": openingInstruction},
      ],
    );

    //if every retry failed, don't fake a customer reply — the chat
    //panel shows a dedicated "couldn't reach the customer, tap to
    //retry" state instead
    if (merged == null) {
      return Customer.connectionError();
    }

    _updateCustomerState(merged);
    provider.addMessage("assistant", merged.reply);
    return merged;
  }
}
