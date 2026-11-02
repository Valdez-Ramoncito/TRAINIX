import 'package:trainixprogram/services/live_room_repository.dart';
import 'package:trainixprogram/services/live_session_run_repository.dart';

enum LiveSessionVisibility { public, private }

enum LiveSessionMode { coaching, practice, feedback, assessment }

class RoomPresence {
  final bool trainerInside;
  final bool traineeInside;
  final String? traineeDisplayName;
  final bool trainerEntryNotified;
  final bool traineeEntryNotified;

  const RoomPresence({
    this.trainerInside = false,
    this.traineeInside = false,
    this.traineeDisplayName,
    this.trainerEntryNotified = false,
    this.traineeEntryNotified = false,
  });

  int get occupantCount => (trainerInside ? 1 : 0) + (traineeInside ? 1 : 0);

  bool get isFull => occupantCount >= 2;

  bool get bothPresent => trainerInside && traineeInside;

  RoomPresence copyWith({
    bool? trainerInside,
    bool? traineeInside,
    String? traineeDisplayName,
    bool? trainerEntryNotified,
    bool? traineeEntryNotified,
  }) {
    return RoomPresence(
      trainerInside: trainerInside ?? this.trainerInside,
      traineeInside: traineeInside ?? this.traineeInside,
      traineeDisplayName: traineeDisplayName ?? this.traineeDisplayName,
      trainerEntryNotified: trainerEntryNotified ?? this.trainerEntryNotified,
      traineeEntryNotified: traineeEntryNotified ?? this.traineeEntryNotified,
    );
  }
}

class LiveTrainingSession {
  final String id;
  final String name;
  final String trainerName;
  final LiveSessionMode mode;
  final LiveSessionVisibility visibility;
  final String? designatedTraineeName;
  final String? description;
  final String? focusArea;
  final DateTime? scheduledAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final RoomPresence presence;
  final bool closed;

  const LiveTrainingSession({
    required this.id,
    required this.name,
    required this.trainerName,
    this.mode = LiveSessionMode.coaching,
    this.visibility = LiveSessionVisibility.public,
    this.designatedTraineeName,
    this.description,
    this.focusArea,
    this.scheduledAt,
    required this.createdAt,
    this.updatedAt,
    this.presence = const RoomPresence(),
    this.closed = false,
  });

  bool get isPrivate => visibility == LiveSessionVisibility.private;
  bool get isPublic => visibility == LiveSessionVisibility.public;
  bool get isScheduled => scheduledAt != null && !presence.bothPresent;

  bool isDesignatedFor(String? traineeName) {
    if (!isPrivate) return false;
    final target = designatedTraineeName?.trim().toLowerCase();
    final who = traineeName?.trim().toLowerCase();
    if (target == null || target.isEmpty || who == null || who.isEmpty) {
      return false;
    }
    if (target == who) return true;
    final t0 = target.split(RegExp(r'\s+')).first;
    final w0 = who.split(RegExp(r'\s+')).first;
    return t0 == w0;
  }

  LiveTrainingSession copyWith({
    String? id,
    String? name,
    String? trainerName,
    LiveSessionMode? mode,
    LiveSessionVisibility? visibility,
    String? designatedTraineeName,
    String? description,
    String? focusArea,
    DateTime? scheduledAt,
    bool clearScheduledAt = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    RoomPresence? presence,
    bool? closed,
  }) {
    return LiveTrainingSession(
      id: id ?? this.id,
      name: name ?? this.name,
      trainerName: trainerName ?? this.trainerName,
      mode: mode ?? this.mode,
      visibility: visibility ?? this.visibility,
      designatedTraineeName:
          designatedTraineeName ?? this.designatedTraineeName,
      description: description ?? this.description,
      focusArea: focusArea ?? this.focusArea,
      scheduledAt: clearScheduledAt ? null : (scheduledAt ?? this.scheduledAt),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      presence: presence ?? this.presence,
      closed: closed ?? this.closed,
    );
  }
}

