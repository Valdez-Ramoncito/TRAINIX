import 'package:trainixprogram/models/training/scenarios/scenario_models.dart';
import 'package:trainixprogram/models/training/scenarios/hybrid_scenario_1.dart';
import 'package:trainixprogram/models/training/scenarios/hybrid_scenario_2.dart';
import 'package:trainixprogram/models/training/scenarios/hybrid_scenario_3.dart';
import 'package:trainixprogram/models/training/scenarios/hybrid_scenario_4.dart';

final List<ScenarioDefinition> hybridScenarios = [
  hybridScenario1,
  hybridScenario2,
  hybridScenario3,
  hybridScenario4,
]..sort((a, b) => a.order.compareTo(b.order));

ScenarioDefinition? hybridScenarioById(String id) {
  for (final s in hybridScenarios) {
    if (s.id == id) return s;
  }
  return null;
}

const List<String> requiredHybridScenarioIds = [
  'hybrid_1',
  'hybrid_2',
  'hybrid_3',
  'hybrid_4',
];
