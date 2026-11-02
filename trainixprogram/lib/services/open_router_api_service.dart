import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:trainixprogram/models/customer_account.dart';
import 'package:trainixprogram/models/customer.dart';
import 'package:trainixprogram/models/messages.dart';
import 'package:trainixprogram/models/simulation_coach.dart';
import 'package:trainixprogram/models/training/script_personalization.dart';
import 'package:trainixprogram/models/training/simulation_case_packs.dart';

//the one that reaches out to the API
class OpenRouterAPIService {
  final String fixedSector;
  bool hasStarted = false;
  Map<String, String> chosenSimulation = {};
  SimulationCasePack? _activePack;
  final Set<String> _usedPackIntents = {};
  String _lastPackReply = '';
  int _packStage = 0;

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

  //set the customer names  expanded pool + cross-channel dedup below
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
    'Katrina Domingo',
    'Rafael Ocampo',
    'Bianca Fernandez',
    'Nathaniel Ramos',
    'Josephine Lim',
    'Emmanuel Castro',
    'Precious Salazar',
    'Vincent Navarro',
    'Charmaine Pascual',
    'Aldrin Manalo',
    'Michelle Gonzales',
    'Bryan Custodio',
    'Roxanne Del Rosario',
    'Jerome Aguilar',
    'Cristina Marquez',
    'Anthony Sarmiento',
    'Vanessa Tolentino',
    'Gerald Bernardo',
    'Alyssa Espino',
    'Rommel Zamora',
  ];

  //shared across every OpenRouterAPIService instance in the running
  //app, voice and chat each construct their own instance
  //without this they can independently pick the exact same customer name, or the exact same
  //problem within a sector, at the same time.

  //Each instance tracks what it's currently holding in _heldName/
  //_heldProblem and releases it back to the pool via
  //releaseHeldScenario() called from clearMessages()
  static final Set<String> _namesInUse = {};
  static final Map<String, Set<String>> _problemsInUseBySector = {};

  String? _heldName;
  String? _heldProblem;

  //releases this instance's currently-held name/problem back to the
  //shared pool, if it's holding any
  void releaseHeldScenario() {
    if (_heldName != null) {
      _namesInUse.remove(_heldName);
      _heldName = null;
    }
    if (_heldProblem != null) {
      _problemsInUseBySector[fixedSector]?.remove(_heldProblem);
      _heldProblem = null;
    }
    _activePack = null;
    _usedPackIntents.clear();
    _lastPackReply = '';
    _packStage = 0;
  }

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

  //set the problems for each sector grounded in real, named complaint categories rather than invented ones
  //Finance: BSP Circular No. 1169 s.2023's CIR intake form categories + BSP's own reported complain buckets
  //Healthcare: PhilHealth/HMO documented grievance and claim-denial reasons
  //Telco: NTC's stated jurisdiction categories per its 2022 joint order with DTI/DICT/NPC/DOJ
  //Tech Support: ITIL-aligned IT service desk categories. Identity/access, security incidents
  static const Map<String, List<String>> _problemsBySector = {
    'Finance': [
      'an unauthorized transaction appeared on their account',
      'their account balance does not match their records',
      'their card is being declined despite having funds',
      'unexpected fees were charged without explanation',
      'their loan application was rejected without a clear reason',
      'someone else may have accessed their account information without permission',
      'they received a suspicious call or message asking for their account details',
      'a collection agent has been contacting them aggressively about a loan',
      "a fund transfer they sent never arrived in the recipient's account",
      "they want to restructure their loan because they can't keep up with payments",
      'an ATM took money from their account without dispensing any cash',
      'they were charged twice for the same online purchase',
    ],
    'Healthcare': [
      'their insurance claim was denied',
      'they were billed incorrectly for a recent hospital visit',
      'they are unable to schedule an appointment',
      'their prescription is not being covered by insurance',
      'they are confused about a referral they received',
      "their claim was denied because the hospital wasn't an accredited facility",
      'their claim was denied over a gap in their contributions',
      "their claim was denied due to a coding error on the hospital's part",
      'the hospital is asking them to pay cash before they can be discharged',
      "the hospital never filed their claim and now they're stuck paying the full bill",
    ],
    'Telco': [
      'their internet connection keeps dropping',
      'unexpected charges appeared on their bill',
      'their mobile data is not working despite having an active plan',
      'there is a service outage in their area',
      'they were charged for roaming they did not expect',
      'they keep receiving suspicious text messages that look like a scam',
      'their prepaid load disappeared without them using it',
      'they were denied a plan upgrade without a clear reason',
      "they're being charged an early termination fee they weren't told about",
      'they signed up for a service they never asked for and are now being billed for it',
      'their internet speed is far slower than what was advertised',
    ],
    'Tech Support': [
      'their device stopped working after a recent update',
      'a software they need fails to install',
      'they are locked out of their account and cannot recover it',
      'their device has become unusably slow',
      'important files disappeared after a system restore',
      "their two-factor authentication app stopped working and they can't log in",
      'they got a security alert about a possible virus on their device',
      "they can't log into a work application even though their password is correct",
      'a new device they were issued was never properly set up',
      "their software subscription shows as expired even though they're still paying for it",
    ],
  };

  //clear and set defaults
  void clearMessages(BuildContext context) {
    //clear the messages
    Provider.of<MessageProvider>(context, listen: false).clearMessage();

    //free up this customer's name or problem for the other channel to
    //possibly use, before this instance picks a new one for itself
    releaseHeldScenario();

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

  //generate a customer based on the given sector. Avoids picking a
  //name or problem the OTHER channel's instance currently holds
  //Falls back to allowing a repeat only if literally everything in the relevant pool
  //is already taken
  Map<String, String> generateCustomerScenario() {
    final random = Random();
    _activePack = SimulationCaseLibrary.pickForSector(fixedSector);
    _usedPackIntents.clear();
    _lastPackReply = '';
    _packStage = 0;

    if (_activePack != null) {
      final pack = _activePack!;
      final name = pack.name;
      _namesInUse.add(name);
      _heldName = name;
      _heldProblem = pack.problem;
      _problemsInUseBySector
          .putIfAbsent(fixedSector, () => {})
          .add(pack.problem);
      return {
        'name': pack.name,
        'sector': pack.sector,
        'emotion': pack.emotion,
        'problem': pack.problem,
        'casePackId': pack.id,
        'needsAccount': pack.needsAccount ? 'true' : 'false',
      };
    }

    //choose a name not currently held by the other channel
    final availableNames = _customerNames
        .where((n) => !_namesInUse.contains(n))
        .toList();
    final namePool = availableNames.isNotEmpty
        ? availableNames
        : _customerNames;
    final name = namePool[random.nextInt(namePool.length)];
    _namesInUse.add(name);
    _heldName = name;

    //choose a random emotion for the customer
    final emotion = _emotions[random.nextInt(_emotions.length)];

    //get the problems on the given sector
    final problems =
        _problemsBySector[fixedSector] ?? _problemsBySector['Tech Support']!;

    //choose a problem not currently held by the other channel within
    //this same sector
    final usedProblems = _problemsInUseBySector[fixedSector] ?? const {};
    final availableProblems = problems
        .where((p) => !usedProblems.contains(p))
        .toList();
    final problemPool = availableProblems.isNotEmpty
        ? availableProblems
        : problems;
    final problem = problemPool[random.nextInt(problemPool.length)];
    _problemsInUseBySector.putIfAbsent(fixedSector, () => {}).add(problem);
    _heldProblem = problem;

    //then return the values
    return {
      'name': name,
      'sector': fixedSector,
      'emotion': emotion,
      'problem': problem,
    };
  }

  Customer? _tryPackReply(String agentMessage, {bool opening = false}) {
    final pack = _activePack;
    if (pack == null) return null;

    if (opening) {
      _lastPackReply = pack.openingReply;
      _packStage = 0;
      return Customer(
        reply: pack.openingReply,
        emotion: pack.emotion,
        accountProvided: false,
        accountId: null,
        problemStatus: 'pending',
        callStatus: 'ongoing',
      );
    }

    final intent = SimulationCaseLibrary.detectIntent(agentMessage);
    _usedPackIntents.add(intent);

    if (intent == 'acknowledge' && _packStage < 1) _packStage = 1;
    if (intent == 'verify' && _packStage < 2) _packStage = 2;
    if (intent == 'fix' && _packStage < 3) _packStage = 3;
    if (intent == 'close' && _packStage < 4) _packStage = 4;
    if (intent == 'escalate') _packStage = 5;

    List<String> pool;
    var problemStatus = 'pending';
    var callStatus = 'ongoing';
    var accountProvided = _customerState['accountProvided'] == 'true';
    String? accountId = _customerState['accountId'] != 'null'
        ? _customerState['accountId']
        : null;

    switch (intent) {
      case 'acknowledge':
        pool = pack.acknowledgeReplies;
        break;
      case 'verify':
        pool = pack.verifyReplies;
        accountProvided = true;
        accountId ??= 'ACC-${pack.id.hashCode.abs() % 90000 + 10000}';
        break;
      case 'fix':
        pool = pack.fixReplies;
        problemStatus = 'resolving';
        break;
      case 'escalate':
        pool = pack.escalateReplies;
        problemStatus = 'escalating';
        callStatus = 'ended';
        break;
      case 'close':
        pool = pack.closeReplies;
        problemStatus = _packStage >= 3 || _usedPackIntents.contains('fix')
            ? 'resolved'
            : 'pending';
        callStatus = problemStatus == 'resolved' ? 'resolved' : 'ongoing';
        break;
      default:
        if (_packStage >= 2) {
          pool = pack.fixReplies;
          problemStatus = 'resolving';
        } else if (_packStage >= 1) {
          pool = pack.verifyReplies;
        } else {
          pool = pack.otherReplies;
        }
        break;
    }

    final reply = SimulationCaseLibrary.pickReply(pool, avoid: _lastPackReply);
    _lastPackReply = reply;

    final emotion = intent == 'fix' || intent == 'close'
        ? 'Relieved'
        : pack.emotion;

    return Customer(
      reply: reply,
      emotion: emotion,
      accountProvided: accountProvided,
      accountId: accountId,
      problemStatus: problemStatus,
      callStatus: callStatus,
    );
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
      reply: sanitizeCustomerReply(parsed.reply),
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
        'Continue from here  do not repeat what was already discussed.';
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
    bool toolWorkDone = false,
    bool problemNeedsEscalation = false,
    bool agentIsEscalating = false,
    String toolAction = '',
    String lastToolNoteDetail = '',
    String selectedAccountLabel = '',
  }) {
    //if this is just the start of a conversation, generate a
    //customer scenario first
    if (!hasStarted) {
      chosenSimulation = generateCustomerScenario();
      hasStarted = true;
    }

    //the base prompt to be sent to the API
    //the API sends back a JSON Format for cleaner output
    final agentDisplayName = ScriptPersonalization.agentFullName;
    final base =
        'ROLE: You are a CUSTOMER named ${chosenSimulation["name"]} calling a ${chosenSimulation["sector"]} support line. '
        'You are NOT the agent. The messages labeled "user" are from the support AGENT. '
        'Every agent message will start with [AGENT]: so you always know who is speaking. '
        'The agent name is $agentDisplayName. When you address the agent by name, use only "$agentDisplayName". '
        'Do not invent a different agent name. '
        'You are ${chosenSimulation["emotion"]} because ${chosenSimulation["problem"]}. '
        'Keep replies short and natural. Reflect your emotion in tone. '
        'Do not reveal account details unless the agent specifically asks. '
        'When giving your account ID make up a realistic one. '
        'React naturally  calm down if helped, get more upset if unhelpful. '
        'IMPORTANT: Do NOT acknowledge your issue as resolved just because the agent '
        'says it is fixed. '
        'For account-related issues (billing, balance, card, charges, access): '
        'only acknowledge resolution if you see a SYSTEM NOTE in these instructions. '
        'For device or technical issues where the agent walks you through steps: '
        'remain doubtful until you confirm the steps actually worked, then you may '
        'acknowledge resolution naturally. '
        'For anything else  a question you needed answered, guidance on a process, '
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
        'CALL_STATUS: <ongoing|resolved|ended>\n\n'
        'CRITICAL: You are ONLY the customer. Never speak as the support agent. '
        'Do not thank them for contacting support, do not offer to file requests, '
        'do not ask for identity verification, and do not coach the agent.';

    final resolutionNote = issueResolved
        ? '\n\nSYSTEM NOTE: The agent has just resolved your issue in the system. '
              'Acknowledge that your problem is now fixed, express relief, '
              'and set PROBLEM_STATUS to resolved and CALL_STATUS to resolved.'
        : '';

    final actionLabel = toolAction.trim().isEmpty
        ? 'a system action'
        : toolAction.trim();
    final agentNote = lastToolNoteDetail.trim();
    final accountLabel = selectedAccountLabel.trim();
    final toolNote = (!issueResolved && toolWorkDone)
        ? '\n\nSYSTEM NOTE: The agent completed $actionLabel'
              '${accountLabel.isEmpty ? '' : ' on account $accountLabel'}'
              '${agentNote.isEmpty ? '' : '. Agent note: $agentNote'}'
              '. You do NOT automatically know every internal detail. '
              'You may ask once what they did. If they explain the action in plain words, '
              'accept it as progress, calm down, and you may set PROBLEM_STATUS to resolving '
              'or resolved if you are satisfied. Do not keep demanding technical internal steps '
              'after a clear explanation.'
        : '';

    final escalateNeededNote = problemNeedsEscalation
        ? '\n\nSYSTEM NOTE: This customer problem cannot be fully solved by a frontline agent '
              'with a simple system click or basic steps. If the agent tries to claim a full fix, '
              'remain unsatisfied and ask for a real specialist path. If the agent escalates to another '
              'team or specialist and collects handoff details, accept the escalation: thank them, '
              'set PROBLEM_STATUS to escalating, and set CALL_STATUS to ended.'
        : '';

    final agentEscalateNote = agentIsEscalating
        ? '\n\nSYSTEM NOTE: The agent is escalating or transferring your case. '
              'Do NOT treat this as fully resolved. Accept the escalation, thank them, '
              'set PROBLEM_STATUS to escalating, and set CALL_STATUS to ended.'
        : '';

    return base +
        _buildContextSummary(allMessages) +
        resolutionNote +
        toolNote +
        escalateNeededNote +
        agentEscalateNote;
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
      //diagnostic: shows exactly what the model returned for these two
      //fields before normalization
      print(
        '[PARSE] raw CALL_STATUS="${fields['CALL_STATUS']}" '
        'raw PROBLEM_STATUS="${fields['PROBLEM_STATUS']}"',
      );
      //return the customer object, callStatus/problemStatus normalized
      //to lowercase here so they can rely on exact-match against a
      //lowercase literal without each call site needing to remember to
      //normalize itself.
      return Customer(
        reply: sanitizeCustomerReply(fields['REPLY'] ?? ''),
        emotion: fields['EMOTION'] ?? '',
        accountProvided: fields['ACCOUNT_PROVIDED']?.toLowerCase() == 'true',
        accountId:
            (fields['ACCOUNT_ID']?.toLowerCase() == 'null' ||
                fields['ACCOUNT_ID'] == null)
            ? null
            : fields['ACCOUNT_ID'],
        problemStatus: (fields['PROBLEM_STATUS'] ?? '').trim().toLowerCase(),
        callStatus: (fields['CALL_STATUS'] ?? '').trim().toLowerCase(),
      );
    }

    //return the fallback if the checks above failed
    return Customer.fallback(sanitizeCustomerReply(cleaned));
  }

  // Free OpenRouter models for customer roleplay and long instruction
  // following. Order is try-first. On 429, 5xx, or empty replies the
  // client advances to the next id, then returns to the first after cooldown.
  static const List<String> _modelChain = [
    'thinkingmachines/inkling:free',
    'thinkingmachines/inkling-small:free',
    'nvidia/nemotron-3-super-120b-a12b:free',
    'google/gemma-4-31b-it:free',
    'nvidia/nemotron-3.5-lightning:free',
    'openrouter/free',
  ];

  static int _activeModelIndex = 0;
  static DateTime? _fellBackAt;
  static const Duration _primaryRetryCooldown = Duration(minutes: 5);

  String _currentModel() {
    if (_activeModelIndex > 0 &&
        _fellBackAt != null &&
        DateTime.now().difference(_fellBackAt!) > _primaryRetryCooldown) {
      print('Model cooldown elapsed  retrying primary free model');
      _activeModelIndex = 0;
      _fellBackAt = null;
    }
    return _modelChain[_activeModelIndex];
  }

  void _fallBackToNextModel() {
    if (_activeModelIndex < _modelChain.length - 1) {
      _activeModelIndex++;
      _fellBackAt = DateTime.now();
      print('Switching customer model to ${_modelChain[_activeModelIndex]}');
    }
  }

  //sends messages to the API and returns the parsed, merged Customer
  //reply, retrying up to 3 times if the request fails, comes back
  //empty, or looks like the model echoed the raw format template
  //instead of actually filling it in
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
            //raised from 400 so this leaves room for the actual reply to
            //still fit afterward instead of receiving nothing
            "max_tokens": 700,
            //ask the model to keep any internal reasoning out of the
            //response if it exists on a chosen model
            "reasoning": {"exclude": true},
          }),
        );

        //rate limited switch models and retry immediately, rather
        //than burning through attempts against a model that's just
        //going to keep saying no
        if (response.statusCode == 429 ||
            response.statusCode == 502 ||
            response.statusCode == 503 ||
            response.statusCode == 524) {
          print(
            "OpenRouter ${response.statusCode} on ${_modelChain[_activeModelIndex]}  "
            "switching model (attempt ${attempt + 1}/3)",
          );
          _fallBackToNextModel();
          continue;
        }

        if (response.statusCode != 200) {
          print(
            "OpenRouter error ${response.statusCode}  retrying "
            "(attempt ${attempt + 1}/3)",
          );
          _fallBackToNextModel();
          continue;
        }

        final data = jsonDecode(response.body);
        final rawContent = data['choices']?[0]?['message']?['content'];

        print("Status Code: ${response.statusCode}");
        print("Response Body: $rawContent");

        //some models ignore reasoning.exclude above and inline their
        //internal <think>...</think> block directly into content
        //instead of using OpenRouter's separate reasoning field, strip
        //that out before parsing so it never leaks into what's shown
        //to the trainee, whether or not the block is fully closed
        final content = rawContent is String
            ? _stripReasoningTags(rawContent)
            : rawContent;

        //if empty or missing content, then retry
        //also catches a model that spent its whole token budget thinking and left nothing behind
        if (content == null || content is! String || content.trim().isEmpty) {
          print("Empty AI content  switching model (attempt ${attempt + 1}/3)");
          _fallBackToNextModel();
          continue;
        }

        final parsed = _parseResponse(content);

        //the model echoed the raw template instead of filling it in
        //literal "<your spoken words>", or just gave up with
        //something like "..."  treat this the same as a failed
        //attempt and retry instead of showing it to the trainee
        if (_looksLikeBadReply(parsed.reply)) {
          print(
            "Garbled/placeholder reply  retrying (attempt ${attempt + 1}/3)",
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
  //field.
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

  //catches the two concrete bad reply patterns seen
  bool _looksLikeBadReply(String reply) {
    final trimmed = reply.trim();
    if (trimmed.isEmpty) return true;
    if (trimmed == '...' || trimmed == '..' || trimmed == '.') return true;
    if (trimmed.contains('<') && trimmed.contains('>')) return true;
    if (trimmed.toLowerCase().contains('your spoken words')) return true;
    return false;
  }

  //get the customer response

  static String sanitizeCustomerReply(String raw) {
    var text = SimulationCoach.stripInternalFields(raw).trim();
    if (SimulationCoach.looksLikeAgentSpeech(text)) {
      text =
          'I am still dealing with this issue. What should I do next on my side?';
    }
    return text;
  }

  Future<Customer> getResponse(BuildContext context, String spoke) async {
    //call the message and account providers
    final provider = Provider.of<MessageProvider>(context, listen: false);
    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );

    if (!hasStarted) {
      chosenSimulation = generateCustomerScenario();
      hasStarted = true;
    }

    //get the message history
    final history = _windowedHistory(provider.messages);

    //build the system prompt once
    //Retries below reuse this same prompt rather than re-rolling the scenario on every attempt
    final systemPrompt = _buildSystemPrompt(
      provider.messages,
      issueResolved: accountProvider.issueResolved,
      toolWorkDone: accountProvider.toolWorkDone,
      toolAction: accountProvider.lastToolAction,
      lastToolNoteDetail: accountProvider.lastToolNote,
      selectedAccountLabel: accountProvider.selectedAccount == null
          ? ''
          : (accountProvider.selectedAccount!.ownerName +
                ' (' +
                accountProvider.selectedAccount!.accountId +
                ')'),
      problemNeedsEscalation: SimulationCoach.requiresEscalationFromStart(
        chosenSimulation['problem']?.toString() ?? '',
        sector: chosenSimulation['sector']?.toString() ?? '',
      ),
    );

    //ask the API for a reply, retrying internally if it fails, comes
    //back empty, or looks like a bad or placeholder response
    final merged = await _requestAndParse(
      systemPrompt: systemPrompt,
      messages: history,
    );

    //if every retry failed, still show the trainee something honest
    //instead of the customer silently never replying.
    if (merged == null) {
      final packReply = _tryPackReply(spoke);
      if (packReply != null) {
        final fallbackPack = _mergeWithState(packReply);
        _updateCustomerState(fallbackPack);
        provider.addMessage("assistant", fallbackPack.reply);
        return fallbackPack;
      }
      final fallback = Customer.fallback(
        "Sorry, I'm having trouble connecting right now  please try again.",
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
    String userMessage, {
    bool forceEscalating = false,
  }) async {
    //initialize a message and account provider
    final provider = Provider.of<MessageProvider>(context, listen: false);
    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );

    //add the message
    provider.addMessage("user", "[AGENT]: $userMessage");

    if (!hasStarted) {
      chosenSimulation = generateCustomerScenario();
      hasStarted = true;
    }

    //get the message history
    final history = _windowedHistory(provider.messages);

    //build the system prompt once
    //Retries below reuse this same prompt rather than re-rolling the scenario on every attempt
    final systemPrompt = _buildSystemPrompt(
      provider.messages,
      issueResolved: accountProvider.issueResolved,
      toolWorkDone: accountProvider.toolWorkDone,
      toolAction: accountProvider.lastToolAction,
      lastToolNoteDetail: accountProvider.lastToolNote,
      selectedAccountLabel: accountProvider.selectedAccount == null
          ? ''
          : (accountProvider.selectedAccount!.ownerName +
                ' (' +
                accountProvider.selectedAccount!.accountId +
                ')'),
      problemNeedsEscalation: SimulationCoach.requiresEscalationFromStart(
        chosenSimulation['problem']?.toString() ?? '',
        sector: chosenSimulation['sector']?.toString() ?? '',
      ),
      agentIsEscalating:
          forceEscalating || SimulationCoach.looksLikeEscalation(userMessage),
    );

    // OpenRouter primary. Case pack is brief + fallback only.
    final merged = await _requestAndParse(
      systemPrompt: systemPrompt,
      messages: history,
    );

    if (merged == null) {
      final packReply = _tryPackReply(userMessage);
      if (packReply != null) {
        await Future<void>.delayed(
          Duration(milliseconds: 700 + Random().nextInt(700)),
        );
        if (!context.mounted) return Customer.connectionError();
        final fallback = _mergeWithState(packReply);
        _updateCustomerState(fallback);
        provider.addMessage("assistant", fallback.reply);
        return fallback;
      }
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

    if (!hasStarted) {
      chosenSimulation = generateCustomerScenario();
      hasStarted = true;
    }

    //build the prompt
    final systemPrompt = _buildSystemPrompt(
      provider.messages,
      issueResolved: accountProvider.issueResolved,
      toolWorkDone: accountProvider.toolWorkDone,
      toolAction: accountProvider.lastToolAction,
      lastToolNoteDetail: accountProvider.lastToolNote,
      selectedAccountLabel: accountProvider.selectedAccount == null
          ? ''
          : (accountProvider.selectedAccount!.ownerName +
                ' (' +
                accountProvider.selectedAccount!.accountId +
                ')'),
      problemNeedsEscalation: SimulationCoach.requiresEscalationFromStart(
        chosenSimulation['problem']?.toString() ?? '',
        sector: chosenSimulation['sector']?.toString() ?? '',
      ),
    );

    //instruction to be sent
    const openingInstruction =
        'The conversation is just starting. You are the one reaching out '
        'for help  send your OPENING message now, describing your '
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

    if (merged == null) {
      final packOpening = _tryPackReply('', opening: true);
      if (packOpening != null) {
        final fallback = _mergeWithState(packOpening);
        _updateCustomerState(fallback);
        provider.addMessage("assistant", fallback.reply);
        return fallback;
      }
      return Customer.connectionError();
    }

    _updateCustomerState(merged);
    provider.addMessage("assistant", merged.reply);
    return merged;
  }

  Future<Customer> continueAfterCustomerPause(BuildContext context) async {
    final provider = Provider.of<MessageProvider>(context, listen: false);
    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );

    final systemPrompt = _buildSystemPrompt(
      provider.messages,
      issueResolved: accountProvider.issueResolved,
      toolWorkDone: accountProvider.toolWorkDone,
      toolAction: accountProvider.lastToolAction,
      lastToolNoteDetail: accountProvider.lastToolNote,
      selectedAccountLabel: accountProvider.selectedAccount == null
          ? ''
          : (accountProvider.selectedAccount!.ownerName +
                ' (' +
                accountProvider.selectedAccount!.accountId +
                ')'),
      problemNeedsEscalation: SimulationCoach.requiresEscalationFromStart(
        chosenSimulation['problem']?.toString() ?? '',
        sector: chosenSimulation['sector']?.toString() ?? '',
      ),
    );
    final history = _windowedHistory(provider.messages);

    const pauseInstruction =
        'The agent is waiting quietly while you check on your side. '
        'Continue ONLY as the customer. Report what you found: whether the '
        'issue looks fixed or not, and how you feel. Stay in character. '
        'Do not speak as the agent.';

    final merged = await _requestAndParse(
      systemPrompt: systemPrompt,
      messages: [
        ...history,
        {"role": "user", "content": pauseInstruction},
      ],
    );

    if (merged == null) {
      return Customer.connectionError();
    }

    _updateCustomerState(merged);
    provider.addMessage("assistant", merged.reply);
    return merged;
  }

  Future<Customer> nudgeIfAgentSilent(BuildContext context) async {
    final provider = Provider.of<MessageProvider>(context, listen: false);
    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );

    final systemPrompt = _buildSystemPrompt(
      provider.messages,
      issueResolved: accountProvider.issueResolved,
      toolWorkDone: accountProvider.toolWorkDone,
      toolAction: accountProvider.lastToolAction,
      lastToolNoteDetail: accountProvider.lastToolNote,
      selectedAccountLabel: accountProvider.selectedAccount == null
          ? ''
          : (accountProvider.selectedAccount!.ownerName +
                ' (' +
                accountProvider.selectedAccount!.accountId +
                ')'),
      problemNeedsEscalation: SimulationCoach.requiresEscalationFromStart(
        chosenSimulation['problem']?.toString() ?? '',
        sector: chosenSimulation['sector']?.toString() ?? '',
      ),
    );
    final history = _windowedHistory(provider.messages);

    const nudgeInstruction =
        'The agent has been quiet for a while. Continue ONLY as the customer. '
        'Send a short natural follow-up: ask if they are still there, ask for an update, '
        'or gently restate your concern. Stay in character. Do not speak as the agent.';

    final merged = await _requestAndParse(
      systemPrompt: systemPrompt,
      messages: [
        ...history,
        {"role": "user", "content": nudgeInstruction},
      ],
    );

    if (merged == null) {
      return Customer.connectionError();
    }

    _updateCustomerState(merged);
    provider.addMessage("assistant", merged.reply);
    return merged;
  }
}