enum RoomDisplayStatus {
  open,
  waitingForTrainer,
  waitingForTrainee,
  inSession,
  full,
  scheduled,
  completed,
  cancelled,
}

class RoomStatusInfo {
  final RoomDisplayStatus status;
  final String label;
  final String detail;
  final ColorTone tone;

  const RoomStatusInfo({
    required this.status,
    required this.label,
    required this.detail,
    required this.tone,
  });
}

enum ColorTone { neutral, blue, green, amber, red }

RoomStatusInfo computeRoomStatus(LiveTrainingSession s) {
  if (s.closed) {
    return const RoomStatusInfo(
      status: RoomDisplayStatus.completed,
      label: 'Closed',
      detail: 'Session ended  ·  Reopen to use this room again',
      tone: ColorTone.neutral,
    );
  }
  final p = s.presence;
  final occupants = p.occupantCount;

  if (p.bothPresent) {
    return RoomStatusInfo(
      status: RoomDisplayStatus.inSession,
      label: 'In Session',
      detail: '2 / 2  ·  Trainer & Trainee present',
      tone: ColorTone.green,
    );
  }

  if (p.isFull) {
    return RoomStatusInfo(
      status: RoomDisplayStatus.full,
      label: 'Full',
      detail: '2 / 2  ·  No seats left',
      tone: ColorTone.red,
    );
  }

  if (s.scheduledAt != null && !p.trainerInside && !p.traineeInside) {
    final open = canJoinBySchedule(s);
    final line = scheduleLabel(s);
    return RoomStatusInfo(
      status: RoomDisplayStatus.scheduled,
      label: open ? 'Ready' : 'Scheduled',
      detail: '$line  ·  $occupants / 2',
      tone: ColorTone.blue,
    );
  }

  if (p.traineeInside && !p.trainerInside) {
    return RoomStatusInfo(
      status: RoomDisplayStatus.waitingForTrainer,
      label: 'Waiting',
      detail: 'Waiting for Trainer ${s.trainerName}  ·  $occupants / 2',
      tone: ColorTone.amber,
    );
  }

  if (p.trainerInside && !p.traineeInside) {
    final who = s.designatedTraineeName?.trim().isNotEmpty == true
        ? s.designatedTraineeName!
        : 'Trainee';
    return RoomStatusInfo(
      status: RoomDisplayStatus.waitingForTrainee,
      label: 'Waiting',
      detail: 'Waiting for $who  ·  $occupants / 2',
      tone: ColorTone.amber,
    );
  }

  return RoomStatusInfo(
    status: RoomDisplayStatus.open,
    label: 'Open',
    detail: '$occupants / 2 present',
    tone: ColorTone.neutral,
  );
}

String _pad2(int n) => n.toString().padLeft(2, '0');

String formatCreatedAt(DateTime dt) {
  final local = dt.toLocal();
  final hour24 = local.hour;
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final ampm = hour24 >= 12 ? 'PM' : 'AM';
  final time = '$hour12:${_pad2(local.minute)} $ampm';
  final date = '${_pad2(local.month)}/${_pad2(local.day)}/${local.year}';
  return '$time  $date';
}

const int kJoinWindowMinutes = 15;

DateTime? joinOpensAt(LiveTrainingSession s) {
  final at = s.scheduledAt;
  if (at == null) return null;
  return at.subtract(const Duration(minutes: kJoinWindowMinutes));
}

bool canJoinBySchedule(LiveTrainingSession s) {
  final openFrom = joinOpensAt(s);
  if (openFrom == null) return true;
  return !DateTime.now().isBefore(openFrom);
}

String relativeUntil(DateTime target) {
  final d = target.difference(DateTime.now());
  if (d.isNegative || d.inSeconds < 60) return 'now';
  if (d.inMinutes < 60) {
    final m = d.inMinutes;
    return 'in $m min';
  }
  if (d.inHours < 48) {
    final h = d.inHours;
    if (h == 1) return 'in 1 hour';
    return 'in $h hours';
  }
  final days = d.inDays;
  if (days <= 1) return 'in 1 day';
  return 'in $days days';
}

