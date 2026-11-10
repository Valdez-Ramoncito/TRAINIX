import 'package:flutter/material.dart';
import 'package:trainixprogram/services/simulation_session_repository.dart';
import 'package:trainixprogram/models/session_score.dart';
import 'package:trainixprogram/models/simulation_phase.dart';
import 'package:trainixprogram/models/training/training_categories.dart';
import 'package:trainixprogram/components/class/trainee_activity_log.dart';
import 'package:trainixprogram/screens/page/profile.dart';

//represents one full completed play-through
//This is what Session History and Score Trend should be counting, not individual evaluations.
class PlayedSession {
  final List<SessionEvaluation> evaluations;
  final double? multitaskingScore;
  final DateTime completedAt;
  final SimulationMode mode;

  const PlayedSession({
    required this.evaluations,
    required this.multitaskingScore,
    required this.completedAt,
    this.mode = SimulationMode.chat,
  });

  //every evaluation in a session shares the same sector
  String get sector => evaluations.isNotEmpty ? evaluations.first.sector : '';

  //average overall score across every evaluation in this session
  double get overallScore {
    if (evaluations.isEmpty) return 0;
    return evaluations.map((e) => e.overallScore).reduce((a, b) => a + b) /
        evaluations.length;
  }

  //first non-empty strength found across this session's evaluations,
  //for the session-history table's "Top Strength" column
  String get topStrength {
    for (final e in evaluations) {
      if (e.strengths.isNotEmpty) return e.strengths.first;
    }
    return '';
  }
}

//where history of all evaluations + multitasking scores
//gets sent into dashboard and sector match
class SimulationHistoryProvider with ChangeNotifier {
  //every individual resolved-customer evaluation ever recorded
  final List<SessionEvaluation> _evaluations = [];

  //every completed playthrough. One entry per finished MockCallScreen
  //run, regardless of how many evaluations it produced. This is what
  //Session History, Score Trend, and "Total Sessions" actually count.
  final List<PlayedSession> _sessions = [];

  //list of all multitasking scores
  final List<double> _multitaskingScores = [];

  //getters
  List<SessionEvaluation> get evaluations {
    final copy = List<SessionEvaluation>.from(_evaluations);
    copy.sort((a, b) => b.evaluatedAt.compareTo(a.evaluatedAt));
    return copy;
  }

  List<PlayedSession> get sessions {
    final copy = List<PlayedSession>.from(_sessions);
    copy.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return copy;
  }

  List<double> get multitaskingScores => _multitaskingScores;
  //average of the multitask score
  double? get averageMultitaskingScore {
    if (_multitaskingScores.isEmpty) return null;

    //return the average after adding all scores in the list
    return _multitaskingScores.reduce((a, b) => a + b) /
        _multitaskingScores.length;
  }

  //add the multitask score in the list
  void saveMultitaskingScore(double score) {
    _multitaskingScores.add(score);
    notifyListeners();
  }

  //average of the evaluation score
  double get averageOverallScore {
    if (_evaluations.isEmpty) return 0;

    //since this is a list of session evaluations, we map each of them
    //and find the overall score to be added to other scores
    //and then return the average
    return _evaluations.map((e) => e.overallScore).reduce((a, b) => a + b) /
        _evaluations.length;
  }

  /// Average customer CSAT (1-5) across rated evaluations.
  double? get averageCustomerRating {
    final rated = _evaluations.where((e) => e.customerRating != null).toList();
    if (rated.isEmpty) return null;
    final sum = rated.fold<int>(0, (a, e) => a + (e.customerRating ?? 0));
    return sum / rated.length;
  }

  //get the best overall score out of all evaluations
  double get bestOverallScore {
    if (_evaluations.isEmpty) return 0;

    //for every session evaluation in the list, loop through their
    //overall scores, compare from the initial value (0.0) as 'best'
    //then check if its lower than the current element, if it is
    //then replace the best's value with that value. Otherwise,
    //keep best's value as it is
    return _evaluations.fold(
      0.0,
      (best, e) => e.overallScore > best ? e.overallScore : best,
    );
  }

  //this returns the sector average
  Map<String, double> get sectorAverages {
    if (_evaluations.isEmpty) return {};

    //create a map of string, list of doubles, and store it here
    final grouped = <String, List<double>>{};

    //for every session evaluation, see if that elements' sector
    //is not present in grouped's keys otherwise create a key of that
    //element's sector and set its value as a list, then add the
    //element's overall score into that list
    for (final e in _evaluations) {
      grouped.putIfAbsent(e.sector, () => []).add(e.overallScore);
    }

    //for every sector we have, add its scores then divide it by the
    //length to get the average score of that sector
    //then return it as a Map of string, double
    return grouped.map(
      (sector, scores) =>
          MapEntry(sector, scores.reduce((a, b) => a + b) / scores.length),
    );
  }

