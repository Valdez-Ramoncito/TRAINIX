import 'package:trainixprogram/services/activity_log_repository.dart';

enum TraineeLogCategory {
  auth,
  navigation,
  simulation,
  liveTraining,
  profile,
  scoring,
  system,
}

class TraineeActivityLogEntry {
  final String id;
  final DateTime at;
  final String actorName;
  final String actorRole;
  final TraineeLogCategory category;
  final String action;
  final String detail;
  final String? roomId;
  final String? sessionRef;

  const TraineeActivityLogEntry({
    required this.id,
    required this.at,
    required this.actorName,
    required this.actorRole,
    required this.category,
    required this.action,
    required this.detail,
    this.roomId,
    this.sessionRef,
  });
}

class TraineeActivityLogStore {
  TraineeActivityLogStore._();
  static final TraineeActivityLogStore instance = TraineeActivityLogStore._();

  final List<TraineeActivityLogEntry> _entries = [];

  List<TraineeActivityLogEntry> get entries =>
      List.unmodifiable(_entries.reversed.toList());

  List<TraineeActivityLogEntry> forActor(String name) {
    final n = name.trim().toLowerCase();
    return _entries
        .where((e) => e.actorName.trim().toLowerCase() == n)
        .toList()
        .reversed
        .toList();
  }

  List<TraineeActivityLogEntry> byCategory(TraineeLogCategory category) {
    return _entries
        .where((e) => e.category == category)
        .toList()
        .reversed
        .toList();
  }

  void log({
    required String actorName,
    required String actorRole,
    required TraineeLogCategory category,
    required String action,
    required String detail,
    String? roomId,
    String? sessionRef,
  }) {
    final entry = TraineeActivityLogEntry(
      id: 'log_${DateTime.now().microsecondsSinceEpoch}',
      at: DateTime.now(),
      actorName: actorName,
      actorRole: actorRole,
      category: category,
      action: action,
      detail: detail,
      roomId: roomId,
      sessionRef: sessionRef,
    );
    _entries.add(entry);
    if (_entries.length > 500) {
      _entries.removeRange(0, _entries.length - 500);
    }
    ActivityLogRepository.instance.insert(entry);
  }

  Future<void> loadFromRemote() async {
    final remote = await ActivityLogRepository.instance.fetchAll();
    if (remote.isEmpty) return;
    _entries
      ..clear()
      ..addAll(remote.reversed);
  }

  int get totalCount => _entries.length;

  int countToday() {
    final now = DateTime.now();
    return _entries.where((e) {
      return e.at.year == now.year &&
          e.at.month == now.month &&
          e.at.day == now.day;
    }).length;
  }

  Set<String> uniqueActors() {
    return _entries.map((e) => e.actorName).toSet();
  }
}
