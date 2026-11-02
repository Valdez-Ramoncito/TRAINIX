import 'package:trainixprogram/models/training/script_personalization.dart';

enum ScenarioTurnType {
  guide,
  customer,
  typeExact,
  speakExact,
  chooseOne,
  accountSearch,
  accountSelect,
  accountResolve,
}

class ScenarioAccount {
  final String accountId;
  final String ownerName;
  final Map<String, String> details;
  final bool isTarget;

  const ScenarioAccount({
    required this.accountId,
    required this.ownerName,
    required this.details,
    this.isTarget = false,
  });
}

class ScenarioMissionStep {
  final String id;
  final String label;

  const ScenarioMissionStep({
    required this.id,
    required this.label,
  });
}

class ScenarioTurn {
  final ScenarioTurnType type;
  final String text;
  final String? targetText;
  final String? coachPrompt;
  final String? successReply;
  final String? failReply;
  final List<String>? options;
  final int? correctIndex;
  final String? searchTarget;
  final String? selectAccountId;
  final String? missionStepId;
  final String? lane;

  const ScenarioTurn({
    required this.type,
    required this.text,
    this.targetText,
    this.coachPrompt,
    this.successReply,
    this.failReply,
    this.options,
    this.correctIndex,
    this.searchTarget,
    this.selectAccountId,
    this.missionStepId,
    this.lane,
  });

  String get resolvedTargetText {
    return ScriptPersonalization.resolve(targetText ?? '');
  }
}

class ScenarioDefinition {
  final String id;
  final String title;
  final String channel;
  final String sector;
  final String customerName;
  final String problem;
  final String emotion;
  final List<String> targetSkills;
  final int maxMistakes;
  final bool isGuided;
  final int order;
  final List<ScenarioTurn> turns;
  final List<ScenarioAccount> accounts;
  final bool usesAccountLookup;
  final List<ScenarioMissionStep> missionSteps;
  final String? secondaryCustomerName;
  final String? secondarySector;
  final String? secondaryProblem;
  final String? secondaryEmotion;
  final List<ScenarioAccount> secondaryAccounts;
  final bool usesSecondaryAccountLookup;

  const ScenarioDefinition({
    required this.id,
    required this.title,
    required this.channel,
    required this.sector,
    required this.customerName,
    required this.problem,
    required this.emotion,
    required this.targetSkills,
    required this.maxMistakes,
    required this.isGuided,
    required this.order,
    required this.turns,
    this.accounts = const [],
    this.usesAccountLookup = false,
    this.missionSteps = const [],
    this.secondaryCustomerName,
    this.secondarySector,
    this.secondaryProblem,
    this.secondaryEmotion,
    this.secondaryAccounts = const [],
    this.usesSecondaryAccountLookup = false,
  });
}
