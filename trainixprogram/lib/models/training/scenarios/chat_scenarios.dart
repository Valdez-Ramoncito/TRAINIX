import 'package:trainixprogram/models/training/scenarios/chat_scenario_1.dart';
import 'package:trainixprogram/models/training/scenarios/chat_scenario_2.dart';
import 'package:trainixprogram/models/training/scenarios/chat_scenario_3.dart';
import 'package:trainixprogram/models/training/scenarios/chat_scenario_4.dart';
import 'package:trainixprogram/models/training/scenarios/chat_scenario_5.dart';
import 'package:trainixprogram/models/training/scenarios/chat_scenario_6.dart';
import 'package:trainixprogram/models/training/scenarios/chat_scenario_7.dart';
import 'package:trainixprogram/models/training/scenarios/chat_scenario_8.dart';
import 'package:trainixprogram/models/training/scenarios/chat_scenario_9.dart';
import 'package:trainixprogram/models/training/scenarios/chat_scenario_10.dart';
import 'package:trainixprogram/models/training/scenarios/scenario_models.dart';

final List<ScenarioDefinition> chatScenarios = [
  chatScenario1,
  chatScenario2,
  chatScenario3,
  chatScenario4,
  chatScenario5,
  chatScenario6,
  chatScenario7,
  chatScenario8,
  chatScenario9,
  chatScenario10,
]..sort((a, b) => a.order.compareTo(b.order));

ScenarioDefinition? chatScenarioById(String id) {
  for (final s in chatScenarios) {
    if (s.id == id) return s;
  }
  return null;
}

const List<String> requiredChatScenarioIds = [
  'chat_1',
  'chat_2',
  'chat_3',
  'chat_4',
  'chat_5',
  'chat_6',
  'chat_7',
  'chat_8',
  'chat_9',
];