String scheduleLabel(LiveTrainingSession s) {
  final at = s.scheduledAt;
  if (at == null) return '';
  final openFrom = joinOpensAt(s)!;
  if (canJoinBySchedule(s)) {
    return 'Starts ${formatCreatedAt(at)}  ·  Join is open';
  }
  return 'Starts ${formatCreatedAt(at)}  ·  Opens ${relativeUntil(openFrom)}';
}

class LiveSessionStore {
  LiveSessionStore._();
  static final LiveSessionStore instance = LiveSessionStore._();

  final List<LiveTrainingSession> _sessions = [];
  final Set<String> _remindedIds = {};
  final Map<String, SessionWorkbench> _workbenches = {};
  final List<LiveTrainingHistoryEntry> _historyArchive = [];
  final List<void Function()> _listeners = [];

  List<LiveTrainingSession> get sessions => List.unmodifiable(_sessions);

  Future<void> loadFromRemote() async {
    final remote = await LiveRoomRepository.instance.fetchAll();
    if (remote.isNotEmpty) {
      final byId = {for (final s in _sessions) s.id: s};
      for (final r in remote) {
        final local = byId[r.id];
        if (local == null) {
          _sessions.add(r);
        } else {
          final i = _sessions.indexWhere((s) => s.id == r.id);
          if (i != -1) {
            _sessions[i] = r.copyWith(presence: local.presence);
          }
        }
      }
      _sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    final runs = await LiveSessionRunRepository.instance.fetchAll();
    if (runs.isNotEmpty) {
      _historyArchive
        ..clear()
        ..addAll(runs);
    }
    _notify();
  }

  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  void _notify() {
    for (final listener in List<void Function()>.from(_listeners)) {
      listener();
    }
  }

  List<LiveTrainingSession> roomsForTrainer(String trainerName) {
    final key = trainerName.trim().toLowerCase();
    final list = _sessions
        .where((s) => s.trainerName.trim().toLowerCase() == key)
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  bool isOwnedBy(String roomId, String trainerName) {
    final s = findByCode(roomId);
    if (s == null) return false;
    return s.trainerName.trim().toLowerCase() ==
        trainerName.trim().toLowerCase();
  }

  List<LiveTrainingSession> upcomingSessions({
    String? trainerName,
    String? traineeName,
    int withinHours = 24,
    int maxItems = 5,
  }) {
    final now = DateTime.now();
    final latest = now.add(Duration(hours: withinHours));
    final earliest = now.subtract(const Duration(minutes: 30));

    final list = _sessions.where((s) {
      final at = s.scheduledAt;
      if (at == null) return false;
      if (at.isAfter(latest)) return false;
      if (at.isBefore(earliest)) return false;
      if (trainerName != null && trainerName.trim().isNotEmpty) {
        if (s.trainerName.trim().toLowerCase() !=
            trainerName.trim().toLowerCase()) {
          return false;
        }
      }
      if (traineeName != null && traineeName.trim().isNotEmpty) {
        final mine = s.isDesignatedFor(traineeName);
        final publicOpen = s.isPublic;
        if (!mine && !publicOpen) return false;
      }
      return true;
    }).toList();

    list.sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));
    if (list.length > maxItems) {
      return list.sublist(0, maxItems);
    }
    return list;
  }

  List<LiveTrainingSession> roomsNeedingReminder() {
    final now = DateTime.now();
    final out = <LiveTrainingSession>[];
    for (final s in _sessions) {
      final at = s.scheduledAt;
      if (at == null) continue;
      if (_remindedIds.contains(s.id)) continue;
      final diff = at.difference(now);
      if (diff.inMinutes <= kJoinWindowMinutes && diff.inMinutes >= -30) {
        out.add(s);
      }
    }
    return out;
  }

  void markReminded(String id) {
    _remindedIds.add(id);
  }

