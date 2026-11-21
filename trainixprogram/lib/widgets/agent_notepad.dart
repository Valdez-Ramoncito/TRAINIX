import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';

class AgentNoteItem {
  final String id;
  String title;
  String body;
  DateTime updatedAt;

  AgentNoteItem({
    required this.id,
    required this.title,
    required this.body,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();
}

/// Session-scoped agent notes (survive customer changes until session ends).
class SessionNotesStore {
  SessionNotesStore._();

  static final List<AgentNoteItem> notes = [];
  static String? selectedId;

  static AgentNoteItem? get selected {
    if (notes.isEmpty) return null;
    if (selectedId == null) return notes.first;
    for (final n in notes) {
      if (n.id == selectedId) return n;
    }
    return notes.first;
  }

  static String get selectedBody => selected?.body.trim() ?? '';

  static void ensureDefault() {
    if (notes.isNotEmpty) return;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    notes.add(AgentNoteItem(id: id, title: 'Note 1', body: ''));
    selectedId = id;
  }

  static AgentNoteItem addNote() {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final item = AgentNoteItem(
      id: id,
      title: 'Note ${notes.length + 1}',
      body: '',
    );
    notes.add(item);
    selectedId = id;
    return item;
  }

  static void deleteSelected() {
    if (notes.isEmpty) return;
    final id = selectedId ?? notes.first.id;
    notes.removeWhere((n) => n.id == id);
    selectedId = notes.isEmpty ? null : notes.first.id;
    if (notes.isEmpty) ensureDefault();
  }

  static void select(String id) {
    selectedId = id;
  }

  static void resetForSession() {
    notes.clear();
    selectedId = null;
  }
}

/// Notepad UI for the session right rail.
class AgentNotepad extends StatefulWidget {
  /// Extra bottom space so the global notification bell does not cover notes.
  /// Non-Voice has no call footer, so it needs more than Voice.
  final double bottomInset;

  /// When true, expand to fill available vertical space (Unguided rail).
  final bool fillHeight;

  const AgentNotepad({
    super.key,
    this.bottomInset = 12,
    this.fillHeight = false,
  });

  @override
  State<AgentNotepad> createState() => _AgentNotepadState();
}

class _AgentNotepadState extends State<AgentNotepad> {
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  final ScrollController _chipScroll = ScrollController();
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    SessionNotesStore.ensureDefault();
    final sel = SessionNotesStore.selected!;
    _titleController = TextEditingController(text: sel.title);
    _bodyController = TextEditingController(text: sel.body);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _chipScroll.dispose();
    super.dispose();
  }

  void _bindSelected() {
    final sel = SessionNotesStore.selected;
    if (sel == null) return;
    _titleController.text = sel.title;
    _bodyController.text = sel.body;
  }

  void _saveCurrent() {
    final sel = SessionNotesStore.selected;
    if (sel == null) return;
    sel.title = _titleController.text.trim().isEmpty
        ? sel.title
        : _titleController.text.trim();
    sel.body = _bodyController.text;
    sel.updatedAt = DateTime.now();
  }

  Future<void> _renameNoteDialog(AgentNoteItem note) async {
    final ctrl = TextEditingController(text: note.title);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.elevated(context),
          title: Text(
            'Rename note',
            style: TextStyle(color: AppColors.warningText()),
          ),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            style: TextStyle(color: AppColors.textPrimary(context)),
            decoration: InputDecoration(
              hintText: 'Note name',
              hintStyle: TextStyle(color: AppColors.textMuted(context)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    ctrl.dispose();
    if (result == null || result.isEmpty) return;
    note.title = result;
    note.updatedAt = DateTime.now();
    if (SessionNotesStore.selectedId == note.id) {
      _titleController.text = result;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    SessionNotesStore.ensureDefault();
    final items = SessionNotesStore.notes;
    final selectedId = SessionNotesStore.selectedId ?? items.first.id;

    final header = InkWell(
      mouseCursor: SystemMouseCursors.click,
      onTap: () {
        if (_expanded) _saveCurrent();
        setState(() => _expanded = !_expanded);
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
        child: Row(
          children: [
            Icon(
              Icons.sticky_note_2_outlined,
              size: 16,
              color: AppColors.warningText(),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Notepad',
                style: TextStyle(
                  color: AppColors.warningText(),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              tooltip: 'New note',
              mouseCursor: SystemMouseCursors.click,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 28,
                minHeight: 28,
              ),
              onPressed: () {
                _saveCurrent();
                SessionNotesStore.addNote();
                _bindSelected();
                setState(() => _expanded = true);
              },
              icon: Icon(
                Icons.add,
                size: 16,
                color: AppColors.warningText(),
              ),
            ),
            Icon(
              _expanded
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.keyboard_arrow_right_rounded,
              size: 18,
              color: AppColors.warningText(),
            ),
          ],
        ),
      ),
    );

    final bodyContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 34,
          child: Row(
            children: [
              IconButton(
                tooltip: 'Previous notes',
                mouseCursor: SystemMouseCursors.click,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
                ),
                onPressed: () {
                  if (!_chipScroll.hasClients) return;
                  _chipScroll.animateTo(
                    (_chipScroll.offset - 120).clamp(
                      0.0,
                      _chipScroll.position.maxScrollExtent,
                    ),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                  );
                },
                icon: Icon(
                  Icons.chevron_left,
                  size: 18,
                  color: AppColors.warningText(),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: _chipScroll,
                  scrollDirection: Axis.horizontal,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) {
                    final n = items[i];
                    final on = n.id == selectedId;
                    return InkWell(
                      mouseCursor: SystemMouseCursors.click,
                      onTap: () {
                        _saveCurrent();
                        SessionNotesStore.select(n.id);
                        _bindSelected();
                        setState(() {});
                      },
                      onLongPress: () => _renameNoteDialog(n),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: on
                              ? AppColors.elevated(context)
                              : AppColors.elevated(context),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: on
                                ? AppColors.warningText()
                                : AppColors.elevated(context),
                          ),
                        ),
                        child: Text(
                          n.title,
                          style: TextStyle(
                            color: on
                                ? AppColors.warningText()
                                : AppColors.textSecondary(context),
                            fontSize: 11,
                            fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              IconButton(
                tooltip: 'More notes',
                mouseCursor: SystemMouseCursors.click,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
                ),
                onPressed: () {
                  if (!_chipScroll.hasClients) return;
                  _chipScroll.animateTo(
                    (_chipScroll.offset + 120).clamp(
                      0.0,
                      _chipScroll.position.maxScrollExtent,
                    ),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                  );
                },
                icon: Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.warningText(),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: TextField(
            controller: _titleController,
            onChanged: (_) {
              _saveCurrent();
              setState(() {});
            },
            style: TextStyle(
              color: AppColors.warningText(),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: 'Rename this note',
              hintStyle: TextStyle(
                color: AppColors.textMuted(context),
                fontSize: 12,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 4,
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: TextField(
              controller: _bodyController,
              onChanged: (_) => _saveCurrent(),
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 12,
                height: 1.45,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.scaffold(context),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.elevated(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.elevated(context)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.warningText()),
                ),
                hintText: 'Account digits, issue, promises, next steps...',
                hintStyle: TextStyle(
                  color: AppColors.textMuted(context),
                  fontSize: 11,
                ),
                contentPadding: EdgeInsets.all(8),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Row(
            children: [
              Text(
                '${items.length} note${items.length == 1 ? '' : 's'}',
                style: TextStyle(
                  color: AppColors.textMuted(context),
                  fontSize: 10,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: items.length <= 1
                    ? null
                    : () {
                        SessionNotesStore.deleteSelected();
                        _bindSelected();
                        setState(() {});
                      },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.errorText(),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Delete',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final body = !_expanded
        ? null
        : widget.fillHeight
            ? Expanded(child: bodyContent)
            : SizedBox(height: 200, child: bodyContent);

    return Container(
      margin: EdgeInsets.fromLTRB(8, 4, 8, widget.bottomInset),
      decoration: BoxDecoration(
        color: AppColors.elevated(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.elevated(context)),
      ),
      child: Column(
        mainAxisSize: widget.fillHeight ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          if (body != null) body,
          if (widget.fillHeight && body == null) const Spacer(),
        ],
      ),
    );
  }
}
