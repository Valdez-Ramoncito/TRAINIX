class MessageSessionItem {
  final String id;
  final String name;
  final String messageCount;
  final String date;
  final bool isCurrent;
  bool isPinned;

  MessageSessionItem({
    required this.id,
    required this.name,
    required this.messageCount,
    required this.date,
    this.isCurrent = false,
    this.isPinned = false,
  });
}

final List<MessageSessionItem> allMessages = [
  // Current / Recent messages
  MessageSessionItem(
    id: '1',
    name: 'Rimuru Tempest',
    messageCount: '1 message',
    date: 'June 6, 2026',
    isCurrent: true,
    isPinned: false,
  ),
  MessageSessionItem(
    id: '2',
    name: 'Rimuru Tempest',
    messageCount: '1 message',
    date: 'June 6, 2026',
    isCurrent: true,
    isPinned: true,
  ),
  // Saved before current / Previous history
  MessageSessionItem(
    id: '3',
    name: 'Veldora Tempest',
    messageCount: '3 messages',
    date: 'June 4, 2026',
    isCurrent: false,
    isPinned: false,
  ),
  MessageSessionItem(
    id: '4',
    name: 'Milim Nava',
    messageCount: '5 messages',
    date: 'June 2, 2026',
    isCurrent: false,
    isPinned: true,
  ),
  MessageSessionItem(
    id: '5',
    name: 'Shion',
    messageCount: '2 messages',
    date: 'May 28, 2026',
    isCurrent: false,
    isPinned: false,
  ),
];