  List<LiveTrainingSession> joinableForTrainee({String? traineeName}) {
    final list = _sessions.where((s) {
      if (s.closed) return false;
      final st = computeRoomStatus(s).status;
      return st != RoomDisplayStatus.completed &&
          st != RoomDisplayStatus.cancelled;
    }).toList();

    list.sort((a, b) {
      final aMine = a.isDesignatedFor(traineeName);
      final bMine = b.isDesignatedFor(traineeName);
      if (aMine && !bMine) return -1;
      if (!aMine && bMine) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }

  void add(LiveTrainingSession session) {
    _sessions.removeWhere((s) => s.id == session.id);
    _sessions.insert(0, session);
    _notify();
    LiveRoomRepository.instance.upsert(session);
  }

  void update(LiveTrainingSession session) {
    final i = _sessions.indexWhere((s) => s.id == session.id);
    if (i == -1) {
      _sessions.insert(0, session);
    } else {
      _sessions[i] = session;
    }
    _notify();
    LiveRoomRepository.instance.upsert(session);
  }

  void remove(String id) {
    _sessions.removeWhere((s) => s.id == id);
    _notify();
    LiveRoomRepository.instance.delete(id);
  }

  LiveTrainingSession? findByCode(String code) {
    final normalized = code.trim();
    try {
      return _sessions.firstWhere((s) => s.id == normalized);
    } catch (_) {
      return null;
    }
  }

  String? tryJoin({
    required String roomId,
    required bool asTrainer,
    String? traineeDisplayName,
    void Function(bool firstEntry)? onJoined,
  }) {
    final i = _sessions.indexWhere((s) => s.id == roomId);
    if (i == -1) return 'Room not found';

    final s = _sessions[i];
    if (s.closed) {
      return 'This room is closed. Ask the trainer to reopen it.';
    }
    if (!canJoinBySchedule(s)) {
      return 'Room opens 15 minutes before ${formatCreatedAt(s.scheduledAt!)}';
    }
    final p = s.presence;

    if (asTrainer) {
      if (p.trainerInside) return 'You are already in this room';
      if (p.isFull) return 'Room is full (1 trainer + 1 trainee only)';
      final first = !p.trainerEntryNotified;
      _sessions[i] = s.copyWith(
        presence: p.copyWith(trainerInside: true, trainerEntryNotified: true),
        updatedAt: DateTime.now(),
      );
      onJoined?.call(first);
      _notify();
      return null;
    }

    if (p.traineeInside) return 'A trainee is already in this room';
    if (p.isFull) return 'Room is full (1 trainer + 1 trainee only)';
    final first = !p.traineeEntryNotified;
    _sessions[i] = s.copyWith(
      presence: p.copyWith(
        traineeInside: true,
        traineeDisplayName: traineeDisplayName,
        traineeEntryNotified: true,
      ),
      updatedAt: DateTime.now(),
    );
    onJoined?.call(first);
    _notify();
    return null;
  }

  SessionWorkbench _emptyWorkbench(String roomId, {LiveSessionMode? mode}) {
    final now = DateTime.now();
    final firstId = 'note_${now.millisecondsSinceEpoch}';
    return SessionWorkbench(
      roomId: roomId,
      notes: [
        SessionNote(id: firstId, title: 'Note 1', body: '', updatedAt: now),
      ],
      activeNoteId: firstId,
      checklist: mode != null
          ? SessionWorkbench.defaultChecklist(mode)
          : const [],
      startedAt: now,
    );
  }

  SessionWorkbench workbenchFor(LiveTrainingSession session) {
    final existing = _workbenches[session.id];
    if (existing != null) return existing;
    final created = _emptyWorkbench(session.id, mode: session.mode);
    _workbenches[session.id] = created;
    return created;
  }

  SessionWorkbench _require(String roomId) {
    final existing = _workbenches[roomId];
    if (existing != null) return existing;
    LiveSessionMode? mode;
    for (final s in _sessions) {
      if (s.id == roomId) {
        mode = s.mode;
        break;
      }
    }
    final created = _emptyWorkbench(roomId, mode: mode);
    _workbenches[roomId] = created;
    return created;
  }

  void saveWorkbench(SessionWorkbench bench) {
    _workbenches[bench.roomId] = bench;
  }

  SessionWorkbench selectNote(String roomId, String noteId) {
    final current = _require(roomId);
    final next = current.copyWith(activeNoteId: noteId);
    _workbenches[roomId] = next;
    return next;
  }

  SessionWorkbench addNote(String roomId) {
    final current = _require(roomId);
    final now = DateTime.now();
    final id = 'note_${now.millisecondsSinceEpoch}';
    final n = current.notes.length + 1;
    final note = SessionNote(
      id: id,
      title: 'Note $n',
      body: '',
      updatedAt: now,
    );
    final next = current.copyWith(
      notes: [...current.notes, note],
      activeNoteId: id,
    );
    _workbenches[roomId] = next;
    return next;
  }

  SessionWorkbench updateActiveNote({
    required String roomId,
    String? title,
    String? body,
  }) {
    final current = _require(roomId);
    final active = current.activeNote;
    if (active == null) return current;
    final updated = active.copyWith(
      title: title,
      body: body,
      updatedAt: DateTime.now(),
    );
    final list = current.notes
        .map((n) => n.id == active.id ? updated : n)
        .toList();
    final next = current.copyWith(notes: list, activeNoteId: active.id);
    _workbenches[roomId] = next;
    return next;
  }

  SessionWorkbench removeNote(String roomId, String noteId) {
    final current = _require(roomId);
    if (current.notes.length <= 1) return current;
    final list = current.notes.where((n) => n.id != noteId).toList();
    String? active = current.activeNoteId;
    if (active == noteId) {
      active = list.first.id;
    }
    final next = current.copyWith(notes: list, activeNoteId: active);
    _workbenches[roomId] = next;
    return next;
  }

  SessionWorkbench toggleChecklistItem(String roomId, String itemId) {
    final current = _require(roomId);
    final list = current.checklist.map((item) {
      if (item.id != itemId) return item;
      return item.copyWith(done: !item.done);
    }).toList();
    final next = current.copyWith(checklist: list);
    _workbenches[roomId] = next;
    return next;
  }

  SessionWorkbench addChecklistItem(String roomId, String label) {
    final current = _require(roomId);
    final trimmed = label.trim();
    if (trimmed.isEmpty) return current;
    final item = SessionChecklistItem(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      label: trimmed,
    );
    final next = current.copyWith(checklist: [...current.checklist, item]);
    _workbenches[roomId] = next;
    return next;
  }

  SessionWorkbench removeChecklistItem(String roomId, String itemId) {
    final current = _require(roomId);
    final list = current.checklist.where((c) => c.id != itemId).toList();
    final next = current.copyWith(checklist: list);
    _workbenches[roomId] = next;
    return next;
  }

  SessionWorkbench saveFeedback({
    required String roomId,
    required int? rating,
    required String feedback,
    String? takeaway,
    bool? needsFollowUp,
  }) {
    final current = _require(roomId);
    final next = current.copyWith(
      rating: rating,
      clearRating: rating == null,
      feedback: feedback,
      takeaway: takeaway,
      needsFollowUp: needsFollowUp,
    );
    _workbenches[roomId] = next;
    return next;
  }

  LiveTrainingHistoryEntry _snapshotHistory(
    LiveTrainingSession s,
    SessionWorkbench w,
  ) {
    return LiveTrainingHistoryEntry(
      roomId: s.id,
      roomName: s.name,
      trainerName: s.trainerName,
      traineeName: s.designatedTraineeName ?? s.presence.traineeDisplayName,
      mode: s.mode,
      startedAt: w.startedAt,
      endedAt: w.endedAt ?? DateTime.now(),
      rating: w.rating,
      feedback: w.feedback,
      takeaway: w.takeaway,
      needsFollowUp: w.needsFollowUp,
      checklistDone: w.checklistDoneCount,
      checklistTotal: w.checklist.length,
      noteCount: w.notes.length,
      notes: List<SessionNote>.from(w.notes),
      checklist: List<SessionChecklistItem>.from(w.checklist),
      roomClosed: true,
    );
  }

  SessionWorkbench endSession(String roomId) {
    final current = _require(roomId);
    final endedAt = DateTime.now();
    final next = current.copyWith(ended: true, endedAt: endedAt);
    _workbenches[roomId] = next;
    final i = _sessions.indexWhere((s) => s.id == roomId);
    if (i != -1) {
      final s = _sessions[i];
      final snap = _snapshotHistory(s, next);
      _historyArchive.add(snap);
      LiveSessionRunRepository.instance.insert(snap);
      _sessions[i] = s.copyWith(
        closed: true,
        presence: s.presence.copyWith(
          trainerInside: false,
          traineeInside: false,
          traineeDisplayName: null,
        ),
        updatedAt: endedAt,
      );
    }
    _notify();
    final closedRoom = findByCode(roomId);
    if (closedRoom != null) {
      LiveRoomRepository.instance.upsert(closedRoom);
    }
    return next;
  }

  LiveTrainingSession? reopenRoom(String roomId, {String? byTrainerName}) {
    final i = _sessions.indexWhere((s) => s.id == roomId);
    if (i == -1) return null;
    final s = _sessions[i];
    if (byTrainerName != null &&
        s.trainerName.trim().toLowerCase() !=
            byTrainerName.trim().toLowerCase()) {
      return null;
    }
    final reopened = s.copyWith(
      closed: false,
      presence: const RoomPresence(),
      updatedAt: DateTime.now(),
    );
    _sessions[i] = reopened;
    _workbenches[roomId] = _emptyWorkbench(roomId, mode: s.mode);
    _notify();
    LiveRoomRepository.instance.upsert(reopened);
    return reopened;
  }

  List<LiveTrainingHistoryEntry> historyEntries() {
    final out = List<LiveTrainingHistoryEntry>.from(_historyArchive);
    out.sort((a, b) => b.endedAt.compareTo(a.endedAt));
    return out;
  }

  void leave({required String roomId, required bool asTrainer}) {
    final i = _sessions.indexWhere((s) => s.id == roomId);
    if (i == -1) return;
    final s = _sessions[i];
    final p = s.presence;
    if (asTrainer) {
      _sessions[i] = s.copyWith(
        presence: p.copyWith(trainerInside: false),
        updatedAt: DateTime.now(),
      );
    } else {
      _sessions[i] = s.copyWith(
        presence: p.copyWith(traineeInside: false, traineeDisplayName: null),
        updatedAt: DateTime.now(),
      );
    }
    _notify();
  }
}

class SessionChecklistItem {
  final String id;
  final String label;
  final bool done;

  const SessionChecklistItem({
    required this.id,
    required this.label,
    this.done = false,
  });

  SessionChecklistItem copyWith({String? label, bool? done}) {
    return SessionChecklistItem(
      id: id,
      label: label ?? this.label,
      done: done ?? this.done,
    );
  }
}

class SessionNote {
  final String id;
  final String title;
  final String body;
  final DateTime updatedAt;

  const SessionNote({
    required this.id,
    required this.title,
    required this.body,
    required this.updatedAt,
  });

  SessionNote copyWith({String? title, String? body, DateTime? updatedAt}) {
    return SessionNote(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SessionWorkbench {
  final String roomId;
  final List<SessionNote> notes;
  final String? activeNoteId;
  final List<SessionChecklistItem> checklist;
  final String takeaway;
  final bool needsFollowUp;
  final int? rating;
  final String feedback;
  final bool ended;
  final DateTime? endedAt;
  final DateTime startedAt;

  const SessionWorkbench({
    required this.roomId,
    this.notes = const [],
    this.activeNoteId,
    this.checklist = const [],
    this.takeaway = '',
    this.needsFollowUp = false,
    this.rating,
    this.feedback = '',
    this.ended = false,
    this.endedAt,
    required this.startedAt,
  });

  SessionNote? get activeNote {
    if (notes.isEmpty) return null;
    if (activeNoteId == null) return notes.first;
    for (final n in notes) {
      if (n.id == activeNoteId) return n;
    }
    return notes.first;
  }

  int get checklistDoneCount => checklist.where((c) => c.done).length;

  SessionWorkbench copyWith({
    List<SessionNote>? notes,
    String? activeNoteId,
    bool clearActiveNoteId = false,
    List<SessionChecklistItem>? checklist,
    String? takeaway,
    bool? needsFollowUp,
    int? rating,
    bool clearRating = false,
    String? feedback,
    bool? ended,
    DateTime? endedAt,
    bool clearEndedAt = false,
    DateTime? startedAt,
  }) {
    return SessionWorkbench(
      roomId: roomId,
      notes: notes ?? this.notes,
      activeNoteId: clearActiveNoteId
          ? null
          : (activeNoteId ?? this.activeNoteId),
      checklist: checklist ?? this.checklist,
      takeaway: takeaway ?? this.takeaway,
      needsFollowUp: needsFollowUp ?? this.needsFollowUp,
      rating: clearRating ? null : (rating ?? this.rating),
      feedback: feedback ?? this.feedback,
      ended: ended ?? this.ended,
      endedAt: clearEndedAt ? null : (endedAt ?? this.endedAt),
      startedAt: startedAt ?? this.startedAt,
    );
  }

  static List<SessionChecklistItem> defaultChecklist(LiveSessionMode mode) {
    switch (mode) {
      case LiveSessionMode.coaching:
        return const [
          SessionChecklistItem(id: 'c1', label: 'Greeting and context set'),
          SessionChecklistItem(id: 'c2', label: 'Main issue discussed'),
          SessionChecklistItem(id: 'c3', label: 'Guidance or tip given'),
          SessionChecklistItem(id: 'c4', label: 'Trainee practiced a response'),
          SessionChecklistItem(id: 'c5', label: 'Next steps agreed'),
        ];
      case LiveSessionMode.practice:
        return const [
          SessionChecklistItem(id: 'p1', label: 'Scenario explained'),
          SessionChecklistItem(id: 'p2', label: 'Trainee ran the flow'),
          SessionChecklistItem(id: 'p3', label: 'Corrections noted'),
          SessionChecklistItem(id: 'p4', label: 'Retry completed'),
        ];
      case LiveSessionMode.feedback:
        return const [
          SessionChecklistItem(id: 'f1', label: 'Strengths reviewed'),
          SessionChecklistItem(id: 'f2', label: 'Gaps reviewed'),
          SessionChecklistItem(id: 'f3', label: 'Action items listed'),
        ];
      case LiveSessionMode.assessment:
        return const [
          SessionChecklistItem(id: 'a1', label: 'Criteria shared'),
          SessionChecklistItem(id: 'a2', label: 'Performance observed'),
          SessionChecklistItem(id: 'a3', label: 'Score or result recorded'),
        ];
    }
  }
}

class LiveTrainingHistoryEntry {
  final String roomId;
  final String roomName;
  final String trainerName;
  final String? traineeName;
  final LiveSessionMode mode;
  final DateTime startedAt;
  final DateTime endedAt;
  final int? rating;
  final String feedback;
  final String takeaway;
  final bool needsFollowUp;
  final int checklistDone;
  final int checklistTotal;
  final int noteCount;
  final List<SessionNote> notes;
  final List<SessionChecklistItem> checklist;
  final bool roomClosed;

  const LiveTrainingHistoryEntry({
    required this.roomId,
    required this.roomName,
    required this.trainerName,
    this.traineeName,
    required this.mode,
    required this.startedAt,
    required this.endedAt,
    this.rating,
    this.feedback = '',
    this.takeaway = '',
    this.needsFollowUp = false,
    this.checklistDone = 0,
    this.checklistTotal = 0,
    this.noteCount = 0,
    this.notes = const [],
    this.checklist = const [],
    this.roomClosed = true,
  });
}
