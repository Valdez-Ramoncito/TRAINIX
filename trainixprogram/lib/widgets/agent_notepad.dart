import 'package:flutter/material.dart';

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
  const AgentNotepad({super.key});

  @override
  State<AgentNotepad> createState() => _AgentNotepadState();
}

class _AgentNotepadState extends State<AgentNotepad> {
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
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

  @override
  Widget build(BuildContext context) {
    SessionNotesStore.ensureDefault();
    final items = SessionNotesStore.notes;
    final selectedId = SessionNotesStore.selectedId ?? items.first.id;

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 56),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1712),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF3D3428)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
              if (_expanded) _saveCurrent();
              setState(() => _expanded = !_expanded);
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.sticky_note_2_outlined,
                    size: 16,
                    color: Color(0xFFFBBF24),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Notepad',
                      style: TextStyle(
                        color: Color(0xFFFDE68A),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'New note',
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
                    icon: const Icon(
                      Icons.add,
                      size: 16,
                      color: Color(0xFFFBBF24),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_right_rounded,
                    size: 18,
                    color: const Color(0xFFFBBF24),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            SizedBox(
              height: 200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (_, i) {
                        final n = items[i];
                        final on = n.id == selectedId;
                        return InkWell(
                          onTap: () {
                            _saveCurrent();
                            SessionNotesStore.select(n.id);
                            _bindSelected();
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: on
                                  ? const Color(0xFF3D3428)
                                  : const Color(0xFF252018),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: on
                                    ? const Color(0xFFFBBF24)
                                    : const Color(0xFF3D3428),
                              ),
                            ),
                            child: Text(
                              n.title,
                              style: TextStyle(
                                color: on
                                    ? const Color(0xFFFDE68A)
                                    : Colors.white70,
                                fontSize: 11,
                                fontWeight: on
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: TextField(
                      controller: _titleController,
                      onChanged: (_) => _saveCurrent(),
                      style: const TextStyle(
                        color: Color(0xFFFDE68A),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Note title',
                        hintStyle: TextStyle(
                          color: Color(0xFF78716C),
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
                        style: const TextStyle(
                          color: Color(0xFFE7E5E4),
                          fontSize: 12,
                          height: 1.45,
                        ),
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Color(0xFF12100E),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF3D3428)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF3D3428)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFFBBF24)),
                          ),
                          hintText:
                              'Account digits, issue, promises, next steps...',
                          hintStyle: TextStyle(
                            color: Color(0xFF57534E),
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
                          style: const TextStyle(
                            color: Color(0xFF78716C),
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
                            foregroundColor: const Color(0xFFF87171),
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
              ),
            ),
        ],
      ),
    );
  }
}
