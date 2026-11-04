import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/screens/page/trainer_session.dart';
import 'package:trainixprogram/screens/page/mini_training.dart';
import 'package:trainixprogram/screens/simulation_hub_screen.dart';
import 'package:trainixprogram/services/app_navigator.dart';
import 'package:trainixprogram/services/notification_inbox_service.dart';
import 'package:trainixprogram/services/supabase_service.dart';
import 'package:trainixprogram/models/training/notifications/training_notification.dart';

export 'package:trainixprogram/services/app_navigator.dart' show AppNavigator;

class NotificationBellAnchor extends StatelessWidget {
  const NotificationBellAnchor({super.key});

  static bool _panelOpen = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NotificationInboxService.instance,
      builder: (context, _) {
        final signedIn =
            SupabaseService.isReady &&
            SupabaseService.client.auth.currentUser != null;
        if (!signedIn) {
          return const SizedBox.shrink();
        }
        final unread = NotificationInboxService.instance.unreadCount;
        return Material(
          color: const Color(0xFF1A1A1A),
          elevation: 4,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            mouseCursor: SystemMouseCursors.click,
            onTap: _openPanel,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white70,
                    size: 22,
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          unread > 9 ? '9+' : '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openPanel() {
    if (_panelOpen) return;
    final navContext = AppNavigator.context;
    if (navContext == null) return;

    _panelOpen = true;
    showDialog(
      context: navContext,
      useRootNavigator: true,
      barrierColor: Colors.black54,
      builder: (ctx) {
        return ListenableBuilder(
          listenable: NotificationInboxService.instance,
          builder: (context, _) {
            final items = NotificationInboxService.instance.items;
            final recent = items.take(5).toList();
            final history = items.length > 5
                ? items.sublist(5)
                : <InboxNotification>[];
            final size = MediaQuery.of(context).size;
            final wide = size.width >= 960;

            return Dialog(
              backgroundColor: const Color(0xFF1A1A1A),
              insetPadding: EdgeInsets.symmetric(
                horizontal: wide ? size.width * 0.08 : 20,
                vertical: 40,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: wide ? 920 : 520,
                  maxHeight: size.height * 0.8,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Notifications',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                NotificationInboxService.instance.markAllRead(),
                            child: const Text('Mark all read'),
                          ),
                          IconButton(
                            mouseCursor: SystemMouseCursors.click,
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFF2A2A2A)),
                    Expanded(
                      child: items.isEmpty
                          ? const Center(
                              child: Text(
                                'No notifications yet.',
                                style: TextStyle(color: Colors.white38),
                              ),
                            )
                          : wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _RecentList(
                                    items: recent,
                                    onOpen: (n) => _handleOpen(ctx, n),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  color: const Color(0xFF2A2A2A),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: _HistoryList(
                                    items: history,
                                    onOpen: (n) => _handleOpen(ctx, n),
                                  ),
                                ),
                              ],
                            )
                          : DefaultTabController(
                              length: 2,
                              child: Column(
                                children: [
                                  const TabBar(
                                    labelColor: Color(0xFF70BD8A),
                                    unselectedLabelColor: Colors.white54,
                                    indicatorColor: Color(0xFF70BD8A),
                                    tabs: [
                                      Tab(text: 'Recent'),
                                      Tab(text: 'History'),
                                    ],
                                  ),
                                  Expanded(
                                    child: TabBarView(
                                      children: [
                                        _RecentList(
                                          items: recent,
                                          onOpen: (n) => _handleOpen(ctx, n),
                                        ),
                                        _HistoryList(
                                          items: history.isEmpty
                                              ? recent
                                              : history,
                                          onOpen: (n) => _handleOpen(ctx, n),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _panelOpen = false;
    });
  }

  void _handleOpen(BuildContext dialogCtx, InboxNotification n) {
    NotificationInboxService.instance.markRead(n.id);
    final action = n.actionType?.trim();
    final payload = n.actionPayload?.trim() ?? '';
    final hint = (n.locationHint ?? '').toLowerCase();

    void go(Widget page) {
      Navigator.pop(dialogCtx);
      final nav = AppNavigator.context;
      if (nav == null) return;
      Navigator.of(nav).push(MaterialPageRoute(builder: (_) => page));
    }

    if (action == 'join_room') {
      go(TrainerSession(initialRoomCode: payload.isEmpty ? null : payload));
      return;
    }
    if (action == 'open_trainer_session') {
      go(const TrainerSession());
      return;
    }
    if (action == 'open_mini_training' ||
        hint.contains('mini training') ||
        hint.contains('scenario practice') ||
        hint.contains('categories')) {
      go(const MiniTraining());
      return;
    }
    if (action == 'open_simulation' ||
        hint.contains('training simulation') ||
        hint.contains('simulation')) {
      go(const SimulationHubScreen());
      return;
    }
    if (hint.contains('trainer session') || hint.contains('create room')) {
      go(const TrainerSession());
    }
  }
}

class _RecentList extends StatelessWidget {
  final List<InboxNotification> items;
  final ValueChanged<InboxNotification> onOpen;

  const _RecentList({required this.items, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'Recent',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const Center(
                  child: Text(
                    'No recent notifications.',
                    style: TextStyle(color: Colors.white38),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Gap(8),
                  itemBuilder: (_, i) => _NotificationTile(
                    note: items[i],
                    emphasize: true,
                    onOpen: () => onOpen(items[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _HistoryList extends StatelessWidget {
  final List<InboxNotification> items;
  final ValueChanged<InboxNotification> onOpen;

  const _HistoryList({required this.items, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'History',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const Center(
                  child: Text(
                    'Older notifications will appear here.',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Gap(6),
                  itemBuilder: (_, i) => _NotificationTile(
                    note: items[i],
                    emphasize: false,
                    onOpen: () => onOpen(items[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final InboxNotification note;
  final bool emphasize;
  final VoidCallback onOpen;

  const _NotificationTile({
    required this.note,
    required this.emphasize,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final hint = (note.locationHint ?? '').toLowerCase();
    final action = note.actionType?.trim();
    final clickable =
        action != null && action.isNotEmpty ||
        hint.contains('trainer session') ||
        hint.contains('mini training') ||
        hint.contains('scenario practice') ||
        hint.contains('categories') ||
        hint.contains('simulation') ||
        hint.contains('create room');
    final openLabel = action == 'join_room'
        ? 'Click to open the room'
        : 'Click to open';

    return Material(
      color: note.isRead
          ? const Color(0xFF141414)
          : (emphasize ? const Color(0xFF1E2A22) : const Color(0xFF1A2220)),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        mouseCursor: clickable
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onTap: clickable ? onOpen : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      style: TextStyle(
                        fontWeight: note.isRead
                            ? FontWeight.w500
                            : FontWeight.w700,
                        fontSize: emphasize ? 13 : 12,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      [
                        note.body,
                        if (note.locationHint != null) note.locationHint!,
                      ].join('\n'),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                    if (clickable) ...[
                      const Gap(6),
                      Text(
                        openLabel,
                        style: const TextStyle(
                          color: Color(0xFF70BD8A),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
