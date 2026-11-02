import 'package:trainixprogram/models/training/scenarios/scenario_models.dart';
import 'package:trainixprogram/models/training/scenarios/voice_scenario_1.dart';
import 'package:trainixprogram/models/training/scenarios/voice_scenario_2.dart';
import 'package:trainixprogram/models/training/scenarios/voice_scenario_3.dart';
import 'package:trainixprogram/models/training/scenarios/voice_scenario_4.dart';
import 'package:trainixprogram/models/training/scenarios/voice_scenario_5.dart';
import 'package:trainixprogram/models/training/scenarios/voice_scenario_6.dart';
import 'package:trainixprogram/models/training/scenarios/voice_scenario_7.dart';
import 'package:trainixprogram/models/training/scenarios/voice_scenario_8.dart';
import 'package:trainixprogram/models/training/scenarios/voice_scenario_9.dart';

final List<ScenarioDefinition> voiceScenarios = [
  voiceScenario1,
  voiceScenario2,
  voiceScenario3,
  voiceScenario4,
  voiceScenario5,
  voiceScenario6,
  voiceScenario7,
  voiceScenario8,
  voiceScenario9,
]..sort((a, b) => a.order.compareTo(b.order));

ScenarioDefinition? voiceScenarioById(String id) {
  for (final s in voiceScenarios) {
    if (s.id == id) return s;
  }
  return null;
}

const List<String> requiredVoiceScenarioIds = [
  'voice_1',
  'voice_2',
  'voice_3',
  'voice_4',
  'voice_5',
  'voice_6',
  'voice_7',
  'voice_8',
  'voice_9',
];