  //this returns the recommended sector
  String? get recommendedSector {
    //get the average for each sector in a type of Map of string, double
    final averages = sectorAverages;

    if (averages.isEmpty) return null;

    //for every entry that we have in this map, compare their values
    //with one another. reduce it to just one entry that has the highest
    //value, then return that value's key
    return averages.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  //this returns the strengths
  List<String> get aggregateStrengths {
    if (_evaluations.isEmpty) return [];
    final frequency = <String, int>{};

    //for every session evaluation, check its strengths
    //and for every strengths that session evaluation has
    //set the frequency's key to its associated value if it has one
    //if it doesnt have one, default it to 0 and add 1
    for (final e in _evaluations) {
      for (final s in e.strengths) {
        frequency[s] = (frequency[s] ?? 0) + 1;
      }
    }

    //for each entry, take the frequency, make it into a list,
    //sort them based on their values (highest to lowest)
    //then store it here
    final sorted = frequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    //take the first three in the list, map them to get the key
    //and make it to a list, then return it
    return sorted.take(3).map((e) => e.key).toList();
  }

  //this returns the areas for improvement
  List<String> get aggregateAreasForImprovement {
    if (_evaluations.isEmpty) return [];
    final frequency = <String, int>{};

    //for every session evaluation, check its areas for improvement
    //and for every improvement that session evaluation has
    //set the frequency's key to its associated value if it has one
    //if it doesnt have one, default it to 0 and add 1
    for (final e in _evaluations) {
      for (final s in e.areasForImprovement) {
        frequency[s] = (frequency[s] ?? 0) + 1;
      }
    }

    //for each entry, take the frequency, make it into a list,
    //sort them based on their values (highest to lowest)
    //then store it here
    final sorted = frequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    //take the first three in the list, map them to get the key
    //and make it to a list, then return it
    return sorted.take(3).map((e) => e.key).toList();
  }

  //returns the average category score
  double averageCategoryScore(double Function(SessionEvaluation) selector) {
    if (_evaluations.isEmpty) return 0;

    //add all the scores in the mapped evaluations and divide it
    //by its length then return the result
    return _evaluations.map(selector).reduce((a, b) => a + b) /
        _evaluations.length;
  }

  //add the session evaluation to the list
  void saveEvaluation(SessionEvaluation evaluation) {
    _evaluations.add(evaluation.withDerivedCustomerRating());
    notifyListeners();
  }

  //call once, when a play-through actually finishes, with everything
  //that session produced
  //this is what Session History, Score Trend and Total Sessions read from
  //separate from the flat evaluations list
  void saveSession({
    required List<SessionEvaluation> evaluations,
    double? multitaskingScore,
    SimulationMode mode = SimulationMode.chat,
    bool countForGuide = true,
  }) {
    if (evaluations.isEmpty) return;
    final rated = evaluations
        .map((e) => e.withDerivedCustomerRating())
        .toList();
    final played = PlayedSession(
      evaluations: rated,
      multitaskingScore: multitaskingScore,
      completedAt: DateTime.now(),
      mode: mode,
    );
    _sessions.add(played);
    for (final e in rated) {
      if (!_evaluations.contains(e)) {
        _evaluations.add(e);
      }
    }
    notifyListeners();
    SimulationSessionRepository.instance.insert(played);
    if (countForGuide) {
      MiniTrainingProgress.markSimulationSessionCompleted();
    }
    final modeLabel = mode == SimulationMode.voice
        ? 'Voice'
        : mode == SimulationMode.chat
        ? 'Non-Voice'
        : mode.name;
    final sector = played.sector.isEmpty ? 'General' : played.sector;
    TraineeActivityLogStore.instance.log(
      actorName: ProfileData.displayName.isNotEmpty
          ? ProfileData.displayName
          : 'Trainee',
      actorRole: ProfileData.role.name,
      category: TraineeLogCategory.simulation,
      action: 'Completed $modeLabel session',
      detail:
          '$sector · ${evaluations.length} customer(s) · score ${played.overallScore.toStringAsFixed(1)}',
      sessionRef: '${modeLabel}_${played.completedAt.millisecondsSinceEpoch}',
    );
  }

  Future<void> loadFromRemote() async {
    final remote = await SimulationSessionRepository.instance.fetchAll();
    if (remote.isEmpty) return;
    _sessions
      ..clear()
      ..addAll(remote);
    _evaluations..clear();
    for (final s in remote) {
      _evaluations.addAll(s.evaluations);
    }
    notifyListeners();
  }

  List<PlayedSession> sessionsForMode(SimulationMode mode) {
    return _sessions.where((s) => s.mode == mode).toList();
  }

  void clear() {
    _evaluations.clear();
    _sessions.clear();
    _multitaskingScores.clear();
    notifyListeners();
  }
}
